# Page Object 生成

## 场景说明
为 iOS UI 测试页面生成 Page Object 类，封装页面元素查询和操作逻辑，提升测试代码可维护性和复用性。

## 输入要求

### 必需
- 页面名称（如：LoginScreen、CheckoutScreen）
- 页面中的可达性标识符列表（Accessibility Identifiers）
- 主要操作流程（如：登录需要输入用户名、密码，点击按钮）

### 可选
- 页面截图或 UI 层级描述
- 现有 Page Object 示例（作为风格参考）
- 特殊交互需求（滚动、滑动、长按）

## 提示词模板

```
请为 iOS UI 测试生成 Page Object 类。

## 页面信息
- **页面名称**：[如：LoginScreen]
- **页面功能**：[简述页面用途，如：用户登录入口]
- **技术栈**：XCUITest

## 页面元素与标识符

### 交互元素（需要操作）
| 元素描述 | 类型 | Accessibility Identifier |
|---------|------|-------------------------|
| [用户名输入框] | TextField | `login_textfield_username` |
| [密码输入框] | SecureTextField | `login_textfield_password` |
| [登录按钮] | Button | `login_button_submit` |
| [忘记密码链接] | Button | `login_button_forgotPassword` |

### 断言元素（需要验证）
| 元素描述 | 类型 | Accessibility Identifier |
|---------|------|-------------------------|
| [错误提示文本] | Label | `login_label_errorMessage` |
| [加载指示器] | ActivityIndicator | `login_indicator_loading` |

## 主要操作流程
1. 输入用户名和密码
2. 点击登录按钮
3. 等待页面跳转或显示错误提示

## 代码要求

### 1. 类结构
- 类名：`<PageName>Screen`（如 `LoginScreen`）
- 初始化方法接收 `XCUIApplication` 实例
- 使用 `private let app` 存储应用引用

### 2. 元素属性
- 所有元素定义为**计算属性**（避免过早查询）
- 使用懒加载，按需访问
- 分组注释：`// MARK: - Elements`

### 3. 操作方法
- 封装高层操作（如 `login(username:password:)`）
- 返回 `Self`，支持链式调用
- 分组注释：`// MARK: - Actions`

### 4. 等待方法
- 提供 `waitForPageToLoad(timeout:)` 方法
- 内部使用 `waitForExistence(timeout:)`
- 返回 `Self`，支持链式调用
- 分组注释：`// MARK: - Waiting`

### 5. 断言辅助
- 提供布尔属性判断状态（如 `isErrorMessageVisible`）
- 提供 `errorMessageText` 等只读属性获取动态内容
- 分组注释：`// MARK: - Assertions`

### 6. 代码风格
- 使用 Swift 命名规范（驼峰命名）
- 添加适当的注释说明复杂操作
- 保持方法简洁（单一职责）

## 示例输出格式

