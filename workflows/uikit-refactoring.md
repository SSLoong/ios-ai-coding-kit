# 工作流：用 AI 重构遗留 UIKit 代码

## 📋 背景

许多 iOS 项目在早期采用了 UIKit，随着时间推移积累了大量遗留代码。这些代码面临：
- **可维护性差**：臃肿的 ViewController（"Massive View Controller"）、紧耦合的逻辑
- **技术债务高**：硬编码、魔法数字、缺少协议抽象
- **重构风险大**：缺少测试覆盖，不敢轻易改动
- **新人接手难**：代码结构混乱，业务逻辑分散

使用 AI 辅助重构遗留 UIKit 代码，可以在保证行为不变的前提下，系统性地改善代码质量，为后续迁移到 SwiftUI 或现代化架构打下基础。

## 🎯 目标

对遗留 UIKit 代码进行渐进式重构，达到以下标准：
- **行为保持**：重构前后 UI 表现与交互完全一致
- **可测试性提升**：提取业务逻辑到独立组件，覆盖率从 < 20% 提升到 ≥ 60%
- **可维护性改善**：单一职责、清晰的依赖关系、遵循现代 Swift 规范
- **风险可控**：小步迭代，每步都有验证，保留回滚能力

## 🛠️ 适用场景

- ✅ 重构臃肿的 ViewController（> 500 行代码）
- ✅ 提取业务逻辑到独立层（ViewModel/Presenter/Interactor）
- ✅ 消除硬编码与魔法数字
- ✅ 将 delegate pattern 重构为协议化设计
- ✅ 优化复杂的视图层级与布局代码
- ❌ 不适合完全重写（风险过高，用增量重构替代）
- ❌ 不适合跨架构迁移（如 UIKit → SwiftUI，需单独工作流）

## 📝 工作流步骤

### 步骤 0：前置准备 — 建立测试基线

在开始重构前，必须确保现有功能有基本的验证方式：

#### 0.1 记录当前行为
创建 `refactoring-checklist.md` 文档，记录：
```markdown
## 重构目标模块
- 模块名称：UserProfileViewController
- 代码行数：850 行
- 主要职责：展示用户资料、处理编辑、头像上传

## 核心功能清单
- [ ] 页面加载时展示用户信息（姓名、头像、简介）
- [ ] 点击编辑按钮进入编辑模式
- [ ] 编辑模式下修改姓名/简介，保存后更新服务器
- [ ] 点击头像弹出图片选择器，选择后上传并更新
- [ ] 网络失败时展示错误提示

## 边界情况
- [ ] 用户信息为空时的占位符显示
- [ ] 超长姓名/简介的显示截断
- [ ] 上传头像时显示 loading 状态
- [ ] 取消编辑时恢复原始数据
```

#### 0.2 建立测试基线
```swift
// 为关键功能添加简单的验证测试
func test_userProfileViewController_initialLoad_displaysUserInfo() {
    // 即使是粗糙的测试，也能在重构时发现问题
    let vc = UserProfileViewController()
    vc.loadViewIfNeeded()
    
    XCTAssertNotNil(vc.nameLabel.text)
    XCTAssertEqual(vc.saveButton.isEnabled, false)
}
```

**为什么需要测试基线？**
- AI 重构可能改变行为而不自知
- 有测试才能自动验证"等价性"
- 后续步骤依赖测试覆盖率指标

### 步骤 1：分析与范围划定

#### 1.1 使用 AI 分析代码结构

在 Cursor 中打开目标文件，使用以下提示词：

```
请分析这个 UIKit ViewController 的结构：

[粘贴完整的 ViewController 代码]

## 分析要求
1. 识别所有职责（视图管理、业务逻辑、网络请求、数据转换等）
2. 列出职责间的依赖关系
3. 找出可提取的独立模块（如网络层、数据模型转换）
4. 识别代码坏味道（硬编码、魔法数字、过长方法、深层嵌套）
5. 评估重构风险等级（高/中/低）

## 输出格式
使用 Markdown 表格和列表，便于人工审查。
```

#### 1.2 人工审查与划定范围

