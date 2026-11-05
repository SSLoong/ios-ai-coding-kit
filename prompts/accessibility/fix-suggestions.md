# 无障碍问题修复建议生成

## 场景说明
针对已识别的无障碍问题，生成具体的代码修复建议，包括 UIKit 和 SwiftUI 两种技术栈的实现方案。

## 输入要求
- **必需**：问题描述（来自审计报告或手动发现）
- **必需**：相关代码片段
- **可选**：技术栈（UIKit / SwiftUI / 混合）
- **可选**：项目约束（如最低系统版本、是否使用 Auto Layout）

## 提示词模板

```
请为以下无障碍问题生成详细的修复建议。

## 问题描述
[描述问题，例如：登录按钮无 accessibilityLabel，VoiceOver 用户无法识别其用途]

## 当前代码
[粘贴相关代码片段]

## 技术栈
- [ ] UIKit
- [ ] SwiftUI
- [ ] 混合（UIKit + SwiftUI）

## 项目约束
- 最低系统版本：iOS [版本号]
- 布局方式：Auto Layout / Frame-based / SwiftUI
- 特殊要求：[如需兼容旧代码风格、有特定的无障碍测试框架等]

## 修复要求

### 1. 提供完整代码
- 给出修复前后的代码对比
- 注明文件名和具体行号（如果已知）
- 代码可直接复制粘贴，无需额外修改

### 2. 说明修复原理
- 解释为什么这样修复可以解决问题
- 如果有多种方案，说明各方案的优劣

### 3. 验证方法
- 说明如何用 Accessibility Inspector 验证
- 提供 VoiceOver 操作步骤验证修复效果
- 如适用，提供 XCUITest 测试代码

### 4. 最佳实践建议
- 是否有更优雅的实现方式？
- 是否需要同步修改其他相似代码？
- 是否需要更新团队编码规范？

## 输出格式

### 修复方案
#### 方案一：[简述方案名称]
**适用场景**：[何时使用此方案]

**修复前代码**：
\`\`\`swift
[原始代码]
\`\`\`

**修复后代码**：
\`\`\`swift
[修复后的代码，包含注释说明关键改动]
\`\`\`

**修复说明**：
[解释修复原理和工作机制]

**验证步骤**：
1. [Accessibility Inspector 验证步骤]
2. [VoiceOver 真机测试步骤]
3. [其他验证方式]

**优点**：
- [优点 1]
- [优点 2]

**缺点**（如有）：
- [缺点 1]

#### 方案二：[如有替代方案]
[同上结构]

### 相关改进建议
- [是否需要在其他地方应用相同修复？]
- [是否需要创建可复用的辅助方法或扩展？]
- [是否需要更新 UI 组件库？]
```

## 使用示例

### 输入
**问题描述**：登录按钮触控目标仅 60×30 pt，不满足 44×44 pt 最小标准

**当前代码**：
```swift
let loginButton = UIButton(type: .system)
loginButton.frame = CGRect(x: 150, y: 300, width: 60, height: 30)
loginButton.setTitle("登录", for: .normal)
```

**技术栈**：UIKit  
**项目约束**：最低 iOS 14，使用 Frame-based 布局

### 输出（期望）

#### 方案一：扩大 Button Frame（推荐）
**适用场景**：布局允许增大按钮尺寸，且视觉设计可接受

**修复前代码**：
```swift
let loginButton = UIButton(type: .system)
loginButton.frame = CGRect(x: 150, y: 300, width: 60, height: 30)
loginButton.setTitle("登录", for: .normal)
```

**修复后代码**：
```swift
let loginButton = UIButton(type: .system)
// 将按钮尺寸调整为 76×44 pt（满足最小触控目标）
loginButton.frame = CGRect(x: 142, y: 293, width: 76, height: 44)
loginButton.setTitle("登录", for: .normal)

// 可选：如果希望视觉上保持原尺寸，使用 contentEdgeInsets 内缩
// loginButton.contentEdgeInsets = UIEdgeInsets(top: 7, left: 8, bottom: 7, right: 8)
```

**修复说明**：
- 将 Button 的 frame 从 60×30 调整为 76×44，确保高度 ≥ 44 pt
- 同时调整 x/y 坐标保持按钮视觉居中（假设原意图是居中）
- 如果设计要求视觉尺寸保持不变，可通过 `contentEdgeInsets` 让标题文字区域小于整个按钮，点击区域仍为 76×44

**验证步骤**：
1. **Accessibility Inspector**：
   - 打开 Xcode → Accessibility Inspector
   - 选择模拟器运行的应用
   - 点击 loginButton，查看 Frame 属性，确认 width ≥ 44 且 height ≥ 44
2. **真机测试**：
   - 在 iPhone 上运行应用，开启"设置 → 辅助功能 → 触控 → 震动触感"
   - 尝试在按钮边缘点击，确认可正常触发
3. **XCUITest**：
```swift
func testLoginButtonHitArea() {
    let loginButton = app.buttons["登录"]
    XCTAssertGreaterThanOrEqual(loginButton.frame.width, 44)
    XCTAssertGreaterThanOrEqual(loginButton.frame.height, 44)
}
```

