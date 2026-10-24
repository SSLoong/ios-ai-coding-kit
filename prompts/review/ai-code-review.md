# AI 代码 Review 提示词

## 场景说明

用于对 iOS/Swift 代码改动（PR 或本地 diff）进行系统化审查，包括风险分级、问题定位和修复建议。

## 适用模型

- **推荐**：GPT-4、Claude 3 Opus、Claude Sonnet 3.5（上下文理解能力强）
- **最低要求**：GPT-3.5-turbo、Claude Haiku（可能遗漏复杂问题）
- **不推荐**：Codex（专注代码生成，审查能力较弱）

## 输入要求

### 必需
- **代码改动 diff**：通过 `git diff` 或 GitHub PR `.diff` 获取
- **项目基本信息**：架构模式（MVVM/MVI/VIPER）、主要技术栈（UIKit/SwiftUI）

### 可选（强烈建议提供）
- **模块依赖关系**：改动涉及的模块及其依赖
- **代码风格约束**：SwiftLint 配置、命名约定
- **安全与隐私要求**：敏感数据处理规范
- **审查重点**：需要特别关注的文件或方法

## 提示词模板

### 阶段一：风险分级

```
我需要对以下 iOS 代码改动进行 Code Review，请先进行风险分级。

## 改动内容
[粘贴 git diff 内容，或 GitHub PR 的 .diff URL]

## 项目上下文
### 架构信息
- 架构模式：[MVVM / MVI / VIPER / Clean Architecture]
- UI 框架：[UIKit / SwiftUI / 混合]
- 依赖注入：[Swinject / 手动注入 / 其他]
- 网络层：[Alamofire / URLSession / 其他]
- 异步处理：[Swift Concurrency / Combine / RxSwift]

### 模块依赖（本次改动涉及）
[列出改动的模块及其依赖关系，例如：
- Core/NetworkManager（网络请求封装）
- Features/UserProfile（用户资料页面）
- 依赖：UserProfile → NetworkManager → Alamofire]

### 代码风格约束
[列出关键约束，例如：
- 禁止使用 force unwrap (!)
- UI 更新必须在主线程
- 遵循 SwiftLint 配置
- 异步操作优先使用 async/await]

### 安全与隐私要求
[列出安全规范，例如：
- 不得硬编码 API Key
- 敏感信息禁止打印到日志
- 使用 HTTPS
- 密码存储使用 Keychain]

## 任务
请分析改动，按以下级别分类问题：

### Blocker（阻断发布，必须立即修复）
- 导致 crash 的明确风险
- 严重的内存泄漏或循环引用
- 安全漏洞（密钥泄漏、SQL 注入、XSS 等）
- 数据丢失或损坏风险
- 明确违反平台规范（导致 App Store 拒审）

### Major（必须在合并前修复）
- 潜在的运行时错误（force unwrap 无保护、数组越界）
- 线程安全问题（数据竞争、死锁风险）
- 明显的性能问题（主线程阻塞、内存暴涨）
- 违反核心架构约束（如直接访问不应暴露的内部实现）
- 缺少关键错误处理（网络请求、文件操作）

### Minor（建议修复，但不阻塞发布）
- 代码风格不一致（命名、格式）
- 可读性问题（命名不清晰、缺少注释）
- 轻微的性能优化机会（可优化但影响不大）
- 潜在的可维护性问题（重复代码、过长方法）
- 非关键路径的错误处理缺失

### Nit（可选优化，锦上添花）
- 空格、换行等格式问题（SwiftLint 可自动修复的）
- 更优雅的写法（但当前写法也没有问题）
- 非关键的代码组织建议

## 输出格式
### 1. 问题数量统计
| 级别 | 数量 |
|------|------|
| Blocker | X |
| Major | X |
| Minor | X |
| Nit | X |

### 2. 高优先级问题概览（仅列出 Blocker 和 Major）
- [问题 1]：[文件名]::[行号] - [一句话描述]
- [问题 2]：[文件名]::[行号] - [一句话描述]
- ...

请先完成此步，等待我确认后再进行详细分析。
```

### 阶段二：详细分析

