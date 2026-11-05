# 工作流：Swift Concurrency 迁移

## 📋 背景

在 iOS 项目演进中，遗留代码常使用回调闭包、GCD 队列、Combine 或 OperationQueue 处理异步逻辑。这导致：
- 回调地狱（Callback Hell），代码嵌套深难维护
- 线程切换不明确，容易出现主线程阻塞或数据竞争
- 错误传播复杂，缺少统一的异常处理机制
- 内存泄漏风险高，循环引用难排查

Swift Concurrency（async/await、Actor、MainActor、Sendable）提供了现代化的异步编程模型，使用 AI 辅助迁移可以在保证正确性的前提下，快速重构遗留代码。

## 🎯 目标

将指定模块的异步代码迁移到 Swift Concurrency，达到以下标准：
- **编译通过**：所有代码符合 Swift 6 并发检查（Strict Concurrency）
- **功能不变**：迁移后行为与原代码完全一致
- **性能不降**：无性能回退，关键路径延迟保持或优化
- **可维护性提升**：消除回调嵌套，错误处理统一为 throws

## 🛠️ 适用场景

- ✅ 迁移基于闭包回调的网络层/数据库层
- ✅ 重构使用 DispatchQueue 的异步逻辑
- ✅ 将 Combine Publisher 改为 AsyncSequence
- ✅ 为 UIKit/SwiftUI 引入 MainActor 隔离
- ❌ 不适合 Objective-C 混编模块（ObjC 不支持 async）
- ❌ 不适合 iOS 12 及以下（需 iOS 13+，完整支持需 iOS 15+）

## 📝 工作流步骤

### 步骤 1：准备上下文

在 Cursor 中准备以下上下文信息：

#### 1.1 确定迁移范围
创建临时文档 `concurrency-migration-context.md`：

```markdown
## 迁移目标模块
- 模块名称：NetworkManager
- 当前异步方案：闭包回调 + DispatchQueue
- 文件路径：Sources/Networking/NetworkManager.swift

## 依赖关系
- 被哪些模块调用：ViewModels, Repository 层
- 依赖哪些外部库：Alamofire（或原生 URLSession）
- 是否涉及 Objective-C 互操作：否

## 项目约束
- 最低支持版本：iOS 15.0
- 是否启用 Strict Concurrency：是（Swift 6 模式）
- 现有测试覆盖率：65%（需保持）
```

#### 1.2 收集代码样本
粘贴待迁移模块的关键代码到 Cursor：

```swift
// 示例：回调风格的网络请求
class NetworkManager {
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().async {
            // 网络请求逻辑
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            }.resume()
        }
    }
}
```

### 步骤 2：风险扫描与迁移计划

使用 AI 提示词生成迁移风险清单：

```
我需要将 NetworkManager 模块迁移到 Swift Concurrency。

## 任务
1. 扫描代码中所有异步模式（闭包回调、DispatchQueue、Combine、Notification）
2. 识别潜在风险点：
   - 数据竞争风险（共享可变状态）
   - 主线程依赖（UI 更新、UserDefaults）
   - 循环引用风险（[weak self] 闭包）
   - 外部依赖兼容性（第三方库是否支持 async）
3. 生成迁移计划，按优先级排序：
   - 叶子节点优先（被调用方先改）
   - 独立模块优先（减少连锁改动）

## 输出格式
请先输出风险清单与迁移计划（Markdown 表格），确认后再进入代码改造。
```

**使用提示词模板**：[prompts/concurrency/risk-scan.md](../prompts/concurrency/risk-scan.md)

### 步骤 3：审查迁移计划

AI 会输出类似结构：

```markdown
## 风险清单

| 风险项 | 位置 | 风险等级 | 缓解措施 |
|--------|------|----------|----------|
| 数据竞争 | NetworkManager.cache | 高 | 改用 Actor 隔离 |
| 主线程阻塞 | UserRepository.save() | 中 | 标记 @MainActor |
| 第三方库不兼容 | Alamofire 4.x | 高 | 升级到 5.x 或包装为 async |
| 循环引用 | ImageDownloader 闭包 | 低 | async 无需 [weak self] |

## 迁移计划（3 阶段）

### 阶段 1：基础设施层（优先级：高）
- [ ] NetworkClient: 闭包回调 → async/await
- [ ] CacheManager: DispatchQueue → Actor
- [ ] Logger: 线程安全检查 → Sendable

### 阶段 2：业务逻辑层（优先级：中）
- [ ] UserRepository: Combine → async/await
- [ ] ImageDownloader: 回调 → AsyncSequence（进度支持）

### 阶段 3：UI 层（优先级：低）
- [ ] ViewModel: @Published → @MainActor async
- [ ] UIViewController: 回调 → Task {}
```

