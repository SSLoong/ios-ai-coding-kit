import Foundation

// MARK: - Protocols

protocol NetworkServiceProtocol {
    func fetchData(from url: URL) async throws -> Data
}

protocol CacheProtocol {
    func get(key: String) -> Any?
    func set(key: String, value: Any, expirationTime: TimeInterval)
    func remove(key: String)
}

// MARK: - Models

struct User: Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let createdAt: Date
}

enum UserManagerError: Error, Equatable {
    case invalidUserId
    case networkFailure
    case decodingFailed
    case cacheCorrupted
}

// MARK: - UserManager

/// 用户管理器，负责获取和缓存用户数据
class UserManager {
    private let networkService: NetworkServiceProtocol
    private let cache: CacheProtocol
    private let cacheExpirationTime: TimeInterval
    
    init(
        networkService: NetworkServiceProtocol,
        cache: CacheProtocol,
        cacheExpirationTime: TimeInterval = 3600
    ) {
        self.networkService = networkService
        self.cache = cache
        self.cacheExpirationTime = cacheExpirationTime
    }
    
    /// 获取用户信息（优先从缓存读取）
    func fetchUser(id: String) async throws -> User {
        guard !id.isEmpty else {
            throw UserManagerError.invalidUserId
        }
        
        let cacheKey = "user_\(id)"
        if let cachedUser = cache.get(key: cacheKey) as? User {
            return cachedUser
        }
        
        let url = URL(string: "https://api.example.com/users/\(id)")!
        
        do {
            let data = try await networkService.fetchData(from: url)
            let user = try JSONDecoder().decode(User.self, from: data)
            cache.set(key: cacheKey, value: user, expirationTime: cacheExpirationTime)
            return user
        } catch is DecodingError {
            throw UserManagerError.decodingFailed
        } catch {
            throw UserManagerError.networkFailure
        }
    }
    
    /// 删除用户缓存
    func clearCache(for userId: String) {
        let cacheKey = "user_\(userId)"
        cache.remove(key: cacheKey)
    }
    
    /// 批量获取用户
    func fetchUsers(ids: [String]) async throws -> [User] {
        try await withThrowingTaskGroup(of: User.self) { group in
            for id in ids {
                group.addTask {
                    try await self.fetchUser(id: id)
                }
            }
            
            var users: [User] = []
            for try await user in group {
                users.append(user)
            }
            return users
        }
    }
}