AI 输出示例：
```markdown
## 职责分析
| 职责 | 代码行数 | 风险等级 | 建议 |
|------|---------|---------|------|
| UI 布局与约束 | 200 行 | 低 | 保持不动，或提取到单独方法 |
| 用户数据获取与展示 | 150 行 | 中 | 提取到 ViewModel |
| 表单验证逻辑 | 80 行 | 低 | 提取到 Validator 类 |
| 图片上传处理 | 120 行 | 高 | 提取到 ImageUploader + 单测 |
| 网络错误处理 | 100 行 | 中 | 统一到 ErrorHandler |

## 代码坏味道
1. 硬编码的 API endpoint（L245-260）
2. 魔法数字：头像尺寸 `120`、边距 `16`（散落各处）
3. 5 层嵌套的 if-else（L300-350）
4. 300 行的 `saveButtonTapped()` 方法
```

**人工决策要点：**
- 优先重构**低风险高收益**的部分（如提取常量、简单方法）
- 高风险部分（如复杂交互逻辑）放到后期，先建立测试
- 第一轮目标：1-2 个小改进，验证流程可行

### 步骤 2：建立上下文 — 让 AI 理解架构

#### 2.1 准备架构上下文文档

创建临时文档 `refactoring-context.md`：
```markdown
## 项目架构
- 架构模式：MVVM（准备迁移到 MVVM-C）
- 网络层：使用 Alamofire + 自定义 NetworkService
- 数据持久化：UserDefaults + Core Data（用户资料用 UserDefaults）
- 依赖注入：手动依赖注入，通过初始化方法传入

## 代码规范
- Swift 版本：Swift 5.9
- 遵循 SwiftLint 规则（`.swiftlint.yml` 在根目录）
- 命名约定：
  - ViewModel 以 `ViewModel` 结尾
  - Protocol 以 `Protocol` 结尾
  - 私有方法使用 `private` 修饰
  
## 依赖关系
UserProfileViewController 依赖：
- NetworkService（网络请求）
- ImageUploader（图片上传）
- UserManager（用户状态管理）

## 重构约束
- 不能改变公开 API（其他模块可能依赖）
- 保持现有的 delegate 调用（AppCoordinator 依赖）
- 不引入新的三方库
```

#### 2.2 提供相关类型定义

将 ViewController 依赖的关键类型添加到上下文：
```swift
// 粘贴到 Cursor 中，作为上下文
protocol NetworkServiceProtocol {
    func fetchUserProfile(userId: String) async throws -> UserProfileResponse
    func updateUserProfile(userId: String, data: UpdateProfileRequest) async throws -> UserProfileResponse
}

struct UserProfileResponse: Codable {
    let id: String
    let name: String
    let bio: String?
    let avatarURL: String?
}

// ... 其他依赖类型
```

### 步骤 3：小步重构 — 一次一个改进

采用"红-绿-重构"循环，每次只改一个点。

#### 3.1 第一步：提取魔法数字与硬编码

**提示词：**
```
请帮我重构以下代码，提取所有硬编码的常量：

[粘贴 ViewController 代码]

## 要求
1. 将魔法数字提取到文件顶部的 `private enum Constants`
2. 将 API endpoint 提取到 `enum API`
3. 将颜色/字体提取到 `enum Appearance`
4. 保持代码逻辑不变，只替换字面量为常量引用

## 输出
只输出修改后的常量定义部分，以及修改示例（不需要完整文件）。
```

**验证：**
```bash
# 编译检查
xcodebuild build -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 15'

# 运行现有测试
xcodebuild test -scheme YourApp -only-testing:YourAppTests/UserProfileTests

# 手动测试：运行 app，验证功能清单中的每一项
```

#### 3.2 第二步：提取独立方法

**提示词：**
```
以下代码中的 `saveButtonTapped()` 方法过长（300 行）。

[粘贴方法代码]

请将其拆分为多个职责单一的私有方法：
1. 验证表单数据 → `validateFormData() -> ValidationResult`
2. 准备请求参数 → `prepareUpdateRequest() -> UpdateProfileRequest`
3. 执行网络请求 → `performUpdateRequest(_:) async throws`
4. 处理成功响应 → `handleUpdateSuccess(_:)`
5. 处理错误 → `handleUpdateError(_:)`

要求：
- 每个方法不超过 30 行
- 使用清晰的命名
- 添加简短的文档注释说明职责
```

