# AI 代码 Review 提示词

## 场景说明
使用 AI 对 Swift/iOS 代码变更进行系统化审查，覆盖风险扫描、代码风格、架构一致性和最佳实践检查。

## 输入要求

### 必需
- Git diff 或完整变更文件
- 项目使用的架构模式（MVVM、MVI、VIPER 等）
- 代码风格规范（SwiftLint 配置或团队约定）

### 可选
- 相关模块的上下文代码
- PR 描述或需求背景
- 历史 Review 意见作为参考

## 提示词模板

### 模板一：Swift PR 风险扫描（快速检查）

```
我需要对以下 Swift 代码变更进行风险扫描。

## 变更内容
[粘贴 git diff 或文件内容]

## 项目上下文
- 架构模式：[MVVM/MVI/VIPER/其他]
- 最低支持版本：iOS [版本]
- 使用的主要框架：[UIKit/SwiftUI/Combine/Async-Await]

## Review 重点
请按以下优先级检查：

### P0 - 阻断问题（必须修复才能合并）
1. **内存安全**：循环引用、隐式强制解包导致的潜在崩溃
2. **线程安全**：主线程阻塞、UI 更新未在主线程、数据竞争
3. **API 兼容性**：使用了不支持的最低版本 API
4. **安全漏洞**：硬编码敏感信息、SQL 注入、不安全的网络请求

### P1 - 高风险问题（强烈建议修复）
1. **架构违背**：绕过 ViewModel 直接修改 Model、职责不清
2. **性能隐患**：主线程执行耗时操作、内存泄漏风险、大量对象创建
3. **测试缺失**：关键业务逻辑无单元测试覆盖

### P2 - 优化建议（可延后）
1. **代码风格**：命名不符合 Swift API 设计规范、可读性问题
2. **最佳实践**：可用更简洁的 Swift 语法、代码重复

## 输出格式
按以下 Markdown 格式输出：

### 🚨 P0 - 阻断问题
- **文件:行号** - [问题类型] 问题描述
  - 风险：[说明后果]
  - 建议：[具体修复方案]

### ⚠️ P1 - 高风险问题
- **文件:行号** - [问题类型] 问题描述
  - 影响：[说明影响范围]
  - 建议：[修复建议]

### 💡 P2 - 优化建议
- **文件:行号** - [问题类型] 建议内容
  - 优化：[改进方向]

### ✅ 正向反馈
- [列出做得好的地方，如良好的错误处理、清晰的命名等]
```

### 模板二：逐文件详细 Review（深度审查）

```
我需要对以下 Swift 文件进行详细代码审查。

## 文件内容
[粘贴完整文件内容]

## 审查上下文
- 这个类的职责：[ViewController/ViewModel/Service/Manager/其他]
- 依赖的协议：[列出关键协议]
- 修改原因：[需求背景或 PR 描述]

## Review 维度

### 1. 架构与职责
- 类的职责是否单一？是否符合 SRP 原则？
- 依赖注入是否合理？是否过度依赖单例？
- 是否有违背项目架构模式的地方？

### 2. Swift 最佳实践
- 命名是否符合 [Swift API 设计指南](https://swift.org/documentation/api-design-guidelines/)？
- 是否充分利用了 Swift 语言特性（optional、enum、pattern matching）？
- 错误处理是否合理（Result、throws、optional）？

### 3. 内存与性能
- 是否有循环引用风险？闭包是否正确使用 [weak self]？
- 是否有不必要的对象复制或内存分配？
- 异步操作是否合理使用 Dispatch/Combine/Async-Await？

### 4. 可测试性
- 是否方便编写单元测试？依赖是否可 Mock？
- 是否有副作用（访问全局状态、文件系统、网络）？

### 5. 可维护性
- 代码是否易读？复杂逻辑是否有注释？
- 是否有魔法数字或硬编码字符串？
- 是否有重复代码可以提取？

## 输出格式
请按文件结构逐段审查，格式如下：

### 第 [行号范围]：[代码段描述]
**问题/建议**：
- [具体问题或建议]

**严重程度**：P0/P1/P2

**改进代码**（如适用）：
\`\`\`swift
[给出改进后的代码片段]
\`\`\`

**解释**：
[说明为什么这样改进]
```

