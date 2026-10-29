# 工作流：API 接口自动生成 Mock

## 📋 背景

在 iOS 开发中，前后端并行开发时常遇到以下问题：
- 后端接口未就绪，前端开发被阻塞
- 联调环境不稳定，影响开发和测试效率
- UI 测试和 SwiftUI Preview 依赖真实网络，运行缓慢
- 手动编写 Mock 数据耗时且容易与真实契约不一致

使用 AI 从 API 契约自动生成 Mock，可以：
- 加速前后端并行开发，消除等待时间
- 提供稳定的测试环境，提升 CI/CD 可靠性
- 让 SwiftUI Preview 秒开，改善开发体验
- 保持 Mock 与契约同步，减少集成问题

## 🎯 目标

根据 API 契约（OpenAPI/Swagger、Swift 协议或现有 Networking 层）自动生成高质量 Mock，达到以下标准：
- **完整性**：覆盖所有已定义的接口端点
- **真实性**：Mock 数据结构与真实响应一致
- **可切换**：支持通过环境变量或编译配置在真实/Mock 间切换
- **可维护性**：契约更新时易于重新生成
- **安全性**：Mock 代码中不包含真实密钥或敏感数据

## 🛠️ 适用场景

- ✅ 前后端并行开发，接口规范已确定但未实现
- ✅ SwiftUI Preview 需要稳定数据源
- ✅ UI 测试需要可重复的网络响应
- ✅ CI 环境无法访问真实 API
- ✅ 演示 Demo 需要离线运行
- ❌ 不适合替代真实集成测试（最终需验证真实接口）
- ❌ 不适合生产环境兜底（应使用缓存或降级方案）

## 📝 工作流步骤

### 步骤 1：收集 API 契约

根据项目情况选择契约来源：

#### 情况 A：有 OpenAPI/Swagger 文档

```bash
# 下载 OpenAPI 规范文件
curl https://api.example.com/swagger.json -o api-spec.json

# 或从后端项目获取
cp ../backend/docs/openapi.yaml api-spec.yaml
```

#### 情况 B：有 Swift 网络层协议

```swift
// 已有的网络服务协议
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(id: String, data: UserUpdateRequest) async throws -> User
    func listUsers(page: Int, pageSize: Int) async throws -> [User]
}
```

#### 情况 C：有现有 API Client 实现

```swift
// 基于 Alamofire 或 URLSession 的实现
class UserAPIClient {
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void)
    func updateUser(id: String, data: UserUpdateRequest) async throws -> User
}
```

### 步骤 2：设计 Mock 架构

根据项目需求选择 Mock 实现方式：

#### 方案 A：协议 Mock（推荐，适合 DI 架构）

```swift
// 1. 定义协议（若已有则跳过）
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
}

// 2. 真实实现
class UserService: UserServiceProtocol {
    func fetchUser(id: String) async throws -> User {
        // 真实网络请求
    }
}

// 3. Mock 实现（AI 生成）
class MockUserService: UserServiceProtocol {
    func fetchUser(id: String) async throws -> User {
        // 返回预定义数据
    }
}

// 4. 依赖注入切换
let service: UserServiceProtocol = AppConfig.useMock ? MockUserService() : UserService()
```

#### 方案 B：URLProtocol 拦截（适合无法改造的旧代码）

```swift
// AI 生成的 URLProtocol 拦截器
class MockURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        // 匹配特定 URL
    }
    
    override func startLoading() {
        // 返回 Mock 响应
    }
}

// 注册到 URLSession
let config = URLSessionConfiguration.default
config.protocolClasses = [MockURLProtocol.self]
let session = URLSession(configuration: config)
```

#### 方案 C：JSON Fixture 文件（适合数据驱动测试）

```
MockData/
├── users/
│   ├── fetch_user_123.json
│   ├── fetch_user_456.json
│   └── list_users_page1.json
└── orders/
    └── fetch_order_789.json
```

```swift
// AI 生成的 Fixture 加载器
class FixtureLoader {
    static func load<T: Decodable>(_ filename: String) -> T? {
        // 从 Bundle 加载 JSON
    }
}
```

### 步骤 3：使用 AI 生成 Mock 代码

在 Cursor 中准备上下文：

#### 3.1 创建上下文文档

