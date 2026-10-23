# AI Agents 使用指南

本文档说明如何使用 AI 工具（Cursor、Claude Code、GitHub Copilot 等）协助开发本项目。

## 📋 项目概览

### 基本信息
- **项目名称**：[填写项目名称]
- **技术栈**：Swift, iOS 15.0+, [UIKit/SwiftUI], [其他框架]
- **架构模式**：[MVVM/MVI/其他]
- **包管理**：[SPM/CocoaPods/Carthage]

### 代码风格
- 遵循 [SwiftLint 配置](../.swiftlint.yml)（如果有）
- 命名约定：类型用 PascalCase，变量用 camelCase
- 使用 `let` 优于 `var`，优先使用协议

## 🗂️ 项目结构

```
YourProject/
├── App/                    # 应用入口、AppDelegate、SceneDelegate
├── Modules/                # 功能模块
│   ├── Home/              # 首页模块
│   │   ├── Views/         # 视图
│   │   ├── ViewModels/    # 视图模型
│   │   └── Models/        # 数据模型
│   ├── Profile/           # 个人资料模块
│   └── ...
├── Core/                   # 核心功能
│   ├── Networking/        # 网络层
│   ├── Storage/           # 数据存储
│   └── Extensions/        # 扩展
├── Resources/              # 资源文件
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/                  # 测试
    ├── UnitTests/
    └── UITests/
```

## 🎯 关键模块说明

### 网络层 (`Core/Networking/`)
- **NetworkManager**：统一的网络请求管理
- **APIEndpoint**：API 端点定义
- **NetworkError**：网络错误类型

**重要约定：**
- 所有网络请求使用 async/await
- 错误统一通过 `NetworkError` 抛出
- 超时时间：30 秒（可配置）

### 数据层 (`Core/Storage/`)
- **UserDefaultsManager**：UserDefaults 封装
- **CacheManager**：内存/磁盘缓存
- **DatabaseManager**：[Core Data/Realm] 管理

**重要约定：**
- 敏感数据存储在 Keychain
- 大文件使用磁盘缓存
- 缓存过期时间：24 小时

### UI 层 (`Modules/`)
- **架构**：MVVM（View - ViewModel - Model）
- **数据绑定**：[Combine/RxSwift/手动绑定]
- **导航**：[Coordinator/自定义]

**重要约定：**
- ViewModel 不持有 View 引用
- 所有 UI 更新在主线程
- 复杂视图使用 `MARK:` 分组

## 🤖 AI 助手使用指南

### 生成新功能模块

当添加新功能时，提供以下上下文：

```
我需要创建一个新的 [功能名称] 模块。

## 功能描述
[描述功能需求]

## 技术要求
- 架构：MVVM
- 网络请求：使用 Core/Networking/NetworkManager
- 数据存储：使用 UserDefaultsManager
- UI 框架：[UIKit/SwiftUI]

## 参考模块
参考 Modules/Home/ 的结构和代码风格

## 输出要求
1. 创建目录结构
2. 生成 View、ViewModel、Model
3. 实现网络请求和数据绑定
4. 添加单元测试
```

### 重构现有代码

当需要重构时：

```
我需要重构 [文件路径]。

## 重构目标
[说明重构原因：性能优化/可读性/可维护性]

## 约束条件
- 保持现有接口不变（或说明需要改动的接口）
- 测试必须通过
- 遵循项目架构模式

## 预期结果
[说明重构后的期望状态]
```

### 补充单元测试

```
为 [类名/文件路径] 生成单元测试。

## 测试要求
- 使用 XCTest 框架
- Mock 所有外部依赖（网络、数据库）
- 覆盖正常流程、边界条件、错误处理
- 测试覆盖率目标：80%+

## 现有测试参考
[粘贴一个现有测试类作为风格参考]
```

## 📚 关键设计决策

### 1. 异步处理
**决策**：全面采用 Swift Concurrency (async/await)
**原因**：
- 避免回调地狱
- 代码更直观易读
- 与 iOS 16+ 异步 API 一致

**示例**：
```swift
// ✅ 推荐
func fetchUser(id: String) async throws -> User {
    let data = try await networkManager.fetch(endpoint: .user(id))
    return try JSONDecoder().decode(User.self, from: data)
}

// ❌ 避免
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    // ...
}
```

### 2. 依赖注入
**决策**：通过构造器注入依赖
**原因**：
- 提高可测试性
- 依赖关系清晰
- 避免隐式依赖

**示例**：
```swift
// ✅ 推荐
class UserViewModel {
    private let networkManager: NetworkManagerProtocol
    
    init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }
}

// ❌ 避免直接使用单例
class UserViewModel {
    func fetchUser() {
        NetworkManager.shared.fetch() // 难以测试
    }
}
```

### 3. 错误处理
**决策**：使用 `throws` 和自定义 `Error` 类型
**原因**：
- 类型安全
- 强制错误处理
- 便于追踪错误源

**示例**：
```swift
enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingFailed(Error)
    case httpError(statusCode: Int)
}
```

## ⚠️ 常见陷阱

### 1. 循环引用
```swift
// ❌ 可能导致循环引用
viewModel.onDataUpdate = {
    self.tableView.reloadData()
}

// ✅ 使用 [weak self]
viewModel.onDataUpdate = { [weak self] in
    self?.tableView.reloadData()
}
```

### 2. 主线程阻塞
```swift
// ❌ 阻塞主线程
func loadImage() {
    let data = try? Data(contentsOf: imageURL) // 同步网络请求！
}

// ✅ 使用异步
func loadImage() async throws {
    let (data, _) = try await URLSession.shared.data(from: imageURL)
}
```

### 3. 强制解包
```swift
// ❌ 可能崩溃
let user = userManager.currentUser!

// ✅ 安全解包
guard let user = userManager.currentUser else {
    return
}
```

## 🔧 开发工具配置

### Cursor 配置
将 `templates/cursor-rules/basic-swift.cursorrules` 复制到项目根目录作为 `.cursorrules`

### SwiftLint
配置文件：`.swiftlint.yml`
运行检查：`swiftlint lint`

### 单元测试
运行所有测试：`⌘ + U`
运行特定测试：右键点击测试方法 → Run

## 📖 扩展阅读

- [项目上下文文档](./CONTEXT.md)
- [API 文档](./docs/API.md)（如果有）
- [架构设计文档](./docs/Architecture.md)（如果有）

---

**最后更新**：[日期]  
**维护者**：[团队名称/负责人]

**使用提示**：将此文档复制到项目根目录，并根据实际情况填充 `[占位符]` 内容。