### 模板三：针对 SwiftUI 的专项 Review

```
我需要审查以下 SwiftUI 视图代码。

## 视图代码
[粘贴 SwiftUI View 代码]

## SwiftUI 专项检查点

### 1. 状态管理
- @State/@Binding/@ObservedObject/@StateObject/@EnvironmentObject 使用是否正确？
- 是否有不必要的状态提升？
- 状态变化是否会触发过多的 body 重新计算？

### 2. 性能优化
- 是否有耗时操作在 body 中执行？
- 是否需要添加 EquatableView 优化？
- List/ScrollView 是否使用了懒加载？

### 3. 代码组织
- body 是否过于复杂（超过 10 层嵌套）？
- 是否应该拆分为子视图或使用 @ViewBuilder？
- 视图逻辑是否应该抽取到 ViewModel？

### 4. 可访问性
- 是否添加了 .accessibilityLabel 和 .accessibilityHint？
- 动态字体是否支持？
- VoiceOver 体验是否良好？

### 5. SwiftUI 最佳实践
- 是否使用了过时的 API（如 onAppear 代替 task）？
- 是否利用了 iOS 新版本的 SwiftUI 特性？
- 预览是否完善（多种状态、暗黑模式、不同尺寸）？

## 输出要求
列出问题和建议，包括改进后的代码示例。
```

## 使用示例

### 场景一：PR 提交前的自检

**输入**（使用模板一）：

```
我需要对以下 Swift 代码变更进行风险扫描。

## 变更内容
diff --git a/Sources/Features/Profile/ProfileViewModel.swift b/Sources/Features/Profile/ProfileViewModel.swift
@@ -15,7 +15,9 @@ class ProfileViewModel: ObservableObject {
     func fetchUserProfile() {
-        networkService.fetchProfile { result in
+        networkService.fetchProfile { [weak self] result in
+            guard let self = self else { return }
             DispatchQueue.main.async {
                 self.profile = result
             }

## 项目上下文
- 架构模式：MVVM
- 最低支持版本：iOS 15.0
- 使用的主要框架：SwiftUI + Combine
```

**AI 输出示例**：

```
### ✅ 正向反馈
- **ProfileViewModel.swift:17** - 正确使用了 [weak self] 避免循环引用
- **ProfileViewModel.swift:19** - 正确在主线程更新 UI 状态

### 💡 P2 - 优化建议
- **ProfileViewModel.swift:15-21** - [现代化建议] 可考虑使用 async/await 替代闭包回调
  - 优化：使用 Swift Concurrency 简化异步代码，更易读且自动处理线程切换
  
  改进代码：
  ```swift
  func fetchUserProfile() async {
      do {
          self.profile = try await networkService.fetchProfile()
      } catch {
          self.error = error
      }
  }
  ```
```

### 场景二：新人代码的详细审查

**输入**（使用模板二）：

```
我需要对以下 Swift 文件进行详细代码审查。

## 文件内容
class UserManager {
    static let shared = UserManager()
    
    var currentUser: User?
    
    func login(username: String, password: String) {
        let url = "https://api.example.com/login"
        // ... 网络请求逻辑
        URLSession.shared.dataTask(with: URL(string: url)!) { data, response, error in
            let user = try! JSONDecoder().decode(User.self, from: data!)
            self.currentUser = user
            NotificationCenter.default.post(name: NSNotification.Name("UserLoggedIn"), object: nil)
        }.resume()
    }
}

## 审查上下文
- 这个类的职责：用户认证和会话管理
- 修改原因：新功能 - 用户登录
```

**AI 输出示例**：

```
### 第 2-4 行：单例实现
**问题**：
- 使用单例模式导致全局状态，不利于测试
- 单例无法注入依赖，违背依赖倒置原则

**严重程度**：P1

**建议**：
1. 将 UserManager 改为普通类，通过依赖注入使用
2. 如确需全局访问，使用 Environment 或依赖容器

**改进代码**：
```swift
// 定义协议便于 Mock
protocol UserManaging {
    func login(username: String, password: String) async throws -> User
}