```markdown
# Mock 生成上下文

## 项目信息
- 架构：MVVM + 依赖注入
- 网络层：Alamofire / URLSession / 自研框架
- 数据解析：Codable
- 测试框架：XCTest

## 已有类型定义
[粘贴 User、Order 等模型定义]

## Mock 要求
- 实现方式：[协议 Mock / URLProtocol / JSON Fixture]
- 数据真实度：包含边界情况（空列表、错误状态）
- 命名约定：Mock 前缀 + 原始类名
```

#### 3.2 选择对应提示词

根据契约来源选择提示词：

**从 OpenAPI 生成 Fixture：** 使用 [`prompts/mocking/openapi-to-fixture.md`](../prompts/mocking/openapi-to-fixture.md)

**从 Swift Protocol 生成 URLProtocol Mock：** 使用 [`prompts/mocking/protocol-to-urlprotocol.md`](../prompts/mocking/protocol-to-urlprotocol.md)

#### 3.3 生成并审查

AI 会生成：
1. **Mock 类/结构体**：实现所有接口方法
2. **测试数据**：典型的正常、边界、错误场景数据
3. **配置代码**：环境切换逻辑

**人工审查要点：**
- [ ] 所有接口方法都有实现
- [ ] Mock 数据结构与真实契约一致
- [ ] 包含错误场景（网络失败、401、404 等）
- [ ] 没有硬编码真实 API Key 或 Token
- [ ] 异步方法签名正确（async/await 或 completion）

### 步骤 4：接入依赖注入或环境开关

#### 方案 A：使用编译配置

```swift
// AppConfig.swift
struct AppConfig {
    #if DEBUG
    static let useMockAPI = true
    #else
    static let useMockAPI = false
    #endif
}

// AppDependency.swift
class AppDependency {
    let userService: UserServiceProtocol
    
    init() {
        if AppConfig.useMockAPI {
            self.userService = MockUserService()
        } else {
            self.userService = UserService()
        }
    }
}
```

#### 方案 B：使用环境变量（更灵活）

```swift
// 在 Scheme 中设置环境变量：USE_MOCK_API = 1

struct AppConfig {
    static var useMockAPI: Bool {
        ProcessInfo.processInfo.environment["USE_MOCK_API"] == "1"
    }
}
```

#### 方案 C：使用 Launch Arguments（适合 UI 测试）

```swift
// UI 测试启动时传入
func testUserFlow() {
    let app = XCUIApplication()
    app.launchArguments = ["--use-mock-api"]
    app.launch()
}

// App 中检测
struct AppConfig {
    static var useMockAPI: Bool {
        CommandLine.arguments.contains("--use-mock-api")
    }
}
```

### 步骤 5：集成到 SwiftUI Preview

```swift
// UserListView.swift
struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    
    var body: some View {
        // ...
    }
}

#if DEBUG
struct UserListView_Previews: PreviewProvider {
    static var previews: some View {
        // 使用 Mock 服务，Preview 秒开
        let mockService = MockUserService()
        let viewModel = UserListViewModel(userService: mockService)
        
        UserListView(viewModel: viewModel)
    }
}
#endif
```

### 步骤 6：编写验证测试

为 Mock 本身编写测试，确保其行为正确：

```swift
final class MockUserServiceTests: XCTestCase {
    var sut: MockUserService!
    
    override func setUp() {
        super.setUp()
        sut = MockUserService()
    }
    
    func test_fetchUser_withValidID_returnsUser() async throws {
        // Given
        let userId = "123"
        
        // When
        let user = try await sut.fetchUser(id: userId)
        
        // Then
        XCTAssertEqual(user.id, userId)
        XCTAssertFalse(user.name.isEmpty)
        XCTAssertNotNil(user.email)
    }
    
    func test_fetchUser_withInvalidID_throwsError() async {
        // When & Then
        do {
            _ = try await sut.fetchUser(id: "invalid")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
}
```

### 步骤 7：验证标准

完成 Mock 生成后，逐项检查：

- [ ] **编译通过**：Mock 类实现了所有协议方法
- [ ] **SwiftUI Preview 可运行**：Preview 能正常加载和显示数据
- [ ] **UI 测试可运行**：UI 测试能在 Mock 模式下跑通关键路径
- [ ] **数据结构正确**：Mock 数据可被 Codable 正确解析
- [ ] **错误场景覆盖**：包含网络失败、4xx、5xx 等场景
- [ ] **无敏感信息**：Mock 代码中无真实 API Key、Token、密码
- [ ] **可切换**：能通过配置在真实/Mock 间切换
- [ ] **文档完整**：注释说明了每个 Mock 方法的返回数据

