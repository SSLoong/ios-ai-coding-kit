# 重构为协议化设计

## 场景说明
将 UIKit 代码中的具体类型依赖重构为面向协议设计（Protocol-Oriented Programming），提升代码的可测试性、可扩展性和模块解耦。

## 输入要求

### 必需
- 目标类的完整源代码（ViewController、ViewModel、Service 等）
- 类的依赖关系说明（依赖哪些具体类型）
- 项目的依赖注入方式（初始化注入、属性注入、Service Locator 等）

### 可选
- 项目中已有的协议设计示例
- 测试需求说明（哪些依赖需要 Mock）
- 架构模式（MVVM、VIPER、Clean Architecture 等）

## 提示词模板

```
我需要将以下代码重构为面向协议设计。

## 目标代码
[粘贴需要重构的类的完整代码]

## 当前依赖关系
该类直接依赖以下具体类型：
- [依赖 1]：[简述用途]
- [依赖 2]：[简述用途]
- [依赖 3]：[简述用途]

## 重构目标

### 1. 识别抽象边界
分析代码中的依赖，识别哪些应提取为协议：
- **优先**：外部服务（网络、数据库、文件系统、系统 API）
- **优先**：跨模块依赖（便于模块独立编译与测试）
- **次要**：复杂的业务逻辑类（便于单元测试）
- **不需要**：简单的数据模型（struct/enum）、工具类

### 2. 协议设计原则
- 遵循 Interface Segregation Principle（接口隔离原则）：协议只包含使用方需要的方法
- 命名约定：协议名以 `Protocol` 结尾（如 `NetworkServiceProtocol`）或使用形容词（如 `NetworkServicing`）
- 使用 `associatedtype` 或泛型支持灵活的返回类型
- 为协议添加文档注释，说明职责与使用场景

### 3. 依赖注入方式
- 通过初始化方法注入协议依赖：
  ```swift
  init(networkService: NetworkServiceProtocol, 
       cache: CacheProtocol) {
      self.networkService = networkService
      self.cache = cache
  }
  ```
- 移除单例依赖（如 `NetworkService.shared`）
- 使用协议类型声明属性：`private let networkService: NetworkServiceProtocol`

### 4. 提供默认实现
- 为协议提供具体实现类（如 `DefaultNetworkService: NetworkServiceProtocol`）
- 创建便捷初始化方法，使用默认实现：
  ```swift
  convenience init() {
      self.init(networkService: DefaultNetworkService(),
                cache: UserDefaultsCache())
  }
  ```

### 5. 测试支持
- 为每个协议创建 Mock 实现（用于单元测试）
- Mock 类命名：`Mock<协议名>`（如 `MockNetworkService`）
- Mock 应支持配置返回值与验证调用

## 输出格式

### 步骤 1：输出协议设计方案
先输出：
1. 建议提取的协议列表（协议名、职责、方法签名）
2. 不需要提取为协议的依赖（说明理由）
3. 依赖注入方案

等待确认后再生成代码。

### 步骤 2：生成完整代码
确认后，输出：
1. 所有协议定义（带文档注释）
2. 协议的默认实现类
3. 重构后的目标类（依赖协议而非具体类型）
4. Mock 实现（用于测试）
5. 使用示例（包括生产环境和测试环境的初始化）

## 附加约束
- 保持公开 API 不变（向后兼容）
- 不改变业务逻辑行为
- 遵循项目的 Swift 代码规范
```

## 使用示例

### 输入

一个直接依赖具体类型的 ViewModel：

```swift
class UserProfileViewModel {
    private let networkService = NetworkService() // 具体类型
    private let imageUploader = ImageUploader() // 具体类型
    private let userDefaults = UserDefaults.standard // 系统单例
    
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadUserProfile(userId: String) {
        isLoading = true
        
        networkService.fetchUser(userId: userId) { [weak self] result in
            self?.isLoading = false
            
            switch result {
            case .success(let user):
                self?.user = user
                self?.cacheUser(user)
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func uploadAvatar(image: UIImage) {
        guard let userId = user?.id else { return }
        
        imageUploader.upload(image: image, userId: userId) { [weak self] result in
            switch result {
            case .success(let imageURL):
                self?.updateUserAvatar(imageURL)
            case .failure(let error):
                self?.errorMessage = "上传失败：\(error.localizedDescription)"
            }
        }
    }
    
    private func cacheUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: "cached_user")
        }
    }
    
    private func updateUserAvatar(_ imageURL: String) {
        // Update logic...
    }
}
```

