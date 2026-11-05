# 提示词：Swift Concurrency 迁移风险扫描

## 场景说明

在将遗留异步代码迁移到 Swift Concurrency 之前，需要识别潜在的并发安全风险、主线程依赖、第三方库兼容性等问题，并生成优先级排序的迁移计划。

## 输入要求

### 必需
- 待迁移模块的完整代码（类、协议、扩展）
- 项目技术栈信息（iOS 最低版本、使用的第三方库）
- 当前异步方案（回调、GCD、Combine、OperationQueue）

### 可选
- 模块调用关系图（被哪些上层模块依赖）
- 现有测试覆盖率报告
- 性能基准数据（关键路径的平均响应时间）

## 提示词模板

```
我需要为 [模块名称] 生成 Swift Concurrency 迁移风险清单与计划。

## 模块信息
- 模块名称：[填写，如 NetworkManager]
- 当前异步方案：[回调闭包 / GCD / Combine / OperationQueue]
- 文件路径：[填写，如 Sources/Networking/NetworkManager.swift]
- iOS 最低版本：[填写，如 iOS 15.0]
- 是否启用 Strict Concurrency：[是 / 否]

## 待扫描代码
[粘贴完整的类/模块代码]

## 项目依赖
[列出使用的第三方库及版本，如：]
- Alamofire 5.6
- Kingfisher 7.0
- Realm Swift 10.40

## 任务要求

### 1. 风险扫描
请识别以下风险类型，输出 Markdown 表格：

| 风险项 | 代码位置 | 风险等级 | 详细说明 | 缓解措施 |
|--------|----------|----------|----------|----------|
| 数据竞争 | NetworkManager.cache | 高 | 可变字典被多线程访问 | 改用 Actor 隔离 |
| ... | ... | ... | ... | ... |

**风险类型包括但不限于：**
- **数据竞争**：共享可变状态（属性、静态变量、单例）在无同步保护下被多线程访问
- **主线程依赖**：UI 更新、UserDefaults、Core Data 主队列上下文等必须在主线程的操作
- **循环引用**：闭包中的 [weak self] / [unowned self] 需求
- **第三方库兼容性**：依赖的库是否支持 async/await（需要包装或升级）
- **隐式线程切换**：DispatchQueue.main.async / .global().async 等需明确映射到 MainActor 或 Task
- **Notification 跨线程**：NotificationCenter 回调的线程不确定性
- **Combine 依赖**：Publisher 链路需重新设计为 AsyncSequence 或 async throws

### 2. 迁移优先级分析
按以下原则对迁移任务排序：
1. **叶子节点优先**：被调用方（底层工具类、网络层）先改，避免改动传播
2. **独立模块优先**：与其他模块耦合少的先改
3. **高风险区域后置**：涉及复杂状态管理的核心业务逻辑最后改

### 3. 迁移计划
输出分阶段的迁移计划（Markdown 清单）：

```markdown
## 迁移计划

### 阶段 1：基础设施层（预计 X 个方法）
- [ ] NetworkClient.request() - 回调改 async/await
- [ ] CacheManager - 改为 Actor 隔离
- [ ] Logger.log() - 标记 Sendable

### 阶段 2：业务逻辑层（预计 Y 个方法）
- [ ] UserRepository.fetchUser() - Combine → async
- [ ] ImageDownloader - 支持 AsyncSequence 进度

### 阶段 3：UI 层（预计 Z 个方法）
- [ ] UserViewModel - @Published → @MainActor
- [ ] ProfileViewController.updateUI() - 标记 @MainActor
```

### 4. 兼容性检查
对于第三方库依赖，说明：
- 哪些库需要升级到支持 async 的版本
- 哪些库需要手动包装（使用 withCheckedContinuation）
- 哪些库无法兼容（需替换方案）

## 输出格式
1. 风险清单（Markdown 表格）
2. 迁移计划（分阶段清单，标注优先级）
3. 兼容性检查结果
4. 预估改动范围（多少个类、多少个方法）

请先输出上述分析结果，等我确认后再进入具体代码迁移。
```

