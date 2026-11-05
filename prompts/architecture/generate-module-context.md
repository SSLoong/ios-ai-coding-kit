# 提示词：生成模块上下文文档

## 场景说明

为 iOS 多模块项目中的单个模块生成 `MODULE_CONTEXT.md` 文档，记录模块职责、公开 API、依赖关系、使用示例和架构约束，用于 AI 理解模块边界。

## 输入要求

- **必需**：模块名称和路径
- **必需**：模块的 Swift 源代码（至少包含 public 声明）
- **必需**：模块的依赖声明（Package.swift 或 .podspec）
- **可选**：现有的使用示例代码
- **可选**：项目的架构分层规则

## 提示词模板

```
请为 [模块名称] 生成 MODULE_CONTEXT.md 文档。

## 模块信息

### 基本信息
- **模块名称**：[模块名，如 UserFeature]
- **模块路径**：[相对路径，如 Packages/UserFeature/]
- **模块类型**：[SPM Package / Xcode Framework / CocoaPods Pod]
- **核心职责**：[一句话描述，如"用户认证、资料管理与账号设置"]

### 依赖声明
[粘贴以下内容之一：]

**选项 1：Package.swift 中的 dependencies**
\`\`\`swift
.target(
    name: "UserFeature",
    dependencies: [
        "Networking",
        "DesignSystem",
        "Common"
    ]
)
\`\`\`

**选项 2：.podspec 中的 dependency**
\`\`\`ruby
s.dependency 'Networking'
s.dependency 'DesignSystem'
\`\`\`

### 模块代码
[粘贴模块的核心 public 声明，或指定文件路径]

**选项 1：直接粘贴 public 声明**
\`\`\`swift
// Sources/UserFeature/Public/UserService.swift
public protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(_ user: User) async throws
    func deleteUser(id: String) async throws
}

public class UserService: UserServiceProtocol {
    public init() {}
    
    public func fetchUser(id: String) async throws -> User {
        // ...
    }
}

// Sources/UserFeature/Public/Models/User.swift
public struct User: Codable {
    public let id: String
    public var name: String
    public var email: String
    public var avatarURL: URL?
    
    public init(id: String, name: String, email: String, avatarURL: URL?) {
        // ...
    }
}

public enum UserError: Error {
    case notFound
    case invalidData
    case unauthorized
}
\`\`\`

**选项 2：指定文件路径**（AI 将读取这些文件）
\`\`\`
Sources/UserFeature/Public/
├── UserService.swift
├── Models/
│   ├── User.swift
│   └── UserError.swift
└── Views/
    └── UserProfileView.swift
\`\`\`

### 内部实现（可选，用于说明哪些是 internal）
\`\`\`swift
// Sources/UserFeature/Internal/UserRepository.swift
internal class UserRepository {
    internal func loadUser(id: String) throws -> User { /* ... */ }
}
\`\`\`

### 现有使用示例（可选）
[如有现有代码使用此模块，粘贴示例]

\`\`\`swift
// App/ContentView.swift
import UserFeature

struct ContentView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        if let user = viewModel.user {
            Text("Hello, \\(user.name)")
        }
    }
}
\`\`\`

### 架构约束（可选）
[如有全局架构规则，粘贴此处]

例如：
- ❌ 不可直接访问数据库（需通过 Storage 模块）
- ❌ 不可引用其他 Feature 模块
- ✅ 可依赖 Networking、DesignSystem、Common

## 任务要求

1. **提取公开 API**
   - 列出所有 `public` 和 `open` 的类、结构体、枚举、协议
   - 记录关键方法签名（包含参数类型和返回类型）
   - 分组：核心类型、协议、错误类型、视图组件等

2. **分析依赖关系**
   - 列出依赖的模块名称
   - 说明依赖的用途（如"Networking：用于 HTTP 请求"）
   - 识别依赖的具体类型（如 `Networking.NetworkClient`）

3. **标注内部实现**
   - 明确哪些是 `internal` 或 `private`，AI 不应直接访问
   - 说明内部实现的用途（如"UserRepository：数据访问层，外部不可见"）

4. **生成使用示例**
   - 至少 2-3 个典型场景
   - 代码示例应可编译（包含必要的 import 语句）
   - 覆盖正常流程和错误处理

5. **记录架构约束**
   - 此模块不可依赖哪些模块（如不可依赖其他 Feature）
   - 此模块不可做什么（如不可直接访问 UserDefaults）
   - 推荐的替代方案

## 输出格式

\`\`\`markdown
# [模块名称] 模块上下文

## 模块职责
[一句话描述核心职责]

## 公开 API

### 核心类型
- \`public struct User\`：用户模型
- \`public protocol UserServiceProtocol\`：用户服务协议
- \`public enum UserError\`：用户相关错误类型

### 核心方法
\`\`\`swift
// UserServiceProtocol
public func fetchUser(id: String) async throws -> User
public func updateUser(_ user: User) async throws
public func deleteUser(id: String) async throws
\`\`\`

### 视图组件（如适用）
- \`public struct UserProfileView: View\`：用户资料视图
- \`public struct EditProfileView: View\`：编辑资料视图

## 依赖模块

| 模块名 | 用途 | 使用的类型 |
|--------|------|-----------|
| Networking | HTTP 请求 | \`NetworkClient\`, \`APIError\` |
| DesignSystem | UI 组件 | \`DSButton\`, \`DSTextField\`, \`DSColor\` |
| Common | 通用工具 | \`Logger\`, \`DateFormatter+Extensions\` |

## 内部实现（AI 不应直接访问）

- \`internal class UserRepository\`：数据访问层，负责与存储层交互
- \`internal struct UserDTO\`：数据传输对象，仅用于网络层与领域层转换
- \`private func validateUserData(_:)\`：内部验证逻辑

**说明**：外部模块只能通过 \`UserServiceProtocol\` 访问功能，不可直接引用 internal 类型。

## 常见使用场景

### 场景 1：获取用户信息
\`\`\`swift
import UserFeature

let service: UserServiceProtocol = UserService()

do {
    let user = try await service.fetchUser(id: "123")
    print("用户名：\\(user.name)")
} catch UserError.notFound {
    print("用户不存在")
} catch {
    print("获取失败：\\(error)")
}
\`\`\`

### 场景 2：更新用户资料
\`\`\`swift
import UserFeature

var user = try await service.fetchUser(id: "123")
user.name = "新名称"
user.email = "newemail@example.com"

try await service.updateUser(user)
\`\`\`

### 场景 3：在 SwiftUI 中使用
\`\`\`swift
import SwiftUI
import UserFeature

struct ProfileScreen: View {
    let userId: String
    @State private var user: User?
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let user = user {
                UserProfileView(user: user)
            } else if let error = error {
                Text("加载失败：\\(error.localizedDescription)")
            } else {
                ProgressView("加载中...")
            }
        }
        .task {
            do {
                user = try await UserService().fetchUser(id: userId)
            } catch {
                self.error = error
            }
        }
    }
}
\`\`\`

## 架构约束

### ❌ 禁止事项
1. **不可直接访问数据库或 UserDefaults**
   - 原因：违反分层规则，数据持久化应通过 Storage 模块
   - 替代方案：依赖注入 \`StorageProtocol\`

2. **不可引用其他 Feature 模块**
   - 原因：Feature 模块应保持独立，避免耦合
   - 替代方案：通过 App 层协调，或使用 Core 层共享协议

3. **不可在 public API 中暴露第三方库类型**
   - 错误示例：\`public func login() -> AnyPublisher<User, Error>\`（暴露 Combine）
   - 正确示例：\`public func login() async throws -> User\`（使用标准 async/await）

### ✅ 推荐实践
1. **使用协议隔离依赖**
   \`\`\`swift
   public protocol NetworkServiceProtocol {
       func request<T: Decodable>(_ endpoint: String) async throws -> T
   }
   
   public class UserService {
       private let networkService: NetworkServiceProtocol
       
       public init(networkService: NetworkServiceProtocol = Networking.NetworkClient()) {
           self.networkService = networkService
       }
   }
   \`\`\`

2. **错误类型使用 public enum**
   \`\`\`swift
   public enum UserError: Error {
       case notFound
       case invalidData
       case unauthorized(message: String)
   }
   \`\`\`

3. **异步方法优先使用 async/await**
   - ✅ \`public func fetchUser(id: String) async throws -> User\`
   - ❌ \`public func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void)\`

## 测试说明

### 单元测试入口
- 测试 Target：\`UserFeatureTests\`
- Mock 对象：\`MockNetworkService\` 实现 \`NetworkServiceProtocol\`

### 关键测试场景
\`\`\`swift
// UserServiceTests.swift
func test_fetchUser_withValidID_returnsUser() async throws {
    let mockNetwork = MockNetworkService()
    mockNetwork.mockedUser = User(id: "123", name: "Test", email: "test@example.com")
    
    let service = UserService(networkService: mockNetwork)
    let user = try await service.fetchUser(id: "123")
    
    XCTAssertEqual(user.id, "123")
    XCTAssertEqual(user.name, "Test")
}
\`\`\`

## 更新日志
- 2026-11-04：初始版本
- [未来更新记录在此]

---

**维护者**：[团队名称]  
**最后审查**：2026-11-04
\`\`\`

## 输出结果
[AI 在此处输出完整的 MODULE_CONTEXT.md 内容]
```

