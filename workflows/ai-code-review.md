# 工作流：使用 AI 进行代码 Review

## 📋 背景

在 iOS 团队协作开发中，代码 Review 是保证代码质量的关键环节，但面临以下挑战：
- 资深工程师时间有限，Review 响应慢
- 人工 Review 容易遗漏常见问题（内存泄漏、线程安全、API 误用）
- 代码风格检查占用大量时间，却价值相对较低
- 跨模块影响分析需要深入上下文，人工容易疏漏

使用 AI 辅助代码 Review，可以在人工审查前完成初筛，提升整体效率和质量。

## 🎯 目标

使用 AI 对 PR 或本地改动进行自动化代码审查，达到以下标准：
- **风险分级**：自动识别 Blocker/Major/Minor/Nit 级别问题
- **覆盖面**：检查代码风格、逻辑缺陷、性能隐患、安全漏洞
- **可执行**：提供具体修改建议，而非模糊评价
- **快速迭代**：5 分钟内完成 300 行以内改动的审查

## 🛠️ 适用场景

- ✅ PR 提交前的自检（避免低级错误浪费 reviewer 时间）
- ✅ 大型重构的分阶段审查（分模块验证）
- ✅ 开源项目外部贡献的初筛
- ✅ 学习最佳实践（理解 AI 给出的改进建议）
- ❌ 不能替代人工 Review 的架构决策讨论
- ❌ 不适合业务逻辑正确性验证（AI 无法理解需求）

## 📝 工作流步骤

### 步骤 1：准备上下文

#### 1.1 获取改动 Diff
```bash
# 方式一：本地未提交改动
git diff > /tmp/review-diff.txt

# 方式二：已提交但未推送的 commits
git diff origin/main...HEAD > /tmp/review-diff.txt

# 方式三：GitHub PR（在 PR 页面）
# 在 PR URL 后加 .diff，例如：
# https://github.com/user/repo/pull/123.diff
```

#### 1.2 准备项目上下文文档
创建 `review-context.md`，包含：

```markdown
## 项目架构
- 架构模式：MVVM + Coordinator
- 依赖注入：使用 Swinject
- 网络层：Alamofire + Codable
- 异步处理：Swift Concurrency (async/await)

## 模块依赖关系
本次改动涉及模块：
- Core/NetworkManager（网络请求封装）
- Features/UserProfile（用户资料页面）
- 依赖关系：UserProfile → NetworkManager → Alamofire

## 代码风格约束
- 遵循 SwiftLint 配置（项目根目录 .swiftlint.yml）
- 命名约定：类名用大驼峰，变量/方法用小驼峰
- 禁止 force unwrap (!)，除非有明确注释说明原因
- UI 更新必须在主线程，使用 @MainActor 或 DispatchQueue.main

## 安全与隐私要求
- 不得在代码中硬编码 API Key、密钥
- 用户敏感信息（手机号、邮箱）禁止打印到日志
- 网络请求必须使用 HTTPS
- UserDefaults 不得存储密码或 Token（使用 Keychain）
```

#### 1.3 标注审查重点
在 Cursor 中标注需要重点关注的部分：

```markdown
## 本次改动重点审查
1. UserProfileViewModel.swift: 新增的异步数据加载逻辑
   - 关注：内存泄漏风险（闭包捕获）
   - 关注：错误处理是否完整

2. NetworkManager.swift: 修改了重试逻辑
   - 关注：是否影响现有调用方
   - 关注：线程安全（并发请求）

3. UserProfileView.swift: SwiftUI 视图性能
   - 关注：是否有不必要的重绘
```

### 步骤 2：第一轮审查 - 风险分级

使用以下提示词进行初步风险评估（参考 [prompts/review/ai-code-review.md](../prompts/review/ai-code-review.md)）：

