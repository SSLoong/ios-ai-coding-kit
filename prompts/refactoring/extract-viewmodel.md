# 提取业务逻辑到 ViewModel

## 场景说明
将 UIKit ViewController 中的业务逻辑提取到独立的 ViewModel，实现 MVVM 架构，提升可测试性。

## 输入要求

### 必需
- 目标 ViewController 的完整源代码
- 项目架构说明（MVVM 规范、依赖注入方式）
- ViewController 依赖的网络层、数据层接口定义

### 可选
- 项目中已有的 ViewModel 示例（作为风格参考）
- 现有的测试用例
- 特定的状态管理方案（Combine、RxSwift、async/await）

## 提示词模板

```
我需要将以下 UIKit ViewController 的业务逻辑提取到 ViewModel。

## 目标 ViewController
[粘贴完整的 ViewController 代码]

## 项目架构上下文
- 架构模式：MVVM
- 状态管理：[Combine / RxSwift / async/await + Closures]
- 依赖注入：通过初始化方法注入
- 网络层：[粘贴 NetworkService 协议定义]
- 数据层：[粘贴 Repository 或 DataManager 协议定义]

## 重构要求

### 1. ViewModel 职责划分
- ViewModel 负责：
  - 数据获取与转换（Model → ViewModel Data）
  - 业务逻辑与验证
  - 状态管理（loading、error、success）
  - 协调网络请求与数据持久化
  
- ViewController 保留：
  - UI 组件的创建与布局
  - 用户交互响应（点击、滑动等）
  - UI 状态更新（订阅 ViewModel 的状态）
  - 导航与路由（可选：也可由 Coordinator 负责）

### 2. 数据流设计
- 使用 [Combine 的 @Published / RxSwift 的 Observable / Closures] 传递状态
- ViewModel 暴露的状态应包含：
  - 数据模型（如 `@Published var user: User?`）
  - 加载状态（如 `@Published var isLoading: Bool`）
  - 错误信息（如 `@Published var errorMessage: String?`）

### 3. 协议化依赖
- ViewModel 通过协议依赖外部服务（便于测试 Mock）
  ```swift
  protocol UserProfileViewModelProtocol {
      var user: Published<User?>.Publisher { get }
      var isLoading: Published<Bool>.Publisher { get }
      var errorMessage: Published<String?>.Publisher { get }
      
      func loadUserProfile()
      func updateProfile(name: String, bio: String)
  }
  ```

### 4. 错误处理
- ViewModel 捕获所有错误，转换为用户友好的错误消息
- 不在 ViewModel 中直接展示 Alert（通过状态通知 ViewController）

## 输出格式

### 步骤 1：输出 ViewModel 接口设计
先输出 ViewModel 的协议定义和状态属性设计，等待我确认架构合理性。

### 步骤 2：生成 ViewModel 实现
确认后，生成：
1. 完整的 ViewModel 实现
2. 修改后的 ViewController（移除业务逻辑，只保留 UI）
3. ViewModel 的依赖协议定义（如果原 ViewController 直接依赖具体类）

### 步骤 3：生成基础单元测试
为 ViewModel 生成单元测试，覆盖：
- 数据加载成功场景
- 数据加载失败场景
- 业务逻辑验证（如表单校验）

## 附加约束
- 不改变 ViewController 的公开接口（避免影响其他模块）
- 保持现有的 delegate 调用（如导航回调）
- 遵循项目的 Swift 代码规范（SwiftLint）
```

## 使用示例

### 输入

假设有一个用户资料页面的 ViewController：

```swift
class UserProfileViewController: UIViewController {
    // UI Components
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let editButton = UIButton()
    
    // Dependencies (hardcoded)
    private let networkService = NetworkService.shared
    
    // State
    private var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserProfile()
    }
    
    private func loadUserProfile() {
        networkService.fetchUserProfile(userId: "123") { [weak self] result in
            switch result {
            case .success(let user):
                self?.user = user
                self?.updateUI(with: user)
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
    
    private func updateUI(with user: User) {
        nameLabel.text = user.name
        bioLabel.text = user.bio
    }
    
    @objc private func editButtonTapped() {
        // Show edit screen...
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}
```

### AI 输出（第一步：接口设计）

```markdown
## ViewModel 接口设计

### 状态属性
\`\`\`swift
protocol UserProfileViewModelProtocol {
    // 数据状态
    var user: Published<User?>.Publisher { get }
    
    // UI 状态
    var isLoading: Published<Bool>.Publisher { get }
    var errorMessage: Published<String?>.Publisher { get }
    
    // 操作
    func loadUserProfile()
    func refreshProfile()
}
\`\`\`

### 数据流
1. ViewController 订阅 `user`、`isLoading`、`errorMessage`
2. 调用 `loadUserProfile()` 触发数据加载
3. ViewModel 更新状态，ViewController 响应式更新 UI

是否确认这个设计？
```

### AI 输出（第二步：实现代码）

确认后，AI 生成：

