# 循环引用审计提示词

## 场景说明
为 Xcode Instruments Leaks 检测到的内存泄漏提供根因分析和修复方案，重点识别强引用循环（Retain Cycle）。

## 输入要求

### 必需
- Instruments Leaks 导出的泄漏对象数据
- 泄漏对象的类名和内存地址
- 相关类的源代码（至少包含初始化和属性声明）

### 可选
- Cycles & Roots 引用链路数据
- Memory Graph 截图
- 项目架构说明（MVVM、Coordinator 等）

## 提示词模板

```
我需要审计 iOS 应用的内存泄漏问题，识别循环引用并提供修复方案。

## 泄漏数据
[粘贴 Instruments Leaks 导出的数据，格式示例：]
```
Leaked Objects:
1. ProfileViewController (0x1a2b3c4d5) - 1 instance, 4.2 KB
   Retains: UserViewModel (0x2b3c4d5e6)
   
2. UserViewModel (0x2b3c4d5e6) - 1 instance, 2.1 KB
   Retains: ProfileViewController (0x1a2b3c4d5) via closure
   
3. NetworkService (0x3c4d5e6f7) - 5 instances, 15.3 KB
   Retains: APIClient (0x4d5e6f7g8)
```

## 相关代码
[粘贴泄漏对象的类代码，示例：]
```swift
class ProfileViewController: UIViewController {
    let viewModel: UserViewModel
    
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        viewModel.onUpdate = {
            self.updateUI()  // 可能的强引用
        }
    }
    
    func updateUI() {
        // ...
    }
}

class UserViewModel {
    var onUpdate: (() -> Void)?
    
    func fetchUser() {
        // ...
    }
}
```

## 架构说明（可选）
- 架构模式：MVVM
- ViewController 持有 ViewModel（强引用）
- ViewModel 通过 closure 回调 ViewController

## 审计要求

### 1. 循环引用识别
对于每个泄漏对象，识别引用链路：
- 绘制引用关系图（A → B → C → A）
- 标记强引用（实线）和弱引用（虚线）
- 定位形成循环的关键引用

### 2. 泄漏类型分类
判断泄漏属于以下哪一类：
- **Closure 强捕获**：闭包中使用 `self` 未标记 `[weak self]` 或 `[unowned self]`
- **Delegate 强引用**：delegate 属性未声明为 `weak`
- **定时器未销毁**：Timer、CADisplayLink 强引用 target 且未 invalidate
- **通知未移除**：NotificationCenter 观察者未移除（iOS 9+ 自动移除，但自定义通知中心可能有问题）
- **KVO 未注销**：addObserver 后未 removeObserver
- **Block 循环**：Objective-C block 强捕获 self

### 3. 修复方案
对于每个泄漏，提供：
- **根因分析**：一句话说明为什么形成循环
- **引用链路图**：可视化展示循环路径
- **修复代码**：包含"问题代码"和"修复后代码"对比
- **修复方式选择**：
  - `[weak self]`：self 可能在闭包执行前释放
  - `[unowned self]`：确定 self 不会在闭包执行前释放（慎用）
  - 显式销毁：timer.invalidate()、NotificationCenter.removeObserver()
- **验证方法**：如何确认修复生效（deinit 日志、Instruments Leaks 复测）

### 4. 优先级评估
- **P0 必须修复**：每次进入页面都泄漏，累积占用大量内存
- **P1 建议修复**：特定场景泄漏，影响有限但应修复
- **P2 可延后**：小对象泄漏（< 1KB）且触发频率低

## 输出格式

请按以下格式输出：

### 🚨 循环引用 #1：[对象A] ↔ [对象B]

**泄漏对象**：[类名] ([内存地址])  
**泄漏大小**：[单个实例大小] × [泄漏次数] = [总大小]  
**泄漏类型**：[Closure 强捕获 / Delegate 强引用 / 定时器未销毁 / ...]  
**优先级**：[P0 / P1 / P2]

**引用链路**：
```
[对象A] (强引用)
  └─ [属性/闭包]: [对象B] (强引用)
      └─ [属性/闭包]: [对象A] ← 循环！
