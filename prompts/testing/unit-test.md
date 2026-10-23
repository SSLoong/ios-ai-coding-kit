# 单元测试生成提示词

## 场景说明
为 Swift 类或结构体生成全面的 XCTest 单元测试，包括正常流程、边界条件和错误处理。

## 输入要求

### 必需
- 目标类/结构体的完整源代码
- 依赖的协议或类型定义
- 测试框架：XCTest

### 可选
- 现有测试用例作为风格参考
- 项目测试命名约定
- Mock 策略说明

## 提示词模板

```
我需要为以下 Swift 代码生成单元测试：

[粘贴目标类的完整代码]

## 测试要求

### 1. 覆盖范围
- 所有公开方法（public/internal）
- 正常执行路径
- 边界条件（空值、空数组、极大/极小值）
- 错误处理分支（throws、optional 为 nil 的情况）

### 2. 测试结构
- 使用 XCTest 框架
- 遵循 Given-When-Then 结构
- 测试用例命名：`test_<方法名>_<场景>_<预期结果>`
- 每个测试独立，不依赖其他测试

### 3. Mock 策略
- 为以下依赖创建 Mock 对象：[列出需要 Mock 的依赖]
- Mock 类放在测试文件顶部
- 使用协议而非具体类型，便于 Mock

### 4. 异步处理
- 对于 async/await 方法，测试方法也使用 async
- 对于 completion handler，使用 XCTestExpectation
- 超时时间设置为 5 秒

### 5. 断言精度
- 优先使用精确断言（XCTAssertEqual）而非模糊断言（XCTAssertNotNil）
- 验证关键属性而非仅检查对象存在
- 错误类型匹配使用 XCTAssertThrowsError

## 输出格式
1. 先输出测试计划（Markdown 列表），列出每个方法需要测试的场景
2. 等待我确认测试计划
3. 确认后，生成完整的测试代码，包括：
   - import 语句
   - Mock 对象定义
   - 测试类 setup/tearDown
   - 所有测试用例实现

## 附加上下文
[可选：粘贴依赖类型定义]
[可选：粘贴一个现有测试作为风格参考]
```

## 使用示例

### 输入

```swift
class UserManager {
    private let networkService: NetworkServiceProtocol
    private let cache: CacheProtocol
    
    init(networkService: NetworkServiceProtocol, cache: CacheProtocol) {
        self.networkService = networkService
        self.cache = cache
    }
    
    func fetchUser(id: String) async throws -> User {
        if let cachedUser = cache.get(key: "user_\(id)") as? User {
            return cachedUser
        }
        
        let user = try await networkService.fetchUser(id: id)
        cache.set(key: "user_\(id)", value: user)
        return user
    }
}
```

### AI 输出（第一步：测试计划）

```markdown
## UserManager 测试计划

### fetchUser(id:) 方法
1. test_fetchUser_withValidID_returnsUser
   - 验证：从网络获取用户并返回
   
2. test_fetchUser_withCachedUser_returnsCachedUser
   - 验证：优先返回缓存数据，不调用网络请求
   
3. test_fetchUser_withInvalidID_throwsError
   - 验证：网络请求失败时抛出错误
   
4. test_fetchUser_withNetworkSuccess_cachesUser
   - 验证：成功获取后将用户存入缓存

请确认是否需要添加其他测试场景。
```

### AI 输出（第二步：确认后生成代码）