```
我需要对以下 iOS 代码改动进行 Code Review，请先进行风险分级。

## 改动内容
[粘贴 diff 内容]

## 项目上下文
[粘贴 review-context.md 内容]

## 任务
请分析改动，按以下级别分类问题：

### Blocker（阻断发布）
- 导致 crash 的明确风险
- 严重的内存泄漏
- 安全漏洞（密钥泄漏、SQL 注入等）
- 数据丢失或损坏风险

### Major（必须修复）
- 潜在的运行时错误（force unwrap 无保护）
- 线程安全问题（数据竞争）
- 明显的性能问题（循环中重复昂贵操作）
- 违反核心架构约束

### Minor（建议修复）
- 代码风格不一致
- 缺少错误处理
- 可读性问题（命名不清晰、缺少注释）
- 轻微的性能优化机会

### Nit（可选优化）
- 空格、换行等格式问题
- 更优雅的写法
- 非关键的代码组织建议

## 输出格式
请先输出每个级别的问题数量统计，然后列出 Blocker 和 Major 问题的具体位置和原因。
```

### 步骤 3：第二轮审查 - 逐项分析

AI 完成风险分级后，针对每个问题深入分析：

```
针对上述 Blocker 和 Major 问题，请逐项给出详细分析：

## 输出格式（每个问题）
### 问题 [编号]：[简要描述]
- **级别**：Blocker / Major / Minor / Nit
- **位置**：[文件名]::[方法名]::[行号]
- **问题描述**：[具体说明为什么是问题]
- **影响范围**：[可能导致的后果]
- **修复建议**：[提供可执行的代码示例]
- **参考资料**：[相关最佳实践文档或 Apple 官方指南]

## 要求
1. 修复建议必须提供完整代码，不要用 "..." 省略
2. 如果有多种修复方案，说明各自的优缺点
3. 对于复杂问题，提供修复前后的对比代码
```

### 步骤 4：专项检查

根据改动类型，进行针对性专项检查：

#### 4.1 内存管理检查
```
针对本次改动，进行内存管理专项检查：

## 检查要点
1. 闭包捕获：所有闭包是否正确使用 [weak self] 或 [unowned self]
2. 循环引用：delegate 是否声明为 weak，观察者是否正确移除
3. 大对象生命周期：图片、数据缓存是否及时释放
4. Timer/观察者：是否在 deinit 中正确清理

## 输出
列出所有潜在的内存问题，标注文件和行号，提供修复代码。
```

#### 4.2 线程安全检查
```
针对本次改动，进行线程安全专项检查：

## 检查要点
1. 共享状态访问：是否有多线程同时读写同一变量
2. UI 更新：所有 UI 操作是否在主线程
3. 异步回调：闭包回调是否在正确的线程
4. Actor 隔离：是否正确使用 @MainActor

## 输出
列出所有线程安全隐患，提供使用 actor 或 DispatchQueue 的修复方案。
```

#### 4.3 SwiftUI 性能检查
（仅当改动涉及 SwiftUI 视图时）

```
针对 SwiftUI 视图改动，进行性能检查：

## 检查要点
1. @State/@ObservableObject 使用：是否有不必要的状态导致重绘
2. 计算属性：是否在 body 中有重复计算，应提取为 @State
3. List/ScrollView：是否遗漏了 id 或使用了低效的更新逻辑
4. 图片加载：是否使用了 resizable() 和 lazy loading

## 输出
列出性能隐患，提供优化建议（如使用 Equatable、拆分子视图等）。
```

#### 4.4 安全与隐私检查
```
针对本次改动，进行安全与隐私专项检查：

## 检查要点
1. 敏感信息：代码中是否包含 API Key、密码、Token
2. 日志安全：print/NSLog 是否输出了用户隐私数据
3. 网络安全：HTTP 请求是否应该用 HTTPS
4. 数据存储：敏感数据是否错误地存储在 UserDefaults
5. 输入验证：用户输入是否经过验证（防止注入攻击）

## 输出
列出所有安全隐患，标注严重程度（Critical/High/Medium/Low）。
```

### 步骤 5：生成审查报告

整合所有审查结果，生成结构化报告：

```
基于前面的分析，生成最终 Code Review 报告。

## 报告结构
### 1. 总体评价
- 改动行数：[统计]
- 风险等级：High / Medium / Low
- 是否建议合并：Yes / No / Yes with changes
- 一句话总结：[改动的核心内容]

### 2. 问题汇总
| 级别 | 数量 | 已修复 | 待修复 |
|------|------|--------|--------|
| Blocker | X | X | X |
| Major | X | X | X |
| Minor | X | X | X |
| Nit | X | X | X |

### 3. 必须修复的问题（Blocker + Major）
[详细列表，包含位置、描述、修复建议]

### 4. 建议改进的问题（Minor + Nit）
[精简列表，仅列出要点]

### 5. 正面亮点
[列出改动中做得好的地方，如良好的测试覆盖、清晰的命名等]

### 6. 后续建议
[如需要补充单测、更新文档、后续重构计划等]
```

