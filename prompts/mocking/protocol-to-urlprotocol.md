# 从 Swift Protocol 生成 URLProtocol Mock

## 场景说明
从 Swift 网络层协议生成 URLProtocol 拦截器，用于在不改动现有代码的情况下 Mock 网络请求，特别适合无法使用依赖注入的遗留项目。

## 输入要求

### 必需
- Swift 网络层协议定义或 API Client 实现
- 需要 Mock 的接口方法列表
- 接口的 URL 模式（如 `https://api.example.com/users/{id}`）

### 可选
- 请求方法（GET、POST、PUT、DELETE）
- 请求和响应的数据模型（Codable 类型）
- 特定的错误场景（网络超时、HTTP 错误码）
- 现有 URLSession 配置方式

## 提示词模板

```
我需要为现有的 Swift 网络层生成 URLProtocol Mock 拦截器。

## 网络层接口
[粘贴协议定义或 API Client 代码]

示例：
```swift
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(id: String, data: UserUpdateRequest) async throws -> User
    func deleteUser(id: String) async throws -> Void
}

// 现有实现使用 URLSession
class UserService: UserServiceProtocol {
    private let session = URLSession.shared
    private let baseURL = "https://api.example.com"
    
    func fetchUser(id: String) async throws -> User {
        let url = URL(string: "\(baseURL)/users/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
}
```

## URL 映射规则
请为以下接口生成 Mock：

| 方法 | URL 模式 | Mock 响应 |
|------|----------|-----------|
| GET | `/users/{id}` | 返回用户详情（见模型定义） |
| GET | `/users` | 返回用户列表（分页） |
| POST | `/users` | 返回创建成功的用户 |
| PUT | `/users/{id}` | 返回更新后的用户 |
| DELETE | `/users/{id}` | 返回 204 No Content |
| GET | `/orders/{id}` | 返回订单详情 |

## Mock 策略

### 1. URL 匹配规则
- 精确匹配：`/users/123` 返回特定用户
- 模式匹配：`/users/{id}` 返回动态生成的用户
- 查询参数：`/users?page=2` 返回第二页数据

### 2. 特殊 ID 约定
- ID = "error" → 返回网络错误（NSURLErrorNetworkConnectionLost）
- ID = "timeout" → 延迟 5 秒后超时
- ID = "401" → 返回 HTTP 401 Unauthorized
- ID = "404" → 返回 HTTP 404 Not Found
- ID = "500" → 返回 HTTP 500 Internal Server Error

### 3. 响应数据
使用以下模型生成 JSON：
[粘贴 User、UserUpdateRequest、Order 等 Codable 定义]

### 4. 延迟模拟
所有成功响应延迟 0.1 秒，模拟真实网络延迟

## 输出要求

生成以下代码：

1. **MockURLProtocol 类**
   - 继承自 URLProtocol
   - 实现 URL 匹配逻辑
   - 返回 Mock 响应数据

2. **MockURLProtocol+Registration 扩展**
   - 注册/注销方法
   - 与现有 URLSession 集成

3. **测试辅助方法**
   - 配置 Mock 场景的便捷 API

4. **使用文档**
   - 如何在 App 启动时启用 Mock
   - 如何在单元测试中使用
   - 如何在 UI 测试中使用

## 代码风格
- Swift 5.5+，使用 async/await
- 遵循 Swift API Design Guidelines
- 添加详细注释说明每个方法用途
- 使用 `// MARK:` 分组代码
```

## 使用示例

### 输入：协议定义

```swift
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func listUsers(page: Int) async throws -> [User]
}

struct User: Codable {
    let id: String
    let name: String
    let email: String
}
```

### AI 输出

```swift
import Foundation

/// URLProtocol Mock 拦截器，用于在测试和开发中 Mock 网络请求
///
/// **支持的接口**：
/// - GET /users/{id} - 获取用户详情
/// - GET /users?page={n} - 获取用户列表
///
/// **特殊 ID 约定**：
/// - "error" - 模拟网络错误
/// - "timeout" - 模拟超时
/// - "401"/"404"/"500" - 模拟 HTTP 错误
///
/// **使用方式**：
/// ```swift
/// // 注册 Mock
/// MockURLProtocol.register()
///
/// // 使用 URLSession（会被自动拦截）
/// let user = try await userService.fetchUser(id: "123")
///
/// // 注销 Mock
/// MockURLProtocol.unregister()
/// ```
class MockURLProtocol: URLProtocol {
    
    // MARK: - Configuration
    
    /// 是否启用延迟（默认 0.1 秒，模拟真实网络）
    static var simulateNetworkDelay = true
    static var networkDelay: TimeInterval = 0.1
    
    /// 是否打印调试日志
    static var debugLoggingEnabled = true
    
    // MARK: - URLProtocol Override
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        
        // 只拦截目标 API 的请求
        let shouldIntercept = url.absoluteString.contains("api.example.com")
        
        if debugLoggingEnabled && shouldIntercept {
            print("🌐 MockURLProtocol intercepting: \(request.httpMethod ?? "GET") \(url)")
        }
        