## ✅ 验证清单

使用以下清单确保工作流完成：

### 代码质量
- [ ] 所有 Mock 类编译通过，无 warning
- [ ] Mock 数据结构与协议/模型定义一致
- [ ] 实现了所有接口方法（无 TODO 或空实现）
- [ ] 异步方法签名正确（async/await 匹配）

### 功能验证
- [ ] SwiftUI Preview 能正常显示（选取 2-3 个核心页面验证）
- [ ] UI 测试能跑通关键路径（登录 → 列表 → 详情）
- [ ] Mock 数据包含多样性（正常、空、边界、错误）

### 安全性
- [ ] 搜索代码确认无真实 API Key（`grep -r "sk-" "AIza"` 等）
- [ ] Mock 中的 Token/密钥为明显的测试值（如 "test-token-123"）
- [ ] `.gitignore` 已排除真实配置文件

### 可维护性
- [ ] Mock 代码集中在单独目录（如 `Mocks/` 或 `MockData/`）
- [ ] 文件命名清晰（`Mock<原始类名>.swift`）
- [ ] 添加了 `// GENERATED` 注释标记，说明生成来源

## 🐛 常见问题

### Q1: Mock 数据过于简单，无法覆盖真实场景

**原因**：AI 默认生成最简数据，缺少边界情况。

**解决**：
1. 明确要求 AI 生成多样化数据：
   ```
   为 fetchUser 生成 3 种场景的 Mock 数据：
   1. 正常用户：完整信息，有头像
   2. 新注册用户：部分字段为空
   3. VIP 用户：额外字段和权限
   ```

2. 提供真实数据样例让 AI 模仿：
   ```
   参考以下真实响应生成 Mock：
   [粘贴 Postman 或 Charles 抓到的真实 JSON]
   ```

### Q2: Mock 与真实契约不一致，集成时出错

**原因**：契约更新后 Mock 未同步，或 AI 理解偏差。

**解决**：
1. **自动化检测**：编写测试对比 Mock 和真实响应结构
   ```swift
   func test_mockUserMatchesRealUserStructure() {
       let mockUser = MockUserService().fetchUser(id: "123")
       let realUser = UserService().fetchUser(id: "123") // 在测试环境调用
       
       // 比较关键字段
       XCTAssertEqual(type(of: mockUser.id), type(of: realUser.id))
       XCTAssertEqual(type(of: mockUser.name), type(of: realUser.name))
   }
   ```

2. **版本化 Mock**：在 OpenAPI 更新时重新生成
   ```bash
   # 脚本：检测 OpenAPI 变更并重新生成
   if git diff HEAD~1 api-spec.json; then
       echo "API spec changed, regenerating mocks..."
       # 触发 AI 重新生成
   fi
   ```

### Q3: URLProtocol Mock 未生效，仍然发起真实请求

**原因**：URLProtocol 注册时机不对，或被其他配置覆盖。

**解决**：
1. **尽早注册**：在 App 启动时立即注册
   ```swift
   @main
   struct MyApp: App {
       init() {
           if AppConfig.useMockAPI {
               URLProtocol.registerClass(MockURLProtocol.self)
           }
       }
   }
   ```

2. **检查 URLSession 配置**：确保使用了正确的 session
   ```swift
   // ❌ 错误：使用 shared session（不受 protocolClasses 影响）
   URLSession.shared.dataTask(with: url)
   
   // ✅ 正确：使用自定义 session
   let config = URLSessionConfiguration.default
   config.protocolClasses = [MockURLProtocol.self]
   let session = URLSession(configuration: config)
   ```

### Q4: SwiftUI Preview 仍然很慢，没有改善

**原因**：Preview 中仍在执行异步网络请求，而非使用同步 Mock。

**解决**：
1. **同步化 Mock**（仅 Preview 用）
   ```swift
   #if DEBUG
   class InstantMockUserService: UserServiceProtocol {
       func fetchUser(id: String) async throws -> User {
           // 直接返回，无延迟
           return User.previewSample
       }
   }
   #endif
   ```