### 步骤 6：人工复核与修正

AI 审查报告生成后，人工复核以下要点：

#### 6.1 验证 Blocker 和 Major 问题
- 逐一检查 AI 标记的高危问题是否真实存在
- 确认修复建议是否可行（有时 AI 会给出不符合项目约束的方案）
- 补充 AI 遗漏的业务逻辑问题

#### 6.2 过滤误报
AI 可能误报的常见场景：

```swift
// 误报示例 1：AI 认为需要 [weak self]，但实际是在 Task 中
Task {
    await self.loadData()  // ✅ Task 不会造成循环引用
}

// 误报示例 2：AI 认为 force unwrap 不安全，但实际有业务保证
let url = URL(string: "https://api.example.com")!  
// ✅ 硬编码 URL，force unwrap 是安全的

// 误报示例 3：AI 认为缺少错误处理，但实际在外层已处理
func fetchUser() async throws -> User {
    let data = try await network.fetch(url)  // ✅ 错误向上抛出
    return try decoder.decode(User.self, from: data)
}
```

#### 6.3 补充业务逻辑审查
AI 无法理解的业务问题需要人工审查：

- 数据一致性：改动是否影响其他模块的数据假设
- 产品逻辑：UI 流程是否符合 PRD 要求
- 边界条件：特殊场景（如网络断开、用户登出）是否考虑
- 向后兼容：API 改动是否兼容旧版本

### 步骤 7：输出与归档

#### 7.1 提交 Review 意见
**GitHub PR 评论格式：**

```markdown
## AI Code Review 报告

### 📊 总体评价
- 改动行数：156 行（+98, -58）
- 风险等级：Medium
- 建议：Approve with minor changes

### 🚨 必须修复（2 项）

#### 1. 潜在内存泄漏 [Major]
**位置**：`UserProfileViewModel.swift:45`

**问题**：
闭包捕获 `self` 可能导致循环引用。

**修复建议**：
\`\`\`swift
// 当前代码
networkManager.fetchUser { user in
    self.user = user  // ⚠️ 强引用 self
}

// 修改为
networkManager.fetchUser { [weak self] user in
    self?.user = user  // ✅ 使用 weak self
}
\`\`\`

---

#### 2. 缺少错误处理 [Major]
**位置**：`NetworkManager.swift:78`

**问题**：
网络请求失败时未处理错误，可能导致 UI 卡死。

**修复建议**：
\`\`\`swift
do {
    let data = try await session.data(from: url)
    return try decoder.decode(User.self, from: data.0)
} catch {
    logger.error("Failed to fetch user: \(error)")
    throw NetworkError.fetchFailed(error)
}
\`\`\`

---

### 💡 建议改进（3 项）

1. **代码风格** - `UserProfileView.swift:23`: 建议使用 SwiftUI 的 `.task` 替代 `.onAppear` 进行异步加载
2. **性能优化** - `UserListView.swift:56`: List 中应添加 `.id()` 避免不必要的重绘
3. **可读性** - `Constants.swift:12`: 建议将魔法数字 300 提取为命名常量

### ✅ 正面亮点
- 良好的单元测试覆盖（新增 8 个测试用例）
- 清晰的命名和代码组织
- 正确使用了 async/await 简化异步逻辑

---
**审查工具**：AI Code Review (GPT-4)  
**审查时间**：2026-10-24 09:30  
**人工复核**：已确认所有 Major 问题
```

#### 7.2 更新团队知识库
将本次审查中发现的新问题类型，补充到团队的 Review Checklist：

```markdown
## Code Review Checklist 更新

新增检查项（来自 PR #123 的 AI 审查）：
- [ ] SwiftUI List 是否为每个元素指定了稳定的 `.id()`
- [ ] 异步任务是否考虑了取消场景（Task.isCancelled）
- [ ] 网络请求重试逻辑是否有上限（避免无限重试）
```

## ✅ 验证清单

使用以下清单确保工作流完成：