```swift
import XCTest

/// 登录页面 Page Object
final class LoginScreen {
    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // MARK: - Elements
    
    var usernameTextField: XCUIElement {
        app.textFields["login_textfield_username"]
    }
    
    var passwordTextField: XCUIElement {
        app.secureTextFields["login_textfield_password"]
    }
    
    var submitButton: XCUIElement {
        app.buttons["login_button_submit"]
    }
    
    var forgotPasswordButton: XCUIElement {
        app.buttons["login_button_forgotPassword"]
    }
    
    var errorMessageLabel: XCUIElement {
        app.staticTexts["login_label_errorMessage"]
    }
    
    var loadingIndicator: XCUIElement {
        app.activityIndicators["login_indicator_loading"]
    }
    
    // MARK: - Actions
    
    /// 执行登录操作
    /// - Parameters:
    ///   - username: 用户名
    ///   - password: 密码
    /// - Returns: Self，支持链式调用
    @discardableResult
    func login(username: String, password: String) -> Self {
        usernameTextField.tap()
        usernameTextField.typeText(username)
        
        passwordTextField.tap()
        passwordTextField.typeText(password)
        
        submitButton.tap()
        return self
    }
    
    /// 点击"忘记密码"链接
    @discardableResult
    func tapForgotPassword() -> Self {
        forgotPasswordButton.tap()
        return self
    }
    
    // MARK: - Waiting
    
    /// 等待登录页加载完成
    /// - Parameter timeout: 超时时间（秒）
    /// - Returns: Self，支持链式调用
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 5) -> Self {
        _ = usernameTextField.waitForExistence(timeout: timeout)
        return self
    }
    
    /// 等待加载指示器消失
    /// - Parameter timeout: 超时时间（秒）
    /// - Returns: Self，支持链式调用
    @discardableResult
    func waitForLoadingToFinish(timeout: TimeInterval = 10) -> Self {
        if loadingIndicator.exists {
            let notExists = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: notExists, object: loadingIndicator)
            _ = XCTWaiter().wait(for: [expectation], timeout: timeout)
        }
        return self
    }
    
    // MARK: - Assertions
    
    /// 错误提示是否可见
    var isErrorMessageVisible: Bool {
        errorMessageLabel.exists
    }
    
    /// 错误提示文本内容
    var errorMessageText: String {
        errorMessageLabel.label
    }
    
    /// 加载指示器是否正在显示
    var isLoading: Bool {
        loadingIndicator.exists
    }
}
```

## 使用方式

```swift
// 在测试用例中使用
func test_loginWithValidCredentials_success() {
    // Given
    let loginScreen = LoginScreen(app: app)
        .waitForPageToLoad()
    
    // When
    loginScreen.login(username: "testuser", password: "Test1234")
    
    // Then
    let homeScreen = HomeScreen(app: app)
    XCTAssertTrue(homeScreen.avatarImage.waitForExistence(timeout: 5))
}

func test_loginWithInvalidPassword_showsError() {
    // Given
    let loginScreen = LoginScreen(app: app)
        .waitForPageToLoad()
    
    // When
    loginScreen.login(username: "testuser", password: "wrong")
    
    // Then
    XCTAssertTrue(loginScreen.isErrorMessageVisible)
    XCTAssertEqual(loginScreen.errorMessageText, "用户名或密码错误")
}
```
```

## 使用示例

### 输入

```
请为 iOS UI 测试生成 Page Object 类。

## 页面信息
- **页面名称**：ProductDetailScreen
- **页面功能**：商品详情页，展示商品信息和购买操作
- **技术栈**：XCUITest

## 页面元素与标识符

### 交互元素
| 元素描述 | 类型 | Accessibility Identifier |
|---------|------|-------------------------|
| 商品图片 | Image | `product_image_cover` |
| 加入购物车按钮 | Button | `product_button_addToCart` |
| 立即购买按钮 | Button | `product_button_buyNow` |
| 数量减少按钮 | Button | `product_button_decreaseQuantity` |
| 数量增加按钮 | Button | `product_button_increaseQuantity` |

### 断言元素
| 元素描述 | 类型 | Accessibility Identifier |
|---------|------|-------------------------|
| 商品标题 | Label | `product_label_title` |
| 商品价格 | Label | `product_label_price` |
| 当前数量 | Label | `product_label_quantity` |

## 主要操作流程
1. 调整购买数量（点击 +/- 按钮）
2. 加入购物车或立即购买
```

### AI 输出（部分）

```swift
import XCTest

/// 商品详情页 Page Object
final class ProductDetailScreen {
    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // MARK: - Elements
    
    var coverImage: XCUIElement {
        app.images["product_image_cover"]
    }
    
    var addToCartButton: XCUIElement {
        app.buttons["product_button_addToCart"]
    }
    
    var buyNowButton: XCUIElement {
        app.buttons["product_button_buyNow"]
    }
    
    var decreaseQuantityButton: XCUIElement {
        app.buttons["product_button_decreaseQuantity"]
    }
    
    var increaseQuantityButton: XCUIElement {
        app.buttons["product_button_increaseQuantity"]
    }
    
    var titleLabel: XCUIElement {
        app.staticTexts["product_label_title"]
    }
    
    var priceLabel: XCUIElement {
        app.staticTexts["product_label_price"]
    }
    
