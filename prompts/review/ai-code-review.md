# AI 代码审查提示词

## 场景说明
对 Swift/iOS 代码进行全面的代码审查，检查内存安全、线程安全、性能、代码规范和 API 兼容性问题。

## 输入要求

### 必需
- 代码变更内容（git diff 或完整文件）
- 项目最低支持 iOS 版本
- 主要技术栈（UIKit/SwiftUI、并发方案）

### 可选
- 团队代码规范文档
- SwiftLint 配置文件
- 已知的架构约定或例外情况

## 提示词模板

```
请对以下 Swift 代码进行全面的代码审查。

## 代码变更
[粘贴 git diff 或具体代码文件]

## 审查重点（iOS/Swift 专项）

### 1. 内存安全
- 检查闭包中的循环引用（self 捕获是否使用 [weak self] 或 [unowned self]）
- Delegate 属性是否声明为 weak
- Timer、NotificationCenter、KVO 观察者是否正确移除
- 异步回调中的对象生命周期管理

### 2. 线程安全
- UI 更新是否在主线程执行（@MainActor 或 DispatchQueue.main）
- 数据竞态：多线程访问可变状态是否有保护机制（锁、Actor、串行队列）
- DispatchQueue 嵌套调用是否可能导致死锁
- Actor 隔离检查（Sendable 协议、跨 Actor 调用）

### 3. 性能问题
- 主线程是否有耗时操作（同步网络请求、文件 I/O、大数据处理、复杂计算）
- 视图层是否有不必要的重绘（TableView/CollectionView 优化）
- 是否有 N+1 查询问题（数据库、网络请求）
- 集合操作效率（避免 O(n²) 嵌套循环，使用 Set/Dictionary 优化查找）
- 图片加载是否有缓存机制

### 4. API 使用
- 是否使用了已废弃的 API（标记为 deprecated）
- iOS 版本兼容性检查（@available 使用是否正确）
- 系统 API 错误处理是否完善
- 是否正确使用可选 API（如蓝牙、定位需要检查可用性）

### 5. Swift 代码规范
- 命名是否清晰（避免缩写、使用描述性名称）
- Optional 处理是否合理：
  - 避免强制解包（!）除非有明确理由
  - 优先使用 if let / guard let
  - 合理使用 ?? 提供默认值
- 错误处理：
  - try? vs try vs try! 的使用是否恰当
  - 自定义 Error 类型是否清晰
- 访问控制：
  - public/internal/private/fileprivate 是否合理
  - 不应暴露的实现细节是否被保护
- 类型设计：
  - 是否合理使用 struct vs class
  - 协议是否提取恰当（避免过度设计）

### 6. SwiftUI 特定（如适用）
- 属性包装器使用是否正确：
  - @State 用于视图内部状态
  - @Binding 用于父子视图通信
  - @ObservedObject/@StateObject 生命周期管理
  - @EnvironmentObject 依赖注入
- 视图拆分是否合理（避免单个视图超过 200 行）
- 重复计算是否避免（使用 @State 缓存计算结果）
- PreferenceKey/EnvironmentValue 是否必要（避免过度使用）

### 7. UIKit 特定（如适用）
- ViewController 生命周期方法使用是否正确：
  - viewDidLoad vs viewWillAppear 的选择
  - 资源释放是否在 deinit 中处理
- AutoLayout 约束：
  - 是否可能产生冲突或歧义
  - 优先级设置是否合理
- 内存警告处理（didReceiveMemoryWarning）
- 导航栈管理（避免内存泄漏）

### 8. 其他重要检查点
- 硬编码问题：
  - 魔法数字是否提取为常量
  - 字符串是否本地化（NSLocalizedString）
- 日志和调试代码：
  - print 语句是否应该移除
  - 调试断点、强制崩溃是否残留
- 注释质量：
  - 复杂逻辑是否有注释说明
  - 注释是否与代码一致（避免过时注释）
- 单元测试：
  - 新增代码是否有对应测试
  - 关键逻辑是否可测试（避免过多副作用）

## 输出格式
按以下结构输出审查结果：

### 🔴 严重问题（必须修复）
列出可能导致崩溃、内存泄漏、数据损坏、安全漏洞的问题。每项包含：
- **[文件名:行号]** 问题描述
- **原因**：为什么这是严重问题
- **修复建议**：具体代码示例
- **风险等级**：崩溃/内存泄漏/数据安全

示例：
- **[UserManager.swift:45]** 循环引用导致内存泄漏
  - **原因**：闭包强引用 self，而 self 持有闭包
  - **修复**：使用 `[weak self] in` 捕获列表
  - **风险**：内存泄漏，长期运行导致 OOM

### 🟡 改进建议（建议修复）
列出影响代码质量、可维护性、性能的问题，但不会立即导致故障。每项包含：
- **[文件名:行号]** 问题描述
- **影响**：对代码质量/性能的影响
- **优化方案**：具体建议（可选代码示例）
- **优先级**：高/中/低

### 🟢 优秀实践（值得保留）
列出代码中做得好的地方，包括：
- 良好的命名
- 合理的架构设计
- 正确的错误处理
- 清晰的注释

### 💡 学习建议（针对代码作者）
如果代码显示出某些模式性问题，提供学习建议：
- 推荐阅读的文档或文章
- 需要强化的知识点
- 团队内可参考的示例代码

### 📊 代码质量评分
给出 0-10 分的评分，并简要说明：
- **内存安全**：X/10 - [简述]
- **线程安全**：X/10 - [简述]
- **性能**：X/10 - [简述]
- **可维护性**：X/10 - [简述]
- **代码规范**：X/10 - [简述]
- **综合评分**：X/10

评分标准：
- 9-10 分：优秀，可作为团队范例
- 7-8 分：良好，有少量改进空间
- 5-6 分：及格，需要修复多个问题
- 3-4 分：较差，存在明显缺陷
- 0-2 分：严重问题，需要重构

## 项目上下文
[粘贴 review-context.md 内容，包含：]
- 项目最低支持 iOS 版本
- 技术栈（UIKit/SwiftUI、Combine/RxSwift、async/await）
- 架构模式（MVVM/MVI/VIPER）
- 团队代码规范
- 已知的架构例外或历史包袱
- 本次 PR 的背景和目标
```