```swift
// MARK: - ViewModel Protocol

protocol UserProfileViewModelProtocol {
    var user: Published<User?>.Publisher { get }
    var isLoading: Published<Bool>.Publisher { get }
    var errorMessage: Published<String?>.Publisher { get }
    
    func loadUserProfile()
    func refreshProfile()
}

// MARK: - ViewModel Implementation

final class UserProfileViewModel: UserProfileViewModelProtocol {
    // Published properties
    @Published private(set) var user: User?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    // Dependencies
    private let networkService: NetworkServiceProtocol
    private let userId: String
    
    // Publishers for protocol
    var user: Published<User?>.Publisher { $user }
    var isLoading: Published<Bool>.Publisher { $isLoading }
    var errorMessage: Published<String?>.Publisher { $errorMessage }
    
    init(networkService: NetworkServiceProtocol, userId: String) {
        self.networkService = networkService
        self.userId = userId
    }
    
    func loadUserProfile() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        networkService.fetchUserProfile(userId: userId) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let user):
                self.user = user
            case .failure(let error):
                self.errorMessage = self.mapErrorToMessage(error)
            }
        }
    }
    
    func refreshProfile() {
        loadUserProfile()
    }
    
    private func mapErrorToMessage(_ error: Error) -> String {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .noConnection:
                return "网络连接失败，请检查网络设置"
            case .timeout:
                return "请求超时，请稍后重试"
            case .serverError:
                return "服务器错误，请稍后重试"
            default:
                return "加载失败，请重试"
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Modified ViewController

class UserProfileViewController: UIViewController {
    // UI Components
    private let nameLabel = UILabel()
    private let bioLabel = UILabel()
    private let editButton = UIButton()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // Dependencies
    private let viewModel: UserProfileViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: UserProfileViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.loadUserProfile()
    }
    
    private func setupUI() {
        // UI setup code...
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.user
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.updateUI(with: user)
            }
            .store(in: &cancellables)
        
        viewModel.isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        viewModel.errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let message = errorMessage {
                    self?.showError(message)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with user: User?) {
        nameLabel.text = user?.name ?? "-"
        bioLabel.text = user?.bio ?? "暂无简介"
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
    }
    
    @objc private func editButtonTapped() {
        // Navigate to edit screen...
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Basic Unit Tests

import XCTest
@testable import YourModule

class UserProfileViewModelTests: XCTestCase {
    var sut: UserProfileViewModel!
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = UserProfileViewModel(networkService: mockNetworkService, userId: "123")
    }
    
    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }
    
    func test_loadUserProfile_success_updatesUser() {
        // Given
        let expectedUser = User(id: "123", name: "Test User", bio: "Test Bio")
        mockNetworkService.mockResult = .success(expectedUser)
        
        let expectation = XCTestExpectation(description: "User loaded")
        var receivedUser: User?
        
        sut.$user
            .dropFirst() // Skip initial nil
            .sink { user in
                receivedUser = user
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.loadUserProfile()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedUser?.id, expectedUser.id)
        XCTAssertEqual(receivedUser?.name, expectedUser.name)
    }
    
    func test_loadUserProfile_failure_setsErrorMessage() {
        // Given
        mockNetworkService.mockResult = .failure(NetworkError.noConnection)
        
        let expectation = XCTestExpectation(description: "Error received")
        var receivedError: String?
        
        sut.$errorMessage
            .dropFirst() // Skip initial nil
            .sink { errorMessage in
                receivedError = errorMessage
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        sut.loadUserProfile()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError, "网络连接失败，请检查网络设置")
    }
    
    func test_loadUserProfile_setsIsLoadingToTrueThenFalse() {
        // Given
        mockNetworkService.mockResult = .success(User(id: "123", name: "Test", bio: nil))
        
        var loadingStates: [Bool] = []
        
        sut.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
            }
            .store(in: &cancellables)
        
        // When
        sut.loadUserProfile()
        
        // Then
        XCTAssertEqual(loadingStates, [false, true, false])
    }
}

// Mock for testing
class MockNetworkService: NetworkServiceProtocol {
    var mockResult: Result<User, Error>?
    
    func fetchUserProfile(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        if let result = mockResult {
            completion(result)
        }
    }
}
```

## 注意事项

### ✅ 好的做法
- 先确认接口设计，避免生成后大改
- ViewModel 只处理业务逻辑，不涉及 UIKit 类型
- 通过协议注入依赖，便于单元测试
- 使用响应式框架（Combine/RxSwift）管理状态流

### ❌ 避免的做法
- ViewModel 直接持有 UIViewController 引用（循环引用风险）
- ViewModel 中出现 UIAlertController、UIColor 等 UIKit 类型
- 使用单例（如 `NetworkService.shared`），难以测试
- 状态更新不在主线程（导致 UI 更新崩溃）

### 🔧 常见调整

如果生成的 ViewModel 不符合项目风格，追加指令：

```
请调整以下内容：
1. 使用 async/await 替代 Combine（项目尚未引入 Combine）
2. 错误处理改为枚举类型 `enum ViewModelError`，而非 String
3. 添加日志记录：每次网络请求前后打印日志
4. 为每个方法添加文档注释
```

## 高级用法

### 场景一：多个网络请求的协调

```
UserProfileViewModel 需要同时请求：
1. 用户基本信息（/api/users/:id）
2. 用户的文章列表（/api/users/:id/posts）
3. 用户的关注状态（/api/users/:id/following）

要求：
- 三个请求并行执行
- 使用 Combine 的 zip 操作符合并结果
- 任一请求失败不影响其他数据展示
```

### 场景二：带表单验证的 ViewModel

```
为编辑资料页面的 ViewModel 添加实时验证：
- 姓名：非空，长度 2-20 字符
- 简介：可选，最多 200 字符
- 头像 URL：必须是合法的 URL

要求：
- 提供 `isFormValid` 属性，绑定到保存按钮的 enabled 状态
- 提供各字段的错误提示（如 `nameError: String?`）
```

### 场景三：分页加载的 ViewModel

```
为文章列表页的 ViewModel 添加分页加载逻辑：
- 初次加载 20 条
- 滚动到底部时加载更多
- 支持下拉刷新
- 处理空数据、网络错误、已全部加载等状态
```

## 相关资源
- [工作流：用 AI 重构遗留 UIKit 代码](../../workflows/uikit-refactoring.md)
- [提示词：优化 UIViewController 布局代码](./optimize-layout.md)
- [提示词：重构为协议化设计](./protocol-oriented.md)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-29  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
