# 工作流：使用 AI 进行代码 Review

## 📋 背景

代码 Review 是保证代码质量的关键环节，但在实际工作中常面临以下挑战：
- **Review 不及时**：团队人手不足，PR 等待时间长
- **Review 不全面**：人工审查容易遗漏内存泄漏、线程安全等隐蔽问题
- **Review 标准不一致**：不同 Reviewer 关注点不同，缺乏统一的检查清单
- **新人 Review 质量低**：缺少经验，难以发现架构层面的问题

使用 AI 辅助代码 Review，可以：
- 快速扫描常见问题（循环引用、强制解包、线程安全）
- 检查架构一致性（是否符合 MVVM/MVI 等约定）
- 提供 Swift 最佳实践建议
- 作为人工 Review 的前置检查，提升整体效率

## 🎯 目标

建立基于 AI 的代码 Review 工作流，达到以下标准：
- **及时性**：PR 提交后 5 分钟内完成 AI 初审
- **全面性**：覆盖内存安全、线程安全、架构一致性、代码风格四大维度
- **可操作性**：每个问题给出具体的修复建议和代码示例
- **人机协作**：AI 负责机械性检查，人工聚焦业务逻辑和设计决策

## 🛠️ 适用场景

- ✅ PR 提交前的自检（开发者自己使用 AI 审查）
- ✅ PR 提交后的初审（团队统一使用 AI 扫描）
- ✅ 新人代码的教学式 Review（详细指出问题和改进方向）
- ✅ 遗留代码的重构前评估（识别风险点）
- ❌ 不适合完全替代人工 Review（业务逻辑正确性需要人判断）
- ❌ 不适合审查需求理解和产品设计（AI 无法判断需求是否合理）

## 📝 工作流步骤

### 步骤 1：准备 Review 上下文

在开始 AI Review 前，准备以下材料：

#### 1.1 获取代码变更

```bash
# 方式一：查看当前分支与主分支的差异
git diff main...HEAD > changes.diff

# 方式二：查看某个 commit 的变更
git show <commit-hash> > changes.diff

# 方式三：从 GitHub PR 获取（安装 gh CLI）
gh pr diff 123 > changes.diff
```

#### 1.2 准备项目上下文文档

创建 `review-context.md` 文件：

```markdown
## 项目技术栈
- 架构模式：MVVM + Coordinator
- UI 框架：SwiftUI（iOS 15+）
- 异步方案：Async/Await + Combine
- 网络层：Alamofire + Codable
- 依赖注入：手动注入（通过 init）

## 代码规范
- 遵循 [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- 使用 SwiftLint（配置见 .swiftlint.yml）
- 命名：ViewModel 以 `ViewModel` 结尾，Service 以 `Service` 结尾
- 错误处理：优先使用 `Result<T, Error>` 或 `throws`

## 架构约定
- ViewModel 不能直接访问 Model 层（通过 Repository 中转）
- UI 组件不能直接调用网络请求（通过 ViewModel）
- 所有网络请求必须有超时和错误处理
- 单例模式仅用于 AppCoordinator 和 NetworkMonitor

## Review 重点（本次 PR）
- 本 PR 重构了用户认证流程
- 关注点：是否有内存泄漏、错误处理是否完善、是否符合 MVVM
```

#### 1.3 准备相关上下文代码

如果改动涉及现有模块的修改，准备相关的协议定义、父类或依赖类型：

```bash
# 例如：改动了 UserViewModel，准备相关的 Protocol
cat Sources/Core/Protocols/ViewModelProtocol.swift > context.swift
cat Sources/Core/Protocols/NetworkServiceProtocol.swift >> context.swift
```

### 步骤 2：第一阶段 - 快速风险扫描

使用 AI 进行**优先级分级的快速扫描**，聚焦高风险问题。

#### 2.1 在 Cursor/Claude 中使用提示词

打开 Cursor，创建新的 Composer 对话（Cmd+I），使用 [prompts/review/ai-code-review.md](../prompts/review/ai-code-review.md) 中的**模板一：Swift PR 风险扫描**。

示例对话：