- [ ] 已准备完整的改动 diff 和项目上下文
- [ ] AI 报告包含风险分级（Blocker/Major/Minor/Nit）
- [ ] 所有 Blocker 和 Major 问题已逐项分析
- [ ] 已进行专项检查（内存、线程、安全）
- [ ] 人工复核确认 AI 报告准确性（无漏报和误报）
- [ ] 修复建议包含可执行代码（非模糊描述）
- [ ] 已补充 AI 无法检测的业务逻辑问题
- [ ] 审查报告已提交到 PR 或内部文档

## 🐛 常见问题

### Q1: AI 报告了大量 Nit 级别问题，如何处理？

**原因**：AI 倾向于严格遵循风格指南，会标记所有不一致的地方。

**解决**：
1. 在提示词中明确优先级：
   ```
   请只关注 Blocker 和 Major 问题，Nit 级别的格式问题可以忽略。
   我们有 SwiftLint 在 CI 阶段会自动检查代码风格。
   ```
2. 或在生成报告前要求过滤：
   ```
   在最终报告中，只列出需要人工修复的问题（Blocker/Major/Minor），
   Nit 级别的问题可以省略。
   ```

### Q2: AI 给出的修复建议与项目架构冲突

**原因**：AI 不了解项目的特定架构约束（如必须使用某个依赖注入框架）。

**解决**：
1. 在 `review-context.md` 中明确约束：
   ```markdown
   ## 架构硬性约束
   - 所有网络请求必须通过 NetworkManager 单例，不得直接使用 URLSession
   - ViewModel 不得直接持有 View 引用
   - 依赖注入使用 Swinject，不得使用其他 DI 框架
   ```
2. 人工复核时修正 AI 的建议，并记录到团队文档

### Q3: AI 遗漏了明显的问题

**原因**：AI 的上下文不足，或问题需要运行时信息才能发现。

**解决**：
1. 补充更多上下文（如相关类的定义、调用链）
2. 使用分步审查，针对遗漏的部分重新提问：
   ```
   你在之前的审查中遗漏了 UserProfileViewModel:67 行的线程安全问题。
   这个方法会被多个线程同时调用，请重新检查并给出修复建议。
   ```
3. 人工补充审查，不要完全依赖 AI

### Q4: AI 报告说代码存在内存泄漏，但实际不会

**原因**：AI 基于模式识别，可能对 Swift Concurrency 的捕获语义理解不完整。

**解决**：
1. 确认是否误报（可使用 Xcode Instruments 验证）
2. 如果确认误报，在 PR 中添加注释说明：
   ```swift
   // AI Review 误报：Task 中的 self 捕获不会造成循环引用
   Task {
       await self.loadData()
   }
   ```
3. 更新团队的 AI Review 误报案例库

### Q5: 如何处理大型 PR（1000+ 行改动）

**原因**：AI 对超长上下文的理解能力下降，且一次性审查容易遗漏问题。

**解决**：
1. **分模块审查**：
   ```bash
   # 按文件或模块分别生成 diff
   git diff origin/main...HEAD -- Sources/Network/ > network-diff.txt
   git diff origin/main...HEAD -- Sources/UI/ > ui-diff.txt
   
   # 分别提交给 AI 审查
   ```
2. **分阶段审查**：
   - 第一轮：只审查 Blocker 和 Major
   - 第二轮：审查 Minor 和架构问题
3. **建议拆分 PR**：
   ```
   这个 PR 改动过大（1200+ 行），建议拆分为：
   1. PR-1: 网络层重构（300 行）
   2. PR-2: UI 层适配（400 行）
   3. PR-3: 单元测试补充（500 行）
   ```

## 🎓 最佳实践

### 1. AI Review 与人工 Review 的分工

| 检查项 | AI 优势 | 人工必须 |
|--------|---------|----------|
| 代码风格一致性 | ✅ 快速检测 | ⚪ 无需人工 |
| 常见错误（force unwrap、内存泄漏） | ✅ 模式识别 | 🔶 人工确认 |
| 线程安全、性能问题 | 🔶 能发现部分 | ✅ 需要经验 |
| 架构设计合理性 | ❌ 难以理解 | ✅ 必须人工 |
| 业务逻辑正确性 | ❌ 无法判断 | ✅ 必须人工 |
| 安全漏洞（明显的） | ✅ 能检测 | ✅ 需要确认 |