### AI 输出（第一步：协议设计方案）

```markdown
## 协议提取方案

### 需要提取的协议

#### 1. NetworkServiceProtocol
**职责**：处理网络请求
**理由**：外部依赖，需要在测试中 Mock，避免真实网络请求

\`\`\`swift
protocol NetworkServiceProtocol {
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void)
}
\`\`\`

#### 2. ImageUploadServiceProtocol
**职责**：上传图片到服务器
**理由**：外部依赖，测试时需要 Mock 避免真实上传

\`\`\`swift
protocol ImageUploadServiceProtocol {
    func upload(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void)
}
\`\`\`

#### 3. UserCacheProtocol
**职责**：缓存用户数据
**理由**：持久化操作，测试时需要 Mock 避免影响真实存储

\`\`\`swift
protocol UserCacheProtocol {
    func save(user: User)
    func load() -> User?
    func clear()
}
\`\`\`

### 不需要提取的类型
- `User` 模型：简单的数据结构，不需要抽象
- `UIImage`：系统类型，不需要包装

### 依赖注入方案
通过初始化方法注入三个协议依赖：

\`\`\`swift
init(networkService: NetworkServiceProtocol,
     imageUploadService: ImageUploadServiceProtocol,
     userCache: UserCacheProtocol)
\`\`\`

提供便捷初始化方法使用默认实现：

\`\`\`swift
convenience init() {
    self.init(
        networkService: DefaultNetworkService(),
        imageUploadService: DefaultImageUploadService(),
        userCache: UserDefaultsUserCache()
    )
}
\`\`\`

是否确认这个设计？
```

### AI 输出（第二步：完整代码）

