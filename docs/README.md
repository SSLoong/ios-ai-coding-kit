# Docs 设计文档

这个目录包含 iOS + AI 编程的设计原则、实践指南和经验总结。

## 📁 文档列表

```
docs/
├── README.md                          # 本文件
├── context-engineering.md             # 上下文工程实践指南
├── principles.md                      # 设计原则与最佳实践（计划中）
├── ai-tools-comparison.md             # AI 工具对比（计划中）
└── case-studies/                      # 案例研究（计划中）
    ├── refactoring-legacy-code.md
    └── building-features-with-ai.md
```

## 📖 文档说明

### [上下文工程实践指南](./context-engineering.md) ✅

**适合阅读者**：想深入理解如何为 AI 工具提供高质量上下文的开发者

**核心内容**：
- 什么是上下文工程
- 为什么上下文质量决定 AI 输出质量
- iOS 项目中的上下文设计模式
- 实战技巧：如何组织项目文档、代码注释、提示词

### 设计原则与最佳实践（计划中）

**核心内容**：
- AI 辅助开发的设计原则
- 代码生成的验证标准
- 人机协作的最佳实践
- 常见陷阱与解决方案

### AI 工具对比（计划中）

**核心内容**：
- Cursor vs Claude Code vs GitHub Copilot
- 各工具的优势场景
- 实际项目中的选型建议
- 成本与效率分析

### 案例研究（计划中）

真实项目中的 AI 编程实践：
- 重构遗留代码：如何用 AI 安全重构 10 万行代码
- 从 0 到 1 开发新功能：AI 如何加速开发周期
- 技术债务偿还：用 AI 补充测试和文档

## 🎯 阅读路径

### 初次接触 AI 编程
1. 阅读 [上下文工程实践指南](./context-engineering.md)
2. 参考 [工作流：为 Swift 模块补充单元测试](../workflows/unit-test-generation.md)
3. 动手尝试 [单元测试示例](../examples/unit-test-example/)

### 想在团队推广
1. 阅读设计原则与最佳实践（开发中）
2. 配置团队 [Cursor Rules](../templates/cursor-rules/)
3. 制定团队规范（参考 AGENTS.md 模板）

### 遇到具体问题
1. 查找对应的 [工作流文档](../workflows/)
2. 使用 [提示词库](../prompts/) 中的模板
3. 在 [案例研究](./case-studies/)（计划中）中找相似场景

## 🤝 贡献文档

欢迎分享你的实践经验：

### 文档结构建议
```markdown
# 标题

## 背景
[描述问题或场景]

## 核心概念
[关键概念解释]

## 实践指南
[具体的操作步骤]

## 案例分析
[真实案例]

## 常见问题
[FAQ]

## 延伸阅读
[相关资源链接]
```

### 提交流程
1. 在 `docs/` 创建 Markdown 文件
2. 更新本 README 的文档列表
3. 提交 PR 并说明文档主题

## 📚 外部资源

### 官方文档
- [Cursor Documentation](https://docs.cursor.com/)
- [Anthropic Claude Guide](https://docs.anthropic.com/claude/docs)
- [GitHub Copilot Docs](https://docs.github.com/en/copilot)

### 推荐阅读
- [The Pragmatic Programmer (AI Era Edition)](https://pragprog.com/)
- [Working Effectively with AI](https://www.oreilly.com/)（示例）
- [Swift.org - Best Practices](https://swift.org/documentation/)

### 社区资源
- [r/iOSProgramming](https://www.reddit.com/r/iOSProgramming/)
- [Swift Forums](https://forums.swift.org/)
- [iOS Dev Weekly](https://iosdevweekly.com/)

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-23

**欢迎反馈**：如果某个主题对你特别有帮助或需要补充，请提 Issue 告诉我们！
