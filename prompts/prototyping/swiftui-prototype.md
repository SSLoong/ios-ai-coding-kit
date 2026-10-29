# SwiftUI 视图快速原型提示词

## 场景说明

从产品需求、界面描述或设计稿说明生成**可编译、可 Preview** 的 SwiftUI 视图骨架，并支持补充布局、状态与简单交互。适用于评审 Demo，不替代完整业务开发。

## 输入要求

### 必需

- 界面目标与用户故事（1–3 句）
- 设计约束：色板/字体/间距规则，或项目 DesignSystem 文件引用
- 技术约束：最低 iOS 版本、状态管理方案（`@State` / `@Observable` / ViewModel）
- 导航上下文：所在 Tab、Push/Sheet 方式

### 可选

- Figma 节点文字描述或截图说明
- 现有可复用组件列表（路径或源码）
- 数据模型字段与空态/错误态规则
- 相近页面的代码风格参考

---

## 提示词模板 A：从需求生成 View 骨架

```
我需要为 iOS 应用生成 SwiftUI 视图原型（非完整业务实现）。

## 界面需求
[描述页面结构、主要区块、用户操作]

## 设计约束
- 色板/字体：[Design token 或具体值]
- 间距与圆角：[数值]
- 图标：SF Symbols 名称（如适用）

## 工程约束
- 最低 iOS：[例如 17]
- 架构：[SwiftUI + @Observable ViewModel / 纯 View + @State]
- 导航：[NavigationStack / Sheet / 全屏]
- 可复用组件：[组件名与职责]

## 数据（原型阶段）
- 展示模型字段：[字段列表]
- 使用静态 fixture，不要调用真实网络 API

## 输出要求
1. **先输出** Markdown 计划，包含：
   - 组件树（主 View 与子 View）
   - UI 状态枚举（如 loading / empty / content / error）
   - 建议文件列表
   - Preview 场景列表（至少 3 个）
2. 等我确认计划后，再生成 Swift 代码。
3. 代码要求：
   - 每个公开 View 提供 `#Preview`（iOS 17+）或 `PreviewProvider`
   - 避免 force unwrap；用户文案考虑本地化占位
   - 主 View body 保持精简，复杂区块拆子 View
   - 在文件顶部用注释说明「原型范围」与 TODO 项

## 附加上下文
[粘贴 DesignSystem、相近 View、或模型定义]
```

---

## 提示词模板 B：从 Figma / 描述补齐布局与状态

```
请在【不改动已有业务逻辑】的前提下，根据以下设计说明调整 SwiftUI 布局。

## 当前代码
[粘贴现有 View 源码或 @ 文件]

## 设计说明（来自 Figma / 设计评审）
- 布局：[对齐方式、栅格、安全区]
- 尺寸：[头像 64×64 圆形、按钮高度 44 等]
- 状态：
  - 默认：[描述]
  - 空态：[描述]
  - 错误：[描述]
- 深色模式：[特殊要求，如有]

## 任务
1. 列出与当前实现的差异（Markdown 表格：区域 | 现状 | 目标）
2. 确认后修改代码，并更新/新增对应 Preview
3. 使用项目设计 Token：[AppColor.xxx / AppFont.xxx]，无法映射处标注 `// TODO: design token`

约束：不新增第三方库；不实现网络层。
```

---

## 提示词模板 C：Preview + 简单交互

```
在以下 SwiftUI 原型上增加可演示的轻量交互（仅 UI 层）。

## 现有代码
[粘贴 View]

## 交互需求
1. [例如：Segment 切换「帖子 / 收藏」]
2. [例如：点击「关注」切换按钮样式，使用 @State]
3. [例如：下拉刷新仅显示 ProgressView 1 秒，用 Task.sleep 模拟]

## 要求
- 动作使用 debugPrint 或空闭包，标注 `// PROTOTYPE`
- 为每种交互状态添加独立 `#Preview("名称")`
- 保证 Preview 不依赖 App 单例或真实 Keychain

输出：完整 Swift 文件 + Preview 列表说明（供我截图验收）。
```

---

## 提示词模板 D：对齐设计系统（收尾）

```
以下 SwiftUI 代码是评审通过的原型，请帮我收敛到项目设计系统。

## 原型代码
[粘贴代码]

## 设计系统
[粘贴 Colors / Typography / Button 样式，或 @ 引用]

## 任务
1. 替换硬编码 Color、Font、cornerRadius
2. 用已有组件替换重复实现（列出替换映射表）
3. 保持 Preview 可运行；fixture 数据移到 `Preview/ProfileHeader+Fixtures.swift`（如合适）
4. 输出仍需人工接入的 TODO（API、路由、权限）

不要在此步骤实现网络请求或持久化。
```

---

## 使用示例

### 输入（摘要）

- 需求：设置页「通知偏好」卡片列表，含开关与副标题
- iOS 17，`NavigationStack`，使用 `SettingsToggleRow` 组件
- 状态：全部开启 / 全部关闭

### 期望输出（计划阶段）

```markdown
## 组件树
- NotificationPreferencesView
  - NotificationPreferencesHeader
  - NotificationToggleSection (ForEach)

## 状态
- displayOnly（Preview fixture）

## Previews
1. AllOn
2. AllOff
3. Large Dynamic Type
```

### 期望输出（代码阶段）

- 可编译的 `NotificationPreferencesView.swift`
- 至少 2 个 `#Preview`
- 无 `!`，开关绑定 `@State` 或 fixture 常量

---

## 注意事项

- **分阶段确认**：计划 → 代码 → 设计系统收敛，避免一次生成过大 diff
- **标明原型边界**：使用注释或目录隔离，防止未评审代码进入发布路径
- **Preview 即验收**：要求 AI 列出 Preview 名称，便于 PR 附截图
- **模型能力**：复杂 Auto Layout 等价约束（多层对齐）需在上下文中数值化
- **不适用**：长动画、UIKit 嵌套、完整 MVVM + 网络 + 持久化一条龙

## 关联资源

- 工作流：[SwiftUI 视图快速原型](../../workflows/swiftui-prototyping.md)
- 示例：[swiftui-prototype 最小案例](../../examples/swiftui-prototype/)

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-27  
**推荐模型**：Claude Sonnet / GPT-4 级别及以上（需理解 SwiftUI 与 HIG）
