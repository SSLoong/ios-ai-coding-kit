# 提示词：迁移单个方法到 async/await

## 场景说明

针对具体的回调风格方法或 GCD 异步代码，生成迁移到 Swift Concurrency（async/await、MainActor、Actor）的代码，确保行为一致、编译通过、符合 Strict Concurrency 要求。

## 输入要求

### 必需
- 待迁移方法的完整代码（包括类上下文）
- 方法当前的异步模式（闭包回调、DispatchQueue、Combine）
- 依赖的类型定义（协议、Model、Error 类型）

### 可选
- 调用方代码示例（了解如何被使用）
- 项目编码规范（命名约定、错误处理风格）
- 是否需要保留旧接口（向后兼容）

## 提示词模板

```
请将以下 Swift 方法迁移到 async/await，符合 Swift Concurrency 最佳实践。

## 待迁移方法
```swift
[粘贴完整的方法代码，包含类定义]
```

## 依赖类型
[粘贴相关的协议、结构体、枚举定义，如：]
```swift
struct User: Codable {
    let id: String
    let name: String
}

enum NetworkError: Error {
    case invalidResponse
    case timeout
}
```

## 迁移要求

### 1. 接口设计
- [ ] 新增 async 版本方法：`func methodName() async throws -> ReturnType`
- [ ] [可选] 保留旧的闭包接口并标记 `@available(*, deprecated)`，内部调用 async 版本
- [ ] 方法命名遵循 Swift API 设计指南（去掉 completion/handler 后缀）

### 2. 并发安全
- [ ] 识别并发访问的可变状态，使用 `actor` 隔离或 `Sendable` 标记
- [ ] UI 相关操作标记 `@MainActor`
- [ ] 跨 Actor 边界传递的类型确保 Sendable（值类型或 final class）

### 3. 错误处理
- [ ] 将 `completion(.failure(error))` 改为 `throw error`
- [ ] 统一错误类型（使用项目定义的 Error enum）
- [ ] 不吞掉错误，保证错误传播完整

### 4. 线程切换
- [ ] 将 `DispatchQueue.main.async { completion(...) }` 改为 `@MainActor` 标注或 `await MainActor.run {}`
- [ ] 移除手动的 `DispatchQueue.global().async`（async 方法默认在协作线程池执行）
- [ ] 明确标注需要主线程的部分

### 5. 取消支持
- [ ] 对于长时间运行的操作，检查 `Task.isCancelled` 或 `try Task.checkCancellation()`
- [ ] 对于网络请求，确保底层支持取消（如 URLSessionTask.cancel()）

## 验证标准
- [ ] 编译通过，无 Strict Concurrency 警告
- [ ] 行为与原方法完全一致（包括错误场景）
- [ ] 代码符合 Swift 6 并发规范
- [ ] [可选] 提供调用示例与对应的单元测试

## 输出格式
1. 迁移后的完整代码（包含类定义）
2. 如果保留旧接口，提供桥接实现
3. 说明关键改动点（线程模型、错误处理、Actor 隔离）
4. [可选] 提供调用示例与测试用例骨架
```

## 使用示例

### 输入

```
请将以下 Swift 方法迁移到 async/await，符合 Swift Concurrency 最佳实践。

## 待迁移方法
```swift
class NetworkManager {
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().async {
            guard let url = URL(string: "https://api.example.com/users/\(id)") else {
                DispatchQueue.main.async {
                    completion(.failure(NetworkError.invalidURL))
                }
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    DispatchQueue.main.async {
                        completion(.failure(NetworkError.invalidResponse))
                    }
                    return
                }
                
                do {
                    let user = try JSONDecoder().decode(User.self, from: data)
                    DispatchQueue.main.async {
                        completion(.success(user))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }.resume()
        }
    }
}
```

## 依赖类型
```swift
struct User: Codable {
    let id: String
    let name: String
    let email: String
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
}
```

## 迁移要求
- 保留旧接口（标记 deprecated）
- 所有 completion 回调在主线程的逻辑改为调用方决定
- 新增 async 版本
```

### 输出示例