## 使用示例

### 输入

```swift
// UserViewModel.swift
class UserViewModel {
    var onUpdate: (() -> Void)?
    let userService: UserService
    
    init(userService: UserService) {
        self.userService = userService
    }
    
    func loadUser() {
        userService.fetchUser { user in
            self.updateUI(with: user)
            self.onUpdate?()
        }
    }
    
    func updateUI(with user: User) {
        // 更新 UI
        let label = UILabel()
        label.text = user.name
    }
}
```

**项目上下文：**
- 最低支持：iOS 14.0
- 技术栈：UIKit + Combine
- 架构：MVVM

### AI 输出

```markdown
## 代码审查结果

### 🔴 严重问题（必须修复）

1. **[UserViewModel.swift:10]** 潜在的循环引用
   - **原因**：闭包捕获了 self，如果 userService 持有此闭包，会形成循环引用
   - **修复**：
     ```swift
     func loadUser() {
         userService.fetchUser { [weak self] user in
             self?.updateUI(with: user)
             self?.onUpdate?()
         }
     }
     ```
   - **风险**：内存泄漏

2. **[UserViewModel.swift:15]** 在非 UI 类中直接操作 UIKit
   - **原因**：ViewModel 不应依赖 UIKit，违反 MVVM 分层
   - **修复**：
     ```swift
     // 在 ViewModel 中只处理数据
     var userName: String = ""
     
     func loadUser() {
         userService.fetchUser { [weak self] user in
             self?.userName = user.name
             self?.onUpdate?()
         }
     }
     
     // 在 ViewController 中绑定 UI
     viewModel.onUpdate = { [weak self] in
         self?.nameLabel.text = self?.viewModel.userName
     }
     ```
   - **风险**：架构混乱，难以测试

3. **[UserViewModel.swift:15]** UI 更新可能不在主线程
   - **原因**：fetchUser 回调的线程不确定，直接操作 UI 可能崩溃
   - **修复**：
     ```swift
     func loadUser() {
         userService.fetchUser { [weak self] user in
             DispatchQueue.main.async {
                 self?.userName = user.name
                 self?.onUpdate?()
             }
         }
     }
     ```
   - **风险**：UI 线程违规崩溃

### 🟡 改进建议（建议修复）

1. **[UserViewModel.swift:2]** 使用闭包回调而非 Combine（优先级：中）
   - **影响**：项目已使用 Combine，这里用闭包不统一
   - **优化**：
     ```swift
     import Combine
     
     class UserViewModel {
         @Published var userName: String = ""
         let userService: UserService
         private var cancellables = Set<AnyCancellable>()
         
         func loadUser() {
             userService.fetchUserPublisher()
                 .map { $0.name }
                 .replaceError(with: "")
                 .assign(to: &$userName)
         }
     }
     ```

2. **[UserViewModel.swift:1]** 缺少访问控制（优先级：低）
   - **影响**：类和属性默认 internal，可能暴露不必要的实现
   - **优化**：
     ```swift
     public class UserViewModel {
         public var onUpdate: (() -> Void)?
         private let userService: UserService
         
         public init(userService: UserService) { ... }
     }
     ```

### 🟢 优秀实践

1. **[UserViewModel.swift:4]** 使用依赖注入
   - 通过构造器注入 userService，便于测试和解耦

### 💡 学习建议

1. **内存管理**：建议复习 Swift 的 ARC 和闭包捕获列表
   - [官方文档：Automatic Reference Counting](https://docs.swift.org/swift-book/LanguageGuide/AutomaticReferenceCounting.html)

2. **MVVM 架构**：ViewModel 应避免直接依赖 UIKit
   - 参考项目中的 ProductViewModel 实现

3. **Combine 框架**：建议统一使用 Combine 替代闭包回调
   - [Hacking with Swift: Combine](https://www.hackingwithswift.com/quick-start/combine)

### 📊 代码质量评分

- **内存安全**：4/10 - 存在循环引用风险
- **线程安全**：3/10 - UI 更新未保证主线程
- **性能**：7/10 - 无明显性能问题
- **可维护性**：5/10 - 架构分层不清晰
- **代码规范**：6/10 - 缺少访问控制，命名尚可
- **综合评分**：5/10

**总结**：代码存在内存和线程安全的严重问题，需要修复后才能合并。架构上建议统一使用 Combine 并明确 ViewModel 职责。
```

