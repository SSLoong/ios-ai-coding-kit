# 上下文工程实践指南

## 📖 什么是上下文工程（Context Engineering）

上下文工程是指**系统性地组织、提供和优化输入信息**，以提高 AI 工具（如 Cursor、Claude Code、GitHub Copilot）的输出质量。

在 AI 辅助编程中，一个核心公式是：

```
AI 输出质量 = 模型能力 × 上下文质量
```

即使使用最先进的模型，如果上下文不清晰、不完整，输出也可能不符合预期。

## 🎯 为什么上下文工程重要

### 问题场景

**差上下文示例：**
```
User: 帮我写一个网络请求
AI: [生成一个通用的 URLSession 代码]
```

问题：
- AI 不知道项目使用什么网络库（URLSession/Alamofire/自定义）
- 不知道错误处理策略（throws/Result/completion）
- 不知道项目架构（直接写还是封装到 Repository）
- 生成的代码可能与项目风格不一致

**好上下文示例：**
```
User: 在我们的项目中，为 UserRepository 添加一个获取用户信息的方法。

上下文：
- 项目使用自定义的 NetworkManager（见下方代码）
- 错误统一使用 throws 和自定义 Error 枚举
- Repository 层通过构造器注入 NetworkManager
- API 端点定义在 APIEndpoint 枚举中

[粘贴 NetworkManager 协议]
[粘贴 APIEndpoint 枚举]
[粘贴现有 Repository 示例]

要求：
- 方法签名：func fetchUser(id: String) async throws -> User
- 使用 async/await
- 添加必要的单元测试
```

AI 现在知道：
- ✅ 使用什么网络库
- ✅ 如何处理错误
- ✅ 代码风格和架构模式
- ✅ 如何集成到现有代码

## 🏗️ iOS 项目的上下文设计模式

### 1. 项目级上下文（Project-Level Context）

在项目根目录创建 `CONTEXT.md` 或 `AGENTS.md`（参考 [模板](../templates/docs/AGENTS.md)）：

```markdown
# 项目上下文

## 技术栈
- Swift 5.9+, iOS 15.0+
- 架构：MVVM + Coordinator
- 网络：自定义 NetworkManager（基于 URLSession）
- 数据存储：Core Data + UserDefaults
- UI：SwiftUI + UIKit（部分遗留页面）

## 代码风格
- 遵循 SwiftLint 规则（.swiftlint.yml）
- 协议优于具体类型
- async/await 处理异步
- 避免强制解包

## 关键设计决策
### 错误处理
所有公开 API 使用 throws 和自定义 Error 枚举：
\`\`\`swift
enum NetworkError: Error {
    case invalidURL
    case noData
    // ...
}
\`\`\`

### 依赖注入
通过构造器注入，便于测试：
\`\`\`swift
class UserViewModel {
    init(repository: UserRepositoryProtocol) { ... }
}
\`\`\`
```

**使用方式：**
- 在 Cursor 中打开此文件，Cursor 会自动将其作为上下文
- 或在提示词中引用："按照 AGENTS.md 的约定生成代码"

### 2. 模块级上下文（Module-Level Context）

在每个模块/功能目录添加 README：

```
Modules/
├── Networking/
│   ├── README.md          # 网络模块说明
│   ├── NetworkManager.swift
│   └── APIEndpoint.swift
└── Storage/
    ├── README.md          # 存储模块说明
    └── ...
```

**`Modules/Networking/README.md` 示例：**
```markdown
# 网络模块

## 职责
统一管理所有 HTTP 请求，提供类型安全的网络访问。

## 核心类型
- `NetworkManager`: 网络请求管理器（协议 + 实现）
- `APIEndpoint`: API 端点枚举
- `NetworkError`: 网络错误类型

## 使用示例
\`\`\`swift
let manager = NetworkManager()
let data = try await manager.fetch(endpoint: .user(id: "123"))
\`\`\`

## 设计约定
- 所有方法使用 async/await
- 超时时间：30 秒
- 自动重试：最多 3 次（仅限网络超时）
```

**使用方式：**
- 修改该模块时，先让 AI 读取 README
- 或在提示词中说明："遵循 Networking/README.md 的设计"

### 3. 文件级上下文（File-Level Context）

在复杂类/结构体前添加注释：

```swift
/// 用户管理器
///
/// 职责：
/// - 从网络或缓存获取用户信息
/// - 管理用户缓存生命周期
///
/// 依赖：
/// - NetworkServiceProtocol: 网络请求抽象
/// - CacheProtocol: 缓存抽象
///
/// 设计决策：
/// - 优先返回缓存数据（Cache-First 策略）
/// - 缓存过期时间：1 小时
/// - 网络失败时不删除过期缓存（Stale-While-Revalidate）
///
/// 使用示例：
/// ```swift
/// let manager = UserManager(networkService: NetworkManager.shared, cache: MemoryCache.shared)
/// let user = try await manager.fetchUser(id: "123")
/// ```
class UserManager {
    // ...
}
```

**使用方式：**
- AI 读取文件时会理解设计意图
- 生成相关代码时遵循同样的模式

## 🛠️ 实战技巧

### 技巧 1：分层提供上下文

不要一次性粘贴整个项目代码，而是分层提供：

```
第 1 步：描述需求
"我需要为用户模块添加获取用户列表的功能"

第 2 步：提供架构上下文
"项目使用 MVVM，View 通过 ViewModel 访问数据，ViewModel 依赖 Repository"

