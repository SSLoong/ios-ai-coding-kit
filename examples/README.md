# Examples 示例代码

这个目录包含 Swift/iOS + AI 编程的最小化示例，展示如何为 AI 工具设计良好的上下文。

## 📁 目录结构

```
examples/
├── README.md                           # 本文件
├── unit-test-example/                  # 单元测试示例
│   ├── Source/
│   │   └── UserManager.swift          # 待测试的源代码
│   ├── Tests/
│   │   └── UserManagerTests.swift     # 生成的测试代码
│   └── README.md                      # 上下文设计说明
├── swiftui-prototype/                  # SwiftUI 视图快速原型示例
│   ├── ProfileHeaderView.swift
│   └── README.md
├── swiftui-component/                  # SwiftUI 组件示例（计划中）
└── networking-layer/                   # 网络层示例（计划中）
```

## 🎯 示例说明

### 1. 单元测试示例 (`unit-test-example/`)

展示如何使用 AI 生成高质量的单元测试：
- **场景**：为一个包含网络请求和缓存的 `UserManager` 类生成测试
- **关键点**：提供依赖协议、Mock 策略、测试命名约定
- **成果**：覆盖率 85%+ 的测试代码

**适合学习**：
- 如何准备上下文让 AI 理解依赖关系
- 如何生成可维护的 Mock 对象
- 如何确保生成的测试符合项目规范

### 2. SwiftUI 视图快速原型 (`swiftui-prototype/`)

展示 AI 生成原型时应具备的代码结构：
- **场景**：个人资料头部区域，含加载态与简单交互
- **关键点**：DisplayData fixture、多状态 `#Preview`、原型边界注释
- **成果**：可复制到 Xcode 验证 Canvas 与动态字体

**适合学习**：
- 如何在工作流中分「计划 → 代码 → 设计系统收敛」
- 如何用 Preview 作为验收标准

详见 [swiftui-prototype/README.md](./swiftui-prototype/README.md)。

### 3. SwiftUI 组件示例（计划中）

展示如何使用 AI 快速原型可复用 SwiftUI 组件：
- **场景**：从设计稿描述生成通用 Cell / Card
- **关键点**：提供设计规范、颜色系统、布局约束

### 4. 网络层示例（计划中）

展示如何使用 AI 构建网络层：
- **场景**：从 API 文档生成网络请求代码
- **关键点**：错误处理、重试逻辑、类型安全

## 📝 如何使用示例

### 学习上下文设计
1. 阅读每个示例的 README
2. 查看"AI 输入"部分，理解需要提供哪些上下文
3. 查看"AI 输出"部分，评估生成质量
4. 尝试修改上下文，观察输出变化

### 作为模板使用
1. 复制对应场景的上下文设计
2. 替换为你的项目信息
3. 粘贴到 Cursor/Claude 生成代码
4. 根据输出调整上下文

### 贡献新示例
1. 创建新目录，包含 `Source/`、`Tests/`（如适用）
2. 添加 README 说明：
   - 场景描述
   - AI 输入（提示词 + 上下文）
   - AI 输出（生成的代码）
   - 人工调整（哪些部分需要修改）
   - 经验总结
3. 保持示例最小化（聚焦一个概念）
4. 提交 PR

## 🎓 上下文设计原则

### 1. 最小化但完整
- ✅ 提供关键类型定义（协议、枚举）
- ✅ 说明依赖关系（"依赖 NetworkService 协议"）
- ❌ 不粘贴整个项目代码

### 2. 风格参考优于规则列表
- ✅ 提供一个现有代码示例
- ❌ 列举 20 条代码规范

### 3. 约束明确
- ✅ "使用 XCTest，Mock 网络请求，覆盖边界条件"
- ❌ "生成一些测试"

### 4. 分阶段确认
- ✅ 先生成计划，确认后再生成代码
- ❌ 一次性生成所有代码

## 📚 推荐学习路径

1. **入门**：[单元测试示例](./unit-test-example/)
   - 学习如何准备上下文
   - 理解 Mock 对象设计
   
2. **进阶**：[SwiftUI 原型示例](./swiftui-prototype/)
   - 学习从需求到可 Preview 代码的生成
   - 掌握设计规范的表达与多状态验收

3. **高级**：多模块项目示例（计划中）
   - 学习复杂依赖的上下文设计
   - 掌握大规模代码生成策略

## 🔗 相关资源

- [工作流：为 Swift 模块补充单元测试](../workflows/unit-test-generation.md)
- [工作流：SwiftUI 视图快速原型](../workflows/swiftui-prototyping.md)
- [提示词：单元测试生成](../prompts/testing/unit-test.md)
- [提示词：SwiftUI 视图快速原型](../prompts/prototyping/swiftui-prototype.md)
- [模板：Cursor Rules](../templates/cursor-rules/)

---

**维护者**：Loong (SSLoong)  
**最后更新**：2026-10-27

**欢迎贡献**：分享你的成功案例，帮助他人少走弯路！
