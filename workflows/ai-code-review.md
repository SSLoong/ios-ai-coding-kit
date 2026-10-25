# 工作流：使用 AI 进行代码 Review

## 📋 背景

在 iOS 项目的日常开发中，代码审查（Code Review）是保障代码质量的关键环节。然而传统人工 Review 面临：
- **时间成本高**：资深工程师需要花费大量时间审查每个 PR
- **覆盖不全面**：容易遗漏内存泄漏、线程安全、API 兼容性等细节问题
- **反馈延迟**：等待人工审查的时间影响开发效率
- **标准不一致**：不同 Reviewer 的关注点和标准差异大

使用 AI 辅助代码 Review，可以在人工审查前快速发现常见问题，让人工审查聚焦在架构设计、业务逻辑等高价值决策上。

## 🎯 目标

通过 AI 工具对 Swift/iOS 代码进行系统化审查，达到以下标准：
- **安全性检查**：内存泄漏（循环引用）、线程安全、数据验证
- **性能优化**：主线程阻塞、冗余计算、资源浪费
- **代码规范**：遵循 Swift API Design Guidelines 和团队约定
- **API 兼容性**：iOS 版本兼容、废弃 API 使用
- **可维护性**：命名清晰、职责单一、注释完整

## 🛠️ 适用场景

- ✅ PR 提交前的自查（作者自审）
- ✅ 人工 Review 前的预筛查（快速发现明显问题）
- ✅ 大规模重构后的质量检查
- ✅ 新人代码的学习式审查（带教学建议）
- ❌ 不能完全替代人工 Review（架构决策、业务逻辑仍需人工）
- ❌ 不适合敏感的安全审计（如加密、隐私合规需专业工具）

## 📝 工作流步骤

### 步骤 1：准备 Review 上下文

在 Cursor 中准备完整的审查材料：

#### 1.1 获取代码变更
```bash
# 查看当前分支的改动
git diff main...HEAD

# 或生成 patch 文件
git diff main...HEAD > changes.patch
```

#### 1.2 准备项目上下文文档
创建 `review-context.md`，包含：
```markdown
## 项目信息
- 最低支持版本：iOS 14.0
- 主要技术栈：UIKit + Combine / SwiftUI
- 架构模式：MVVM / MVI
- 并发方案：async/await + Actor

## 团队规范
- 代码风格：遵循 SwiftLint 配置（见 .swiftlint.yml）
- 命名约定：类型用 PascalCase，方法/变量用 camelCase
- 内存管理：优先使用 weak/unowned 避免循环引用

## 本次 PR 背景
- 功能描述：[简述本次改动的目的]
- 关键变更：[列出核心修改的文件/模块]
- 风险点：[自己担心的潜在问题]
```

### 步骤 2：执行 AI 代码审查

使用专用提示词进行审查（见 [prompts/review/ai-code-review.md](../prompts/review/ai-code-review.md)）：

```
请对以下 Swift 代码进行全面的代码审查。

## 代码变更
[粘贴 git diff 或具体代码文件]

## 审查重点（iOS/Swift 专项）

### 1. 内存安全
- 检查闭包中的循环引用（self 捕获）
- Delegate 是否正确使用 weak
- 定时器、通知、观察者是否正确释放

### 2. 线程安全
- UI 更新是否在主线程
- 数据竞态（多线程访问可变状态）
- Actor 隔离是否正确

### 3. 性能问题
- 主线程是否有耗时操作（网络、文件 I/O、大数据处理）
- 是否有不必要的视图重绘
- 集合操作是否高效（避免嵌套循环）

### 4. API 使用
- 是否使用了已废弃的 API
- iOS 版本兼容性检查（@available）
- 系统 API 是否正确处理错误

### 5. Swift 代码规范
- 命名是否清晰（避免缩写、表意明确）
- 是否合理使用 optional（避免强制解包 !）
- 错误处理是否完善（try? vs try vs try!）
- 访问控制是否合理（public/internal/private）

### 6. SwiftUI 特定（如适用）
- @State/@Binding/@ObservedObject 使用是否正确
- 视图是否拆分合理（避免巨型视图）
- PreferenceKey/EnvironmentValue 是否必要

### 7. UIKit 特定（如适用）
- ViewController 生命周期方法使用是否正确
- AutoLayout 约束是否会冲突
- 内存警告处理

## 输出格式
按以下结构输出审查结果：

### 🔴 严重问题（必须修复）
- [文件:行号] 问题描述 + 修复建议

### 🟡 改进建议（建议修复）
- [文件:行号] 问题描述 + 优化方案

### 🟢 优秀实践（值得保留）
- [文件:行号] 好的做法

### 📊 代码质量评分
- 内存安全：X/10
- 线程安全：X/10
- 性能：X/10
- 可维护性：X/10
- 综合评分：X/10

## 项目上下文
[粘贴 review-context.md 内容]
```

### 步骤 3：分类处理 Review 结果

