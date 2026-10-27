# SwiftUI 视图快速原型示例

最小化示例：展示 AI 生成原型时应具备的 **DisplayData + View + 多状态 Preview** 结构。本目录为独立 Swift 片段，可复制到 Xcode Playground 或 App target 中验证。

## 场景

- **界面**：个人资料页头部（头像、昵称、简介、编辑入口）
- **目标**：评审前可演示加载态与正常态，含简单展开/收起交互

## 建议提供给 AI 的上下文

```markdown
## 界面目标
个人资料头部：64pt 圆形头像、标题、两行简介可展开、主按钮「编辑资料」

## 约束
- iOS 17+，使用 #Preview
- 原型不接网络；ProfileHeaderDisplayData 静态 fixture
- 无 force unwrap

## 验收
- Preview: Loaded / Loading / Large Text
- 编辑按钮仅 debugPrint
```

完整提示词见 [prompts/prototyping/swiftui-prototype.md](../../prompts/prototyping/swiftui-prototype.md)。

## 文件说明

| 文件 | 说明 |
|------|------|
| `ProfileHeaderView.swift` | 展示模型、主 View、3 个 Preview |

## 人工收尾（正式接入前）

1. 将 `ProfileHeaderDisplayData` 映射到真实 ViewModel
2. 颜色/字体替换为项目 DesignSystem
3. 删除 `// PROTOTYPE` 占位，接入路由与 API

## 相关链接

- [工作流：SwiftUI 视图快速原型](../../workflows/swiftui-prototyping.md)
- [上下文工程](../../docs/context-engineering.md)

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-27