**人工审查要点：**
- 迁移顺序是否自底向上？（避免中间层先改导致上下游都要改）
- 高风险项是否有明确的缓解措施？
- 是否有遗漏的共享可变状态？

### 步骤 4：分批迁移代码

按计划逐模块迁移，每次只改一个类/文件。

#### 4.1 使用迁移提示词
```
请将 NetworkManager.fetchUser(id:completion:) 方法迁移到 async/await。

## 要求
1. 保留原方法签名（兼容旧代码），新增 async 版本
2. 使用 withCheckedThrowingContinuation 桥接到 async
3. 确保错误传播正确（completion(.failure) → throw）
4. 主线程切换改用 @MainActor 标记

## 原代码
[粘贴待迁移方法]

## 验证标准
- 编译通过，无 Strict Concurrency 警告
- 行为与原方法完全一致（包括错误场景）
- 新方法添加单元测试覆盖
```

**使用提示词模板**：[prompts/concurrency/migrate-snippet.md](../prompts/concurrency/migrate-snippet.md)

#### 4.2 AI 生成的代码示例
```swift
// ✅ 迁移后的代码
class NetworkManager {
    // 保留旧接口（标记为 deprecated）
    @available(*, deprecated, message: "Use async version instead")
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        Task {
            do {
                let user = try await fetchUser(id: id)
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // 新增 async 接口
    func fetchUser(id: String) async throws -> User {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
}
```

### 步骤 5：编译与并发检查

#### 5.1 启用 Strict Concurrency
在 Xcode 项目设置或 Package.swift 中启用：

```swift
// Package.swift
let package = Package(
    // ...
    swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
    ]
)
```

或在 Xcode Build Settings 中设置：
```
SWIFT_STRICT_CONCURRENCY = complete
```

#### 5.2 修复并发警告

常见警告类型：

**警告 1：跨 Actor 边界访问可变状态**
```swift
// ❌ 警告：Main actor-isolated property 'text' can not be mutated from a non-isolated context
Task {
    label.text = "Loading..." // label 是 @MainActor 隔离的
}

// ✅ 修复：在 MainActor 上下文中访问
Task { @MainActor in
    label.text = "Loading..."
}
```

**警告 2：非 Sendable 类型跨并发域传递**
```swift
// ❌ 警告：Capture of 'cache' with non-sendable type 'Cache'
Task {
    let data = cache.fetch(key) // cache 不是 Sendable
}

// ✅ 修复：将 Cache 改为 Actor 或标记 Sendable
actor Cache: Sendable {
    func fetch(_ key: String) -> Data? { ... }
}
```

**警告 3：隐式主线程访问**
```swift
// ❌ 警告：Call to main actor-isolated initializer 'init()' in a synchronous nonisolated context
func setup() {
    let vc = MyViewController() // UIViewController 默认是 @MainActor
}

// ✅ 修复：明确标记方法为 @MainActor 或使用 Task
@MainActor
func setup() {
    let vc = MyViewController()
}
```

#### 5.3 编译检查清单
```bash
# 编译并启用并发检查
xcodebuild build \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  SWIFT_STRICT_CONCURRENCY=complete

# 检查无警告输出
```

### 步骤 6：人工审查关键路径

AI 迁移的代码需要人工确认以下要点：

#### 6.1 主线程隔离正确性
```swift
// ✅ UI 更新必须在 MainActor
@MainActor
func updateUI(with user: User) {
    label.text = user.name
    imageView.image = user.avatar
}

// ❌ 错误：在后台线程更新 UI
func updateUI(with user: User) { // 未标记 @MainActor
    label.text = user.name // 运行时可能崩溃
}
```

#### 6.2 取消任务处理
```swift
// ✅ 正确：检查 Task.isCancelled
func loadData() async throws -> Data {
    try Task.checkCancellation() // 抛出 CancellationError
    
    let data = try await fetchFromNetwork()
    
    if Task.isCancelled { return Data() } // 提前退出
    
    return data
}

// ❌ 错误：未处理取消，任务继续执行浪费资源
func loadData() async throws -> Data {
    let data = try await fetchFromNetwork()
    return data
}
```

