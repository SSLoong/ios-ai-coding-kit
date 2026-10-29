# Prompts 提示词库

这个目录收录了在 iOS/Swift 开发中常用的 AI 提示词，按场景分类。

## 📁 文件组织

```
prompts/
├── README.md                    # 本文件
├── code-generation/             # 代码生成场景
│   ├── swift-model.md          # Swift 模型类生成（计划中）
│   ├── swiftui-component.md    # SwiftUI 组件生成（计划中）
│   └── protocol-implementation.md  # 协议实现生成（计划中）
├── prototyping/                 # 原型与界面探索
│   └── swiftui-prototype.md    # SwiftUI 视图快速原型 ✅
├── testing/                     # 测试相关
│   ├── unit-test.md            # 单元测试生成 ✅
│   ├── mock-generation.md      # Mock 对象生成（计划中）
│   └── test-data-builder.md    # 测试数据构建（计划中）
├── mocking/                     # API Mock 生成
│   ├── openapi-to-fixture.md   # 从 OpenAPI 生成 JSON Fixture ✅
│   └── protocol-to-urlprotocol.md  # 从 Swift Protocol 生成 URLProtocol Mock ✅
├── refactoring/                 # 重构场景 ✅
│   ├── extract-viewmodel.md    # 提取业务逻辑到 ViewModel ✅
│   ├── optimize-layout.md      # 优化 UIViewController 布局代码 ✅
│   └── protocol-oriented.md    # 重构为协议化设计 ✅
└── review/                      # 代码审查
    ├── ai-code-review.md       # AI 代码 Review ✅
    ├── security-check.md       # 安全检查（计划中）
    ├── performance-audit.md    # 性能审计（计划中）
    └── swift-style.md          # Swift 代码风格检查（计划中）
```

## 🚀 快速使用

### 方式一：直接复制
1. 打开对应场景的 `.md` 文件
2. 复制提示词模板
3. 替换 `[占位符]` 为实际内容
4. 粘贴到 Cursor/Claude 中使用

### 方式二：配置到 Cursor Rules
将常用提示词添加到 `.cursor/rules` 文件中：

```yaml
# .cursor/rules 示例
custom_instructions: |
  [从 prompts/testing/unit-test.md 复制核心指令]
```

### 方式三：保存为 Cursor Snippets
在 Cursor 中创建代码片段（Settings → Snippets）：

```json
{
  "Swift Unit Test Generation": {
    "prefix": "gen-test",
    "body": "[从 prompts/testing/unit-test.md 复制]"
  }
}
```

## 📝 提示词编写规范

提交新提示词时，请遵循以下结构：

```markdown
# [提示词名称]

## 场景说明
[简述适用场景，1-2 句话]

## 输入要求
- 必需：[列出必需的上下文信息]
- 可选：[列出可选的额外信息]

## 提示词模板
\`\`\`
[完整的提示词内容，用 [占位符] 标记需要替换的部分]
\`\`\`

## 使用示例
### 输入
[具体示例的输入]

### 输出
[期望的输出格式或示例]

## 注意事项
- [列出常见陷阱或最佳实践]
```

## 🎯 热门提示词

| 提示词 | 场景 | 文件路径 |
|--------|------|----------|
| 单元测试生成 | 为 Swift 类生成 XCTest 测试 | [testing/unit-test.md](./testing/unit-test.md) |
| AI 代码 Review | Swift/iOS PR 风格扫描与深度审查 | [review/ai-code-review.md](./review/ai-code-review.md) |
| SwiftUI 视图快速原型 | 从需求生成可 Preview 的视图骨架 | [prototyping/swiftui-prototype.md](./prototyping/swiftui-prototype.md) |
| OpenAPI 生成 Fixture | 从 OpenAPI 规范生成 JSON Mock 数据 | [mocking/openapi-to-fixture.md](./mocking/openapi-to-fixture.md) |
| Protocol 生成 URLProtocol Mock | 从协议生成网络拦截 Mock | [mocking/protocol-to-urlprotocol.md](./mocking/protocol-to-urlprotocol.md) |
| 提取 ViewModel | 将业务逻辑提取到 ViewModel | [refactoring/extract-viewmodel.md](./refactoring/extract-viewmodel.md) |
| 优化布局代码 | 重构 UIViewController 布局代码 | [refactoring/optimize-layout.md](./refactoring/optimize-layout.md) |
| 协议化重构 | 重构为面向协议设计 | [refactoring/protocol-oriented.md](./refactoring/protocol-oriented.md) |
| SwiftUI 组件生成 | 快速原型 UI 组件 | [code-generation/swiftui-component.md](./code-generation/swiftui-component.md)（计划中）|
| 安全审计 | 检查常见安全漏洞 | [review/security-check.md](./review/security-check.md)（计划中）|

## 🤝 贡献新提示词

1. 按场景分类，放到对应子目录
2. 遵循上述编写规范
3. 在本 README 中更新目录索引
4. 提交 PR 时说明适用场景与验证结果

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-28