2. **使用 `PreviewProvider` 专用 Mock**
   ```swift
   extension User {
       static var previewSample: User {
           User(id: "preview-1", name: "预览用户", email: "preview@example.com")
       }
   }
   ```

### Q5: 把 Mock 当生产兜底，真实接口失败时返回 Mock 数据

**这是反模式！** Mock 仅用于开发和测试，不应进入生产逻辑。

**正确做法**：
```swift
// ❌ 错误：生产环境兜底使用 Mock
func fetchUser(id: String) async throws -> User {
    do {
        return try await realService.fetchUser(id: id)
    } catch {
        return try await mockService.fetchUser(id: id) // 危险！
    }
}

// ✅ 正确：生产环境使用缓存或降级
func fetchUser(id: String) async throws -> User {
    do {
        return try await realService.fetchUser(id: id)
    } catch {
        if let cached = cache.getUser(id: id) {
            return cached // 返回缓存
        }
        throw error // 或返回默认值，但不返回 Mock
    }
}
```

## 🎓 最佳实践

### 1. 分阶段生成

```
阶段一：生成骨架
- 所有接口方法签名
- 最简单的返回值（空对象或单条数据）

阶段二：丰富数据
- 正常场景的完整数据
- 边界情况（空列表、极值）

阶段三：错误处理
- 网络失败、超时
- 401、403、404、500 等 HTTP 错误
```

### 2. 契约驱动开发（Contract-Driven Development）

```
1. 前后端约定 OpenAPI 规范
   ↓
2. 前端从 OpenAPI 生成 Mock
   ↓
3. 前端基于 Mock 并行开发
   ↓
4. 后端完成后，切换到真实接口
   ↓
5. 验证真实接口符合 OpenAPI 规范
```

### 3. Mock 数据版本管理

```swift
// MockDataVersion.swift
struct MockDataVersion {
    static let version = "1.2.0" // 与后端 API 版本对应
    
    static func checkCompatibility() {
        #if DEBUG
        print("Using Mock Data Version: \(version)")
        print("Ensure backend API is compatible with v\(version)")
        #endif
    }
}
```

### 4. 定期同步验证

```swift
// 集成测试：验证 Mock 与真实接口一致性
func testMockMatchesRealAPI() async throws {
    // 在测试环境同时调用真实和 Mock
    let mockUser = try await mockService.fetchUser(id: "test-123")
    let realUser = try await realService.fetchUser(id: "test-123")
    
    // 比较结构而非具体值
    XCTAssertEqual(Mirror(reflecting: mockUser).children.count,
                   Mirror(reflecting: realUser).children.count)
}
```

### 5. 文档化 Mock 局限性

在 Mock 类顶部注释：

```swift
/// Mock 实现说明
///
/// **覆盖范围**：
/// - ✅ 用户基本信息 CRUD
/// - ✅ 分页列表（最多返回 3 页）
/// - ❌ 实时通知推送（WebSocket）
/// - ❌ 文件上传进度
///
/// **数据特点**：
/// - 用户 ID "123" 返回正常数据
/// - 用户 ID "error" 模拟网络错误
/// - 用户 ID "401" 模拟未授权
///
/// **更新记录**：
/// - 2026-10-28: 初始版本，基于 OpenAPI v1.2.0
class MockUserService: UserServiceProtocol {
    // ...
}
```

## 📚 扩展阅读

- [OpenAPI Specification](https://swagger.io/specification/)
- [URLProtocol 官方文档](https://developer.apple.com/documentation/foundation/urlprotocol)
- [Dependency Injection in Swift](https://www.swiftbysundell.com/articles/dependency-injection-using-factories-in-swift/)
- [Contract Testing Best Practices](https://martinfowler.com/articles/practical-test-pyramid.html)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md)
- [SwiftUI 视图快速原型](./swiftui-prototyping.md)（开发中）
- [使用 AI 进行代码 Review](./ai-code-review.md)（开发中）

## 🔗 相关提示词

- [从 OpenAPI 生成 JSON Fixture](../prompts/mocking/openapi-to-fixture.md)
- [从 Swift Protocol 生成 URLProtocol Mock](../prompts/mocking/protocol-to-urlprotocol.md)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-28  
**适用工具**：Cursor、Claude Code、GitHub Copilot