#### 6.3 错误传播完整性
```swift
// ✅ 正确：所有错误都 throw
func fetchUser(id: String) async throws -> User {
    guard isValid(id) else {
        throw ValidationError.invalidID
    }
    
    do {
        return try await apiClient.fetch(id)
    } catch {
        throw NetworkError.underlying(error) // 包装底层错误
    }
}

// ❌ 错误：吞掉错误或返回可选值（调用方无法判断失败原因）
func fetchUser(id: String) async -> User? {
    do {
        return try await apiClient.fetch(id)
    } catch {
        print("Error: \(error)") // 只打日志
        return nil
    }
}
```

### 步骤 7：测试验证

#### 7.1 单元测试覆盖
为迁移后的 async 方法补充测试：

```swift
// 测试正常流程
func test_fetchUser_withValidID_returnsUser() async throws {
    let manager = NetworkManager(client: MockClient())
    let user = try await manager.fetchUser(id: "123")
    XCTAssertEqual(user.id, "123")
}

// 测试错误处理
func test_fetchUser_withNetworkFailure_throwsError() async {
    let manager = NetworkManager(client: FailingMockClient())
    
    do {
        _ = try await manager.fetchUser(id: "123")
        XCTFail("Should throw error")
    } catch {
        XCTAssertTrue(error is NetworkError)
    }
}

// 测试取消任务
func test_fetchUser_whenCancelled_throwsCancellationError() async {
    let manager = NetworkManager(client: SlowMockClient())
    
    let task = Task {
        try await manager.fetchUser(id: "123")
    }
    
    task.cancel()
    
    do {
        _ = try await task.value
        XCTFail("Should throw cancellation error")
    } catch {
        XCTAssertTrue(error is CancellationError)
    }
}
```

#### 7.2 集成测试
在真实环境测试迁移后的代码：

```swift
// 测试主线程隔离
func test_updateUI_executesOnMainThread() async {
    await MainActor.run {
        let vc = UserViewController()
        let user = User(id: "123", name: "Test")
        
        // 确保不崩溃
        vc.updateUI(with: user)
        
        XCTAssertEqual(vc.nameLabel.text, "Test")
    }
}
```

#### 7.3 性能基准测试
对比迁移前后的性能：

```swift
func test_fetchUser_performanceComparison() {
    // 旧版本基准
    measure {
        let exp = expectation(description: "Old callback version")
        oldManager.fetchUser(id: "123") { _ in
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
    
    // 新版本基准
    measure {
        let exp = expectation(description: "New async version")
        Task {
            _ = try? await newManager.fetchUser(id: "123")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }
}
```

## ✅ 验证清单

迁移完成后，使用以下清单确保质量：

- [ ] 所有代码编译通过，无 Strict Concurrency 警告
- [ ] 旧接口标记为 `@available(*, deprecated)`，保留向后兼容
- [ ] UI 更新相关代码标记 `@MainActor`
- [ ] 共享可变状态封装在 `actor` 中
- [ ] 跨并发域传递的类型遵循 `Sendable` 协议
- [ ] 长时间运行任务正确处理 `Task.isCancelled`
- [ ] 所有异步方法有对应的单元测试
- [ ] 测试覆盖率不低于迁移前
- [ ] 性能基准测试无回退（关键路径延迟 ±5% 内）
- [ ] Code Review 确认无数据竞争风险

## 🐛 常见问题

### Q1: AI 生成的代码有数据竞争警告

**原因**：AI 可能未识别共享可变状态的并发访问。

**解决**：
1. 识别被多个 Task 访问的可变属性：
   ```swift
   class Cache {
       private var storage: [String: Data] = [:] // ⚠️ 未同步
   }
   ```

2. 使用 Actor 隔离状态：
   ```swift
   actor Cache {
       private var storage: [String: Data] = [:]
       
       func get(_ key: String) -> Data? {
           storage[key]
       }
       
       func set(_ key: String, value: Data) {
           storage[key] = value
       }
   }
   ```

### Q2: 旧代码调用新 async 方法时编译报错

**原因**：同步上下文无法直接调用 async 方法。

**解决**：
1. 保留旧的闭包接口，内部调用 async 版本：
   ```swift
   func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
       Task {
           do {
               let user = try await fetchUser(id: id)
               completion(.success(user))
           } catch {
               completion(.failure(error))
           }
       }
   }
   ```

2. 或在调用方创建 Task：
   ```swift
   // 调用方代码
   Task {
       let user = try await manager.fetchUser(id: "123")
       await updateUI(with: user)
   }
   ```

### Q3: MainActor 隔离导致性能下降

**原因**：过度使用 `@MainActor` 标记导致计算密集型操作阻塞主线程。