```swift
// MARK: - 迁移后的代码

class NetworkManager {
    
    // ✅ 新增 async 版本（主要接口）
    func fetchUser(id: String) async throws -> User {
        // 1. 构造 URL
        guard let url = URL(string: "https://api.example.com/users/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        // 2. 发起网络请求（URLSession.data 原生支持 async/await）
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 3. 验证响应
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        // 4. 解码
        do {
            return try JSONDecoder().decode(User.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }
    
    // ✅ 保留旧接口（向后兼容）
    @available(*, deprecated, message: "Use async version: fetchUser(id:) async throws -> User")
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                let user = try await fetchUser(id: id)
                // 注意：不再强制在主线程调用 completion
                // 调用方可以自行决定是否切换到主线程
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - 关键改动说明

/**
 ### 改动点 1：移除手动线程切换
 - 旧版本：手动 DispatchQueue.main.async 切换
 - 新版本：去掉强制主线程，由调用方决定（如在 ViewModel 中标记 @MainActor）
 
 ### 改动点 2：错误处理简化
 - 旧版本：每个错误分支都要 completion(.failure(...))
 - 新版本：直接 throw，编译器保证错误传播
 
 ### 改动点 3：URLSession 原生 async 支持
 - 旧版本：dataTask(with:completionHandler:)
 - 新版本：data(from:) async throws
 
 ### 改动点 4：无需 [weak self]
 - async 上下文无需闭包捕获，self 自动管理
 
 ### 改动点 5：向后兼容
 - 保留旧接口，内部通过 Task 桥接到 async 版本
 - 标记 deprecated，引导开发者迁移
 */

// MARK: - 调用示例

// ✅ 在 @MainActor 上下文（ViewModel）中调用
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager()
    
    func loadUser(id: String) {
        Task {
            do {
                // 自动在主线程，因为整个方法是 @MainActor
                user = try await networkManager.fetchUser(id: id)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// ✅ 在后台上下文调用
func backgroundTask() {
    Task {
        do {
            let user = try await NetworkManager().fetchUser(id: "123")
            print("Fetched user: \(user.name)")
            
            // 需要更新 UI 时，显式切换到主线程
            await MainActor.run {
                // 更新 UI
            }
        } catch {
            print("Error: \(error)")
        }
    }
}

// MARK: - 测试用例骨架

import XCTest

class NetworkManagerTests: XCTestCase {
    
    // ✅ 测试正常流程
    func test_fetchUser_withValidID_returnsUser() async throws {
        let manager = NetworkManager()
        let user = try await manager.fetchUser(id: "123")
        
        XCTAssertEqual(user.id, "123")
        XCTAssertFalse(user.name.isEmpty)
    }
    
    // ✅ 测试错误处理
    func test_fetchUser_withInvalidID_throwsError() async {
        let manager = NetworkManager()
        
        do {
            _ = try await manager.fetchUser(id: "invalid")
            XCTFail("Should throw error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    // ✅ 测试取消
    func test_fetchUser_whenCancelled_throwsCancellationError() async {
        let manager = NetworkManager()
        
        let task = Task {
            try await manager.fetchUser(id: "123")
        }
        
        task.cancel()
        
        do {
            _ = try await task.value
            XCTFail("Should throw cancellation error")
        } catch is CancellationError {
            // 预期行为
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
```

## 注意事项

### 1. 主线程策略变化
**旧模式**（强制主线程回调）：
```swift
DispatchQueue.main.async {
    completion(.success(data))
}
```

**新模式**（调用方决定）：
- 如果调用方是 `@MainActor` 上下文（ViewModel、ViewController），自动在主线程
- 如果在后台 Task，需要时用 `await MainActor.run {}`
- 不再在底层强制主线程，提升灵活性

### 2. 桥接旧接口时避免循环
❌ **错误示例**（相互调用导致无限递归）：
```swift
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    Task {
        let result = await fetchUser(id: id) // ⚠️ 调用了自己
        completion(result)
    }
}
```

✅ **正确示例**（明确区分方法签名）：
```swift
// async 版本
func fetchUser(id: String) async throws -> User { ... }

// 旧版本调用 async 版本
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    Task {
        do {
            let user = try await fetchUser(id: id) // 调用 async 版本
            completion(.success(user))
        } catch {
            completion(.failure(error))
        }
    }
}
```

### 3. Sendable 边界
跨并发域传递的类型必须是 Sendable：
```swift
// ✅ 值类型自动 Sendable
struct User: Codable, Sendable {
    let id: String
}

// ❌ 可变类需显式声明
class MutableCache: @unchecked Sendable { // 需保证内部同步
    private let lock = NSLock()
    private var storage: [String: Data] = [:]
}

// ✅ 改用 Actor 更安全
actor Cache {
    private var storage: [String: Data] = [:]
}
```

### 4. 长时间操作的取消处理
```swift
func downloadLargeFile(url: URL) async throws -> Data {
    var chunks: [Data] = []
    
    for try await chunk in URLSession.shared.bytes(from: url) {
        // 定期检查取消状态
        try Task.checkCancellation()
        
        chunks.append(chunk)
    }
    
    return chunks.reduce(Data(), +)
}
```

### 5. 迁移 Combine Publisher
**单值 Publisher**：
```swift
// 旧版本
func fetchUser(id: String) -> AnyPublisher<User, Error> {
    URLSession.shared.dataTaskPublisher(for: url)
        .map(\.data)
        .decode(type: User.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}

// 新版本
func fetchUser(id: String) async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}
```

**多值 Publisher（流）**：
```swift
// 旧版本
var progressPublisher: AnyPublisher<Double, Never> { ... }

// 新版本
func downloadProgress() -> AsyncStream<Double> {
    AsyncStream { continuation in
        // 每次进度更新时
        continuation.yield(0.25)
        continuation.yield(0.50)
        continuation.finish()
    }
}
```

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-11-01  
**适用模型**：Claude Sonnet 3.5+, GPT-4, Cursor Composer