#### 3.1 严重问题（🔴）立即修复
AI 标记为"严重问题"的条目，优先处理：

**示例：循环引用**
```swift
// ❌ AI 发现的问题
class ViewController: UIViewController {
    var onComplete: (() -> Void)?
    
    func setupCallback() {
        onComplete = {
            self.dismiss(animated: true)  // 强引用 self
        }
    }
}

// ✅ 修复后
func setupCallback() {
    onComplete = { [weak self] in
        self?.dismiss(animated: true)
    }
}
```

**示例：主线程阻塞**
```swift
// ❌ AI 发现的问题
func loadData() {
    let data = try? Data(contentsOf: url)  // 同步网络请求
    updateUI(with: data)
}

// ✅ 修复后
func loadData() async {
    do {
        let (data, _) = try await URLSession.shared.data(from: url)
        await MainActor.run {
            updateUI(with: data)
        }
    } catch {
        handleError(error)
    }
}
```

#### 3.2 改进建议（🟡）评估优先级
根据影响范围和修改成本决定是否在本 PR 修复：

**立即修复的情况：**
- 影响 API 设计（如访问控制不当）
- 容易引发后续 bug（如强制解包）
- 修改成本低（如变量命名）

**后续 PR 处理：**
- 需要大范围重构（如架构调整）
- 性能优化非关键路径
- 涉及其他模块联动

#### 3.3 优秀实践（🟢）文档化
将 AI 认可的好做法记录到团队知识库：
```markdown
## 团队最佳实践案例

### Combine 订阅管理
来源：PR #123 @yourname
\`\`\`swift
class ViewModel {
    private var cancellables = Set<AnyCancellable>()
    
    func bind() {
        publisher
            .sink { [weak self] value in
                self?.handle(value)
            }
            .store(in: &cancellables)  // 自动管理生命周期
    }
}
\`\`\`
```

### 步骤 4：运行自动化检查

AI Review 后，运行静态分析工具验证：

#### 4.1 SwiftLint 检查
```bash
swiftlint lint --strict
```

#### 4.2 编译 Warning 检查
```bash
xcodebuild clean build \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  | xcpretty --color --report html
```

#### 4.3 单元测试
```bash
xcodebuild test \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

### 步骤 5：生成 Review 总结

整理 AI Review 结果，添加到 PR 描述或评论：

```markdown
## AI 代码审查总结

### ✅ 已修复问题（3 项）
1. **内存泄漏**：`VideoPlayerView.swift:45` - 添加 [weak self] 避免循环引用
2. **线程安全**：`DataManager.swift:89` - UI 更新移到主线程
3. **API 兼容**：`NetworkClient.swift:120` - 添加 @available(iOS 15.0, *) 检查

### ⚠️ 待后续优化（2 项）
1. **性能**：`HomeViewController.swift:200` - tableView 数据源可缓存计算结果
2. **重构**：`LoginViewModel.swift` - 建议提取验证逻辑到独立 Validator

### 📊 质量评分：8.5/10
- 内存安全：9/10（已修复循环引用）
- 线程安全：8/10（已修复主线程问题）
- 性能：8/10（无明显性能瓶颈）
- 可维护性：9/10（代码清晰，注释完整）

### 🤖 审查工具
- AI 工具：Cursor (Claude 3.5 Sonnet)
- 静态检查：SwiftLint 0.54.0
- 单元测试：78% 覆盖率（新增代码 100%）
```

### 步骤 6：人工复审与讨论

AI Review 完成后，仍需人工审查：

#### 6.1 人工关注的重点
- **架构决策**：模块划分、依赖关系是否合理
- **业务逻辑**：实现是否符合产品需求
- **边界条件**：特殊场景处理是否完善
- **用户体验**：交互流程、错误提示是否友好

#### 6.2 与 AI Review 结果对比
如果人工审查发现 AI 遗漏的问题：
```markdown
## 补充审查意见

**AI 未发现的问题：**
- [文件:行号] 业务逻辑问题：支付金额计算未考虑优惠券叠加规则

