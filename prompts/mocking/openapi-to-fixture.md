# 从 OpenAPI 生成 JSON Fixture

## 场景说明
从 OpenAPI/Swagger 规范文件自动生成 JSON Fixture 文件和对应的加载器代码，用于 Mock API 响应、单元测试和 SwiftUI Preview。

## 输入要求

### 必需
- OpenAPI/Swagger 规范文件（JSON 或 YAML 格式）
- 目标生成的接口路径列表

### 可选
- 数据真实度要求（简单测试数据 vs 接近生产的完整数据）
- 特定的错误场景（401、404、500 等）
- 项目中已有的模型定义（Swift Codable 类型）

## 提示词模板

```
我需要从 OpenAPI 规范生成 JSON Fixture 文件和加载器。

## OpenAPI 规范
[粘贴 OpenAPI JSON 内容，或提供文件路径]

## 生成要求

### 1. 目标接口
请为以下接口生成 Fixture：
- GET /users/{id} - 获取单个用户
- GET /users - 获取用户列表（分页）
- POST /users - 创建用户
- GET /orders/{id} - 获取订单详情

### 2. Fixture 文件组织
```
MockData/
├── users/
│   ├── get_user_123.json          # 正常用户
│   ├── get_user_456.json          # VIP 用户（额外字段）
│   ├── get_user_error_404.json    # 用户不存在
│   ├── get_users_page1.json       # 第一页（10 条）
│   ├── get_users_empty.json       # 空列表
│   └── post_user_success.json     # 创建成功响应
└── orders/
    ├── get_order_789.json
    └── get_order_error_401.json   # 未授权
```

### 3. 数据要求
- **真实性**：数据结构完全符合 OpenAPI schema，包含所有必需字段
- **多样性**：为每个接口生成至少 3 种场景：
  - 正常成功响应（包含完整数据）
  - 边界情况（空列表、部分字段缺失、极值）
  - 错误响应（按 OpenAPI 定义的错误格式）
- **可读性**：使用有意义的测试数据（如用户名 "Alice Test"，邮箱 "alice@example.com"）

### 4. 加载器代码
生成 Swift Fixture 加载器：
```swift
// FixtureLoader.swift
class FixtureLoader {
    enum FixtureError: Error {
        case fileNotFound
        case invalidJSON
    }
    
    static func load<T: Decodable>(_ filename: String, 
                                   subdirectory: String? = nil) throws -> T {
        // 1. 从 Bundle 加载文件
        // 2. 解析 JSON
        // 3. 返回类型安全的结果
    }
    
    // 便捷方法
    static func loadUser(id: String) throws -> User
    static func loadUserList(page: Int) throws -> [User]
    static func loadOrder(id: String) throws -> Order
}
```

### 5. 使用示例
同时生成使用文档：
```swift
// 在单元测试中使用
func testUserViewModel() throws {
    let user = try FixtureLoader.loadUser(id: "123")
    let viewModel = UserViewModel(user: user)
    XCTAssertEqual(viewModel.displayName, "Alice Test")
}

// 在 SwiftUI Preview 中使用
struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        let user = try! FixtureLoader.loadUser(id: "123")
        UserView(user: user)
    }
}

// 模拟错误场景
func testHandleUserNotFound() throws {
    // 加载 404 错误响应
    let errorResponse = try FixtureLoader.load("get_user_error_404", 
                                                subdirectory: "users") as APIErrorResponse
    XCTAssertEqual(errorResponse.statusCode, 404)
}
```

## 附加上下文
项目使用的 JSON 解析方式：
- [ ] Codable（默认）
- [ ] SwiftyJSON
- [ ] 其他：[指定]

现有模型定义（可选）：
[粘贴已有的 User、Order 等 Codable 定义，AI 会生成匹配的 Fixture]
```

## 使用示例

### 输入：OpenAPI 片段

```json
{
  "openapi": "3.0.0",
  "paths": {
    "/users/{id}": {
      "get": {
        "summary": "获取用户详情",
        "parameters": [
          {
            "name": "id",
            "in": "path",
            "required": true,
            "schema": { "type": "string" }
          }
        ],
        "responses": {
          "200": {
            "description": "成功",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "id": { "type": "string" },
                    "name": { "type": "string" },
                    "email": { "type": "string", "format": "email" },
                    "age": { "type": "integer", "minimum": 0 },
                    "premium": { "type": "boolean" }
                  },
                  "required": ["id", "name", "email"]
                }
              }
            }
          },
          "404": {
            "description": "用户不存在",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "error": { "type": "string" },
                    "statusCode": { "type": "integer" }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

### AI 输出

#### 1. Fixture 文件：`MockData/users/get_user_123.json`

```json
{
  "id": "123",
  "name": "Alice Test",
  "email": "alice@example.com",
  "age": 28,
  "premium": true
}
```

#### 2. Fixture 文件：`MockData/users/get_user_error_404.json`

```json
{
  "error": "User not found",
  "statusCode": 404
}
```

#### 3. 加载器代码：`FixtureLoader.swift`

```swift
import Foundation

enum FixtureLoader {
    enum FixtureError: Error {
        case fileNotFound(String)
        case invalidJSON(String)
        case decodingFailed(String, Error)
    }
    