## 使用示例

### 输入

```
我需要为 NetworkManager 生成 Swift Concurrency 迁移风险清单与计划。

## 模块信息
- 模块名称：NetworkManager
- 当前异步方案：回调闭包 + DispatchQueue
- 文件路径：Sources/Networking/NetworkManager.swift
- iOS 最低版本：iOS 15.0
- 是否启用 Strict Concurrency：是

## 待扫描代码
```swift
class NetworkManager {
    static let shared = NetworkManager()
    
    private var cache: [String: Data] = [:]
    private let queue = DispatchQueue(label: "network.cache")
    
    func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
        DispatchQueue.global().async {
            // 网络请求
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                // 缓存逻辑
                self.queue.async {
                    self.cache[id] = data
                }
                
                DispatchQueue.main.async {
                    completion(.success(user))
                }
            }.resume()
        }
    }
    
    func clearCache() {
        queue.async {
            self.cache.removeAll()
        }
    }
}
```

## 项目依赖
- Alamofire 4.9（未使用，可移除）
- Kingfisher 7.0

## 任务要求
[按模板执行扫描与分析]
```

### 输出示例

```markdown
## 风险清单

| 风险项 | 代码位置 | 风险等级 | 详细说明 | 缓解措施 |
|--------|----------|----------|----------|----------|
| 数据竞争 | cache 字典 | 高 | 虽然用 queue 保护写入，但读取时未同步 | 改为 Actor 隔离所有访问 |
| 主线程依赖 | completion 回调 | 中 | 强制在 main 线程调用，需明确标注 | 迁移后用 @MainActor 标记调用方 |
| 单例模式 | shared 实例 | 中 | 全局可变单例需确保 Sendable | 改为 actor 或标记 final + Sendable |
| 循环引用 | [weak self] | 低 | async 上下文无需 weak，可简化 | 移除 [weak self] |

## 迁移计划

### 阶段 1：基础设施层（2 个方法）
- [ ] NetworkManager.cache - 改为 Actor 隔离
- [ ] NetworkManager.fetchUser() - 回调改 async/await

### 阶段 2：调用方适配（取决于上层模块）
- [ ] 标记调用方为 @MainActor（如 ViewModel）
- [ ] 移除 DispatchQueue.main.async 包装

## 兼容性检查
- Alamofire 4.9：未在此模块使用，可移除依赖
- Kingfisher 7.0：已支持 async/await，无需改动

## 预估改动
- 类数量：1 个（NetworkManager）
- 方法数量：2 个（fetchUser, clearCache）
- 新增类型：1 个（将 NetworkManager 改为 actor）
- 测试覆盖：需新增 3 个 async 测试用例
```

## 注意事项

### 1. 共享可变状态识别
- 检查所有 `var` 属性（特别是集合类型、单例）
- 关注静态变量和全局变量
- 注意延迟初始化的属性（`lazy var`）

### 2. 隐式主线程假设
以下操作需明确标记 `@MainActor`：
- UIKit/AppKit 视图操作
- UserDefaults 读写
- Core Data 主队列 context
- NotificationCenter 发送（如涉及 UI 更新）

### 3. 第三方库版本检查
- Alamofire：5.5+ 支持 async
- Kingfisher：7.0+ 支持 async
- Realm：10.27+ 支持 async/await
- RxSwift：需手动桥接或迁移到 AsyncSequence

### 4. 性能敏感路径
- 识别高频调用的方法（如图片加载、滚动列表数据获取）
- 避免过度使用 `await`（多个串行 await 可能影响响应速度）
- 考虑使用 `async let` 并发执行独立任务

### 5. 迁移顺序验证
- 确保依赖方向：下游→上游（被调用方先改）
- 避免中间层先改导致上下游都要改
- 每阶段完成后提交代码，避免大爆炸式改动

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-11-01  
**适用模型**：Claude Sonnet 3.5+, GPT-4, Cursor Composer
