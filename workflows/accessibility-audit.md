# 工作流：iOS 无障碍审计与修复

## 📋 背景

iOS 无障碍支持（Accessibility）不仅是产品的社会责任，也是 App Store 审核的关注点。常见问题包括：
- VoiceOver 用户无法识别关键按钮用途
- 动态字体（Dynamic Type）下布局错乱
- 颜色对比度不足，弱视用户难以阅读
- 触控目标过小，肢体障碍用户难以点击
- 动画未适配 Reduce Motion 选项，引发眩晕

传统人工审计需要逐屏测试 VoiceOver、调整系统字体大小、开启辅助功能选项，耗时且容易遗漏。使用 AI 辅助审计，可以快速扫描代码，发现常见问题，并生成修复建议。

## 🎯 目标

对指定 iOS 模块进行无障碍审计，达到以下标准：
- **VoiceOver 友好**：所有交互元素有准确的 accessibilityLabel/Hint/Traits
- **Dynamic Type 支持**：文本使用系统字体，布局适配大字号
- **对比度达标**：文本与背景对比度 ≥ 4.5:1（WCAG AA 级）
- **触控目标充足**：可点击元素尺寸 ≥ 44×44 pt
- **动画适配**：响应 Reduce Motion 设置

## 🛠️ 适用场景

- ✅ App Store 上线前无障碍合规检查
- ✅ 重构旧代码时补充无障碍支持
- ✅ 为企业级应用添加 WCAG 2.1 合规能力
- ❌ 不适合复杂自定义控件的细粒度审计（需专业工具如 Accessibility Inspector）
- ❌ 不适合替代真人测试（应结合 VoiceOver 实测）

## 📝 工作流步骤

### 步骤 1：准备审计上下文

#### 1.1 确定审计范围
在 Cursor 中打开目标模块代码：
```bash
# 示例：审计登录模块
# LoginViewController.swift (UIKit)
# 或 LoginView.swift (SwiftUI)
```

#### 1.2 准备上下文文档
创建 `accessibility-context.md`，包含：
```markdown
## 审计目标
- 模块：登录流程（LoginViewController + InputFieldView）
- 技术栈：UIKit / SwiftUI / 混合
- 系统要求：iOS 15+

## 现有无障碍实现
[粘贴已有的 accessibilityLabel 设置代码，如果有的话]

## 设计稿信息
- 主题色：#007AFF（蓝色）
- 背景色：#FFFFFF（白色）
- 错误提示色：#FF3B30（红色）
```

### 步骤 2：静态代码审计

使用提示词让 AI 扫描代码：

```
我需要对以下 iOS 代码进行无障碍审计。

## 审计维度
1. VoiceOver 支持：
   - 检查所有 UIButton、自定义控件是否设置 accessibilityLabel
   - 检查图标按钮是否有文字说明
   - 检查复杂视图是否正确设置 accessibilityElements 顺序

2. Dynamic Type 支持：
   - 检查 UILabel/UITextView 是否使用 UIFont.preferredFont
   - 检查固定高度约束是否会在大字号下截断文本

3. 对比度检查：
   - 列出所有文本颜色与背景色组合
   - 计算对比度比值，标记 < 4.5:1 的情况

4. 触控目标：
   - 检查所有可点击元素的 frame/bounds 设置
   - 标记尺寸 < 44×44 pt 的按钮

5. 动画适配：
   - 检查动画代码是否判断 UIAccessibility.isReduceMotionEnabled

## 输出格式
请以表格形式输出问题清单：
| 文件:行号 | 问题类型 | 严重程度 | 问题描述 | 修复建议 |
```

### 步骤 3：分析审计报告

AI 会输出类似以下报告：