（在阶段一完成后继续）

```
针对上述 Blocker 和 Major 问题，请逐项给出详细分析。

## 输出格式（针对每个问题）
### 问题 [编号]：[简要描述]

**级别**：[Blocker / Major]

**位置**：
- 文件：`[完整文件路径]`
- 方法/类：`[类名]::[方法名]`
- 行号：`[具体行号或行号范围]`

**问题描述**：
[详细说明为什么这是一个问题，包括：
1. 具体的技术原因
2. 在什么情况下会出现问题
3. 可能导致的后果（crash、数据错误、安全风险等）]

**影响范围**：
[分析影响面，包括：
- 影响的功能模块
- 影响的用户场景
- 是否影响其他依赖此代码的模块]

**当前代码**：
```swift
[粘贴有问题的代码片段]
```

**修复建议**：
```swift
[提供完整的修复代码，不要使用 "..." 省略]
```

**修复说明**：
[解释为什么这样修复，如果有多种方案，列出各自的优缺点]

**参考资料**：
[如适用，提供相关的：
- Apple 官方文档链接
- Swift Evolution 提案
- 业界最佳实践文章]

---

## 要求
1. 每个问题必须提供完整的修复代码（不要用 "..." 省略）
2. 修复建议必须符合项目的架构约束
3. 如果问题复杂，提供修复前后的对比代码
4. 对于有争议的修复方案，说明各自的权衡
```

### 阶段三：专项检查（可选，按需使用）

#### 内存管理专项检查

```
针对本次改动，进行内存管理专项检查。

## 检查要点
1. **闭包捕获**：
   - 所有闭包是否正确使用 [weak self] 或 [unowned self]
   - 是否存在循环引用风险（self → closure → self）
   
2. **循环引用**：
   - delegate 是否声明为 weak
   - 观察者是否在 deinit 中正确移除
   - NotificationCenter 观察者是否正确清理

3. **大对象生命周期**：
   - 图片、大数据缓存是否及时释放
   - 是否有不必要的强引用导致内存无法释放

4. **Timer/观察者清理**：
   - Timer 是否在 deinit 中 invalidate
   - KVO 观察者是否正确移除
   - Combine/AsyncSequence 订阅是否正确取消

## 输出格式
针对每个潜在问题：
- **位置**：[文件名]::[行号]
- **问题**：[描述循环引用或内存泄漏的路径]
- **验证方法**：[如何用 Instruments 验证]
- **修复代码**：[完整的修复代码]
```

#### 线程安全专项检查

```
针对本次改动，进行线程安全专项检查。

## 检查要点
1. **共享状态访问**：
   - 是否有多线程同时读写同一变量（数据竞争）
   - 是否需要使用 actor、锁或串行队列保护

2. **UI 更新**：
   - 所有 UI 操作是否在主线程
   - 是否正确使用 @MainActor 或 DispatchQueue.main

3. **异步回调**：
   - 网络请求、文件操作的回调在哪个线程
   - 回调中的 UI 更新是否切换到主线程

4. **Actor 隔离**：
   - 是否正确使用 @MainActor 标记 UI 类型
   - 跨 actor 调用是否正确使用 await

## 输出格式
针对每个潜在问题：
- **位置**：[文件名]::[行号]
- **问题**：[描述数据竞争或线程问题]
- **复现条件**：[什么情况下会出现]
- **修复方案**：[提供使用 actor 或 DispatchQueue 的修复代码]
```

#### SwiftUI 性能检查

```
针对 SwiftUI 视图改动，进行性能检查。

## 检查要点
1. **状态管理**：
   - @State/@ObservableObject 使用是否合理
   - 是否有不必要的状态导致重绘
   - 是否应该使用 @StateObject 而非 @ObservedObject

2. **计算属性**：
   - body 中是否有重复计算
   - 是否应提取为 @State 或使用缓存

3. **List/ScrollView**：
   - 是否遗漏了 .id() 导致重绘
   - 数据更新时是否触发全量刷新

4. **图片加载**：
   - 是否使用了 resizable() 和合适的 contentMode
   - 是否使用 lazy loading（AsyncImage）

5. **子视图拆分**：
   - 是否应该拆分为独立 View 减少重绘范围
   - 是否正确使用 Equatable 优化

## 输出格式
针对每个性能问题：
- **位置**：[文件名]::[行号]
- **问题**：[描述性能隐患及影响]
- **优化建议**：[具体优化方案和代码]
- **性能提升预期**：[估算优化效果]
```