```
我需要对以下 Swift 代码变更进行风险扫描。

## 变更内容
[粘贴 changes.diff 的内容]

## 项目上下文
[粘贴 review-context.md 的内容]

## Review 重点
请按以下优先级检查：

### P0 - 阻断问题（必须修复才能合并）
1. 内存安全：循环引用、隐式强制解包导致的潜在崩溃
2. 线程安全：主线程阻塞、UI 更新未在主线程、数据竞争
3. API 兼容性：使用了不支持的最低版本 API
4. 安全漏洞：硬编码敏感信息、SQL 注入、不安全的网络请求

### P1 - 高风险问题（强烈建议修复）
1. 架构违背：绕过 ViewModel 直接修改 Model、职责不清
2. 性能隐患：主线程执行耗时操作、内存泄漏风险
3. 测试缺失：关键业务逻辑无单元测试覆盖

### P2 - 优化建议（可延后）
1. 代码风格：命名不符合 Swift API 设计规范
2. 最佳实践：可用更简洁的 Swift 语法、代码重复

## 输出格式
按优先级分组输出，每个问题包含文件位置、问题描述、风险说明、修复建议。
```

#### 2.2 解读 AI 输出

AI 会输出类似以下格式的报告：

```markdown
### 🚨 P0 - 阻断问题

- **UserViewModel.swift:45** - [内存安全] 强制解包可选值
  - 风险：当 `user` 为 nil 时会崩溃
  - 建议：使用 `guard let` 或 `if let` 安全解包
  
- **LoginViewController.swift:78** - [线程安全] UI 更新未在主线程
  - 风险：可能导致 UI 更新延迟或崩溃
  - 建议：用 `DispatchQueue.main.async` 或 `@MainActor`

### ⚠️ P1 - 高风险问题

- **ProfileViewModel.swift:102** - [架构违背] ViewModel 直接访问 UserDefaults
  - 影响：违背依赖倒置原则，难以测试
  - 建议：通过 `StorageService` 协议抽象存储层

### ✅ 正向反馈
- LoginViewModel 正确使用了 [weak self] 避免循环引用
- 错误处理使用了 Swift 的 Result 类型，类型安全
```

#### 2.3 人工判断与分类

**立即修复（P0）**：
- 所有可能导致崩溃的问题
- 明确的安全漏洞
- 线程安全问题

**本 PR 修复（P1）**：
- 架构违背（如果改动不大）
- 明显的性能问题

**后续优化（P2）**：
- 代码风格建议
- 重构建议（如果改动较大）

### 步骤 3：第二阶段 - 逐文件深度审查

对于**核心变更文件**或 AI 标记了 P0/P1 问题的文件，进行逐文件的深度审查。

#### 3.1 选择需要深度审查的文件

通常包括：
- 新增的核心业务类（ViewModel、Service、Repository）
- 有 P0/P1 问题的文件
- 改动行数超过 100 行的文件
- 涉及并发、网络、数据库的文件

#### 3.2 使用深度审查提示词

在 Cursor 中，针对单个文件使用 [prompts/review/ai-code-review.md](../prompts/review/ai-code-review.md) 中的**模板二：逐文件详细 Review**。

示例对话：

```
我需要对以下 Swift 文件进行详细代码审查。

## 文件内容
[粘贴完整的 UserViewModel.swift 内容]

## 审查上下文
- 这个类的职责：用户信息管理的 ViewModel
- 依赖的协议：UserRepositoryProtocol, AuthServiceProtocol
- 修改原因：重构用户登录流程，支持生物识别登录

## Review 维度
1. 架构与职责：是否符合 MVVM，职责是否单一
2. Swift 最佳实践：命名、可选值处理、错误处理
3. 内存与性能：循环引用、不必要的对象创建
4. 可测试性：依赖是否可 Mock，是否方便写测试
5. 可维护性：代码可读性、注释质量

请逐段审查，给出具体的问题和改进代码。
```

#### 3.3 审查 SwiftUI 视图（如适用）

如果改动涉及 SwiftUI 视图，使用**模板三：针对 SwiftUI 的专项 Review**：

```
我需要审查以下 SwiftUI 视图代码。

## 视图代码
[粘贴 ProfileView.swift]

## SwiftUI 专项检查点
1. 状态管理：@State/@Binding/@ObservedObject 使用是否正确
2. 性能优化：是否有耗时操作在 body 中执行
3. 代码组织：body 是否过于复杂（超过 10 层嵌套）
4. 可访问性：是否添加了 accessibility 标签
5. SwiftUI 最佳实践：是否使用了过时 API

请列出问题和改进建议。
```

### 步骤 4：人工审查与决策

AI Review 输出后，需要人工进行最终判断：