**验证：**
- 编译通过
- 所有测试通过
- 使用 SwiftLint 检查：`swiftlint lint --path UserProfileViewController.swift`
- 手动测试核心场景（如保存资料）

#### 3.3 第三步：提取业务逻辑到 ViewModel

**提示词：**
```
请将 UserProfileViewController 中的业务逻辑提取到新的 UserProfileViewModel。

## 上下文
[粘贴 refactoring-context.md 中的架构说明]

## 要求
1. 创建 `UserProfileViewModel` 类
2. 将数据获取、验证、更新逻辑移到 ViewModel
3. ViewModel 暴露 `@Published` 属性供 ViewController 订阅（使用 Combine）
4. ViewController 只负责 UI 更新与用户交互
5. ViewModel 通过协议依赖 NetworkService，便于测试

## 输出
1. 完整的 ViewModel 定义
2. 修改后的 ViewController（只保留 UI 代码）
3. ViewModel 的基础单元测试（测试数据获取与验证逻辑）
```

**验证标准：**
- ViewController 代码量减少 > 30%
- ViewModel 单元测试覆盖率 ≥ 80%
- 所有集成测试通过
- UI 行为与重构前完全一致（对照功能清单逐项验证）

#### 3.4 第四步：优化协议与依赖注入

**提示词：**
```
当前 UserProfileViewController 直接依赖具体类型（如 NetworkService）。
请重构为面向协议设计：

1. 定义 `UserProfileViewModelProtocol` 
2. ViewController 依赖协议而非具体 ViewModel
3. 通过初始化方法注入依赖（Dependency Injection）
4. 移除所有单例依赖（如 `NetworkService.shared`）

目标：让 ViewController 可以在单元测试中使用 Mock ViewModel。
```

### 步骤 4：验证与回归测试

每次小步重构后，执行完整验证：

#### 4.1 自动化验证清单

```bash
#!/bin/bash
# refactoring-verify.sh

echo "1. 编译检查..."
xcodebuild build -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 15' || exit 1

echo "2. 运行单元测试..."
xcodebuild test -scheme YourApp -only-testing:YourAppTests || exit 1

echo "3. SwiftLint 检查..."
swiftlint lint --path Sources/ --strict || exit 1

echo "4. 代码覆盖率..."
xcrun xccov view --report DerivedData/Logs/Test/*.xcresult

echo "✅ 所有检查通过！"
```

#### 4.2 手动验证清单

对照步骤 0.1 中的功能清单，逐项测试：
- [ ] 页面加载
- [ ] 编辑功能
- [ ] 头像上传
- [ ] 错误处理
- [ ] 边界情况

**重要**：重构后的行为必须与基线完全一致！

#### 4.3 性能对比

```swift
// 使用 Instruments 或简单计时对比重构前后性能
func testPerformance_viewDidLoad() {
    measure {
        let vc = UserProfileViewController()
        vc.loadViewIfNeeded()
    }
}
```

重构不应引入明显的性能衰退（允许 ±5% 波动）。

### 步骤 5：文档与 Code Review

#### 5.1 更新文档

重构完成后，更新相关文档：
```markdown
## 重构总结
- 重构模块：UserProfileViewController
- 代码行数：850 → 320 行（减少 62%）
- 测试覆盖率：15% → 68%
- 架构模式：MVC → MVVM

## 主要改进
1. 提取 UserProfileViewModel，包含数据获取与验证逻辑
2. 移除 350 行硬编码，提取到 Constants/API 枚举
3. 拆分 300 行的保存方法为 5 个职责单一的方法
4. 引入协议化依赖，支持单元测试 Mock

## 遗留问题
- [ ] 图片上传逻辑仍在 ViewController，计划下次重构
- [ ] 部分复杂 UI 布局代码未提取（风险较高，暂不动）
```

#### 5.2 提交 PR 前自查