        return shouldIntercept
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        // 模拟网络延迟
        let delay = Self.simulateNetworkDelay ? Self.networkDelay : 0
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.handleRequest(url: url)
        }
    }
    
    override func stopLoading() {
        // 取消请求（如果正在进行）
    }
    
    // MARK: - Request Handling
    
    private func handleRequest(url: URL) {
        let path = url.path
        let method = request.httpMethod ?? "GET"
        
        do {
            // 解析路径并生成响应
            if let mockResponse = try generateMockResponse(path: path, method: method, url: url) {
                // 返回 HTTP 响应
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: mockResponse.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": "application/json"]
                )!
                
                client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
                
                if let data = mockResponse.data {
                    client?.urlProtocol(self, didLoad: data)
                }
                
                client?.urlProtocolDidFinishLoading(self)
                
                if Self.debugLoggingEnabled {
                    print("✅ MockURLProtocol returned: \(mockResponse.statusCode)")
                }
            } else {
                // 未匹配的路径
                throw URLError(.fileDoesNotExist)
            }
        } catch {
            if Self.debugLoggingEnabled {
                print("❌ MockURLProtocol error: \(error)")
            }
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    private func generateMockResponse(path: String, method: String, url: URL) throws -> MockResponse? {
        // GET /users/{id}
        if method == "GET" && path.hasPrefix("/users/") {
            let id = String(path.dropFirst("/users/".count))
            return try mockFetchUser(id: id)
        }
        
        // GET /users?page={n}
        if method == "GET" && path == "/users" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let page = components?.queryItems?.first(where: { $0.name == "page" })?.value ?? "1"
            return try mockListUsers(page: Int(page) ?? 1)
        }
        
        // POST /users
        if method == "POST" && path == "/users" {
            return try mockCreateUser()
        }
        
        // PUT /users/{id}
        if method == "PUT" && path.hasPrefix("/users/") {
            let id = String(path.dropFirst("/users/".count))
            return try mockUpdateUser(id: id)
        }
        
        // DELETE /users/{id}
        if method == "DELETE" && path.hasPrefix("/users/") {
            return MockResponse(statusCode: 204, data: nil)
        }
        
        return nil
    }
    
    // MARK: - Mock Data Generators
    
    private func mockFetchUser(id: String) throws -> MockResponse {
        // 特殊 ID 处理
        switch id {
        case "error":
            throw URLError(.networkConnectionLost)
        case "timeout":
            Thread.sleep(forTimeInterval: 5.0)
            throw URLError(.timedOut)
        case "401":
            return MockResponse(statusCode: 401, data: errorJSON(message: "Unauthorized"))
        case "404":
            return MockResponse(statusCode: 404, data: errorJSON(message: "User not found"))
        case "500":
            return MockResponse(statusCode: 500, data: errorJSON(message: "Internal server error"))
        default:
            // 正常用户数据
            let user = User(id: id, name: "Test User \(id)", email: "user\(id)@example.com")
            let data = try JSONEncoder().encode(user)
            return MockResponse(statusCode: 200, data: data)
        }
    }
    
    private func mockListUsers(page: Int) throws -> MockResponse {
        let users = (1...10).map { index in
            User(
                id: "\((page - 1) * 10 + index)",
                name: "User \(index)",
                email: "user\(index)@example.com"
            )
        }
        let data = try JSONEncoder().encode(users)
        return MockResponse(statusCode: 200, data: data)
    }
    
    private func mockCreateUser() throws -> MockResponse {
        let user = User(id: "new-\(UUID().uuidString)", name: "New User", email: "new@example.com")
        let data = try JSONEncoder().encode(user)
        return MockResponse(statusCode: 201, data: data)
    }
    
    private func mockUpdateUser(id: String) throws -> MockResponse {
        let user = User(id: id, name: "Updated User", email: "updated@example.com")
        let data = try JSONEncoder().encode(user)
        return MockResponse(statusCode: 200, data: data)
    }
    
    private func errorJSON(message: String) -> Data {
        let json = ["error": message]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}

// MARK: - Response Model

private struct MockResponse {
    let statusCode: Int
    let data: Data?
}

// MARK: - Registration

extension MockURLProtocol {
    /// 注册 Mock URLProtocol（全局生效）
    static func register() {
        URLProtocol.registerClass(MockURLProtocol.self)
        if debugLoggingEnabled {
            print("🔧 MockURLProtocol registered")
        }
    }
    
    /// 注销 Mock URLProtocol
    static func unregister() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        if debugLoggingEnabled {
            print("🔧 MockURLProtocol unregistered")
        }
    }
    
    /// 为指定 URLSession 配置 Mock
    /// - Returns: 配置了 Mock 的 URLSessionConfiguration
    static func mockSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return config
    }
}

// MARK: - Usage Examples

#if DEBUG
extension MockURLProtocol {
    /// 示例：在 App 启动时启用 Mock
    static func setupForDevelopment() {
        register()
        simulateNetworkDelay = true
        networkDelay = 0.2 // 稍慢一点，更真实
        debugLoggingEnabled = true
    }
    