#### 4.1 验证 AI 发现的问题

**检查清单**：
- [ ] P0 问题是否真的会导致崩溃？（在测试环境验证）
- [ ] P1 架构问题是否符合团队实际约定？（AI 可能不了解特殊约定）
- [ ] 性能问题是否真的存在？（用 Instruments 实测）
- [ ] 建议的改进代码是否可以直接使用？（可能需要调整）

#### 4.2 补充 AI 遗漏的检查

AI 不擅长的领域需要人工检查：
- **业务逻辑正确性**：计算逻辑是否正确，边界条件是否处理
- **需求理解**：改动是否真正解决了需求，有无过度设计
- **向后兼容性**：API 变更是否影响现有调用方
- **用户体验**：交互流程是否合理，错误提示是否友好

#### 4.3 生成 Review 意见

将 AI 的输出和人工检查结果整理为 Review 意见：

```markdown
## Code Review 意见

### 🚨 必须修复（Blocking）
1. **UserViewModel.swift:45** - 强制解包会导致崩溃
   - 建议：改用 `guard let user = user else { return }`
   
2. **LoginViewController.swift:78** - UI 更新未在主线程
   - 建议：用 `await MainActor.run { self.updateUI() }`

### ⚠️ 建议修复（本 PR）
1. **ProfileViewModel.swift:102** - 直接访问 UserDefaults 违背架构
   - 建议：注入 `StorageService` 协议，便于测试
   
### 💡 可选优化（后续 PR）
1. **多处代码重复** - UserViewModel 和 ProfileViewModel 有重复的错误处理逻辑
   - 建议：提取为 `BaseViewModel` 或使用 Combine 的统一错误处理

### ✅ 做得好的地方
- 正确使用 [weak self] 避免循环引用
- 错误提示信息用户友好
- 添加了完善的单元测试
```

### 步骤 5：修复问题并验证

#### 5.1 修复 P0 和 P1 问题

按照 Review 意见修复代码：

```swift
// ❌ 修复前（P0 问题）
let userName = user!.name

// ✅ 修复后
guard let user = user else {
    logger.error("User is nil when accessing name")
    return
}
let userName = user.name
```

#### 5.2 运行自动化检查

```bash
# SwiftLint 检查
swiftlint lint --strict

# 编译检查
xcodebuild clean build \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 运行测试
xcodebuild test \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### 5.3 再次 AI Review（可选）

如果改动较大，可以再次运行快速风险扫描：

```bash
# 生成新的 diff
git diff HEAD~1 > fixed-changes.diff

# 在 Cursor 中再次运行模板一检查
```

### 步骤 6：与 PR 流程集成

#### 6.1 在 PR 描述中记录 AI Review 结果

```markdown
## PR Description
[需求描述]

## AI Code Review Summary
- ✅ 已通过 AI 风险扫描（无 P0/P1 问题）
- ✅ 已修复 2 个 P0 问题（强制解包、主线程更新）
- 📝 有 1 个 P2 建议（代码重复），计划在后续 PR 优化

<details>
<summary>AI Review 详细报告</summary>

[粘贴 AI 输出的完整报告]

</details>
```

#### 6.2 配置 GitHub Actions 自动化（可选）

创建 `.github/workflows/ai-review.yml`：

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Get PR diff
        id: diff
        run: |
          gh pr diff ${{ github.event.pull_request.number }} > changes.diff
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: AI Review with Claude API
        run: |
          # 调用 Claude API 进行 Review
          # 需要配置 ANTHROPIC_API_KEY secret
          python scripts/ai_review.py changes.diff
      
      - name: Post Review Comment
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const reviewResult = fs.readFileSync('review-result.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: reviewResult
            });
```

#### 6.3 人工 Review 聚焦高价值部分

有了 AI 的初审后，人工 Reviewer 可以：
- **跳过机械性检查**（内存泄漏、空指针、代码风格）
- **聚焦业务逻辑**：算法是否正确、边界条件是否完备
- **聚焦设计决策**：架构选择是否合理、是否有更好的方案
- **聚焦团队知识传递**：给新人讲解为什么这样设计

### 步骤 7：持续优化 Review 流程

#### 7.1 积累项目特定的 Review 规则

将团队常见问题整理为 Review 检查清单，添加到 `review-context.md`：