**优点**：
- 实现简单，只需修改 frame
- 符合 Apple HIG 最佳实践
- 真实触控区域与视觉尺寸一致，用户体验最佳

**缺点**：
- 如果布局空间紧张，可能与其他元素重叠（需调整其他控件位置）

---

#### 方案二：重写 point(inside:with:) 扩大点击区域
**适用场景**：布局空间受限，无法扩大按钮 frame，但需保证触控目标达标

**修复后代码**：
```swift
class AccessibleButton: UIButton {
    /// 最小触控区域尺寸（遵循 Apple HIG）
    private let minimumHitArea: CGSize = CGSize(width: 44, height: 44)
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // 计算需要扩展的边距
        let dx = max(0, (minimumHitArea.width - bounds.width) / 2)
        let dy = max(0, (minimumHitArea.height - bounds.height) / 2)
        
        // 扩展点击区域
        let expandedBounds = bounds.insetBy(dx: -dx, dy: -dy)
        return expandedBounds.contains(point)
    }
}

// 使用
let loginButton = AccessibleButton(type: .system)
loginButton.frame = CGRect(x: 150, y: 300, width: 60, height: 30)
loginButton.setTitle("登录", for: .normal)
```

**修复说明**：
- 创建自定义 `AccessibleButton` 类，重写 `point(inside:with:)`
- 当按钮尺寸 < 44×44 时，自动向外扩展点击区域至最小标准
- 视觉尺寸保持 60×30，但实际可点击区域为 60×44（高度扩展 7pt × 2）

**验证步骤**：
1. **调试验证**：
```swift
// 在 point(inside:with:) 方法中打断点，点击按钮边缘，查看 expandedBounds 范围
print("Original bounds: \(bounds), Expanded bounds: \(expandedBounds)")
```
2. **真机测试**：在按钮上下左右边缘外 5pt 处点击，确认可触发
3. **Accessibility Inspector**：Frame 仍显示 60×30（这是预期行为），但实际触控生效

**优点**：
- 不影响布局和视觉设计
- 可复用于整个项目（定义为基类或扩展）
- 动态适配任意尺寸的按钮

**缺点**：
- 点击区域大于视觉区域，可能与相邻元素的触控区域重叠（需手动检查）
- Accessibility Inspector 不会显示扩展后的真实触控区域（需真机验证）

---

#### 方案三：SwiftUI 实现（如项目使用 SwiftUI）
**修复后代码**：
```swift
Button("登录") {
    // 登录操作
}
.frame(width: 60, height: 30) // 视觉尺寸
.contentShape(Rectangle()) // 确保整个 frame 可点击
.frame(minWidth: 44, minHeight: 44) // 扩展到最小触控目标
.background(Color.blue)
```

**修复说明**：
- 使用 `.frame(minWidth:minHeight:)` 确保触控区域 ≥ 44×44
- 内层 `.frame(width:height:)` 控制视觉尺寸（可选）
- `.contentShape()` 确保整个区域可响应点击

**验证步骤**：
- 在 SwiftUI Preview 中开启 Accessibility Inspector
- 使用 VoiceOver 测试真机

---

### 相关改进建议

#### 1. 创建可复用的 UIButton 扩展
```swift
extension UIButton {
    /// 确保按钮满足最小触控目标
    func ensureMinimumHitArea() {
        // 如果当前 frame 小于 44×44，自动扩展
        // （实现同方案二的 point(inside:with:) 逻辑）
    }
}

// 在 UIButton 初始化后统一调用
loginButton.ensureMinimumHitArea()
```

#### 2. 集成到 UI 组件库
- 如果项目有自定义 Button 基类，将方案二的逻辑集成进去
- 所有按钮自动继承无障碍友好的触控目标处理

#### 3. 添加 SwiftLint 规则
```yaml
# .swiftlint.yml
custom_rules:
  minimum_button_size:
    regex: 'UIButton.*frame.*CGRect\(.*width:\s*([0-9]+).*height:\s*([0-9]+)'
    message: "Button 尺寸应 ≥ 44×44 pt 或使用 AccessibleButton"
    severity: warning
```

#### 4. 更新团队编码规范
在团队文档中添加：
> 所有可交互元素（UIButton、自定义手势识别器）的触控目标必须 ≥ 44×44 pt。
> - 优先使用 `AccessibleButton` 基类
> - 或在布局时预留足够空间
> - 代码 Review 时需检查 Accessibility Inspector 报告

## 注意事项

### 1. 方案选择原则
- **优先方案一**（扩大 frame）：最符合 Apple 原生体验
- **方案二**（扩展点击区域）：适合遗留代码重构，改动最小
- **方案三**（SwiftUI）：适合新项目或 SwiftUI 模块

### 2. 避免过度扩展
- 触控目标不是越大越好，过大可能导致误触
- 相邻按钮的扩展区域不应重叠（通过调整间距解决）

### 3. 与设计师沟通
- 触控目标调整可能影响视觉布局，需提前与设计师对齐
- 建议在设计阶段就按 44×44 pt 标准规划控件尺寸

### 4. 测试覆盖
- 在 XCUITest 中添加触控目标检查
- 集成到 CI 流程，防止后续改动引入回归
