# 工作流：SwiftUI 视图快速原型

## 📋 背景

产品评审、设计走查或技术方案讨论时，往往需要**可运行的 UI 骨架**来对齐信息架构与交互，而不是等完整业务逻辑就绪再画界面。传统做法要么手写大量占位 View，要么在 Figma 与 Xcode 之间反复搬运。

使用 Cursor、Claude Code 等 AI 工具，可以在提供足够上下文的前提下，快速生成**可编译、可 Preview、可演示关键状态**的 SwiftUI 视图骨架，再由工程师收敛到设计系统与正式实现。

## 🎯 目标

为指定界面需求生成可验证的 SwiftUI 原型，达到以下标准：

- **可预览**：`#Preview` 或 `PreviewProvider` 可在 Xcode Canvas 中渲染
- **状态可演示**：加载中 / 空态 / 错误 / 正常等关键 UI 状态可通过 Preview 或简单开关切换
- **结构清晰**：视图拆分合理（主 View + 子组件），命名符合 [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- **安全基线**：原型代码中避免滥用 force unwrap（`!`）、避免在 View body 中做重计算
- **可演进**：数据通过协议或占位 Model 注入，便于后续接入真实 ViewModel / 网络层

## 🛠️ 适用场景

- ✅ 新页面/新组件的信息架构与布局验证
- ✅ 设计稿文字描述或截图说明 → SwiftUI 骨架
- ✅ 评审前快速搭建可点击/可切换状态的 Demo
- ✅ 与设计师对齐间距、字体层级、色板映射到设计系统
- ❌ **不适合**完整业务实现（支付、权限、复杂校验应进正式迭代）
- ❌ **不适合**复杂动画调优（弹簧曲线、逐帧动效需人工精调）
- ❌ **不适合**深度 UIKit 互操作改造（`UIViewRepresentable` 边界情况多，需专项方案）

## 📝 工作流步骤

### 步骤 1：准备上下文

在 Cursor / Claude Code 中集中提供「AI 无法从项目里猜到的约束」。

#### 1.1 设计约束

创建临时文档 `prototype-context.md`（或贴在对话开头），建议包含：

```markdown
## 界面目标
- 页面名称：个人资料页 - 头部区域
- 用户故事：用户进入资料页，看到头像、昵称、简介与编辑入口

## 设计系统（必需尽量具体）
- 色板：primary #007AFF，background secondary systemGroupedBackground
- 字体：标题 .title2.bold()，正文 .body，辅助 .caption.secondary
- 圆角/间距：卡片 cornerRadius 12，水平 padding 16，区块间距 24
- 图标：SF Symbols（pencil.circle.fill 等）

## 工程约束
- 最低部署：iOS 17+
- 架构：SwiftUI + @Observable / ObservableObject（写明项目实际用法）
- 导航：NavigationStack，从 ProfileTab  push 进入
- 现有组件：PrimaryButton、AvatarView（粘贴路径或源码摘要）

## 数据接口（原型阶段）
- 展示模型：ProfileHeaderDisplayData（字段列表）
- 暂不接网络；Preview 用静态 fixture

## 参考
- [可选] Figma 节点说明或截图文字描述
- [可选] 项目中相近页面路径：Features/Settings/SettingsRow.swift
```

#### 1.2 在 IDE 中挂载相关文件

```bash
# 在 Cursor 中 @ 引用或打开：
# - DesignSystem/Colors.swift、Typography.swift
# - 可复用的 Button、Cell 组件
# - 路由/Tab 结构（避免 AI 发明不存在的导航）
```

### 步骤 2：生成视图骨架

使用 [prompts/prototyping/swiftui-prototype.md](../prompts/prototyping/swiftui-prototype.md) 中的「从需求生成 View 骨架」模板。

**推荐分两阶段：**

1. 先让 AI 输出 **视图结构计划**（组件树、状态枚举、文件列表）
2. 确认后再生成 **Swift 代码 + Preview**

示例对话要点：

```
请为「个人资料头部」生成 SwiftUI 原型。
先输出 Markdown 计划：子 View 拆分、@State / 入参、Preview 场景列表。
不要实现网络请求；数据用 ProfileHeaderDisplayData fixture。
复用项目中的 AvatarView（我会 @ 该文件）。
```

### 步骤 3：Preview 验证

#### 3.1 本地编译与 Canvas

```bash
# 命令行快速编译（替换 scheme / simulator）
xcodebuild build \
  -scheme YourApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet
```

在 Xcode 中打开目标 View 文件，启用 Canvas（`Editor → Canvas`），确认：

- 默认 Preview 与深色模式 Preview（如需要）
- 动态字体（Accessibility → XXXL）不严重错位

#### 3.2 多状态 Preview

要求 AI 为每个关键状态提供独立 Preview 或 `Preview` 参数化，例如：

```swift
#Preview("Loaded") {
    ProfileHeaderView(data: .fixtureLoaded)
}

#Preview("Loading") {
    ProfileHeaderView(data: .fixtureLoading)
}
```

**人工审查要点：**

- 布局是否与设计稿一致（对齐、间距、截断规则）
- 是否误用 `Spacer()` 撑满导致滚动异常
- 长文案、空昵称等边界是否在 Preview 中覆盖

### 步骤 4：补充状态与简单交互

在骨架稳定后，再让 AI **增量**添加：

- `@State` 控制展开/收起、Segment 切换
- 按钮动作使用 `#if DEBUG` 占位或 `print`，避免接真实业务 API
- 加载态：`ProgressView` / 骨架屏占位

提示词示例：

```
在现有 ProfileHeaderView 上增加：
1. bio 超过 2 行时可「展开/收起」
2. 编辑按钮仅触发 debugPrint
不要新增第三方依赖；保持单文件可 Preview。
```

### 步骤 5：对齐设计系统

将硬编码颜色、字体替换为项目 Token：

```
请将 ProfileHeaderView 中的 Color.blue、.font(.title2) 
替换为 DesignSystem 中的 AppColor.accent、AppFont.sectionTitle。
列出仍无法映射的样式，标注 TODO。
```

**审查清单：**

- [ ] 颜色/字体来自设计系统或 Asset Catalog
- [ ] 复用已有组件而非重复造轮子
- [ ] 未引入仅原型需要的全局单例

### 步骤 6：人工审查（无障碍、可访问性、性能）

AI 原型**必须**经工程师过目：

| 维度 | 检查项 |
|------|--------|
| 无障碍 | `accessibilityLabel` / `accessibilityHint`；可点击区域 ≥ 44pt |
| 动态类型 | 大字号下不重叠、可滚动 |
| 性能 | 避免在 `body` 内过滤大数组；图片使用合适 `resizable` / 占位 |
| 本地化 | 用户可见文案进入 `Localizable.strings` 或 `String(localized:)` |

### 步骤 7：进入正式实现

原型验收通过后：

1. 将 DisplayData 映射到真实 ViewModel 与 API
2. 将 DEBUG 占位动作替换为路由 / Coordinator 调用
3. 补充单元测试（纯逻辑）与快照测试（如团队有约定）
4. 删除或降级仅用于原型的重复组件

可参考 [为 Swift 模块补充单元测试](./unit-test-generation.md) 覆盖 ViewModel 逻辑。

## ✅ 验证清单

- [ ] 目标 View 在 Xcode Preview 中可渲染（含至少 2 种 UI 状态）
- [ ] `xcodebuild build` 通过（或所在 Module 编译通过）
- [ ] 关键交互可在 Preview 或模拟器中演示（切换、按钮反馈）
- [ ] 无业务无关的 force unwrap；可选值有合理默认或空态
- [ ] 命名清晰：`ProfileHeaderView` 而非 `View1`
- [ ] 设计系统 Token / 组件复用已对齐，硬编码样式有 TODO 或已消除
- [ ] 无障碍与动态类型抽样检查通过
- [ ] 团队评审记录：与 design spec 的差异列表已确认

## 🐛 常见问题

### Q1: Preview 一直「Cannot preview in this file」

**原因**：目标不在当前 target、缺少 `@main` 依赖、或 Preview 宏与部署版本不匹配。

**解决**：

1. 确认文件已加入 App target membership
2. 将复杂依赖改为 Preview 专用 fixture 或 `PreviewModifier`
3. 对 iOS 17+ 统一使用 `#Preview` 宏

### Q2: AI 生成的布局与 Figma 偏差大

**原因**：上下文只有「做一个资料页」，缺少间距、字号、对齐规则。

**解决**：

1. 在 `prototype-context.md` 中补充**数值化**约束（padding、font token）
2. 提供一张截图的文字描述（左对齐、头像 64pt 圆形等）
3. 要求 AI 先输出 ASCII 线框再写代码

### Q3: 生成代码堆砌在一个 400 行 View 里

**原因**：未要求拆分组件。

**解决**：

```
请将 ProfileHeaderView 拆分为：
ProfileAvatarSection、ProfileBioSection、ProfileActionBar。
主 View 不超过 80 行；子 View 放在同一文件底部或 Extensions 文件。
```

### Q4: 误接真实 API 导致原型无法离线演示

**原因**：提示词未强调「原型阶段」。

**解决**：明确「仅静态 fixture + 协议占位」；网络层用 `// PROTOTYPE: replace with API` 标注。

## 🎓 最佳实践

### 1. 上下文工程优先

- ✅ 设计系统色板、字体、组件清单
- ✅ 导航栈与模块边界
- ✅ 数据模型字段与空态规则
- ❌ 只给一句「做个首页」

### 2. 计划先于代码

- ✅ 组件树 + 状态表 + Preview 列表 → 确认 → 代码
- ❌ 一次性生成多个 Tab 的全部界面

### 3. 原型与生产代码边界清晰

- 使用 `// MARK: - Prototype` 或独立 `Prototype/` 目录
- 合并前删除实验性样式与死代码

### 4. 用 Preview 当验收标准

- 将「可演示状态」写进 PR 描述或截图
- 与设计师对齐时直接共享 Canvas 或录屏

## 📚 扩展阅读

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [本仓库：上下文工程](../docs/context-engineering.md)
- [示例：SwiftUI 原型最小案例](../examples/swiftui-prototype/)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md)
- [Mock API 接口自动生成](./api-mock-generation.md)（计划中）
- [重构遗留 UIKit 代码](./uikit-refactoring.md)（计划中）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-27  
**适用工具**：Cursor、Claude Code、GitHub Copilot