```swift
import XCTest
@testable import YourModule

// MARK: - Mock Objects

class MockNetworkService: NetworkServiceProtocol {
    var shouldThrowError = false
    var mockedUser: User?
    var fetchUserCallCount = 0
    
    func fetchUser(id: String) async throws -> User {
        fetchUserCallCount += 1
        if shouldThrowError {
            throw NetworkError.requestFailed
        }
        return mockedUser ?? User(id: id, name: "Test User")
    }
}

class MockCache: CacheProtocol {
    private var storage: [String: Any] = [:]
    var setCallCount = 0
    var getCallCount = 0
    
    func get(key: String) -> Any? {
        getCallCount += 1
        return storage[key]
    }
    
    func set(key: String, value: Any) {
        setCallCount += 1
        storage[key] = value
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
        sut = UserManager(networkService: mockNetworkService, cache: mockCache)
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
        let expectedUser = User(id: "123", name: "John Doe")
        mockNetworkService.mockedUser = expectedUser
        
        // When
        let user = try await sut.fetchUser(id: "123")
        
        // Then
        XCTAssertEqual(user.id, expectedUser.id)
        XCTAssertEqual(user.name, expectedUser.name)
        XCTAssertEqual(mockNetworkService.fetchUserCallCount, 1)
    }
    
    func test_fetchUser_withCachedUser_returnsCachedUser() async throws {
        // Given
        let cachedUser = User(id: "123", name: "Cached User")
        mockCache.set(key: "user_123", value: cachedUser)
        
        // When
        let user = try await sut.fetchUser(id: "123")
        
        // Then
        XCTAssertEqual(user.id, cachedUser.id)
        XCTAssertEqual(user.name, cachedUser.name)
        XCTAssertEqual(mockNetworkService.fetchUserCallCount, 0, "Should not call network when cache hit")
        XCTAssertEqual(mockCache.getCallCount, 1)
    }
    
    func test_fetchUser_withInvalidID_throwsError() async {
        // Given
        mockNetworkService.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await sut.fetchUser(id: "invalid")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func test_fetchUser_withNetworkSuccess_cachesUser() async throws {
        // Given
        let user = User(id: "456", name: "Jane Doe")
        mockNetworkService.mockedUser = user
        
        // When
        _ = try await sut.fetchUser(id: "456")
        
        // Then
        XCTAssertEqual(mockCache.setCallCount, 1)
        let cachedUser = mockCache.get(key: "user_456") as? User
        XCTAssertNotNil(cachedUser)
        XCTAssertEqual(cachedUser?.id, user.id)
    }
}
```

## 注意事项

### ✅ 好的做法
- 提供完整的上下文（包括依赖类型）
- 先确认测试计划，避免生成不必要的测试
- 指定明确的命名约定
- 要求 AI 使用精确断言

### ❌ 避免的做法
- 一次性要求生成整个模块的测试（容易遗漏细节）
- 不提供依赖类型，导致 AI 猜测 Mock 接口
- 忽略异步测试的超时处理
- 接受模糊的断言（如只检查 notNil）

### 🔧 常见调整
如果生成的测试不符合预期，可以追加指令：

```
请调整以下内容：
1. 测试命名改为 `testMethodName_Scenario_ExpectedResult` 格式
2. 将所有 Mock 对象移到单独的文件 `Mocks.swift`
3. 为 test_fetchUser_withCachedUser 添加验证：确保网络请求未被调用
4. 添加边界测试：空字符串 ID、超长 ID
```

## 高级用法

### 场景一：生成带性能测试的用例
在提示词中添加：
```
额外要求：为性能敏感的方法添加性能测试（使用 measure block）
```

### 场景二：生成参数化测试
```
对于需要测试多组输入的方法，使用数组驱动的测试：
- 创建测试数据数组
- 在单个测试方法中遍历测试
- 使用 XCTContext.runActivity 为每组数据命名
```

### 场景三：集成代码覆盖率要求
```
生成测试后，分析覆盖率：
1. 列出未覆盖的代码行号
2. 为未覆盖分支补充测试用例
3. 目标覆盖率：≥ 85%
```

## 相关资源
- [工作流：为 Swift 模块补充单元测试](../../workflows/unit-test-generation.md)
- [模板：XCTest 测试类模板](../../templates/xctest-template.md)（计划中）
- [示例：完整的测试用例](../../examples/unit-test-example/)（计划中）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-23  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
