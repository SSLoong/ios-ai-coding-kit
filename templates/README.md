# Templates 配置模板

这个目录包含用于配置项目 AI 编程环境的模板文件，可以直接复制到项目中使用。

## 📁 目录结构

```
templates/
├── README.md                    # 本文件
├── cursor-rules/                # Cursor AI 规则配置
│   ├── basic-swift.cursorrules # 基础 Swift 项目规则
│   ├── swiftui.cursorrules     # SwiftUI 项目规则
│   └── uikit.cursorrules       # UIKit 项目规则
├── github/                      # GitHub 配置模板
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       └── ios-ci.yml          # iOS CI 工作流
└── docs/                        # 项目文档模板
    ├── AGENTS.md               # AI Agent 使用说明
    └── CONTEXT.md              # 项目上下文文档
```

## 🚀 快速使用

### 1. 配置 Cursor Rules

将对应的 `.cursorrules` 文件复制到项目根目录：

```bash
# 基础 Swift 项目
cp templates/cursor-rules/basic-swift.cursorrules /path/to/your/project/.cursorrules

# SwiftUI 项目
cp templates/cursor-rules/swiftui.cursorrules /path/to/your/project/.cursorrules

# UIKit 项目
cp templates/cursor-rules/uikit.cursorrules /path/to/your/project/.cursorrules
```

### 2. 配置 GitHub 模板

```bash
# 创建 .github 目录
mkdir -p /path/to/your/project/.github/workflows

# 复制 PR 模板
cp templates/github/PULL_REQUEST_TEMPLATE.md /path/to/your/project/.github/

# 复制 CI 工作流
cp templates/github/workflows/ios-ci.yml /path/to/your/project/.github/workflows/
```

### 3. 添加项目文档

```bash
# 复制 AI 使用说明
cp templates/docs/AGENTS.md /path/to/your/project/

# 复制上下文文档
cp templates/docs/CONTEXT.md /path/to/your/project/
```

## 📝 模板说明

### Cursor Rules

| 文件 | 适用场景 | 主要配置 |
|------|----------|----------|
| `basic-swift.cursorrules` | 通用 Swift 项目 | 代码风格、命名约定、基本架构 |
| `swiftui.cursorrules` | SwiftUI 应用 | 视图组件、数据流、预览配置 |
| `uikit.cursorrules` | UIKit 应用 | 视图控制器、自动布局、生命周期 |

### GitHub 模板

- **PULL_REQUEST_TEMPLATE.md**：标准 PR 描述模板，包含变更说明、测试清单、截图要求
- **ios-ci.yml**：iOS CI 工作流，包含构建、测试、代码覆盖率检查

### 文档模板

- **AGENTS.md**：告诉 AI Agent 如何理解和操作项目
- **CONTEXT.md**：项目架构、技术栈、关键设计决策

## 🎯 最佳实践

### 1. 自定义 Cursor Rules

复制模板后，根据项目调整：

```yaml
# 添加项目特定的技术栈
tech_stack:
  - SwiftUI
  - Combine
  - Core Data
  - Firebase

# 添加团队约定
team_conventions:
  - "使用 SwiftLint 规则：.swiftlint.yml"
  - "单测覆盖率要求 ≥ 80%"
  - "所有网络请求必须有超时配置"
```

### 2. 分层配置

大型项目可以使用多层配置：

```
YourProject/
├── .cursorrules                    # 全局规则
├── Modules/
│   ├── Networking/
│   │   └── .cursorrules           # 网络模块规则
│   └── UI/
│       └── .cursorrules           # UI 模块规则
```

### 3. 版本控制

将模板文件纳入 Git 管理：

```gitignore
# .gitignore 示例
# 不忽略模板配置
!.cursorrules
!.github/PULL_REQUEST_TEMPLATE.md
!AGENTS.md
!CONTEXT.md
```

## 🔧 自定义指南

### 添加新的 Cursor Rule

1. 创建新文件：`templates/cursor-rules/your-custom.cursorrules`
2. 遵循以下结构：

```yaml
---
name: "Your Custom Rules"
description: "Describe when to use this template"
version: "1.0.0"
author: "Your Name"
---

# Project Context
[描述项目类型、技术栈]

# Code Style
[代码风格规范]

# Architecture
[架构模式与设计原则]

# AI Assistant Behavior
[期望 AI 如何协助开发]
```

3. 更新本 README 的模板列表
4. 提交 PR

### 添加新的 GitHub 模板

参考 GitHub 官方文档：
- [创建 PR 模板](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)
- [配置 Issue 模板](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository)

## 📚 相关资源

- [Cursor Documentation](https://docs.cursor.com/)
- [GitHub Templates Guide](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
- [工作流：配置 AI 开发环境](../../workflows/setup-ai-environment.md)（计划中）

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-23