#### 安全与隐私检查

```
针对本次改动，进行安全与隐私专项检查。

## 检查要点
1. **敏感信息泄漏**：
   - 代码中是否包含 API Key、密码、Token、证书
   - 是否应该使用环境变量或 Keychain

2. **日志安全**：
   - print/NSLog/Logger 是否输出了用户隐私数据（手机号、邮箱、身份证、地址）
   - 生产环境日志是否可能泄漏敏感信息

3. **网络安全**：
   - 是否使用了 HTTP（应该用 HTTPS）
   - 证书验证是否正确（没有禁用证书校验）
   - 是否有 SSL Pinning 需求但未实现

4. **数据存储**：
   - 敏感数据是否错误地存储在 UserDefaults 或文件系统
   - 密码、Token 是否正确使用 Keychain 存储
   - 缓存数据是否包含敏感信息且未加密

5. **输入验证**：
   - 用户输入是否经过验证（防止注入攻击）
   - URL、文件路径是否经过校验（防止路径穿越）
   - 是否有 SQL 注入风险（如使用 SQLite）

6. **权限申请**：
   - 是否在使用前申请了必要权限（相机、位置、通讯录）
   - Info.plist 中的权限说明是否清晰

## 输出格式
针对每个安全问题：
- **位置**：[文件名]::[行号]
- **严重程度**：[Critical / High / Medium / Low]
- **安全风险**：[描述可能的攻击场景或数据泄漏风险]
- **修复方案**：[提供安全的实现代码]
- **合规性**：[是否影响 App Store 审核或 GDPR/隐私合规]
```

### 阶段四：生成最终报告

```
基于前面的分析，生成最终 Code Review 报告。

## 报告结构

### 1. 总体评价
- **改动规模**：[新增 X 行，删除 Y 行，共涉及 Z 个文件]
- **风险等级**：[High / Medium / Low]
- **建议操作**：[Approve / Request Changes / Approve with Minor Changes]
- **一句话总结**：[用一句话概括本次改动的核心内容和质量]

### 2. 问题汇总

| 级别 | 数量 | 说明 |
|------|------|------|
| Blocker | X | 阻断发布，必须立即修复 |
| Major | X | 必须在合并前修复 |
| Minor | X | 建议修复 |
| Nit | X | 可选优化 |

### 3. 必须修复的问题（Blocker + Major）

[对每个 Blocker 和 Major 问题，使用之前生成的详细格式]

### 4. 建议改进的问题（Minor）

[列表形式，每项包含：位置、问题、简要建议]

### 5. 可选优化建议（Nit）

[精简列表，仅列出要点]

### 6. 正面亮点

[列出改动中做得好的地方，例如：
- 良好的错误处理
- 清晰的命名和注释
- 完善的单元测试覆盖
- 符合项目架构规范
- 性能优化措施]

### 7. 后续建议

[如果有需要后续跟进的事项，例如：
- 补充单元测试（当前覆盖率 X%，建议达到 Y%）
- 更新相关文档
- 后续重构计划
- 性能测试验证
- 安全测试]

---

## 审查元信息
- **审查工具**：AI Code Review
- **审查时间**：[生成时间]
- **审查范围**：[列出检查的维度：代码风格、内存管理、线程安全等]
- **人工复核**：[待人工确认 / 已确认]
```

## 使用示例

### 输入示例