**解决**：
1. 只标记真正需要主线程的部分：
   ```swift
   class ViewModel {
       // ❌ 整个类标记 @MainActor
       @MainActor
       class BadViewModel {
           func processData() { /* 耗时计算 */ }
       }
       
       // ✅ 只标记 UI 相关属性
       @MainActor var displayText: String = ""
       
       func processData() async { // 后台执行
           let result = heavyComputation()
           await updateUI(result)
       }
       
       @MainActor
       private func updateUI(_ text: String) {
           displayText = text
       }
   }
   ```

### Q4: 如何迁移 Combine Publisher？

**原因**：Combine 和 async/await 是不同的异步模型。

**解决**：
1. 单值 Publisher → async/await：
   ```swift
   // Combine 版本
   func fetchUser(id: String) -> AnyPublisher<User, Error> {
       URLSession.shared.dataTaskPublisher(for: url)
           .map(\.data)
           .decode(type: User.self, decoder: JSONDecoder())
           .eraseToAnyPublisher()
   }
   
   // async/await 版本
   func fetchUser(id: String) async throws -> User {
       let (data, _) = try await URLSession.shared.data(from: url)
       return try JSONDecoder().decode(User.self, from: data)
   }
   ```

2. 多值 Publisher → AsyncSequence：
   ```swift
   // Combine 版本
   func downloadProgress() -> AnyPublisher<Double, Never> {
       progressSubject.eraseToAnyPublisher()
   }
   
   // AsyncSequence 版本
   func downloadProgress() -> AsyncStream<Double> {
       AsyncStream { continuation in
           // 在进度更新时调用
           continuation.yield(0.5)
           continuation.finish()
       }
   }
   ```

### Q5: 第三方库不支持 async/await 怎么办？

**解决**：
1. 使用 `withCheckedThrowingContinuation` 桥接：
   ```swift
   // 包装 Alamofire 请求
   func request(_ url: URL) async throws -> Data {
       try await withCheckedThrowingContinuation { continuation in
           AF.request(url).responseData { response in
               switch response.result {
               case .success(let data):
                   continuation.resume(returning: data)
               case .failure(let error):
                   continuation.resume(throwing: error)
               }
           }
       }
   }
   ```

2. 或升级到支持 async 的版本（如 Alamofire 5.5+）

## 🎓 最佳实践

### 1. 渐进式迁移
- ✅ 采用双接口策略：保留旧接口，新增 async 版本
- ✅ 从叶子节点（底层工具类）开始迁移
- ✅ 每迁移一个模块，立即补充测试并提交
- ❌ 不要一次性重写整个模块

### 2. 明确 Actor 边界
- ✅ 识别共享可变状态，用 Actor 封装
- ✅ UI 相关类型使用 `@MainActor` 隔离
- ✅ 网络层、数据库层使用自定义 Actor 或 Sendable 类型
- ❌ 不要过度使用 Actor（纯计算逻辑无需隔离）

### 3. 错误处理统一化
- ✅ 所有异步方法使用 `throws` 传播错误
- ✅ 定义业务错误类型（enum Error）
- ✅ 在最外层（ViewModel/Controller）统一捕获并展示
- ❌ 不要在中间层吞掉错误或返回 Optional

### 4. 测试先行
- ✅ 迁移前确保有回归测试覆盖
- ✅ 为每个 async 方法补充单元测试
- ✅ 测试取消场景（Task.cancel()）
- ✅ 性能基准测试确保无回退

### 5. Code Review 要点
人工审查 AI 生成的迁移代码时，重点检查：
- 所有 UI 访问是否在 `@MainActor` 上下文
- 是否有遗漏的数据竞争风险（共享可变状态）
- Task 取消是否正确处理
- 错误传播是否完整（无静默失败）
- 性能敏感路径是否有不必要的线程切换

## 📚 扩展阅读

- [Swift Concurrency 官方文档](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Migrating to Swift 6 (Apple)](https://developer.apple.com/documentation/swift/adoptingswift6)
- [Understanding Sendable and @Sendable closures](https://www.swiftbysundell.com/articles/sendable-and-sendable-closures-in-swift/)
- [MainActor usage in SwiftUI](https://www.hackingwithswift.com/quick-start/concurrency/understanding-how-global-actor-inference-works)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md) - 迁移后补充 async 测试
- [重构遗留 UIKit 代码](./uikit-refactoring.md) - UI 层迁移到 MainActor

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-01  
**适用工具**：Cursor、Claude Code、GitHub Copilot
