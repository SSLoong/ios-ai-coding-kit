# 提示词：审查公开 API 变更影响

## 场景说明

当修改多模块 iOS 项目中某个模块的 public API（类型、方法、属性）时，分析变更的影响范围，识别 Breaking Changes，生成受影响模块清单和迁移指南。

## 输入要求

- **必需**：API 变更内容（git diff 或文字描述）
- **必需**：项目依赖图（哪些模块依赖此模块）
- **可选**：受影响模块的代码（用于精确定位编译错误）
- **可选**：现有的迁移指南模板

## 提示词模板

```
请审查以下 public API 变更的影响范围，并生成迁移指南。

## 变更内容

### 模块名称
[被修改的模块名，如 Networking]

### 变更类型
[选择一项：新增 / 修改 / 删除 / 重命名]

### 具体变更
[粘贴以下内容之一：]

**选项 1：git diff**
\`\`\`diff
--- a/Packages/Networking/Sources/NetworkClient.swift
+++ b/Packages/Networking/Sources/NetworkClient.swift
@@ -10,7 +10,7 @@ public class NetworkClient {
-    public func fetchData(url: String) async throws -> Data {
+    public func fetchData(url: URL) async throws -> Data {
         // ...
     }
\`\`\`

**选项 2：文字描述**
- 将 \`NetworkClient.fetchData(url: String)\` 的参数类型从 \`String\` 改为 \`URL\`
- 新增 \`NetworkClient.uploadImage(_:)\` 方法
- 删除 \`NetworkClient.setHeader(_:forKey:)\` 方法（已废弃）
- 将 \`User.avatarURL\` 从 \`String\` 改为 \`URL?\`

**选项 3：完整的修改前后对比**
\`\`\`swift
// 修改前
public func fetchData(url: String) async throws -> Data

// 修改后
public func fetchData(url: URL) async throws -> Data
\`\`\`

## 项目依赖图

[粘贴项目的依赖图或依赖列表]

### 直接依赖此模块的模块
- UserFeature
- PaymentFeature
- OrderFeature

### 依赖图（Mermaid，可选）
\`\`\`mermaid
graph TB
    App --> UserFeature
    App --> PaymentFeature
    UserFeature --> Networking
    PaymentFeature --> Networking
    OrderFeature --> Networking
\`\`\`

## 受影响模块的代码（可选，用于精确定位）

[如需精确分析，粘贴受影响模块调用此 API 的代码]

### UserFeature/UserService.swift
\`\`\`swift
// 第 45 行
let data = try await networkClient.fetchData(url: "https://api.example.com/users")
\`\`\`

### PaymentFeature/PaymentAPI.swift
\`\`\`swift
// 第 23 行
let response = try await networkClient.fetchData(url: endpoint)
\`\`\`

## 任务要求

1. **识别变更类型**
   - 🟢 **向后兼容（Non-breaking）**：新增方法、可选参数、默认值
   - 🔴 **破坏性变更（Breaking Change）**：修改签名、删除方法、改变返回类型

2. **分析影响范围**
   - 列出所有**直接依赖**此模块的模块
   - 列出所有**间接依赖**此模块的模块（传递依赖）
   - 标注哪些模块会出现编译错误
   - 估算受影响代码行数或文件数

3. **生成影响清单**
   - 按模块分组
   - 标注具体文件和行号（如提供了代码）
   - 说明错误类型（类型不匹配、方法未找到等）

4. **提供迁移方案**
   - 如为 Breaking Change，提供具体迁移步骤
   - 给出兼容过渡方案（如使用 @available(*, deprecated)）
   - 估算迁移工作量

## 输出格式

### 1. 变更摘要

| 属性 | 值 |
|------|-----|
| 变更模块 | Networking |
| 变更类型 | 🔴 Breaking Change |
| 变更数量 | 1 个方法签名修改 |
| 影响模块数 | 3 个直接依赖，5 个间接依赖 |

### 2. Breaking Changes 明细

#### 🔴 Breaking Change #1：\`fetchData(url:)\` 参数类型变更

**修改前：**
\`\`\`swift
public func fetchData(url: String) async throws -> Data
\`\`\`

**修改后：**
\`\`\`swift
public func fetchData(url: URL) async throws -> Data
\`\`\`

**影响原因：**
- 参数类型从 \`String\` 改为 \`URL\`，调用方需修改传参

**受影响代码模式：**
\`\`\`swift
// ❌ 旧代码（编译错误）
let data = try await client.fetchData(url: "https://example.com")

// ✅ 新代码
let data = try await client.fetchData(url: URL(string: "https://example.com")!)
\`\`\`

### 3. 影响范围清单

#### 直接依赖模块

| 模块 | 文件 | 行号 | 错误类型 | 优先级 |
|------|------|------|---------|--------|
| UserFeature | UserService.swift | 45 | ❌ 类型不匹配：String → URL | 🔴 高 |
| UserFeature | ProfileViewModel.swift | 78 | ❌ 类型不匹配 | 🔴 高 |
| PaymentFeature | PaymentAPI.swift | 23 | ❌ 类型不匹配 | 🔴 高 |
| PaymentFeature | TransactionService.swift | 56 | ❌ 类型不匹配 | 🔴 高 |
| OrderFeature | OrderRepository.swift | 67 | ❌ 类型不匹配 | 🔴 高 |

**预估影响：** 5 个文件，共约 5 处调用点

#### 间接依赖模块

| 模块 | 影响方式 | 是否需要修改 |
|------|---------|-------------|
| App | 依赖 UserFeature → 依赖 Networking | ❌ 无需修改（不直接调用 Networking） |

### 4. 迁移指南

#### 策略一：立即迁移（推荐）

**步骤：**

1. **在 Networking 模块提供过渡方法（可选，降低影响）**
   \`\`\`swift
   // NetworkClient.swift
   @available(*, deprecated, message: "Use fetchData(url: URL) instead")
   public func fetchData(url: String) async throws -> Data {
       guard let urlObj = URL(string: url) else {
           throw NetworkError.invalidURL
       }
       return try await fetchData(url: urlObj)
   }
   \`\`\`

2. **逐模块修改调用处**

   **UserFeature/UserService.swift**
   \`\`\`swift
   // 修改前（第 45 行）
   let data = try await networkClient.fetchData(url: "https://api.example.com/users")
   
   // 修改后
   guard let url = URL(string: "https://api.example.com/users") else {
       throw NetworkError.invalidURL
   }
   let data = try await networkClient.fetchData(url: url)
   \`\`\`

   **PaymentFeature/PaymentAPI.swift**
   \`\`\`swift
   // 修改前（第 23 行）
   let endpoint = "https://api.example.com/payment"
   let response = try await networkClient.fetchData(url: endpoint)
   
   // 修改后
   let endpoint = "https://api.example.com/payment"
   guard let url = URL(string: endpoint) else {
       throw NetworkError.invalidURL
   }
   let response = try await networkClient.fetchData(url: url)
   \`\`\`

3. **编译并运行测试**
   \`\`\`bash
   xcodebuild test -scheme UserFeature
   xcodebuild test -scheme PaymentFeature
   xcodebuild test -scheme OrderFeature
   \`\`\`

4. **（可选）移除 deprecated 方法**
   - 在下一个大版本（如 v2.0）移除过渡方法

#### 策略二：分阶段迁移

**适用场景：** 受影响模块较多，希望分批迁移

**步骤：**

1. **第 1 阶段（当前版本 v1.5）**
   - 保留旧方法 \`fetchData(url: String)\`，标记为 \`@available(*, deprecated)\`
   - 新增新方法 \`fetchData(url: URL)\`
   - 文档中说明迁移计划

2. **第 2 阶段（v1.6）**
   - 逐模块迁移到新方法
   - 在编译时警告：使用了 deprecated 方法

3. **第 3 阶段（v2.0）**
   - 删除旧方法 \`fetchData(url: String)\`
   - 发布 Breaking Change 说明

### 5. 工作量估算

| 任务 | 预估时间 | 风险 |
|------|---------|------|
| Networking 模块添加过渡方法 | 10 分钟 | 低 |
| 修改 UserFeature（2 处） | 20 分钟 | 低 |
| 修改 PaymentFeature（2 处） | 20 分钟 | 低 |
| 修改 OrderFeature（1 处） | 10 分钟 | 低 |
| 编译并运行测试 | 15 分钟 | 中 |
| 代码审查与 PR | 20 分钟 | 低 |
| **总计** | **约 1.5 小时** | 低 |

### 6. 推荐方案

✅ **推荐策略一（立即迁移）**

**理由：**
- 影响范围小（仅 3 个模块，5 处调用）
- 修改简单（String → URL 转换）
- 可在 1 次 PR 中完成

**执行建议：**
1. 先在 Networking 模块添加过渡方法（防止其他分支合并时冲突）
2. 逐模块提交 PR，分别审查
3. 全部合并后，下个版本移除 deprecated 方法

## 输出结果
[AI 在此处输出完整的影响分析和迁移指南]
```

