import XCTest
@testable import YourModule

// MARK: - Mock Objects

class MockNetworkService: NetworkServiceProtocol {
    var shouldThrowError = false
    var errorToThrow: Error = UserManagerError.networkFailure
    var mockedData: Data?
    var fetchCallCount = 0
    var lastFetchedURL: URL?
    
    func fetchData(from url: URL) async throws -> Data {
        fetchCallCount += 1
        lastFetchedURL = url
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return mockedData ?? Data()
    }
}

class MockCache: CacheProtocol {
    private var storage: [String: (value: Any, expiration: Date)] = [:]
    var setCallCount = 0
    var getCallCount = 0
    var removeCallCount = 0
    
    func get(key: String) -> Any? {
        getCallCount += 1
        guard let item = storage[key] else { return nil }
        
        if item.expiration < Date() {
            storage.removeValue(forKey: key)
            return nil
        }
        return item.value
    }
    
    func set(key: String, value: Any, expirationTime: TimeInterval) {
        setCallCount += 1
        let expiration = Date().addingTimeInterval(expirationTime)
        storage[key] = (value: value, expiration: expiration)
    }
    
    func remove(key: String) {
        removeCallCount += 1
        storage.removeValue(forKey: key)
    }
    
    func clear() {
        storage.removeAll()
    }
}

// MARK: - Test Helpers

extension User {
    static func mock(
        id: String = "123",
        name: String = "John Doe",
        email: String = "john@example.com",
        createdAt: Date = Date()
    ) -> User {
        User(id: id, name: name, email: email, createdAt: createdAt)
    }
}

// MARK: - Tests

final class UserManagerTests: XCTestCase {
    var sut: UserManager!
    var mockNetworkService: MockNetworkService!
    var mockCache: MockCache!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockCache = MockCache()
        sut = UserManager(
            networkService: mockNetworkService,
            cache: mockCache,
            cacheExpirationTime: 3600
        )
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockCache = nil
        super.tearDown()
    }
    
    // MARK: - fetchUser Tests
    
    func test_fetchUser_withValidID_returnsUser() async throws {
        // Given
        let expectedUser = User.mock(id: "123", name: "Alice")
        let userData = try JSONEncoder().encode(expectedUser)
        mockNetworkService.mockedData = userData
        
        // When
        let user = try await sut.fetchUser(id: "123")
        
        // Then
        XCTAssertEqual(user.id, expectedUser.id)
        XCTAssertEqual(user.name, expectedUser.name)
        XCTAssertEqual(user.email, expectedUser.email)
        XCTAssertEqual(mockNetworkService.fetchCallCount, 1)
    }
    
    func test_fetchUser_withCachedUser_returnsCachedUser() async throws {
        // Given
        let cachedUser = User.mock(id: "123", name: "Cached User")
        mockCache.set(key: "user_123", value: cachedUser, expirationTime: 3600)
        
        // When
        let user = try await sut.fetchUser(id: "123")
        
        // Then
        XCTAssertEqual(user.id, cachedUser.id)
        XCTAssertEqual(user.name, cachedUser.name)
        XCTAssertEqual(mockNetworkService.fetchCallCount, 0, "Should not call network when cache hit")
        XCTAssertEqual(mockCache.getCallCount, 1)
    }
    
    func test_fetchUser_withEmptyID_throwsInvalidUserIdError() async {
        // Given
        let emptyID = ""
        
        // When & Then
        do {
            _ = try await sut.fetchUser(id: emptyID)
            XCTFail("Expected UserManagerError.invalidUserId to be thrown")
        } catch {
            XCTAssertEqual(error as? UserManagerError, .invalidUserId)
        }
    }
    
    func test_fetchUser_withNetworkFailure_throwsNetworkFailureError() async {
        // Given
        mockNetworkService.shouldThrowError = true
        mockNetworkService.errorToThrow = UserManagerError.networkFailure
        
        // When & Then
        do {
            _ = try await sut.fetchUser(id: "123")
            XCTFail("Expected UserManagerError.networkFailure to be thrown")
        } catch {
            XCTAssertEqual(error as? UserManagerError, .networkFailure)
        }
    }
    
    func test_fetchUser_withInvalidJSON_throwsDecodingFailedError() async {
        // Given
        mockNetworkService.mockedData = "invalid json".data(using: .utf8)
        
        // When & Then
        do {
            _ = try await sut.fetchUser(id: "123")
            XCTFail("Expected UserManagerError.decodingFailed to be thrown")
        } catch {
            XCTAssertEqual(error as? UserManagerError, .decodingFailed)
        }
    }
    
    func test_fetchUser_withNetworkSuccess_cachesUser() async throws {
        // Given
        let user = User.mock(id: "456", name: "Jane Doe")
        let userData = try JSONEncoder().encode(user)
        mockNetworkService.mockedData = userData
        
        // When
        _ = try await sut.fetchUser(id: "456")
        
        // Then
        XCTAssertEqual(mockCache.setCallCount, 1)
        let cachedUser = mockCache.get(key: "user_456") as? User
        XCTAssertNotNil(cachedUser)
        XCTAssertEqual(cachedUser?.id, user.id)
    }
    
    func test_fetchUser_constructsCorrectURL() async throws {
        // Given
        let userId = "789"
        let expectedURL = URL(string: "https://api.example.com/users/789")!
        mockNetworkService.mockedData = try JSONEncoder().encode(User.mock(id: userId))
        
        // When
        _ = try await sut.fetchUser(id: userId)
        
        // Then
        XCTAssertEqual(mockNetworkService.lastFetchedURL, expectedURL)
    }
    
    // MARK: - clearCache Tests
    
    func test_clearCache_removesUserFromCache() {
        // Given
        let userId = "123"
        let user = User.mock(id: userId)
        mockCache.set(key: "user_\(userId)", value: user, expirationTime: 3600)
        
        // When
        sut.clearCache(for: userId)
        
        // Then
        XCTAssertEqual(mockCache.removeCallCount, 1)
        let cachedUser = mockCache.get(key: "user_\(userId)")
        XCTAssertNil(cachedUser)
    }
    
    // MARK: - fetchUsers Tests
    
    func test_fetchUsers_withMultipleIDs_returnsAllUsers() async throws {
        // Given
        let user1 = User.mock(id: "1", name: "User 1")
        let user2 = User.mock(id: "2", name: "User 2")
        let user3 = User.mock(id: "3", name: "User 3")
        
        mockNetworkService.mockedData = try JSONEncoder().encode(user1)
        
        // When
        let users = try await sut.fetchUsers(ids: ["1", "2", "3"])
        
        // Then
        XCTAssertEqual(users.count, 3)
        XCTAssertEqual(mockNetworkService.fetchCallCount, 3)
    }
    
    func test_fetchUsers_withEmptyArray_returnsEmptyArray() async throws {
        // When
        let users = try await sut.fetchUsers(ids: [])
        
        // Then
        XCTAssertTrue(users.isEmpty)
        XCTAssertEqual(mockNetworkService.fetchCallCount, 0)
    }
    
    func test_fetchUsers_withOneFailure_throwsError() async {
        // Given
        mockNetworkService.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await sut.fetchUsers(ids: ["1", "2"])
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