**对 AI 建议的不同意见：**
- AI 建议提取 LoginValidator，但当前仅 1 处使用，暂不提取避免过度设计
```

将遗漏的问题补充到提示词中，持续改进 AI Review 效果。

## ✅ 验证清单

使用以下清单确保 Review 完成：

- [ ] AI 已审查所有代码变更（新增、修改、删除的文件）
- [ ] 严重问题（🔴）全部修复
- [ ] 改进建议（🟡）已评估，决定本 PR 或后续处理
- [ ] SwiftLint 检查通过（0 error, warning 符合团队标准）
- [ ] 编译 Warning 已处理或标注为已知问题
- [ ] 单元测试全部通过，新增代码覆盖率 ≥ 80%
- [ ] AI Review 总结已添加到 PR 描述
- [ ] 人工审查已完成（或已请求团队 Review）

## 🐛 常见问题

### Q1: AI 标记了很多"问题"，但实际上是项目特定设计，如何处理？

**原因**：AI 不了解项目特定的架构决策或历史包袱。

**解决**：
1. 在 `review-context.md` 中补充说明：
   ```markdown
   ## 已知例外
   - 允许在 LegacyManager 中使用强制解包（历史代码，待重构）
   - NetworkClient 使用单例模式（团队约定）
   ```
2. 在提示词中添加：
   ```
   以下模式是项目允许的，不需要标记：
   - [具体说明]
   ```

### Q2: AI 没有发现明显的内存泄漏，但运行时确实存在

**原因**：AI 静态分析有局限，复杂的引用链难以发现。

**解决**：
1. 使用 Xcode Instruments 的 Leaks 和 Allocations 工具
2. 添加内存监控日志：
   ```swift
   deinit {
       print("\(type(of: self)) deallocated")
   }
   ```
3. 将发现的模式补充到提示词中教导 AI

### Q3: AI 建议的修复方案不适用于当前 iOS 版本

**原因**：AI 可能推荐较新的 API，但项目支持旧版本。

**解决**：
1. 在 `review-context.md` 明确最低支持版本
2. 在提示词中强调：
   ```
   项目最低支持 iOS 14.0，请只建议兼容该版本的 API。
   如需使用新 API，必须提供 @available 检查的向后兼容方案。
   ```

### Q4: 对同一段代码多次 Review，AI 给出不同的建议

**原因**：AI 输出具有随机性，且受上下文影响。

**解决**：
1. 使用更低的 temperature 参数（如 Cursor 设置中调整）
2. 在提示词中明确优先级：
   ```
   审查优先级：内存安全 > 线程安全 > 性能 > 代码风格
   ```
3. 将核心规则固化到 `.cursor/rules` 文件中

## 🎓 最佳实践

### 1. 分层审查策略

**第一层：AI 自动化审查**
- 快速发现语法、规范、常见安全问题
- 适合作为 PR 提交前的自查工具

**第二层：团队成员互审**
- 关注业务逻辑、架构合理性
- 学习他人的代码实现思路

**第三层：资深工程师抽查**
- 审查关键模块、高风险变更
- 指导架构演进方向

### 2. 定制化提示词

根据项目特点定制专属提示词：

```markdown
## 我们项目的特殊审查点

### 网络层
- 所有 API 请求必须有超时设置（30 秒）
- 必须使用统一的 APIClient，不允许直接用 URLSession

### 数据持久化
- 禁止使用 UserDefaults 存储敏感信息
- CoreData 操作必须在后台 context

### UI 相关
- 所有颜色/字体必须从 DesignSystem 获取
- 适配暗黑模式（检查 .label、.systemBackground 等）
```

### 3. 持续改进 Review 质量

#### 3.1 记录误报和漏报
```markdown
## AI Review 问题日志

### 误报（False Positive）
- 日期：2026-10-23
- 问题：AI 标记 singleton 为坏实践，但这是团队约定
- 改进：在提示词中添加 singleton 例外说明

### 漏报（False Negative）
- 日期：2026-10-22
- 问题：未发现 DispatchQueue.main.async 嵌套导致的死锁风险
- 改进：补充"检查 DispatchQueue 嵌套调用"到提示词
```

#### 3.2 建立团队 Review Checklist
将 AI 常发现的问题整理为人工 Checklist：
```markdown
## iOS 代码 Review Checklist

### 内存管理
- [ ] 闭包捕获 self 使用 [weak self] 或 [unowned self]
- [ ] Delegate 声明为 weak
- [ ] Timer/NotificationCenter 正确移除

### 线程安全
- [ ] UI 更新在主线程
- [ ] 可变状态的多线程访问有保护机制
- [ ] async/await 函数正确使用 @MainActor

### 性能
- [ ] 主线程无耗时操作
- [ ] TableView/CollectionView 使用复用机制
- [ ] 图片加载有缓存策略
```

### 4. 结合 CI/CD 流程

将 AI Review 集成到自动化流程：

```yaml
# .github/workflows/ai-review.yml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Get PR diff
        run: |
          gh pr diff ${{ github.event.pull_request.number }} > pr-diff.txt
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Run AI Review
        uses: cursor-ai/review-action@v1  # 假设的 Action
        with:
          diff-file: pr-diff.txt
          prompt-file: .github/prompts/review.md
          
      - name: Post Review Comment
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const reviewResult = fs.readFileSync('ai-review-result.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: reviewResult
            });
```

## 📚 扩展阅读

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [iOS Memory Management](https://developer.apple.com/documentation/swift/swift_standard_library/manual_memory_management)
- [Thread Sanitizer (TSan) for iOS](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)
- [SwiftLint Rules Reference](https://realm.github.io/SwiftLint/rule-directory.html)
- [Concurrent Programming with Swift](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md)
- [重构遗留 UIKit 代码](./uikit-refactoring.md)（计划中）
- [SwiftUI 视图快速原型](./swiftui-prototyping.md)（计划中）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-25  
**适用工具**：Cursor、Claude Code、GitHub Copilot