## 使用示例

### 输入

```
请为 Networking 模块生成 MODULE_CONTEXT.md。

## 模块信息
- **模块名称**：Networking
- **模块路径**：Packages/Networking/
- **模块类型**：SPM Package
- **核心职责**：HTTP 请求封装、错误处理、网络监控

## 依赖声明
\`\`\`swift
.target(
    name: "Networking",
    dependencies: ["Common"]
)
\`\`\`

## 模块代码
\`\`\`swift
// Sources/Networking/NetworkClient.swift
public class NetworkClient {
    public static let shared = NetworkClient()
    
    public init() {}
    
    public func request<T: Decodable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        body: Data? = nil
    ) async throws -> T {
        // 实现...
    }
}

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingFailed
    case serverError(statusCode: Int)
}

// Sources/Networking/Internal/RequestBuilder.swift
internal class RequestBuilder {
    internal func build(endpoint: String, method: HTTPMethod) -> URLRequest {
        // 实现...
    }
}
\`\`\`
```

### 输出（AI 生成，节选）

```markdown
# Networking 模块上下文

## 模块职责
HTTP 请求封装、网络错误处理、请求/响应拦截与监控

## 公开 API

### 核心类型
- `public class NetworkClient`：HTTP 客户端，负责发起网络请求
- `public enum HTTPMethod`：HTTP 方法枚举（GET、POST、PUT、DELETE）
- `public enum NetworkError`：网络错误类型

### 核心方法
\`\`\`swift
public func request<T: Decodable>(
    _ endpoint: String,
    method: HTTPMethod = .get,
    body: Data? = nil
) async throws -> T
\`\`\`

## 依赖模块

| 模块名 | 用途 | 使用的类型 |
|--------|------|-----------|
| Common | 日志、扩展工具 | `Logger`, `Data+Extensions` |

## 内部实现（AI 不应直接访问）
- `internal class RequestBuilder`：构建 URLRequest，外部不可见
- `private var session: URLSession`：URLSession 实例，私有

## 常见使用场景

### 场景 1：GET 请求获取数据
\`\`\`swift
import Networking

let client = NetworkClient.shared

do {
    let users: [User] = try await client.request("/api/users")
    print("获取到 \\(users.count) 个用户")
} catch NetworkError.serverError(let code) {
    print("服务器错误：\\(code)")
} catch {
    print("请求失败：\\(error)")
}
\`\`\`

### 场景 2：POST 请求提交数据
\`\`\`swift
import Networking

let userData = try JSONEncoder().encode(newUser)

let response: CreateUserResponse = try await client.request(
    "/api/users",
    method: .post,
    body: userData
)
print("用户创建成功，ID：\\(response.id)")
\`\`\`

## 架构约束

### ❌ 禁止事项
1. **不可在此模块处理业务逻辑**
   - 错误示例：在 NetworkClient 中判断用户是否登录
   - 正确示例：只负责 HTTP 请求，业务逻辑在 Feature 层

2. **不可依赖 Feature 模块**
   - 原因：Networking 是 Core 层，不可依赖高层 Feature

### ✅ 推荐实践
1. **使用泛型简化调用**
   \`\`\`swift
   let user: User = try await client.request("/api/users/123")
   // 而非：let data = ...; let user = try JSONDecoder().decode(User.self, from: data)
   \`\`\`

2. **错误类型使用 public enum**
   - 让调用方可以针对特定错误类型处理

---

**维护者**：Core Team  
**最后审查**：2026-11-04
```