    var quantityLabel: XCUIElement {
        app.staticTexts["product_label_quantity"]
    }
    
    // MARK: - Actions
    
    /// 设置购买数量
    /// - Parameter quantity: 目标数量
    /// - Returns: Self，支持链式调用
    @discardableResult
    func setQuantity(_ quantity: Int) -> Self {
        let currentQuantity = Int(quantityLabel.label) ?? 1
        let difference = quantity - currentQuantity
        
        if difference > 0 {
            for _ in 0..<difference {
                increaseQuantityButton.tap()
            }
        } else if difference < 0 {
            for _ in 0..<abs(difference) {
                decreaseQuantityButton.tap()
            }
        }
        return self
    }
    
    /// 加入购物车
    @discardableResult
    func addToCart() -> Self {
        addToCartButton.tap()
        return self
    }
    
    /// 立即购买
    @discardableResult
    func buyNow() -> Self {
        buyNowButton.tap()
        return self
    }
    
    // MARK: - Waiting
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 5) -> Self {
        _ = titleLabel.waitForExistence(timeout: timeout)
        return self
    }
    
    // MARK: - Assertions
    
    var productTitle: String {
        titleLabel.label
    }
    
    var productPrice: String {
        priceLabel.label
    }
    
    var currentQuantity: Int {
        Int(quantityLabel.label) ?? 0
    }
}
```

## 注意事项

### ✅ 好的做法
- **元素查询延迟执行**：使用计算属性而非 `let`，避免初始化时元素未加载
- **链式调用**：操作方法返回 `Self`，支持连贯的测试代码（`.waitForPageToLoad().login(...)`）
- **封装高层操作**：提供 `login(username:password:)` 而非暴露每个输入框的操作
- **等待策略明确**：每个 Page Object 提供 `waitForPageToLoad` 方法

### ❌ 避免的做法
- 在 Page Object 中写断言（`XCTAssert...`），应该只提供查询方法，断言留给测试用例
- 元素查询写在 `init` 中（会过早执行，可能失败）
- 操作方法过于底层（如 `tapUsernameTextField`），应封装为业务操作
- 缺少等待逻辑，直接操作元素（易导致 flaky）

### 🔧 常见调整

如果生成的 Page Object 不符合预期，可以追加指令：

```
请调整以下内容：
1. 为 `login()` 方法添加键盘收起逻辑（输入后点击 Done）
2. 增加 `loginAndWaitForResult(timeout:)` 方法，等待登录完成（加载指示器消失）
3. 将所有按钮的 `tap()` 改为 `waitAndTap(timeout: 5)`（需先实现 XCUIElement 扩展）
4. 提取 BasePage 基类，包含通用的等待方法
```

## 高级用法

### 场景一：生成 Base Page 基类

```
额外要求：
- 创建 `BasePage` 基类，包含通用方法：
  - `waitForElement(_:timeout:)` - 等待元素出现
  - `dismissKeyboard()` - 收起键盘
  - `scrollToElement(_:)` - 滚动到元素可见
- 所有 Page Object 继承自 `BasePage`
```

### 场景二：处理列表/TableView

```
页面信息补充：
- 页面包含 UITableView，显示商品列表
- 每个 cell 的标识符格式：`list_cell_product_{index}`

代码要求：
- 提供 `productCell(at index: Int)` 方法获取指定 cell
- 提供 `scrollToProduct(at index: Int)` 方法滚动到指定 cell
- 提供 `tapProduct(at index: Int)` 方法点击商品进入详情
```

### 场景三：页面导航封装

```
额外要求：
- 操作方法返回下一个页面的 Page Object
- 例如：`func login(...) -> HomeScreen`（登录成功跳转到首页）
- 链式调用示例：`LoginScreen(app).login(...).tapProfile()`
```

## 相关资源
- [工作流：XCUITest UI 自动化测试](../../workflows/xcuitest-generation.md)
- [提示词：UI 测试用例规划](./test-case-planning.md)
- [提示词：Flaky 测试诊断](./flaky-test-diagnosis.md)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-05  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