## 使用示例

### 输入

```
请审查以下 API 变更的影响。

## 变更内容

### 模块名称
UserFeature

### 变更类型
修改

### 具体变更
\`\`\`swift
// 修改前
public struct User: Codable {
    public let id: String
    public let name: String
    public let avatarURL: String  // ← 改为可选 URL 类型
}

// 修改后
public struct User: Codable {
    public let id: String
    public let name: String
    public let avatarURL: URL?
}
\`\`\`

## 项目依赖图

### 直接依赖 UserFeature 的模块
- App（主 Target）
- ProfileFeature
- ChatFeature
```

### 输出（AI 生成，节选）

```markdown
## 变更摘要

| 属性 | 值 |
|------|-----|
| 变更模块 | UserFeature |
| 变更类型 | 🔴 Breaking Change |
| 变更数量 | 1 个属性类型修改 |
| 影响模块数 | 3 个直接依赖 |

## Breaking Changes 明细

#### 🔴 Breaking Change #1：\`User.avatarURL\` 类型变更

**修改前：**
\`\`\`swift
public let avatarURL: String
\`\`\`

**修改后：**
\`\`\`swift
public let avatarURL: URL?
\`\`\`

**影响原因：**
1. 类型从 \`String\` 改为 \`URL?\`，所有访问 \`user.avatarURL\` 的代码需适配
2. 现在为可选类型，需处理 \`nil\` 情况

**受影响代码模式：**
\`\`\`swift
// ❌ 旧代码（编译错误：类型不匹配）
let urlString: String = user.avatarURL
loadImage(from: urlString)

// ✅ 新代码
if let avatarURL = user.avatarURL {
    loadImage(from: avatarURL)
}
\`\`\`

## 影响范围清单

| 模块 | 文件 | 预估影响 |
|------|------|---------|
| App | ProfileViewController.swift | ❌ 需修改：\`user.avatarURL\` 的访问方式 |
| App | SettingsView.swift | ❌ 需修改 |
| ProfileFeature | AvatarView.swift | ❌ 需修改 |
| ChatFeature | MessageCell.swift | ❌ 需修改 |

**预估影响：** 4 个文件，约 8-10 处调用点

## 迁移指南

### 修改前后对比

**ProfileViewController.swift**
\`\`\`swift
// 修改前
let avatarURLString = user.avatarURL
imageView.load(from: avatarURLString)

// 修改后
if let avatarURL = user.avatarURL {
    imageView.load(from: avatarURL)
} else {
    imageView.image = UIImage(named: "default_avatar")
}
\`\`\`

**AvatarView.swift (SwiftUI)**
\`\`\`swift
// 修改前
AsyncImage(url: URL(string: user.avatarURL))

// 修改后
AsyncImage(url: user.avatarURL)
\`\`\`

## 工作量估算
- 修改 4 个文件，约 8-10 处调用
- 预估时间：30-45 分钟
- 风险：中（需确保所有 nil 情况都有默认处理）
```