## 注意事项

1. **只记录 public/open API**
   - internal 和 private 声明简要说明即可
   - 目的是让 AI 知道"这部分不应直接访问"

2. **使用示例必须可编译**
   - 包含必要的 import 语句
   - 变量类型明确，避免歧义

3. **架构约束要具体**
   - ❌ 泛泛地说"遵循架构规则"
   - ✅ 明确说"不可引用 UserFeature 模块"

4. **定期更新**
   - 每次修改 public API 后，同步更新 MODULE_CONTEXT.md
   - 在 PR 中检查是否遗漏更新

5. **多人协作时**
   - MODULE_CONTEXT.md 由模块负责人维护
   - 修改前先与负责人确认

## 扩展用法

### 用法 1：批量生成所有模块的 MODULE_CONTEXT.md

```
请为以下所有模块生成 MODULE_CONTEXT.md。

## 模块列表
1. UserFeature（路径：Packages/UserFeature/）
2. PaymentFeature（路径：Packages/PaymentFeature/）
3. Networking（路径：Packages/Networking/）
4. Storage（路径：Packages/Storage/）

## 要求
- 分析每个模块的 Package.swift 和 Sources/ 目录
- 按统一格式生成 MODULE_CONTEXT.md
- 一次输出一个模块，等待确认后再生成下一个
```

### 用法 2：更新现有 MODULE_CONTEXT.md

```
UserFeature 模块新增了第三方登录功能，请更新 MODULE_CONTEXT.md。

## 现有 MODULE_CONTEXT.md
[粘贴现有内容]

## 新增代码
\`\`\`swift
public protocol UserServiceProtocol {
    // 新增方法
    func loginWithThirdParty(provider: ThirdPartyProvider) async throws -> User
}

public enum ThirdPartyProvider {
    case apple
    case google
    case facebook
}
\`\`\`

## 要求
- 在"公开 API"部分添加新方法
- 在"常见使用场景"部分添加第三方登录示例
- 更新"更新日志"
```

---

**适用工具**：Cursor、Claude Code、ChatGPT、GitHub Copilot  
**输出格式**：Markdown  
**最后更新**：2026-11-04