    /// 从 Bundle 加载 JSON Fixture 并解析为指定类型
    /// - Parameters:
    ///   - filename: 文件名（不含扩展名）
    ///   - subdirectory: 子目录（相对于 MockData）
    ///   - bundle: Bundle（默认为 main）
    /// - Returns: 解析后的对象
    static func load<T: Decodable>(
        _ filename: String,
        subdirectory: String? = nil,
        bundle: Bundle = .main
    ) throws -> T {
        // 构建文件路径
        let fullPath: String
        if let subdirectory = subdirectory {
            fullPath = "MockData/\(subdirectory)/\(filename)"
        } else {
            fullPath = "MockData/\(filename)"
        }
        
        // 查找文件
        guard let url = bundle.url(forResource: fullPath, withExtension: "json") else {
            throw FixtureError.fileNotFound("File not found: \(fullPath).json")
        }
        
        // 读取数据
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw FixtureError.invalidJSON("Failed to read file: \(fullPath).json")
        }
        
        // 解析 JSON
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            throw FixtureError.decodingFailed("Failed to decode \(fullPath).json as \(T.self)", error)
        }
    }
}

// MARK: - 便捷方法

extension FixtureLoader {
    /// 加载用户 Fixture
    static func loadUser(id: String) throws -> User {
        try load("get_user_\(id)", subdirectory: "users")
    }
    
    /// 加载用户列表 Fixture
    static func loadUserList(scenario: String = "page1") throws -> UserListResponse {
        try load("get_users_\(scenario)", subdirectory: "users")
    }
    
    /// 加载订单 Fixture
    static func loadOrder(id: String) throws -> Order {
        try load("get_order_\(id)", subdirectory: "orders")
    }
    
    /// 加载 API 错误响应
    static func loadError(statusCode: Int, entity: String = "user") throws -> APIErrorResponse {
        try load("get_\(entity)_error_\(statusCode)", subdirectory: "\(entity)s")
    }
}

// MARK: - Preview 专用扩展

#if DEBUG
extension FixtureLoader {
    /// 加载失败时返回默认值（仅用于 Preview，避免崩溃）
    static func loadOrDefault<T: Decodable>(_ filename: String, 
                                             subdirectory: String? = nil,
                                             default: T) -> T {
        do {
            return try load(filename, subdirectory: subdirectory)
        } catch {
            print("⚠️ Fixture load failed, using default: \(error)")
            return `default`
        }
    }
}
#endif
```

#### 4. 使用文档：`MockData/README.md`

```markdown
# Mock Data Fixtures

## 文件组织

所有 Fixture 按接口模块组织：
- `users/` - 用户相关接口
- `orders/` - 订单相关接口

## 命名约定

`<HTTP方法>_<资源名>_<标识符或场景>.json`

示例：
- `get_user_123.json` - GET /users/123 的正常响应
- `get_user_error_404.json` - GET /users/{id} 的 404 错误
- `get_users_page1.json` - GET /users?page=1 的响应
- `post_user_success.json` - POST /users 的成功响应

## 使用方法

### 在单元测试中
\```swift
func testUserViewModel() throws {
    let user = try FixtureLoader.loadUser(id: "123")
    let viewModel = UserViewModel(user: user)
    XCTAssertEqual(viewModel.displayName, "Alice Test")
}
\```

### 在 SwiftUI Preview 中
\```swift
struct UserView_Previews: PreviewProvider {
    static var previews: some View {
        let user = try! FixtureLoader.loadUser(id: "123")
        UserView(user: user)
    }
}
\```

### 在 Mock Service 中
\```swift
class MockUserService: UserServiceProtocol {
    func fetchUser(id: String) async throws -> User {
        try FixtureLoader.loadUser(id: id)
    }
}
\```

## 更新 Fixture

当 OpenAPI 规范更新时：
1. 重新运行生成脚本
2. 比对差异（git diff）
3. 更新依赖 Fixture 的测试用例
```

## 注意事项

### ✅ 好的做法
- 为每个接口生成多种场景（正常、边界、错误）
- 使用有意义的测试数据（真实姓名、邮箱格式）
- 文件命名清晰，包含 HTTP 状态码
- 提供加载器的便捷方法，减少重复代码

### ❌ 避免的做法
- 只生成正常场景，忽略错误处理
- 使用无意义数据（如 "aaa", "111"）
- 把所有 Fixture 放在一个大 JSON 文件中
- 硬编码真实用户数据或敏感信息

### 🔧 常见调整

如果生成的 Fixture 不符合预期：

```
请调整以下内容：
1. 为 User 增加边界场景：年龄为 0、邮箱格式异常、名字包含 emoji
2. 错误响应需符合项目统一格式：{ "message": "...", "code": 1001 }
3. 分页列表需包含 metadata：{ "data": [...], "total": 100, "page": 1, "pageSize": 10 }
4. 日期字段使用 ISO 8601 格式："2024-10-28T10:30:00Z"
```

## 高级用法

### 场景一：生成带本地化的 Fixture

```
额外要求：为用户名和错误消息生成中英文两个版本：
- MockData/users/zh-CN/get_user_123.json
- MockData/users/en-US/get_user_123.json
```

### 场景二：生成大数据集

```
生成压力测试用的大数据集：
- get_users_large.json：包含 1000 条用户记录
- 数据需要有一定随机性（不同年龄、状态、注册时间）
```

### 场景三：关联数据

```
生成有外键关联的数据：
- User 123 关联 Order 789 和 Order 790
- 确保 order.userId 与 user.id 匹配
```

## 相关资源
- [工作流：API 接口自动生成 Mock](../../workflows/api-mock-generation.md)
- [提示词：从 Swift Protocol 生成 URLProtocol Mock](./protocol-to-urlprotocol.md)
- [OpenAPI Specification](https://swagger.io/specification/)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-28  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
