# 无障碍审计清单生成

## 场景说明
为 iOS 视图控制器或 SwiftUI 视图生成完整的无障碍审计清单，覆盖 VoiceOver、Dynamic Type、对比度、触控目标、Reduce Motion 等维度。

## 输入要求
- **必需**：目标代码文件（UIViewController、SwiftUI View 或自定义控件）
- **可选**：设计稿中的颜色值、现有的无障碍配置代码

## 提示词模板

```
请为以下 iOS 代码生成无障碍审计清单。

## 代码内容
[粘贴 Swift 代码]

## 审计维度

### 1. VoiceOver 支持
检查项：
- [ ] 所有 UIButton / Button 是否设置了 accessibilityLabel？
- [ ] 纯图标按钮是否有文字说明（非 "Button" 或空字符串）？
- [ ] UIImageView / Image 如果作为信息传递（非装饰），是否设置 accessibilityLabel？
- [ ] 自定义控件是否正确设置 isAccessibilityElement = true？
- [ ] 复杂视图是否配置了 accessibilityElements 数组来控制朗读顺序？
- [ ] 是否使用了合适的 accessibilityTraits（.button、.image、.header 等）？
- [ ] 是否为非明显操作添加了 accessibilityHint？

### 2. Dynamic Type 支持
检查项：
- [ ] UILabel / Text 是否使用 UIFont.preferredFont 或 SwiftUI 默认字体？
- [ ] 是否设置了 adjustsFontForContentSizeCategory = true（UIKit）？
- [ ] 固定高度约束是否会导致大字号下文本被截断？
- [ ] numberOfLines 是否设置为 0（允许多行）或足够大的值？
- [ ] ScrollView / List 内容是否能随字体放大自动扩展？

### 3. 颜色对比度
检查项：
- [ ] 列出所有文本颜色与背景色组合
- [ ] 计算每组对比度（使用 WebAIM Contrast Checker）
- [ ] 标记对比度 < 4.5:1 的组合（正常文本）或 < 3:1（大号文本 ≥ 18pt）
- [ ] 是否使用了系统语义颜色（.label、.secondaryLabel、.systemBackground）？
- [ ] 是否考虑了 Dark Mode 下的颜色对比度？

### 4. 触控目标尺寸
检查项：
- [ ] 所有可点击元素（按钮、链接、手势识别器）的尺寸是否 ≥ 44×44 pt？
- [ ] 如果视觉尺寸 < 44×44，是否通过以下方式扩大点击区域：
  - 使用 contentEdgeInsets（UIButton）
  - 重写 point(inside:with:) 方法
  - 使用 .contentShape() 修饰符（SwiftUI）
- [ ] 相邻可点击元素之间是否有足够间距（建议 ≥ 8pt）？

### 5. Reduce Motion 适配
检查项：
- [ ] UIView.animate、CAAnimation 是否判断 UIAccessibility.isReduceMotionEnabled？
- [ ] SwiftUI 动画是否读取 @Environment(\.accessibilityReduceMotion)？
- [ ] 是否为关键动画提供了静态替代方案（如淡入淡出）？
- [ ] 自动播放的动画是否默认禁用或提供关闭选项？

### 6. 其他无障碍最佳实践
检查项：
- [ ] 是否使用了语义化的 accessibilityTraits（避免全部标记为 .button）？
- [ ] 是否为状态变化提供了语音反馈（如 UIAccessibility.post(notification:argument:)）？
- [ ] 输入框是否设置了 accessibilityValue 来朗读当前内容？
- [ ] 是否测试了横竖屏切换下的无障碍体验？

## 输出格式

### 审计报告
以表格形式输出发现的问题：

| 文件:行号 | 问题类型 | 严重程度 | 问题描述 | 修复建议 |
|-----------|----------|----------|----------|----------|
| [自动填充] | [自动填充] | 高/中/低 | [自动填充] | [自动填充] |

### 优先级说明
- **高**：严重影响无障碍用户使用（如关键按钮无法识别）
- **中**：影响用户体验但有替代方案（如对比度稍低）
- **低**：可改进但非必需（如 Hint 缺失但 Label 已足够清晰）

### 汇总统计
- 发现问题总数：[数字]
- 高优先级：[数字]
- 中优先级：[数字]
- 低优先级：[数字]
- 预计修复工作量：[小/中/大]
```