    /// 示例：在单元测试中启用 Mock
    static func setupForUnitTesting() {
        register()
        simulateNetworkDelay = false // 测试要快
        debugLoggingEnabled = false
    }
    
    /// 示例：在 UI 测试中启用 Mock
    static func setupForUITesting() {
        register()
        simulateNetworkDelay = true
        networkDelay = 0.1
        debugLoggingEnabled = true
    }
}
#endif
```

### 使用文档

```swift
// MARK: - 使用方式

// 1. 在 App 启动时启用（AppDelegate 或 @main）
#if DEBUG
MockURLProtocol.setupForDevelopment()
#endif

// 2. 在单元测试中使用
class UserServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockURLProtocol.setupForUnitTesting()
    }
    
    override func tearDown() {
        MockURLProtocol.unregister()
        super.tearDown()
    }
    
    func testFetchUser() async throws {
        let service = UserService() // 使用真实实现
        let user = try await service.fetchUser(id: "123")
        XCTAssertEqual(user.id, "123")
        XCTAssertEqual(user.name, "Test User 123")
    }
    
    func testFetchUserError() async {
        let service = UserService()
        do {
            _ = try await service.fetchUser(id: "error")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is URLError)
        }
    }
}

// 3. 在 UI 测试中使用
class UITests: XCTestCase {
    func testUserListFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--use-mock-api"]
        app.launch()
        
        // MockURLProtocol 在 App 中检测到 launch argument 后自动启用
        
        app.tables.cells.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Test User 1"].exists)
    }
}

// 4. 在 SwiftUI Preview 中使用
#if DEBUG
struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = MockURLProtocol.register() // Preview 启动时注册
        UserListView()
    }
}
#endif
```

## 注意事项

### ✅ 好的做法
- 明确定义 URL 匹配规则，避免误拦截其他请求
- 使用特殊 ID 约定模拟错误场景（"error", "404" 等）
- 提供注册/注销方法，方便测试清理
- 添加调试日志，帮助排查问题

### ❌ 避免的做法
- 拦截所有 HTTP 请求（会影响第三方 SDK）
- 硬编码 JSON 字符串（应使用 Codable）
- 忽略请求方法（GET 和 POST 应返回不同响应）
- 在生产环境注册 Mock（仅限 DEBUG）

### 🔧 常见调整

如果生成的 Mock 不符合预期：

```
请调整以下内容：
1. URL 匹配改为正则表达式：支持 `/users/[0-9]+`
2. 添加请求体解析：POST /users 时从 request.httpBody 读取参数
3. 支持 Header 验证：检查 Authorization token 是否存在
4. 添加多场景切换：通过静态变量控制返回成功/失败
```

## 高级用法

### 场景一：动态切换 Mock 行为

```swift
extension MockURLProtocol {
    enum Scenario {
        case success
        case networkError
        case serverError
        case slow // 模拟慢网络
    }
    
    static var currentScenario: Scenario = .success
    
    private func generateMockResponse(...) throws -> MockResponse? {
        switch Self.currentScenario {
        case .success:
            // 正常响应
        case .networkError:
            throw URLError(.networkConnectionLost)
        case .serverError:
            return MockResponse(statusCode: 500, data: ...)
        case .slow:
            Thread.sleep(forTimeInterval: 3.0)
            // 正常响应
        }
    }
}

// 在测试中切换场景
MockURLProtocol.currentScenario = .networkError
```

### 场景二：记录请求历史

```swift
extension MockURLProtocol {
    static var requestHistory: [URLRequest] = []
    
    override func startLoading() {
        Self.requestHistory.append(request)
        // ...
    }
    
    static func clearHistory() {
        requestHistory.removeAll()
    }
}

// 在测试中验证
XCTAssertEqual(MockURLProtocol.requestHistory.count, 2)
XCTAssertEqual(MockURLProtocol.requestHistory[0].httpMethod, "GET")
```

### 场景三：从 Fixture 文件加载响应

```swift
private func mockFetchUser(id: String) throws -> MockResponse {
    // 尝试从 Fixture 文件加载
    if let fixtureData = loadFixture(name: "user_\(id)") {
        return MockResponse(statusCode: 200, data: fixtureData)
    }
    
    // 降级到动态生成
    let user = User(id: id, name: "Test User \(id)", email: "...")
    let data = try JSONEncoder().encode(user)
    return MockResponse(statusCode: 200, data: data)
}

private func loadFixture(name: String) -> Data? {
    guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
        return nil
    }
    return try? Data(contentsOf: url)
}
```

## 相关资源
- [工作流：API 接口自动生成 Mock](../../workflows/api-mock-generation.md)
- [提示词：从 OpenAPI 生成 JSON Fixture](./openapi-to-fixture.md)
- [URLProtocol 官方文档](https://developer.apple.com/documentation/foundation/urlprotocol)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-28  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