```

**根因分析**：
[一句话说明问题]

**问题代码**：
```swift
// ❌ 当前实现
[粘贴问题代码]
```

**修复方案**：
```swift
// ✅ 修复方式 1：使用 [weak self]
[粘贴修复代码]

// ✅ 修复方式 2：使用 Combine（如适用）
[粘贴基于 Combine 的方案]
```

**修复方式选择建议**：
- 推荐使用 [weak self / unowned self / 显式销毁]
- 原因：[说明为什么推荐这种方式]

**验证方法**：
1. 在 deinit 中添加日志：`print("✅ \(Self.self) deinitialized")`
2. [具体验证步骤]
3. 使用 Instruments Leaks 复测，确认泄漏对象数量为 0

---

### 🚨 循环引用 #2：...

[同上格式]

---

## 审计总结

**泄漏统计**：
- 总泄漏对象数：[N] 个
- 总泄漏内存：[X] MB
- P0 级别：[N1] 个
- P1 级别：[N2] 个

**修复优先级**：
1. [泄漏对象名] - 每次触发泄漏 [X] KB，优先级最高
2. [泄漏对象名] - 累积泄漏 [Y] MB，建议尽快修复
...

**批量修复建议**：
[如果多个泄漏是同一类型，给出统一的修复规范]
```

## 使用示例

### 输入

```
我需要审计 iOS 应用的内存泄漏问题，识别循环引用并提供修复方案。

## 泄漏数据
Leaked Objects:
1. ProfileViewController (0x1a2b3c4d5) - 1 instance, 4.2 KB
   Retains: UserViewModel (0x2b3c4d5e6)
   
2. UserViewModel (0x2b3c4d5e6) - 1 instance, 2.1 KB
   Retains: ProfileViewController (0x1a2b3c4d5) via closure 'onUpdate'

## 相关代码
class ProfileViewController: UIViewController {
    let viewModel: UserViewModel
    
    init(viewModel: UserViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()
    }
    
    private func setupBindings() {
        viewModel.onUpdate = {
            self.updateUI()  // 强捕获 self
        }
    }
    
    func updateUI() {
        titleLabel.text = viewModel.userName
    }
}

class UserViewModel {
    var onUpdate: (() -> Void)?
    var userName: String = ""
    
    func fetchUser() {
        // 模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.userName = "John Doe"
            self.onUpdate?()  // 触发回调
        }
    }
}

## 架构说明
- 架构模式：MVVM
- ViewController 持有 ViewModel（强引用）
- ViewModel 通过 closure 回调 ViewController 更新 UI

## 审计要求
[使用上述完整要求]
```

### AI 输出

```markdown
### 🚨 循环引用 #1：ProfileViewController ↔ UserViewModel

**泄漏对象**：ProfileViewController (0x1a2b3c4d5)  
**泄漏大小**：4.2 KB × 1 = 4.2 KB（每次进入页面都泄漏）  
**泄漏类型**：Closure 强捕获  
**优先级**：P0（必须修复）

**引用链路**：
```
ProfileViewController (强引用)
  └─ viewModel: UserViewModel (强引用)
      └─ onUpdate: () -> Void (closure 强捕获)
          └─ self (ProfileViewController) ← 循环！
```

**根因分析**：
`setupBindings()` 中的闭包 `viewModel.onUpdate = { self.updateUI() }` 强捕获了 `self`（ProfileViewController），而 ProfileViewController 又强引用 `viewModel`，形成循环。

**问题代码**：
```swift
// ❌ 当前实现
private func setupBindings() {
    viewModel.onUpdate = {
        self.updateUI()  // 强捕获 self，导致循环引用
    }
}
```

**修复方案**：
```swift
// ✅ 修复方式 1：使用 [weak self]（推荐）
private func setupBindings() {
    viewModel.onUpdate = { [weak self] in
        self?.updateUI()
    }
}