- [ ] 所有测试通过
- [ ] SwiftLint 无 warning
- [ ] 代码覆盖率提升（量化数字）
- [ ] 提交信息清晰：`重构: 提取 UserProfileViewModel，优化依赖注入`
- [ ] PR 描述包含：
  - 重构动机
  - 改动范围
  - 验证方式
  - Before/After 对比（代码行数、测试覆盖率）

#### 5.3 Code Review 要点

请 Reviewer 重点关注：
- **行为等价性**：是否有未测试到的行为变化？
- **测试充分性**：新提取的 ViewModel 测试覆盖是否足够？
- **架构一致性**：是否符合项目既有的 MVVM 模式？
- **边界情况**：是否处理了 nil、空字符串、网络超时等？

### 步骤 6：持续集成到 CI

将重构验证加入 CI 流程：

```yaml
# .github/workflows/refactoring-check.yml
name: Refactoring Safety Check

on:
  pull_request:
    paths:
      - 'Sources/**/*.swift'

jobs:
  verify:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Tests
        run: |
          xcodebuild test \
            -scheme YourApp \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -enableCodeCoverage YES
      
      - name: Check Coverage
        run: |
          COVERAGE=$(xcrun xccov view --report DerivedData/Logs/Test/*.xcresult | grep 'YourApp.app' | awk '{print $4}')
          echo "Coverage: $COVERAGE"
          # 确保覆盖率不降低
          if (( $(echo "$COVERAGE < 60.0" | bc -l) )); then
            echo "❌ Coverage below 60%"
            exit 1
          fi
      
      - name: SwiftLint
        run: swiftlint lint --strict
```

## ✅ 验证清单

使用以下清单确保重构质量：

### 功能正确性
- [ ] 所有自动化测试通过
- [ ] 手动测试所有核心功能
- [ ] 边界情况与错误处理符合预期
- [ ] UI 表现与交互无变化

### 代码质量
- [ ] 代码行数减少 ≥ 30%（或职责更清晰）
- [ ] 单元测试覆盖率提升 ≥ 20 个百分点
- [ ] 无 SwiftLint warning
- [ ] 类/方法遵循单一职责原则

### 架构改进
- [ ] 依赖通过协议注入，而非硬编码
- [ ] 业务逻辑与 UI 逻辑分离
- [ ] 可测试性提升（可 Mock 所有依赖）
- [ ] 符合项目既有架构模式

### 风险控制
- [ ] 每次改动都有对应测试
- [ ] 提交历史清晰，可逐步回滚
- [ ] 性能无明显衰退（±5% 以内）
- [ ] 文档已更新（代码注释、架构文档）

## 🐛 常见问题

### Q1: AI 生成的重构代码编译失败

**原因**：AI 不了解项目的依赖关系或自定义类型。

**解决**：
1. 提供更完整的上下文（依赖类型定义、协议签名）
2. 分步生成：先生成接口定义，确认后再生成实现
3. 使用项目内搜索找到现有类似实现作为参考：
   ```
   请参考项目中的 LoginViewModel（[粘贴代码]）的风格，
   为 UserProfileViewController 生成类似的 ViewModel。
   ```

### Q2: 重构后测试通过，但手动测试发现 UI 错乱

**原因**：测试覆盖不足，未测试 UI 布局与交互。

**解决**：
1. 补充 UI 测试（使用 XCUITest）：
   ```swift
   func testUserProfile_editMode_showsSaveButton() {
       let app = XCUIApplication()
       app.launch()
       app.buttons["Edit"].tap()
       XCTAssertTrue(app.buttons["Save"].exists)
   }
   ```
2. 使用快照测试（Snapshot Testing）验证 UI 外观
3. 在 PR 中附上重构前后的截图对比

### Q3: ViewModel 过于复杂，难以测试

**原因**：一次性提取过多逻辑，导致 ViewModel 承担多个职责。

**解决**：
1. 继续拆分：将 ViewModel 中的独立功能提取为单独类
   ```
   UserProfileViewModel
   ├── ProfileValidator（表单验证）
   ├── ProfileUpdater（数据更新）
   └── AvatarUploader（头像上传）
   ```
2. 使用组合而非继承
3. 每个类单独测试，降低复杂度

### Q4: 重构导致性能下降

**原因**：引入过多抽象层或不必要的数据转换。