```markdown
## 团队常见问题（重点检查）
- [ ] 是否使用了已废弃的 `LegacyNetworkManager`？（应该用 `ModernNetworkService`）
- [ ] 是否在 ViewController 中写了业务逻辑？（应该在 ViewModel）
- [ ] 是否处理了 `AppDelegate` 的应用启动时序问题？
- [ ] 新增的公开 API 是否更新了文档？
```

#### 7.2 记录 AI Review 的误报和漏报

创建 `docs/ai-review-notes.md` 记录：

```markdown
## AI Review 误报案例
- **误报**：AI 认为使用单例违背原则，但 `AppCoordinator` 确实需要全局唯一
- **解决**：在提示词中说明"单例仅用于 AppCoordinator"

## AI Review 漏报案例
- **漏报**：AI 未发现计算折扣的算法错误（业务逻辑问题）
- **应对**：人工 Review 必须验证业务逻辑，不能只依赖 AI
```

#### 7.3 定期更新提示词

根据团队反馈，每月更新一次提示词模板：
- 补充新的检查点（如项目引入了新框架）
- 调整优先级（如某类问题频繁出现，提升到 P1）
- 优化输出格式（让 AI 输出更易读）

## ✅ 验证清单

使用以下清单确保 AI Review 流程有效：

### Review 完成度
- [ ] 所有变更文件都经过 AI 快速风险扫描
- [ ] 核心变更文件（新增/修改 >100 行）经过深度审查
- [ ] AI 发现的所有 P0 问题已修复并验证
- [ ] P1 问题已修复或记录到后续 PR

### Review 质量
- [ ] 编译通过，无 warning（或 warning 在可接受范围内）
- [ ] 所有测试通过（单元测试 + UI 测试）
- [ ] SwiftLint 检查通过
- [ ] 人工检查了业务逻辑正确性（AI 无法判断的部分）

### 流程规范
- [ ] PR 描述中记录了 AI Review 结果摘要
- [ ] Review 意见清晰标记优先级（P0/P1/P2）
- [ ] 改进建议附带了具体的代码示例
- [ ] 记录了 AI 的误报或漏报（用于改进提示词）

## 🐛 常见问题

### Q1: AI Review 发现的问题太多，无法全部修复怎么办？

**原因**：可能是首次使用 AI Review，积累的技术债较多。

**解决**：
1. **优先修复 P0 问题**：可能导致崩溃的必须在本 PR 修复
2. **P1 问题分批修复**：创建 follow-up issues，排期修复
3. **P2 问题可接受**：代码风格问题可以在下次大重构时统一处理
4. **调整 Review 粒度**：新代码严格执行，遗留代码只检查改动部分

**防范**：
- 在 PR 提交前自己先用 AI 自检，避免 P0 问题提交
- 建立"新代码零 P0"的团队约定

### Q2: AI 给出的架构建议不符合项目实际情况

**原因**：AI 不了解项目的特殊约定或历史原因。

**解决**：
1. **在提示词中明确说明**：
   ```
   ## 架构特殊说明
   - 本项目的 Coordinator 需要持有 ViewController 强引用（特殊设计）
   - NetworkManager 使用单例是历史遗留，暂不重构
   ```

2. **使用"上下文优先级"**：
   ```
   如果你的建议与以下约定冲突，以项目约定为准：
   [列出项目的核心约定]
   ```

3. **人工判断**：对于 AI 的架构建议，最终由资深工程师决策

### Q3: AI Review 没有发现明显的性能问题

**原因**：AI 只能进行静态分析，无法模拟运行时行为。

**解决**：
1. **性能问题需要实测**：
   ```bash
   # 使用 Instruments 进行性能分析
   xcodebuild -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 15' \
     | xcpretty
   # 在 Xcode 中打开 Instruments，选择 Time Profiler
   ```

2. **让 AI 审查特定场景**：
   ```
   请检查以下代码是否有性能问题：
   [粘贴循环或递归代码]
   
   关注点：
   - 是否有 N+1 查询问题
   - 是否有不必要的对象复制
   - 是否在主线程执行耗时操作
   ```

3. **人工 Review 必须包含性能检查**：
   - 大循环是否优化
   - 列表渲染是否使用懒加载
   - 图片加载是否有缓存

### Q4: 如何处理 AI 给出的相互矛盾的建议？

**原因**：不同的提示词或上下文可能导致 AI 给出不同建议。

**示例**：
- AI 建议提取为 BaseViewModel（减少重复）
- 同时建议保持类独立（避免过度继承）

