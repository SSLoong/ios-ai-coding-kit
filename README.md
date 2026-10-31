# iOS + AI 编程工作流合集

> 面向 iOS/Swift 开发者的 AI 辅助编程实践指南  
> AI-Powered Coding Workflows for iOS/Swift Developers

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📖 项目定位

这是一个**日更维护**的 iOS + AI 编程工作流合集，收录技术负责人 Loong 在实践中总结的端到端工作流、可复用提示词、配置模板与最佳实践。

**核心目标：**
- 让 iOS/Swift 开发者高效使用 Cursor、Claude Code、GitHub Copilot 等 AI 工具
- 提供从需求到上线的完整工作流文档
- 积累可复用的上下文工程（Context Engineering）实践
- 降低 AI 编程在 iOS 项目中的接入成本

## 🗂️ 目录结构

```
ios-ai-coding-kit/
├── workflows/       # 端到端工作流文档（需求→实现→Review→测试）
├── prompts/         # 可复用的系统/任务提示词，按场景分文件
├── templates/       # 脚手架文件（.cursor/rules、AGENTS.md、PR 模板等）
├── examples/        # Swift/iOS 最小示例与上下文设计案例
├── docs/            # 设计原则、上下文工程在 iOS 项目中的实践
├── LICENSE          # MIT License
└── README.md        # 本文件
```

## 🚀 快速开始

### 1. 适用人群

- **iOS/Swift 开发者**：使用 Cursor、Claude Code、Codex 等 AI 工具
- **技术 Leader**：需要在团队推广 AI 编程工作流
- **独立开发者**：想用 AI 加速从原型到上线的全流程

### 2. 如何使用

#### 场景一：使用现有工作流
1. 浏览 `workflows/` 目录，找到匹配场景（如补单测、重构、code review）
2. 按工作流文档步骤执行，复制相关提示词到 Cursor/Claude
3. 根据项目实际情况调整上下文与验证标准

#### 场景二：配置项目 AI 环境
1. 从 `templates/` 复制 `.cursor/rules` 或 `AGENTS.md` 到项目根目录
2. 根据项目技术栈（UIKit/SwiftUI、MVVM/MVI 等）修改规则
3. 参考 `docs/context-engineering.md` 设计项目上下文

#### 场景三：学习与贡献
1. 阅读 `docs/` 了解设计原则与实践思路
2. 参考 `examples/` 中的最小示例理解上下文设计
3. 提交 PR 分享你的工作流或改进建议

### 3. 目录导航

| 目录 | 说明 | 推荐场景 |
|------|------|----------|
| [workflows/](./workflows/) | 完整工作流文档 | 需要端到端流程指导 |
| [prompts/](./prompts/) | 可复用提示词 | 快速复制粘贴使用 |
| [templates/](./templates/) | 配置模板 | 配置新项目 AI 环境 |
| [examples/](./examples/) | 代码示例 | 学习上下文设计 |
| [docs/](./docs/) | 设计文档 | 深入理解原则 |

## 💡 核心理念

### 1. 上下文工程优先
AI 的输出质量 = 上下文质量 × 模型能力。在 iOS 项目中：
- 提供架构图、模块依赖关系
- 明确代码风格（SwiftLint 规则、命名约定）
- 附上关键类型定义与协议

### 2. 验证标准前置
每个工作流都包含**明确的验证标准**：
- 单测覆盖率阈值
- 编译时 warning 容忍度
- SwiftLint 规则检查

### 3. 迭代式改进
- 记录每次 AI 辅助开发的效果（时间节省、bug 率）
- 定期更新提示词与工作流
- 分享失败案例与解决方案

## 📚 推荐工作流

### 入门
- [为 Swift 模块补充单元测试](./workflows/unit-test-generation.md) ✅ 已完成
- [使用 AI 进行代码 Review](./workflows/ai-code-review.md) ✅ 已完成
- [SwiftUI 视图快速原型](./workflows/swiftui-prototyping.md) ✅ 已完成
- [API 接口自动生成 Mock](./workflows/api-mock-generation.md) ✅ 已完成

### 进阶
- [重构遗留 UIKit 代码](./workflows/uikit-refactoring.md) ✅ 已完成
- [iOS 无障碍审计与修复](./workflows/accessibility-audit.md) ✅ 已完成
- [多模块架构的上下文设计](./workflows/multi-module-context.md) 🚧 计划中

## 🤝 如何贡献

我们欢迎所有形式的贡献：

### 贡献类型
- ✅ **新工作流**：提交你的端到端实践流程
- ✅ **改进现有工作流**：优化步骤、补充验证标准
- ✅ **提示词库**：分享可复用的 prompt
- ✅ **配置模板**：提供新的 `.cursor/rules` 或团队配置
- ✅ **问题反馈**：报告工作流中的问题或不适用场景

### 提交流程
1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/your-workflow`)
3. 提交改动 (`git commit -m 'Add: 新增 XX 工作流'`)
4. 推送到分支 (`git push origin feature/your-workflow`)
5. 发起 Pull Request

### 内容规范
- 工作流文档需包含：背景、步骤、验证标准、常见问题
- 提示词需注明适用场景与模型版本
- 示例代码保持最小化，聚焦核心概念

## 📅 日更说明

本项目承诺**工作日每日更新**：
- 周一至周五：新增工作流、优化现有内容或分享实践案例
- 周末：整理反馈、规划下周内容
- 每月月底：发布月度总结与最佳实践精选

## 📧 联系方式

- **作者**：Loong (SSLoong)
- **GitHub**：[@SSLoong](https://github.com/SSLoong)
- **Issues**：[提交问题或建议](https://github.com/SSLoong/ios-ai-coding-kit/issues)

## 📄 开源协议

本项目采用 [MIT License](./LICENSE) 开源协议。

---

⭐ 如果这个项目对你有帮助，欢迎 Star 支持！