## 注意事项

### ✅ 好的做法
- 提供完整的代码上下文（包括依赖的类型定义）
- 明确项目的最低支持 iOS 版本
- 说明团队的特殊约定或已知例外
- 对于大型 PR，分多次审查不同模块

### ❌ 避免的做法
- 只粘贴代码片段，缺少上下文
- 不说明项目技术栈，导致 AI 建议不适用的方案
- 一次性审查超过 1000 行代码（容易遗漏问题）
- 盲目接受 AI 建议，不经过人工判断

### 🔧 常见调整

如果 AI 的审查结果不符合预期，可以追加指令：

```
请补充以下检查：
1. 重点审查 NetworkManager.swift 中的线程安全问题
2. 检查所有 DispatchQueue 的使用是否合理
3. 标注所有需要添加 @available 检查的 API

请调整审查标准：
1. 对于单例模式，不需要标记为问题（团队约定）
2. 强制解包在测试代码中是允许的
3. 提高内存安全的检查优先级
```

## 高级用法

### 场景一：针对性能敏感模块的深度审查

在提示词中添加：
```
本次 PR 涉及性能关键路径（首页启动、滑动列表），请重点审查：
1. 主线程耗时操作（目标：启动时间 < 500ms）
2. 内存分配（避免频繁创建大对象）
3. TableView/CollectionView 优化（复用、预加载）
4. 图片处理效率（解码、缓存）

提供性能优化建议时，请包含：
- 预期的性能提升（定量）
- 实现成本（代码改动量）
- 可能的风险
```

### 场景二：安全审计模式

```
请以安全审计的角度审查代码，重点关注：
1. 用户输入验证（SQL 注入、XSS）
2. 敏感数据处理（密码、token 是否正确存储）
3. 加密使用（是否使用过时算法）
4. 网络通信（是否强制 HTTPS、证书验证）
5. 权限检查（相机、定位等权限的请求和使用）

对于每个安全问题，标注：
- 漏洞类型（如：信息泄露、权限绕过）
- CVSS 评分（如适用）
- 修复优先级（P0/P1/P2）
```

### 场景三：新人代码的教学式审查

```
这是团队新人的代码，请以教学的方式审查：
1. 对于问题，不仅指出错误，还要解释原因
2. 提供正反示例对比
3. 推荐学习资源（文档、文章）
4. 指出可以参考的团队内优秀代码

语气保持鼓励和建设性，强调优点的同时指出改进方向。
```

### 场景四：持续集成的简洁输出

```
输出格式要求（用于 CI 评论）：
1. 只输出严重问题和改进建议，省略优秀实践
2. 每个问题用一行简述，点击展开查看详情
3. 如果无严重问题，输出：✅ AI Review 通过，无阻塞性问题
4. 使用 Markdown collapsible section：
   <details>
   <summary>🔴 严重问题 (3)</summary>
   [详细内容]
   </details>
```

## 相关资源

- [工作流：使用 AI 进行代码 Review](../../workflows/ai-code-review.md)
- [工作流：为 Swift 模块补充单元测试](../../workflows/unit-test-generation.md)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SwiftLint 规则参考](https://realm.github.io/SwiftLint/rule-directory.html)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-25  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