| 文件:行号 | 问题类型 | 严重程度 | 问题描述 | 修复建议 |
|-----------|----------|----------|----------|----------|
| LoginViewController.swift:45 | VoiceOver | 高 | 登录按钮无 accessibilityLabel | 添加：`button.accessibilityLabel = "登录"` |
| InputFieldView.swift:23 | Dynamic Type | 中 | 使用固定字体 UIFont.systemFont(ofSize: 14) | 改用 `UIFont.preferredFont(forTextStyle: .body)` |
| Theme.swift:12 | 对比度 | 高 | 灰色文本(#999999)在白底对比度仅 2.8:1 | 改为 #666666（对比度 5.7:1）|
| ActionButton.swift:67 | 触控目标 | 中 | 图标按钮尺寸 30×30 pt | 增加 padding 或扩大 hitTest 范围至 44×44 |
| AnimatedBanner.swift:89 | Reduce Motion | 低 | 横幅动画未判断系统设置 | 添加 `if !UIAccessibility.isReduceMotionEnabled { ... }` |

**人工审查要点：**
- 严重程度为"高"的问题必须修复
- "中"级问题根据产品优先级决定
- 对比度计算可用工具验证：[WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)

### 步骤 4：生成修复代码

针对审计报告中的问题，逐项生成修复代码：

```
针对审计报告中的问题，请生成完整的修复代码。

## 要求
1. 为每个问题生成可直接复制的代码片段
2. 注明文件名和插入位置
3. 如果涉及重构，提供前后对比

## 优先处理
- 严重程度"高"的问题
- 修复成本低但影响大的问题（如添加 accessibilityLabel）

## 代码风格
- UIKit：使用 lazy var 或 setupAccessibility() 方法集中配置
- SwiftUI：使用 .accessibilityLabel() 等修饰符
- 遵循项目现有代码规范
```

### 步骤 5：实施修复

#### 5.1 UIKit 修复示例

**问题**：登录按钮无 accessibilityLabel

```swift
// ❌ 修复前
let loginButton = UIButton(type: .system)
loginButton.setTitle("", for: .normal) // 纯图标按钮
loginButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)

// ✅ 修复后
let loginButton = UIButton(type: .system)
loginButton.setTitle("", for: .normal)
loginButton.setImage(UIImage(systemName: "arrow.right"), for: .normal)
loginButton.accessibilityLabel = "登录"
loginButton.accessibilityTraits = .button
loginButton.accessibilityHint = "点按以提交用户名和密码"
```

**问题**：固定字体未支持 Dynamic Type

```swift
// ❌ 修复前
titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)

// ✅ 修复后
titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
titleLabel.adjustsFontForContentSizeCategory = true
```

**问题**：触控目标过小

```swift
// ❌ 修复前
iconButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)

// ✅ 修复后（方案一：扩大 frame）
iconButton.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
iconButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)

// ✅ 修复后（方案二：扩大点击区域）
class TappableButton: UIButton {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expandedBounds = bounds.insetBy(dx: -7, dy: -7)
        return expandedBounds.contains(point)
    }
}
```

#### 5.2 SwiftUI 修复示例

**问题**：自定义按钮无无障碍标签

```swift
// ❌ 修复前
Image(systemName: "heart.fill")
    .onTapGesture { toggleFavorite() }

// ✅ 修复后
Image(systemName: "heart.fill")
    .onTapGesture { toggleFavorite() }
    .accessibilityLabel("收藏")
    .accessibilityHint("点按以添加或移除收藏")
    .accessibilityAddTraits(.isButton)
```

**问题**：动画未适配 Reduce Motion

```swift
// ❌ 修复前
.transition(.scale)
.animation(.spring(), value: isPresented)

// ✅ 修复后
@Environment(\.accessibilityReduceMotion) var reduceMotion

// 在视图中使用
.transition(reduceMotion ? .opacity : .scale)
.animation(reduceMotion ? .none : .spring(), value: isPresented)
```

**问题**：颜色对比度不足

```swift
// ❌ 修复前
Text("次要信息")
    .foregroundColor(Color(hex: "#999999")) // 对比度 2.8:1

// ✅ 修复后
Text("次要信息")
    .foregroundColor(.secondary) // 系统自适应颜色
    // 或手动指定高对比度色
    .foregroundColor(Color(hex: "#666666")) // 对比度 5.7:1
```

### 步骤 6：验证修复效果

#### 6.1 代码编译检查
```bash
# 确保代码编译通过
xcodebuild build -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

#### 6.2 Accessibility Inspector 验证
1. 在 Xcode 中打开 Accessibility Inspector（Xcode → Open Developer Tool → Accessibility Inspector）
2. 运行模拟器，选择目标应用
3. 使用 Inspection 模式逐个检查修复的元素：
   - Label 是否正确显示
   - Traits 是否准确（Button、Image、StaticText 等）
   - Frame 尺寸是否 ≥ 44×44 pt

#### 6.3 VoiceOver 真机测试
```
1. 在 iPhone 上开启 VoiceOver（设置 → 辅助功能 → VoiceOver）
2. 浏览修复后的界面，确认：
   - 每个元素都能被 VoiceOver 识别
   - 朗读内容清晰易懂（不是 "Button" "Image" 这种无意义文本）
   - 操作顺序符合逻辑（从上到下、从左到右）
```

#### 6.4 Dynamic Type 测试
```
1. 打开模拟器，设置 → 辅助功能 → 显示与文字大小 → 更大字体
2. 拖动滑块到最大
3. 返回应用，检查：
   - 文本是否正确放大
   - 布局是否错乱（文字被截断、控件重叠）
   - 可滚动区域是否自动适配
```

#### 6.5 对比度工具验证
使用在线工具或 Xcode Color Contrast Calculator：
```bash
# 在 macOS 终端计算对比度
# 需要安装 https://github.com/dmargolis/color-contrast-calc
color-contrast-calc "#666666" "#FFFFFF"
# 输出：5.74:1 (AA Pass)
```

### 步骤 7：集成到 CI

#### 7.1 自动化静态检查
创建 SwiftLint 自定义规则检查无障碍：

```yaml
# .swiftlint.yml
custom_rules:
  accessibility_label_for_buttons:
    name: "Accessibility Label Required"
    regex: '(UIButton|Button)\(.*\)(?!.*accessibilityLabel)'
    message: "交互元素应设置 accessibilityLabel"
    severity: warning
```

#### 7.2 UI 自动化测试
添加 XCUITest 验证无障碍属性：

```swift
func testLoginButtonAccessibility() {
    let loginButton = app.buttons["登录"]
    
    XCTAssertTrue(loginButton.exists)
    XCTAssertEqual(loginButton.label, "登录")
    XCTAssertTrue(loginButton.isAccessibilityElement)
    
    // 验证触控目标尺寸
    let frame = loginButton.frame
    XCTAssertGreaterThanOrEqual(frame.width, 44)
    XCTAssertGreaterThanOrEqual(frame.height, 44)
}
```

## ✅ 验证清单

使用以下清单确保工作流完成：

- [ ] 所有交互元素（按钮、链接、输入框）有 accessibilityLabel
- [ ] 纯图标按钮添加了文字说明
- [ ] 所有文本使用 Dynamic Type（preferredFont 或 SwiftUI 默认字体）
- [ ] 所有文本与背景对比度 ≥ 4.5:1（使用工具验证）
- [ ] 所有可点击元素触控目标 ≥ 44×44 pt
- [ ] 动画代码判断 isReduceMotionEnabled 或使用系统自适应动画
- [ ] Accessibility Inspector 扫描无警告
- [ ] VoiceOver 真机测试可流畅完成核心流程
- [ ] 已添加 XCUITest 覆盖关键无障碍属性

## 🐛 常见问题

### Q1: AI 建议的 accessibilityLabel 过于啰嗦

**原因**：AI 可能生成类似 "这是一个用于提交表单的登录按钮" 的冗余文本。

**解决**：
- VoiceOver 会自动朗读元素类型（"按钮"），Label 只需说明用途
- ✅ 好的示例：`accessibilityLabel = "登录"`
- ❌ 冗余示例：`accessibilityLabel = "登录按钮"`

**提示词优化**：
```
生成 accessibilityLabel 时，遵循以下原则：
1. 简洁，只说明用途（动词+名词）
2. 不要重复元素类型（按钮、图片、文本）
3. 参考 Apple 官方应用的风格（如邮件、设置）
```

### Q2: Dynamic Type 下布局破坏

**原因**：使用固定高度约束，文本放大后被截断。

**解决**：
```swift
// ❌ 错误：固定高度
titleLabel.heightAnchor.constraint(equalToConstant: 30)

// ✅ 正确：基于内容的动态高度
titleLabel.numberOfLines = 0
titleLabel.setContentHuggingPriority(.required, for: .vertical)

// 或使用 Stack View 自动布局
stackView.axis = .vertical
stackView.spacing = 8
```

### Q3: 对比度计算与实际视觉不符

**原因**：
1. 未考虑透明度叠加（如半透明遮罩上的文字）
2. 未考虑 Dark Mode 下的颜色差异

**解决**：
```swift
// 使用系统语义颜色，自动适配 Light/Dark Mode 和对比度
label.textColor = .label           // 主要文本
label.textColor = .secondaryLabel  // 次要文本（自动保证对比度）

// SwiftUI
Text("内容")
    .foregroundColor(.primary)  // 系统自适应
```

### Q4: 自定义控件 VoiceOver 无法识别

**原因**：自定义 UIView 默认 `isAccessibilityElement = false`。

**解决**：
```swift
class CustomButton: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
    }
    
    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityLabel = "分享"
        accessibilityTraits = .button
        // 如果有多个子视图需要合并朗读
        accessibilityElements = [iconView, titleLabel].compactMap { $0 }
    }
}
```

## 🎓 最佳实践

### 1. 优先使用系统组件
- ✅ UIButton、UILabel、SwiftUI 原生控件自带基础无障碍支持
- ✅ 系统颜色（.label、.systemBackground）自动适配对比度
- ❌ 避免过度自定义，除非有明确设计需求

### 2. 无障碍属性集中配置
```swift
// UIKit：在 setupUI() 后调用 setupAccessibility()
private func setupAccessibility() {
    loginButton.accessibilityLabel = "登录"
    usernameField.accessibilityLabel = "用户名"
    // ... 其他配置
}