## 使用示例

### 输入
```swift
class LoginViewController: UIViewController {
    let logoImageView = UIImageView(image: UIImage(named: "logo"))
    let usernameField = UITextField()
    let loginButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        logoImageView.frame = CGRect(x: 100, y: 100, width: 120, height: 120)
        
        usernameField.placeholder = "用户名"
        usernameField.font = UIFont.systemFont(ofSize: 16)
        
        loginButton.setTitle("登录", for: .normal)
        loginButton.frame = CGRect(x: 150, y: 300, width: 60, height: 30)
        loginButton.backgroundColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0) // #999999
        loginButton.setTitleColor(.white, for: .normal)
    }
}
```

### 输出（期望）
| 文件:行号 | 问题类型 | 严重程度 | 问题描述 | 修复建议 |
|-----------|----------|----------|----------|----------|
| LoginViewController.swift:2 | VoiceOver | 中 | logoImageView 未设置 accessibilityLabel，VoiceOver 用户无法了解这是应用 Logo | 如果是装饰性图片，设置 `logoImageView.isAccessibilityElement = false`；如果传递信息，设置 `logoImageView.accessibilityLabel = "应用名称"` |
| LoginViewController.swift:3 | VoiceOver | 低 | usernameField 未显式设置 accessibilityLabel，但 placeholder 可作为默认 Label | 建议显式设置 `usernameField.accessibilityLabel = "用户名"` 以保证跨系统版本一致性 |
| LoginViewController.swift:12 | Dynamic Type | 高 | usernameField 使用固定字体大小 16，不支持 Dynamic Type | 改用 `UIFont.preferredFont(forTextStyle: .body)` 并设置 `adjustsFontForContentSizeCategory = true` |
| LoginViewController.swift:14-16 | 触控目标 | 高 | loginButton 尺寸 60×30 pt，小于最小触控目标 44×44 pt | 将 frame 改为至少 `CGRect(x: 142, y: 293, width: 76, height: 44)` |
| LoginViewController.swift:15-16 | 对比度 | 高 | 灰色背景(#999999)与白色文字对比度约 2.8:1，不满足 WCAG AA 标准（需 ≥ 4.5:1）| 改用深色背景（如 `UIColor.systemBlue`）或深色文字 |

**汇总统计**
- 发现问题总数：5
- 高优先级：3（Dynamic Type、触控目标、对比度）
- 中优先级：1（Logo 无障碍标签）
- 低优先级：1（输入框标签）
- 预计修复工作量：小（约 30 分钟）

## 注意事项

### 1. 对比度计算需借助工具
AI 可以识别颜色代码并标记潜在问题，但精确计算需使用：
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Xcode Color Contrast Calculator（需 macOS）
- 浏览器插件（如 WCAG Contrast Checker）

### 2. 不能完全替代真人测试
AI 审计擅长发现**静态代码问题**，但无法检测：
- VoiceOver 朗读的实际体验（语速、停顿、歧义）
- 复杂交互流程的逻辑合理性
- 多语言环境下的无障碍适配

建议流程：**AI 审计（快速筛查）→ 修复 → Accessibility Inspector 验证 → VoiceOver 真人测试**

### 3. 优先级判断需结合产品
- 电商应用：支付流程的无障碍支持为"高"优先级
- 内容阅读应用：Dynamic Type 和对比度为"高"优先级
- 工具类应用：关键功能按钮的 VoiceOver 支持为"高"优先级

### 4. 与现有工作流集成
- 在代码 Review 阶段使用此提示词生成清单
- 将审计清单作为 PR 描述的一部分
- 定期（如每个季度）对核心模块进行全量审计