```swift
// MARK: - Protocol Definitions

/// 处理用户相关的网络请求
protocol NetworkServiceProtocol {
    /// 获取用户信息
    /// - Parameters:
    ///   - userId: 用户 ID
    ///   - completion: 完成回调，返回 User 或 Error
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void)
}

/// 处理图片上传服务
protocol ImageUploadServiceProtocol {
    /// 上传图片到服务器
    /// - Parameters:
    ///   - image: 要上传的图片
    ///   - userId: 用户 ID
    ///   - completion: 完成回调，返回图片 URL 或 Error
    func upload(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void)
}

/// 缓存用户数据
protocol UserCacheProtocol {
    /// 保存用户到缓存
    func save(user: User)
    
    /// 从缓存加载用户
    func load() -> User?
    
    /// 清空缓存
    func clear()
}

// MARK: - Default Implementations

/// NetworkServiceProtocol 的默认实现
final class DefaultNetworkService: NetworkServiceProtocol {
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        // 原 NetworkService 的实现
        // ...
    }
}

/// ImageUploadServiceProtocol 的默认实现
final class DefaultImageUploadService: ImageUploadServiceProtocol {
    func upload(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        // 原 ImageUploader 的实现
        // ...
    }
}

/// UserCacheProtocol 的 UserDefaults 实现
final class UserDefaultsUserCache: UserCacheProtocol {
    private let userDefaults: UserDefaults
    private let cacheKey = "cached_user"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func save(user: User) {
        if let data = try? JSONEncoder().encode(user) {
            userDefaults.set(data, forKey: cacheKey)
        }
    }
    
    func load() -> User? {
        guard let data = userDefaults.data(forKey: cacheKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }
    
    func clear() {
        userDefaults.removeObject(forKey: cacheKey)
    }
}

// MARK: - Refactored ViewModel

final class UserProfileViewModel {
    // Dependencies (protocols)
    private let networkService: NetworkServiceProtocol
    private let imageUploadService: ImageUploadServiceProtocol
    private let userCache: UserCacheProtocol
    
    // Published properties
    @Published var user: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    /// 使用自定义依赖初始化（主要用于测试）
    init(networkService: NetworkServiceProtocol,
         imageUploadService: ImageUploadServiceProtocol,
         userCache: UserCacheProtocol) {
        self.networkService = networkService
        self.imageUploadService = imageUploadService
        self.userCache = userCache
    }
    
    /// 使用默认依赖初始化（生产环境）
    convenience init() {
        self.init(
            networkService: DefaultNetworkService(),
            imageUploadService: DefaultImageUploadService(),
            userCache: UserDefaultsUserCache()
        )
    }
    
    // MARK: - Public Methods
    
    func loadUserProfile(userId: String) {
        isLoading = true
        errorMessage = nil
        
        networkService.fetchUser(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let user):
                self.user = user
                self.userCache.save(user: user)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func uploadAvatar(image: UIImage) {
        guard let userId = user?.id else {
            errorMessage = "用户信息不存在"
            return
        }
        
        isLoading = true
        
        imageUploadService.upload(image: image, userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let imageURL):
                self.updateUserAvatar(imageURL)
            case .failure(let error):
                self.errorMessage = "上传失败：\(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func updateUserAvatar(_ imageURL: String) {
        // Update logic...
    }
}

// MARK: - Mock Implementations for Testing

/// NetworkServiceProtocol 的 Mock 实现
final class MockNetworkService: NetworkServiceProtocol {
    var fetchUserResult: Result<User, Error>?
    var fetchUserCallCount = 0
    
    func fetchUser(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        fetchUserCallCount += 1
        if let result = fetchUserResult {
            completion(result)
        }
    }
}

/// ImageUploadServiceProtocol 的 Mock 实现
final class MockImageUploadService: ImageUploadServiceProtocol {
    var uploadResult: Result<String, Error>?
    var uploadCallCount = 0
    var uploadedImage: UIImage?
    
    func upload(image: UIImage, userId: String, completion: @escaping (Result<String, Error>) -> Void) {
        uploadCallCount += 1
        uploadedImage = image
        if let result = uploadResult {
            completion(result)
        }
    }
}

/// UserCacheProtocol 的 Mock 实现
final class MockUserCache: UserCacheProtocol {
    var savedUser: User?
    var loadReturnValue: User?
    var saveCallCount = 0
    var loadCallCount = 0
    var clearCallCount = 0
    
    func save(user: User) {
        saveCallCount += 1
        savedUser = user
    }
    
    func load() -> User? {
        loadCallCount += 1
        return loadReturnValue
    }
    
    func clear() {
        clearCallCount += 1
        savedUser = nil
    }
}

// MARK: - Usage Examples

// 生产环境：使用默认依赖
let viewModel = UserProfileViewModel()

// 测试环境：注入 Mock 依赖
let mockNetworkService = MockNetworkService()
mockNetworkService.fetchUserResult = .success(User(id: "123", name: "Test User"))

let mockImageUploader = MockImageUploadService()
mockImageUploader.uploadResult = .success("https://example.com/avatar.jpg")

let mockCache = MockUserCache()

let testViewModel = UserProfileViewModel(
    networkService: mockNetworkService,
    imageUploadService: mockImageUploader,
    userCache: mockCache
)

// MARK: - Unit Test Example

import XCTest

final class UserProfileViewModelTests: XCTestCase {
    var sut: UserProfileViewModel!
    var mockNetworkService: MockNetworkService!
    var mockImageUploader: MockImageUploadService!
    var mockCache: MockUserCache!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockImageUploader = MockImageUploadService()
        mockCache = MockUserCache()
        
        sut = UserProfileViewModel(
            networkService: mockNetworkService,
            imageUploadService: mockImageUploader,
            userCache: mockCache
        )
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        mockImageUploader = nil
        mockCache = nil
        super.tearDown()
    }
    
    func test_loadUserProfile_success_savesToCache() {
        // Given
        let expectedUser = User(id: "123", name: "Test User")
        mockNetworkService.fetchUserResult = .success(expectedUser)
        
        // When
        sut.loadUserProfile(userId: "123")
        
        // Then
        XCTAssertEqual(mockNetworkService.fetchUserCallCount, 1)
        XCTAssertEqual(mockCache.saveCallCount, 1)
        XCTAssertEqual(mockCache.savedUser?.id, expectedUser.id)
    }
    
    func test_uploadAvatar_success_updatesAvatar() {
        // Given
        sut.user = User(id: "123", name: "Test")
        let testImage = UIImage()
        mockImageUploader.uploadResult = .success("https://example.com/avatar.jpg")
        
        // When
        sut.uploadAvatar(image: testImage)
        
        // Then
        XCTAssertEqual(mockImageUploader.uploadCallCount, 1)
        XCTAssertNotNil(mockImageUploader.uploadedImage)
    }
}
```