// ✅ 修复方式 2：使用 [unowned self]（仅当确定 self 不会提前释放）
private func setupBindings() {
    viewModel.onUpdate = { [unowned self] in
        self.updateUI()
    }
}

// ✅ 修复方式 3：使用 Combine 替代闭包（现代化方案）
import Combine

class ProfileViewController: UIViewController {
    let viewModel: UserViewModel
    private var cancellables = Set<AnyCancellable>()
    
    private func setupBindings() {
        viewModel.$userName  // 假设 userName 是 @Published
            .sink { [weak self] userName in
                self?.updateUI()
            }
            .store(in: &cancellables)
    }
    
    // Combine 订阅会在 ViewController 释放时自动取消
}

// 对应的 ViewModel 改动（使用 Combine）
class UserViewModel {
    @Published var userName: String = ""
    
    func fetchUser() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.userName = "John Doe"
            // 不再需要手动触发 onUpdate，@Published 自动通知
        }
    }
}
```

**修复方式选择建议**：
- **推荐使用 `[weak self]`**（方式 1）
- **原因**：
  1. ✅ 安全：即使 ViewController 提前释放，闭包也不会崩溃（可选链自动处理 nil）
  2. ✅ 通用：适用于所有场景
  3. ✅ 代码改动小：仅需添加 `[weak self]` 和 `?`
- **不推荐 `[unowned self]`**（方式 2）：
  - ⚠️ 风险：如果 ViewController 在闭包执行前释放，会崩溃
  - 仅在"确定 self 生命周期长于闭包"时使用（如 viewDidLoad 中的同步闭包）
- **可选：Combine**（方式 3）：
  - ✅ 现代化：自动管理订阅生命周期
  - ✅ 声明式：代码更清晰
  - ⚠️ 改动较大：需要引入 Combine，ViewModel 改为 @Published

**验证方法**：
1. 在 `ProfileViewController` 的 `deinit` 中添加日志：
   ```swift
   deinit {
       print("✅ ProfileViewController deinitialized")
   }
   ```
2. 运行应用，进入 ProfileViewController → 返回上一页
3. 检查控制台是否打印 `✅ ProfileViewController deinitialized`
4. 如果打印了，说明对象正常释放；如果没打印，泄漏仍存在
5. 使用 Instruments Leaks 再次运行测试场景（进入-退出 10 次），确认 Leaked Objects 列表为空

---

## 审计总结

**泄漏统计**：
- 总泄漏对象数：2 个（ProfileViewController + UserViewModel）
- 总泄漏内存：6.3 KB（单次）
- 累积影响：如果用户反复进入该页面 100 次，泄漏 630 KB
- P0 级别：1 个（ProfileViewController）

**修复优先级**：
1. **ProfileViewController 循环引用** - 优先级最高
   - 原因：每次进入页面都泄漏，用户高频操作（如查看个人资料）
   - 改动成本：极低（添加 `[weak self]`）
   - 收益：彻底解决泄漏，内存占用下降 6.3 KB / 次

**批量修复建议**：
如果项目中有多个类似的 ViewModel + ViewController 组合，建议统一规范：
1. **所有 ViewController → ViewModel 的闭包回调都使用 `[weak self]`**
2. **或统一迁移到 Combine**（长期方案，需要团队培训）
3. **Code Review 检查清单**：
   - [ ] 所有闭包中访问 `self` 是否标记了 `[weak self]`？
   - [ ] Delegate 属性是否声明为 `weak`？
   - [ ] Timer/CADisplayLink 是否在 `deinit` 中 invalidate？

**团队规范建议**：
在项目的 SwiftLint 配置中添加规则，强制闭包中使用 `[weak self]`：
```yaml
# .swiftlint.yml
custom_rules:
  closure_capture_self:
    name: "Closure Capture Self"
    regex: '(?<!weak\s)(?<!unowned\s)self\.'
    match_kinds: identifier
    message: "使用 [weak self] 或 [unowned self] 避免循环引用"
    severity: warning