**解决**：
1. **明确优化目标**：告诉 AI 当前最重要的是什么
   ```
   本项目优先考虑代码可读性，允许一定的重复。
   如果提取 BaseViewModel 会增加理解成本，保持独立更好。
   ```

2. **分阶段重构**：
   - 第一步：修复 P0/P1 问题，保持现有结构
   - 第二步：单独的重构 PR 优化架构

3. **团队讨论**：对于架构层面的权衡，组织团队讨论，而非由 AI 决定

### Q5: SwiftUI 的预览代码是否需要 Review？

**原因**：Preview 代码通常不参与生产构建。

**建议**：
1. **基础检查**：
   - 确保 Preview 代码编译通过
   - 不要在 Preview 中写复杂逻辑
   
2. **可以跳过**：
   - 代码风格检查（Preview 代码允许简写）
   - 错误处理（Preview 可以用简单的 mock）

3. **让 AI 专注生产代码**：
   ```
   请忽略 #Preview 代码块，只审查生产代码。
   ```

## 🎓 最佳实践

### 1. 分阶段 Review

- ✅ **第一阶段**：快速风险扫描（5 分钟），发现 P0 问题
- ✅ **第二阶段**：深度逐文件审查（20-30 分钟），发现架构和设计问题
- ✅ **第三阶段**：人工审查（15-30 分钟），验证业务逻辑和设计决策
- ❌ 不要一次性让 AI 做所有检查（输出太长，重点不突出）

### 2. 提供高质量上下文

- ✅ 粘贴完整的 diff 或文件内容（不要只给片段）
- ✅ 说明修改背景和目标（帮助 AI 判断是否过度设计）
- ✅ 提供项目架构约定和代码规范（让 AI 检查一致性）
- ❌ 不要期望 AI 推测项目背景

### 3. 明确优先级

- ✅ 在提示词中明确要求分 P0/P1/P2
- ✅ 对 P0 问题零容忍（必须修复才能合并）
- ✅ P1 问题可以协商（如果改动量大，可以后续修复）
- ❌ 不要把所有建议都当成必须修复的问题

### 4. 人机协作，各司其职

| 检查内容 | AI 擅长 | 人工擅长 |
|---------|---------|---------|
| 内存泄漏、空指针 | ✅ | ❌ |
| 线程安全检查 | ✅ | ⚠️ 复杂场景需人工 |
| 代码风格一致性 | ✅ | ❌ |
| 架构模式一致性 | ✅ | ⚠️ 需人工判断特殊情况 |
| 业务逻辑正确性 | ❌ | ✅ |
| 需求理解 | ❌ | ✅ |
| 设计决策权衡 | ❌ | ✅ |
| 用户体验判断 | ❌ | ✅ |

### 5. 持续改进 Review 流程

- ✅ 每月回顾 AI Review 的误报和漏报
- ✅ 根据团队反馈更新提示词模板
- ✅ 记录项目特定的 Review 规则
- ✅ 分享 Review 中发现的典型问题（团队知识沉淀）

### 6. 与自动化工具结合

```
┌─────────────────┐
│  SwiftLint      │ ← 代码风格、命名约定（自动化）
├─────────────────┤
│  AI Review      │ ← 内存安全、线程安全、架构一致性（半自动）
├─────────────────┤
│  人工 Review    │ ← 业务逻辑、设计决策、需求理解（人工）
└─────────────────┘
```

**工作流整合**：
1. SwiftLint 作为 pre-commit hook（提交前自动检查）
2. AI Review 在 PR 创建后自动触发（GitHub Actions）
3. 人工 Review 在 AI Review 完成后进行（聚焦高价值部分）

## 📚 扩展阅读

- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Kodeco: The Complete Guide to Swift Code Review](https://www.kodeco.com/books/advanced-ios-app-architecture/v4.0/chapters/12-code-review)
- [iOS Memory Management Best Practices](https://developer.apple.com/documentation/swift/memory-safety)
- [SwiftUI Performance Tips](https://www.swiftbysundell.com/articles/swiftui-performance-tuning/)

## 🔗 相关工作流

- [Prompts：AI 代码 Review 提示词](../prompts/review/ai-code-review.md)
- [为 Swift 模块补充单元测试](./unit-test-generation.md)
- [重构遗留 UIKit 代码](./uikit-refactoring.md)（计划中）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-26  
**适用工具**：Cursor、Claude Code、GitHub Copilot