第 3 步：提供关键类型
[粘贴 UserRepository 协议]
[粘贴 User 模型]

第 4 步：提供风格参考
[粘贴一个现有的类似方法]

第 5 步：明确要求
"生成以下内容：
1. Repository 方法签名
2. ViewModel 属性和方法
3. 单元测试"
```

### 技巧 2：使用"风格参考"而非"规则列表"

❌ **不好的做法：**
```
要求：
- 变量用 camelCase
- 常量用 let
- 私有方法用 private
- 错误用 throws
- ...（列举 20 条规则）
```

✅ **好的做法：**
```
参考以下代码风格生成新代码：

[粘贴一个现有的、风格良好的类]
```

AI 会自动学习并模仿这个风格。

### 技巧 3：提供"依赖协议"而非"具体实现"

❌ **不好的做法：**
```
[粘贴 NetworkManager 类的 200 行实现]
```

✅ **好的做法：**
```swift
// 项目中的网络服务协议
protocol NetworkServiceProtocol {
    func fetch(endpoint: APIEndpoint) async throws -> Data
}

// 项目中的 API 端点枚举
enum APIEndpoint {
    case user(id: String)
    case userList(page: Int)
}
```

AI 只需要知道接口，不需要实现细节。

### 技巧 4：用 Mock 对象说明测试策略

在生成测试时，提供一个 Mock 示例：

```swift
// 项目中的 Mock 风格示例
class MockNetworkService: NetworkServiceProtocol {
    var shouldThrowError = false
    var mockedData: Data?
    
    func fetch(endpoint: APIEndpoint) async throws -> Data {
        if shouldThrowError {
            throw NetworkError.requestFailed
        }
        return mockedData ?? Data()
    }
}
```

AI 会生成类似风格的 Mock。

### 技巧 5：分阶段确认

不要一次性生成所有代码：

```
第 1 步：生成计划
"列出需要生成的文件和方法"

[AI 输出计划]

第 2 步：确认计划
"计划确认，请生成 UserRepository 的方法"

[AI 生成代码]

第 3 步：逐步完善
"现在生成 ViewModel"
"现在生成单元测试"
```

这样可以在每一步纠正偏差。

## 📊 上下文质量检查清单

生成代码前，检查是否提供了以下上下文：

### 必需上下文
- [ ] 技术栈（Swift 版本、iOS 版本、框架）
- [ ] 架构模式（MVVM/MVI/其他）
- [ ] 关键依赖的协议或类型定义
- [ ] 错误处理策略（throws/Result/completion）
- [ ] 异步处理方式（async/await/closure）

### 推荐上下文
- [ ] 一个现有代码示例（作为风格参考）
- [ ] 测试框架和 Mock 策略
- [ ] 命名约定（如有特殊要求）
- [ ] 性能要求（如主线程限制）

### 可选上下文
- [ ] 项目 README 或 AGENTS.md
- [ ] 相关模块的文档
- [ ] 团队编码规范文档

## 🔄 上下文迭代优化

### 记录生成效果

每次使用 AI 生成代码后，记录：
- ✅ 哪些部分生成得很好（无需修改）
- ⚠️ 哪些部分需要小幅调整
- ❌ 哪些部分完全不符合预期

### 分析原因

对于不符合预期的部分：
- 是缺少上下文？（例如：没说明项目使用协议注入）
- 还是描述不清晰？（例如："生成网络请求" 太模糊）
- 还是提供了错误示例？（例如：参考的代码本身有问题）

### 更新上下文

根据分析结果，更新：
- 项目 AGENTS.md（补充缺失的设计决策）
- 模块 README（说明模块约定）
- 提示词模板（优化提示词结构）

### 案例：优化测试生成

**第 1 次尝试（效果差）：**
```
提示词："生成单元测试"
结果：生成了测试，但 Mock 对象风格不一致，命名混乱
```

**第 2 次尝试（改进）：**
```
提示词："生成单元测试，使用 XCTest，Mock 外部依赖"
结果：测试生成了，但测试命名不符合项目约定
```

**第 3 次尝试（优化）：**
```
提示词：
"生成单元测试
- 框架：XCTest
- 命名：test_<方法名>_<场景>_<预期结果>
- Mock 策略：参考以下示例

[粘贴一个现有的 Mock 类]
[粘贴一个现有的测试类]"

结果：✅ 测试质量高，符合项目规范
```

**更新上下文：**
将"测试生成"提示词保存到 `prompts/testing/unit-test.md`，下次直接复用。

## 📚 扩展阅读

### 本仓库资源
- [工作流：为 Swift 模块补充单元测试](../workflows/unit-test-generation.md)
- [提示词库](../prompts/)
- [配置模板](../templates/)
- [代码示例](../examples/)

### 外部资源
- [OpenAI: Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
- [Anthropic: Claude Prompt Design](https://docs.anthropic.com/claude/docs/introduction-to-prompt-design)
- [Cursor Documentation](https://docs.cursor.com/)

## 💡 总结

上下文工程的核心原则：

1. **最小化但完整**：提供刚好够用的上下文，不多不少
2. **示例优于规则**：一个好的代码示例胜过 10 条文字规则
3. **分层组织**：项目级 → 模块级 → 文件级
4. **持续迭代**：根据生成效果优化上下文设计

掌握上下文工程，可以让 AI 成为真正高效的编程伙伴。

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-23  
**反馈**：欢迎在 [Issues](https://github.com/SSLoong/ios-ai-coding-kit/issues) 分享你的实践经验！