```
```

## 注意事项

### ✅ 好的做法
- 提供完整的引用链路数据（Cycles & Roots）
- 粘贴泄漏对象的完整类代码（AI 才能准确定位问题）
- 说明架构模式（MVVM、Coordinator 等，帮助 AI 理解引用关系）
- 要求多种修复方案（对比 [weak self]、Combine、显式销毁）

### ❌ 避免的做法
- 只给泄漏对象名不给代码（AI 无法分析根因）
- 混合多个无关的泄漏（每次询问聚焦 1-2 个泄漏）
- 盲目使用 `[unowned self]`（可能导致崩溃）
- 忽略验证步骤（修复后不检查 deinit）

### 🔧 常见调整

如果 AI 输出不符合预期，追加指令：

```
请调整以下内容：
1. 对于修复方案，我只想要 [weak self] 方式，不需要 Combine
2. 补充说明：如果使用 [unowned self]，什么情况下会崩溃
3. 生成完整的测试代码：验证 deinit 是否被调用
4. 添加 Memory Graph 解读：如何从 Xcode Memory Graph 中确认循环引用
```

## 高级用法

### 场景一：分析复杂的多层循环引用

```
[粘贴复杂的引用链路]

这是一个三层循环引用：
A → B → C → A

请：
1. 绘制完整的引用关系图
2. 分析哪些引用必须是强引用（不能改为 weak）
3. 给出最小改动方案（只打破一个环节）
```

### 场景二：从 Memory Graph 截图分析

```
[上传 Xcode Memory Graph 截图]

请分析这个 Memory Graph：
1. 识别所有的循环引用路径
2. 找出泄漏的根对象（root object）
3. 给出修复建议
```

### 场景三：生成自动化检测代码

```
请生成一个 XCTest 单元测试，自动检测 ProfileViewController 是否泄漏：

要求：
1. 使用 XCTestExpectation 监听 deinit
2. 如果 5 秒内 deinit 未调用，测试失败
3. 可以在 CI 中自动运行
```

**示例输出**：
```swift
import XCTest
@testable import YourApp

final class ProfileViewControllerLeakTests: XCTestCase {
    func test_profileViewController_shouldDeinitWhenPopped() {
        // Given
        let expectation = expectation(description: "ViewController should deinit")
        let viewModel = UserViewModel()
        
        var viewController: ProfileViewController? = ProfileViewController(viewModel: viewModel)
        
        // 监听 deinit（通过弱引用）
        weak var weakVC = viewController
        
        // When: 模拟 pop（释放引用）
        viewController = nil
        
        // Then: 等待 deinit
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if weakVC == nil {
                expectation.fulfill()  // deinit 成功调用
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
```

### 场景四：审计第三方库的泄漏

```
我使用了第三方库 XYZFramework，Instruments 显示它的对象泄漏。

## 泄漏对象
XYZManager (第三方库的类)

## 我的代码
class MyViewController: UIViewController {
    let xyzManager = XYZManager()
    
    override func viewDidLoad() {
        xyzManager.delegate = self  // 可能这里有问题？
    }
}

请分析：
1. 是第三方库的 bug 还是我使用不当？
2. 如果是使用不当，如何修复？
3. 如果是库的 bug，有什么 workaround？
```

## 相关资源
- [工作流：Instruments 性能诊断](../../workflows/performance-profiling.md)
- [Prompts：Time Profiler 热点分析](./time-profiler-hotspot.md)
- [Apple: Debugging Memory Issues](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [WWDC: Finding Leaks Using Xcode Memgraph](https://developer.apple.com/videos/play/wwdc2021/10180/)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-02  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