**推荐流程**：
1. AI 先进行初筛，标记常见问题
2. 开发者根据 AI 报告自查并修复
3. 人工 Reviewer 重点关注架构和业务逻辑

### 2. 渐进式接入 AI Review

**阶段一：个人自检（1-2 周）**
- 提交 PR 前，自己先跑一次 AI Review
- 修复明显问题后再提交，减少 reviewer 负担

**阶段二：团队试点（1 个月）**
- 在小团队（3-5 人）内试用
- 收集 AI 误报案例，调整提示词
- 整理常见问题类型到知识库

**阶段三：全团队推广**
- 将 AI Review 集成到 CI 流程（GitHub Actions）
- 自动在 PR 中发布审查报告
- 定期回顾 AI 发现的问题类型，优化检查规则

### 3. 构建项目专属 Review 提示词

通用提示词可能不适合特定项目，建议定制：

```markdown
# 项目专属 AI Review 提示词

## 项目背景
[项目名称]：金融类 App，对安全性和稳定性要求极高

## 重点检查（按优先级）
1. **数据安全**：金额计算必须使用 Decimal，禁止 Double
2. **日志脱敏**：所有涉及金额、账户的日志必须脱敏
3. **错误处理**：金融交易相关代码必须有完整的错误处理和回滚逻辑
4. **线程安全**：账户余额操作必须使用 actor 或串行队列

## 项目架构约束
- 网络层：使用自研的 SecureNetworkManager（基于 URLSession）
- 状态管理：使用 TCA (The Composable Architecture)
- 数据库：使用 CoreData，禁止直接使用 SQLite

## 常见误报（可忽略）
- ViewModel 中的 @Published 属性未初始化 → 使用 TCA 的 State，不需要初始化
- UI 更新未在主线程 → TCA 的 Effect 自动调度到主线程
```

### 4. 安全与隐私审查的额外注意事项

AI Review 在安全检查方面有局限性，需要额外注意：

**AI 能检测的安全问题：**
- ✅ 硬编码的密钥、API Key
- ✅ HTTP 而非 HTTPS 的 URL
- ✅ 明文存储密码
- ✅ 日志中打印敏感信息

**AI 难以检测的安全问题：**
- ❌ 业务逻辑漏洞（如越权访问）
- ❌ 加密算法选择不当
- ❌ 复杂的注入攻击（需要理解数据流）
- ❌ 隐私合规问题（如未经用户同意收集数据）

**补充措施：**
1. 使用专业的安全扫描工具（如 SonarQube、Snyk）
2. 定期进行人工安全审计
3. 敏感模块（支付、认证）必须经过安全团队审查

### 5. 持续优化 AI Review 质量

**建立反馈闭环：**
1. 记录 AI 误报和漏报案例
2. 每月回顾，分析原因（上下文不足？模型限制？）
3. 更新提示词和上下文模板
4. 对比 AI Review 前后的 bug 率变化

**质量指标：**
```markdown
## AI Review 质量月度报告

### 覆盖情况
- 参与 Review 的 PR 数量：120
- AI 发现的问题总数：340
- 开发者采纳的修复建议：280（82%）

### 准确性
- 误报数量：15（4.4%）
- 漏报数量（人工发现的 AI 遗漏）：8

### 效率提升
- 人工 Review 平均时间：从 45min 降至 25min
- PR 合并前的迭代次数：从 3.2 降至 2.1

### 下月优化方向
1. 补充"线程安全"专项检查到提示词（本月漏报的 5 个问题均为此类）
2. 优化上下文准备流程（减少误报）
```

## 📚 扩展阅读

- [Code Review Best Practices - Google Engineering Practices](https://google.github.io/eng-practices/review/)
- [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple's Swift Concurrency Documentation](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [OWASP Mobile Security Testing Guide](https://mobile-security.gitbook.io/mobile-security-testing-guide/)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md)
- [重构遗留 UIKit 代码](./uikit-refactoring.md)（计划中）
- [API 接口自动生成 Mock](./api-mock-generation.md)（计划中）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-24  
**适用工具**：Cursor、Claude Code、GitHub Copilot