class UserManager: UserManaging {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    // ...
}
```

### 第 6-15 行：login 方法
**问题**：
1. **P0** - 强制解包 `URL(string: url)!` 和 `data!` 会导致崩溃
2. **P0** - `try!` 强制解包错误，JSON 解析失败会崩溃
3. **P0** - 硬编码 URL，存在安全和可维护性问题
4. **P1** - 未在主线程更新 currentUser，可能导致 UI 异常
5. **P1** - 使用字符串通知名称，易出错且不类型安全
6. **P1** - 直接使用 URLSession，未抽象网络层，难以测试

**改进代码**：
```swift
func login(username: String, password: String) async throws -> User {
    guard let url = URL(string: APIEndpoints.login) else {
        throw AuthError.invalidURL
    }
    
    let (data, response) = try await networkService.request(url: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw AuthError.serverError
    }
    
    let user = try JSONDecoder().decode(User.self, from: data)
    
    await MainActor.run {
        self.currentUser = user
        NotificationCenter.default.post(name: .userLoggedIn, object: user)
    }
    
    return user
}
```

**解释**：
- 使用 async/await 简化异步代码
- 所有可能失败的操作都用 guard 或 try 正确处理
- 使用类型安全的通知名称（extension Notification.Name）
- 抽象网络层，方便测试和替换实现
```

## 注意事项

### ✅ 好的做法
- **提供完整上下文**：粘贴完整的 diff 或文件内容，不要只粘贴片段
- **说明修改背景**：告诉 AI 为什么改这段代码，帮助判断是否过度设计
- **分阶段审查**：先用模板一快速扫描 P0 问题，再用模板二深度审查
- **结合自动化工具**：SwiftLint、SwiftFormat 能发现的问题让工具处理，AI 关注业务逻辑和架构

### ❌ 避免的做法
- **过度依赖 AI**：安全漏洞、性能问题需要人工最终确认
- **忽略项目背景**：不同项目的架构约定不同，AI 的建议需要结合实际情况
- **批量修改**：一次提交包含多个不相关模块，AI 难以给出准确建议
- **盲目接受所有建议**：P2 级别的优化建议需要权衡投入产出比

### 🔧 常见调整

如果 AI 给出的建议不合适，可以追加指令：

```
请重新审查，调整以下内容：
1. 忽略代码风格问题，只关注内存安全和架构一致性
2. 针对第 45-60 行的循环，提供更详细的性能分析
3. 建议中的 async/await 改写不适用（项目需支持 iOS 13），请用 Combine 或 Completion 方案
```

## 高级用法

### 场景一：与 GitHub PR 集成

在 PR 描述中要求 AI Review：

```markdown
## AI Review Checklist
<!-- 复制以下内容到 Claude/Cursor，粘贴本 PR 的 Files Changed diff -->

使用 [AI 代码 Review 提示词](prompts/review/ai-code-review.md) 的模板一进行风险扫描。

关注点：
- [ ] 本次改动涉及网络层重构，检查错误处理是否完善
- [ ] 新增的 ViewModel 是否符合 MVVM 架构
- [ ] 是否有循环引用风险
```

### 场景二：针对特定风险的专项审查

```
仅检查以下代码的线程安全问题：

[粘贴代码]

要求：
1. 列出所有可能的数据竞争场景
2. 检查所有 UI 更新是否在主线程
3. 检查是否有未保护的共享状态访问
4. 给出线程安全的改进方案
```

### 场景三：遗留代码的重构前评估

```
我计划重构以下类，请先评估改动风险：

[粘贴旧代码]

评估要点：
1. 这个类被多少其他类依赖？（从代码结构推测）
2. 重构为 MVVM 模式的难度和风险
3. 是否需要先补充单元测试再重构？
4. 给出分步重构计划，最小化每次改动的风险
```

## 相关资源

- [工作流：使用 AI 进行代码 Review](../../workflows/ai-code-review.md)
- [Swift API 设计指南](https://swift.org/documentation/api-design-guidelines/)
- [工作流：为 Swift 模块补充单元测试](../../workflows/unit-test-generation.md)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-26  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