### 重构效果

**重构前的问题：**
- 直接依赖具体类型，难以单元测试
- 使用单例（`UserDefaults.standard`），测试时污染真实存储
- 无法在测试中控制网络请求和上传行为

**重构后的改进：**
- 所有外部依赖通过协议注入，易于 Mock
- 提供默认实现，生产环境无需改动
- 完整的 Mock 实现，支持单元测试验证调用
- 测试覆盖率可从 < 20% 提升到 > 80%

## 注意事项

### ✅ 好的做法
- 优先为外部依赖（网络、数据库、系统 API）提取协议
- 协议方法签名保持简洁，遵循接口隔离原则
- 为协议添加文档注释，说明职责与使用场景
- Mock 实现支持验证调用次数和参数

### ❌ 避免的做法
- 为所有类型提取协议（过度抽象，增加复杂度）
- 协议包含过多方法（违反接口隔离原则）
- 协议命名模糊：`ServiceProtocol`、`ManagerProtocol`（不知道具体职责）
- Mock 实现过于简单，无法验证调用行为

### 🔧 常见调整

如果生成的协议设计不符合预期，追加指令：

```
请调整以下内容：
1. 将 NetworkServiceProtocol 拆分为 UserNetworkServiceProtocol 和 PostNetworkServiceProtocol（接口隔离）
2. 使用 async/await 替代 completion handler（项目已支持 Swift Concurrency）
3. 为 UserCacheProtocol 添加泛型支持，便于缓存其他类型
4. Mock 实现添加 XCTAssert，在方法被调用时自动验证
```

## 高级用法

### 场景一：使用 associatedtype 支持泛型协议

```
请将 CacheProtocol 改为泛型协议，支持缓存任意 Codable 类型：

protocol CacheProtocol {
    associatedtype Value: Codable
    func save(_ value: Value, forKey key: String)
    func load(forKey key: String) -> Value?
    func clear(forKey key: String)
}

并提供 UserCache 和 PostCache 的具体实现。
```

### 场景二：协议组合（Protocol Composition）

```
UserProfileViewModel 依赖的网络服务包含多个职责：
- 获取用户信息
- 更新用户资料
- 上传头像

请拆分为三个独立协议：
- UserFetchable
- UserUpdatable
- AvatarUploadable

ViewModel 通过协议组合依赖：
typealias UserNetworkService = UserFetchable & UserUpdatable & AvatarUploadable
```

### 场景三：使用 Dependency Container

```
项目有多个 ViewModel，它们共享相同的依赖（NetworkService、Cache 等）。

请创建一个 DependencyContainer 管理依赖注入：
- 单例模式提供默认依赖
- 支持替换为测试依赖
- 避免每个 ViewModel 重复传递依赖
```

## 相关资源
- [工作流：用 AI 重构遗留 UIKit 代码](../../workflows/uikit-refactoring.md)
- [提示词：提取业务逻辑到 ViewModel](./extract-viewmodel.md)
- [提示词：优化 UIViewController 布局代码](./optimize-layout.md)
- [Swift Protocol-Oriented Programming (Apple)](https://developer.apple.com/videos/play/wwdc2015/408/)
- [SOLID 原则在 Swift 中的实践](https://www.swiftbysundell.com/articles/solid-swift/)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-29  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