**解决**：
1. 使用 Instruments 定位性能瓶颈
2. 优化热路径（频繁调用的方法）：
   - 减少不必要的拷贝
   - 使用 lazy 延迟计算
   - 缓存计算结果
3. 权衡：有时为了清晰架构，牺牲 5% 性能是可接受的

### Q5: 如何处理与其他模块的耦合？

**原因**：ViewController 被其他模块直接引用，改动接口会影响调用方。

**解决**：
1. 保持公开 API 不变，只重构内部实现
2. 如需改接口，使用 `@available` 标记废弃：
   ```swift
   @available(*, deprecated, message: "Use init(viewModel:) instead")
   init(networkService: NetworkService) { ... }
   ```
3. 通知依赖方升级，给出迁移指南
4. 或使用 Adapter 模式保持兼容

## 🎓 最佳实践

### 1. 渐进式重构，不要 Big Bang

- ✅ 每次只改一个小点（提取常量、拆分方法、提取类）
- ✅ 每次改动都立即验证（编译 + 测试 + 手动检查）
- ❌ 一次性重写整个 ViewController（容易引入 bug）
- ❌ 连续多次改动后才验证（难以定位问题）

### 2. 测试先行，覆盖后重构

- ✅ 重构前先补充测试，建立基线
- ✅ 重构中每步都运行测试，确保等价
- ❌ 先重构再补测试（可能已经改变行为）
- ❌ 依赖手动测试（成本高、不可重复）

### 3. AI 生成代码需人工审查

AI 擅长识别模式和生成模板代码，但需要人工把关：
- **架构设计**：AI 的架构建议需结合项目实际评估
- **边界处理**：AI 可能遗漏 nil、空数组等边界情况
- **性能优化**：AI 生成的代码可读性高，但不一定最优
- **领域知识**：AI 不了解业务逻辑的隐含约束

### 4. 保留可回滚能力

- ✅ 每个小步重构单独提交（清晰的 commit 历史）
- ✅ 使用 feature flag 控制新代码生效（线上可快速切回）
- ✅ 保留旧代码一段时间（标记 deprecated）
- ❌ 一次提交包含多个不相关改动

### 5. 记录决策与权衡

在代码中或 PR 里记录重构决策：
```swift
// 注意：这里保留了原来的同步回调，而非改为 async/await，
// 因为 PaymentViewController 依赖这个回调时序。
// TODO: 等 Payment 模块重构后统一改为 async（Jira: IOS-1234）
@available(*, deprecated, message: "Use fetchUserAsync() instead")
func fetchUser(completion: @escaping (Result<User, Error>) -> Void) { ... }
```

## 📚 扩展阅读

### 重构理论
- [《Refactoring: Improving the Design of Existing Code》](https://martinfowler.com/books/refactoring.html) - Martin Fowler
- [重构代码的艺术](https://refactoring.guru/refactoring) - 中文重构模式目录

### Swift/iOS 特定实践
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/) - Apple 官方指南
- [Point-Free: Modern UIKit](https://www.pointfree.co/collections/uikit) - 现代化 UIKit 实践
- [iOS Architecture: MVVM in Practice](https://www.vadimbulavin.com/swift-mvvm-pattern/)

### 测试驱动重构
- [《Working Effectively with Legacy Code》](https://www.oreilly.com/library/view/working-effectively-with/0131177052/) - Michael Feathers
- [iOS Unit Testing by Example](https://pragprog.com/titles/jrlegios/ios-unit-testing-by-example/)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md) - 重构前建立测试基线
- [使用 AI 进行代码 Review](./ai-code-review.md)（计划中）- 重构后的 Code Review
- [API 接口自动生成 Mock](./api-mock-generation.md)（计划中）- 提升 ViewModel 可测试性

## 🔗 相关提示词

- [提取业务逻辑到 ViewModel](../prompts/refactoring/extract-viewmodel.md)
- [优化 UIViewController 布局代码](../prompts/refactoring/optimize-layout.md)
- [重构为协议化设计](../prompts/refactoring/protocol-oriented.md)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-29  
**适用工具**：Cursor、Claude Code、GitHub Copilot