// SwiftUI：使用 ViewModifier 复用
extension View {
    func primaryButton(label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }
}
```

### 3. 定期进行真人测试
- 邀请使用 VoiceOver 的用户参与 Beta 测试
- 记录真实用户遇到的困难，反馈到设计与开发流程
- AI 审计 + 真人测试才能保证真正可用

### 4. 建立团队规范
在团队的 `.cursor/rules` 中添加：
```markdown
## 无障碍开发规范
- 所有 PR 必须通过 Accessibility Inspector 扫描
- 新增交互元素必须设置 accessibilityLabel
- 禁止使用固定字体大小，必须使用 Dynamic Type
- 颜色选择参考 Apple HIG 的对比度指南
```

## 📚 扩展阅读

- [Apple Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/overview/)
- [WCAG 2.1 标准（Web 内容无障碍指南）](https://www.w3.org/WAI/WCAG21/quickref/)
- [Accessibility Inspector 使用指南](https://developer.apple.com/library/archive/documentation/Accessibility/Conceptual/AccessibilityMacOSX/OSXAXTestingApps.html)
- [iOS Accessibility Programming Guide](https://developer.apple.com/documentation/uikit/accessibility)
- [Color Contrast Checker (WebAIM)](https://webaim.org/resources/contrastchecker/)

## 🔗 相关工作流

- [使用 AI 进行代码 Review](./ai-code-review.md) - 可集成无障碍检查项
- [SwiftUI 视图快速原型](./swiftui-prototyping.md) - 原型阶段即考虑无障碍设计
- [重构遗留 UIKit 代码](./uikit-refactoring.md) - 重构时补充无障碍支持

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-31  
**适用工具**：Cursor、Claude Code、GitHub Copilot、Xcode Accessibility Inspector