```
我需要对以下 iOS 代码改动进行 Code Review，请先进行风险分级。

## 改动内容
diff --git a/Sources/Network/NetworkManager.swift b/Sources/Network/NetworkManager.swift
index 1234567..abcdefg 100644
--- a/Sources/Network/NetworkManager.swift
+++ b/Sources/Network/NetworkManager.swift
@@ -15,10 +15,15 @@ class NetworkManager {
     
-    func fetchUser(id: String, completion: @escaping (User?) -> Void) {
-        let url = URL(string: "https://api.example.com/users/\(id)")!
-        URLSession.shared.dataTask(with: url) { data, _, _ in
-            guard let data = data else { completion(nil); return }
-            let user = try? JSONDecoder().decode(User.self, from: data)
-            completion(user)
+    func fetchUser(id: String) async throws -> User {
+        let url = URL(string: "https://api.example.com/users/\(id)")!
+        let (data, _) = try await URLSession.shared.data(from: url)
+        return try JSONDecoder().decode(User.self, from: data)
+    }
+    
+    func fetchUserWithCache(id: String) async -> User? {
+        if let cached = cache[id] {
+            return cached
+        }
+        let user = try? await fetchUser(id: id)
+        cache[id] = user
+        return user
     }

## 项目上下文
### 架构信息
- 架构模式：MVVM
- UI 框架：SwiftUI
- 依赖注入：手动注入
- 网络层：URLSession（无第三方库）
- 异步处理：Swift Concurrency (async/await)

### 代码风格约束
- 禁止使用 force unwrap (!)
- UI 更新必须在主线程
- 异步操作优先使用 async/await

[后续对话按模板继续]
```

### 输出示例

```markdown
### 1. 问题数量统计
| 级别 | 数量 |
|------|------|
| Blocker | 1 |
| Major | 2 |
| Minor | 1 |
| Nit | 0 |

### 2. 高优先级问题概览
- [Blocker-1]：NetworkManager.swift::20 - force unwrap 可能导致 crash
- [Major-1]：NetworkManager.swift::28 - 线程安全问题（cache 并发访问）
- [Major-2]：NetworkManager.swift::26 - 缺少错误处理和日志

---

[后续详细分析...]
```

## 注意事项

### 1. 上下文质量决定审查质量
- ✅ 提供完整的 diff 和项目架构信息
- ✅ 明确说明审查重点（如"重点检查内存管理"）
- ❌ 只给代码片段，不提供依赖和上下文

### 2. 分阶段进行，避免信息过载
- ✅ 先风险分级，确认后再详细分析
- ✅ 大型 PR 分模块审查
- ❌ 一次性要求完整报告（容易遗漏）

### 3. 人工复核必不可少
- ✅ AI 报告作为初筛，人工确认问题
- ✅ 补充 AI 无法检测的业务逻辑问题
- ❌ 完全依赖 AI 结果（可能有误报和漏报）

### 4. 根据项目定制提示词
- ✅ 将项目特定约束写入提示词
- ✅ 积累常见误报案例，在提示词中说明
- ❌ 使用通用提示词不做调整

### 5. 持续迭代优化
- ✅ 记录 AI 发现的问题类型
- ✅ 定期回顾误报和漏报
- ✅ 根据反馈更新提示词

## 扩展与定制

### 针对特定技术栈的定制

#### UIKit 项目专项检查
```
额外检查以下 UIKit 特有问题：
1. IBOutlet 是否正确声明为 weak
2. ViewController 生命周期方法是否正确（viewDidLoad/viewWillAppear）
3. 自动布局约束是否可能冲突
4. 是否有 retain cycle（ViewController → View → Closure → ViewController）
```

#### SwiftUI 项目专项检查
```
额外检查以下 SwiftUI 特有问题：
1. @State 是否错误地用于引用类型
2. @ObservedObject 是否应该改用 @StateObject
3. 视图是否过度重绘（使用 Self._printChanges() 验证）
4. 是否有不必要的 AnyView 类型擦除
```

#### Combine 项目专项检查
```
额外检查以下 Combine 特有问题：
1. 订阅是否正确存储到 cancellables
2. 是否在主线程更新 UI（使用 receive(on: DispatchQueue.main)）
3. 是否有操作符使用不当（如 switchToLatest 可能导致请求取消）
```

---

**适用场景**：Pull Request 审查、本地改动自检、团队 Code Review 流程  
**推荐模型**：GPT-4、Claude 3 Opus、Claude Sonnet 3.5  
**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-24