## 注意事项

1. **优先提供依赖图**
   - 没有依赖图，AI 只能猜测影响范围
   - 使用 `prompts/architecture/generate-dependency-graph.md` 生成

2. **区分直接依赖和间接依赖**
   - 直接依赖：调用了修改的 API，必须修改
   - 间接依赖：通过中间模块使用，可能无需修改

3. **精确定位需要代码**
   - 如只提供依赖图，AI 只能估算影响
   - 提供具体代码，AI 可精确定位行号

4. **考虑测试代码**
   - 测试代码也可能受影响（如 Mock 对象）
   - 记得更新单元测试中的 Mock 实现

5. **文档同步更新**
   - 更新 MODULE_CONTEXT.md 中的 API 说明
   - 更新 README 或 CHANGELOG

## 扩展用法

### 用法 1：批量审查多个 API 变更

```
请审查以下一批 API 变更的综合影响。

## 变更列表
1. Networking.fetchData(url:) 参数从 String 改为 URL
2. User.avatarURL 从 String 改为 URL?
3. UserService.updateUser(_:) 新增 throws

## 项目依赖图
[粘贴依赖图]

## 要求
- 综合分析所有变更的影响
- 推荐最优迁移顺序（如先改 Networking，再改 UserFeature）
- 给出整体工作量估算
```

### 用法 2：评估是否应该引入 Breaking Change

```
我计划修改 Networking.fetchData(url:) 的参数类型，请评估是否值得引入这个 Breaking Change。

## 计划变更
- 从 String 改为 URL
- 原因：避免每次调用时手动转换 String → URL

## 项目规模
- 依赖 Networking 的模块：15 个
- 预估调用处：约 50-80 处

## 请评估
1. 这个变更的价值是否大于迁移成本？
2. 有没有更好的方案（如重载方法）？
3. 如果引入，推荐的迁移策略是什么？
```

### 用法 3：生成 CHANGELOG 条目

```
基于以下 API 变更，生成 CHANGELOG.md 的 Breaking Changes 部分。

## 变更内容
[粘贴变更]

## 要求
- 使用 Keep a Changelog 格式
- 明确标注 Breaking Change
- 提供迁移示例
```

**输出示例：**

```markdown
## [2.0.0] - 2026-11-04

### ⚠️ BREAKING CHANGES

#### Networking Module

- **\`fetchData(url:)\` 参数类型变更**
  - **修改前：** \`public func fetchData(url: String) async throws -> Data\`
  - **修改后：** \`public func fetchData(url: URL) async throws -> Data\`
  - **迁移方法：**
    \`\`\`swift
    // 旧代码
    let data = try await client.fetchData(url: "https://example.com")
    
    // 新代码
    let data = try await client.fetchData(url: URL(string: "https://example.com")!)
    \`\`\`
```

---

**适用工具**：Cursor、Claude Code、ChatGPT、GitHub Copilot  
**输出格式**：Markdown  
**最后更新**：2026-11-04
