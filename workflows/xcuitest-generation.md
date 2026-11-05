# 工作流：XCUITest UI 自动化测试

## 📋 背景

iOS UI 自动化测试（XCUITest）是保障用户界面质量的重要手段，但在实际项目中常面临以下挑战：
- 测试编写耗时，手动录制生成的代码脆弱且难维护
- 异步加载、动画、网络请求导致测试不稳定（flaky tests）
- 缺乏统一的页面对象模型，重复代码多
- 可达性标识（Accessibility Identifier）遗漏或命名混乱

使用 AI 辅助生成 XCUITest，可以系统化地解决上述问题，快速构建稳定、可维护的 UI 测试套件。

## 🎯 目标

为 iOS 应用生成高质量 UI 自动化测试，达到以下标准：
- **完整性**：覆盖核心用户流程（登录、主流程、关键交互）
- **稳定性**：合理等待策略，flaky rate < 5%
- **可维护性**：采用 Page Object 模式，职责清晰
- **可读性**：测试用例遵循 Given-When-Then 结构，命名清晰
- **可达性标识规范**：统一命名约定（如 `module_component_action`）

## 🛠️ 适用场景

- ✅ 为关键用户流程添加端到端 UI 测试
- ✅ 回归测试自动化（替代手工点击验证）
- ✅ 重构后的 UI 行为验证
- ✅ 多语言/多主题适配的一致性测试
- ❌ 不适合单元测试（应使用 XCTest，参见 [单元测试工作流](./unit-test-generation.md)）
- ❌ 不适合复杂手势或特殊传感器交互（需手动编写）

## 📝 工作流步骤

### 步骤 1：规划测试用例

#### 1.1 分析用户流程
使用 AI 分析应用功能，生成测试计划：

```
我需要为 iOS 应用的 [模块名称] 规划 UI 自动化测试。

## 应用信息
- 模块：[如：登录模块、购物车流程]
- 技术栈：[UIKit/SwiftUI]
- 现有页面：[列出主要页面和功能]

## 测试目标
- 覆盖核心用户路径（Happy Path）
- 包含错误处理场景（网络失败、无效输入）
- 验证关键状态转换

## 输出要求
1. 列出需要测试的用户流程（按优先级排序）
2. 每个流程用 Given-When-Then 格式描述
3. 标注需要的可达性标识（Accessibility Identifier）

## 示例输出格式
### 用户流程 1：用户登录
**优先级**：P0（核心流程）

**Given**：用户未登录，在登录页
**When**：输入有效用户名和密码，点击登录按钮
**Then**：跳转到首页，显示用户头像

**所需可达性标识**：
- `login_textfield_username`
- `login_textfield_password`
- `login_button_submit`
- `home_image_avatar`
```

#### 1.2 审查测试计划
人工审查 AI 生成的计划，确保：
- 覆盖了主流程和关键分支
- Given-When-Then 描述清晰
- 可达性标识命名符合团队规范（建议格式：`模块_组件_动作`）

### 步骤 2：添加可达性标识

在开始编写测试前，先为 UI 元素添加 Accessibility Identifier。

#### 2.1 使用 AI 批量生成标识符

```
请为以下 [UIKit ViewController / SwiftUI View] 添加 Accessibility Identifier。

## 代码
[粘贴视图代码]

## 命名规范
- 格式：`<模块>_<组件类型>_<用途>`
- 示例：`login_button_submit`、`cart_label_totalPrice`
- 组件类型：button、textfield、label、image、cell 等

## 要求
1. 为所有交互元素（按钮、输入框）添加标识符
2. 为需要断言的元素（Label 显示的金额、状态文字）添加标识符
3. 输出完整的修改后代码

## UIKit 示例
submitButton.accessibilityIdentifier = "login_button_submit"

## SwiftUI 示例
Button("登录") { }
    .accessibilityIdentifier("login_button_submit")
```

#### 2.2 验证标识符唯一性
确保同一页面内标识符不重复：

```bash
# 在 Xcode 中全局搜索 accessibilityIdentifier
# 或使用正则检查重复
grep -r "accessibilityIdentifier = \"login_button_submit\"" .
```

### 步骤 3：创建 Page Object 模型

采用 Page Object 模式封装页面元素和操作，提升测试可维护性。

#### 3.1 生成页面对象类

```
请为 [页面名称] 创建 Page Object 类。

## 页面信息
- 页面名称：LoginScreen
- 功能：用户登录
- 可达性标识列表：
  - `login_textfield_username`
  - `login_textfield_password`
  - `login_button_submit`
  - `login_label_errorMessage`

## 要求
1. 使用 XCUIApplication 访问元素
2. 封装所有页面元素为计算属性
3. 提供高层操作方法（如 `login(username:password:)`）
4. 添加等待逻辑（元素出现/消失）
5. 遵循命名约定：`<PageName>Screen`

## 输出格式
完整的 Swift 类定义，包含：
- 元素属性（懒加载）
- 操作方法
- 等待辅助方法
```

**AI 输出示例：**

```swift
import XCTest

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
    
    var errorMessageLabel: XCUIElement {
        app.staticTexts["login_label_errorMessage"]
    }
    
    // MARK: - Actions
    
    @discardableResult
    func login(username: String, password: String) -> Self {
        usernameTextField.tap()
        usernameTextField.typeText(username)
        
        passwordTextField.tap()
        passwordTextField.typeText(password)
        
        submitButton.tap()
        return self
    }
    
    // MARK: - Waiting
    
    @discardableResult
    func waitForPageToLoad(timeout: TimeInterval = 5) -> Self {
        _ = usernameTextField.waitForExistence(timeout: timeout)
        return self
    }
    
    // MARK: - Assertions
    
    var isErrorMessageVisible: Bool {
        errorMessageLabel.exists
    }
}
```

### 步骤 4：生成测试用例代码

基于 Page Object 和测试计划，生成完整测试代码。

```
请为以下用户流程生成 XCUITest 测试代码。

## 用户流程
**Given**：用户未登录，在登录页
**When**：输入有效用户名和密码，点击登录按钮
**Then**：跳转到首页，显示用户头像

## 上下文
- Page Object 类：LoginScreen、HomeScreen（已定义）
- 测试目标：iOS 17+
- 使用 Swift Concurrency（async/await）

## 要求
1. 测试方法命名：`test_<场景>_<预期结果>`
2. 使用 Page Object 操作页面
3. 合理使用 `waitForExistence(timeout:)`
4. 断言精确（验证具体文本或状态）
5. 添加注释说明等待原因

## 输出格式
完整的测试方法实现（包含 setUp、tearDown）
```

**AI 输出示例：**

```swift
import XCTest

final class LoginFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    func test_loginWithValidCredentials_navigatesToHomeScreen() {
        // Given: 用户在登录页
        let loginScreen = LoginScreen(app: app)
            .waitForPageToLoad()
        
        // When: 输入有效凭证并登录
        loginScreen.login(username: "testuser", password: "password123")
        
        // Then: 成功跳转到首页
        let homeScreen = HomeScreen(app: app)
        
        // 等待首页加载（网络请求可能需要时间）
        XCTAssertTrue(
            homeScreen.avatarImage.waitForExistence(timeout: 10),
            "首页头像应在 10 秒内出现"
        )
        XCTAssertTrue(homeScreen.avatarImage.exists)
    }
    
    func test_loginWithInvalidPassword_showsErrorMessage() {
        // Given: 用户在登录页
        let loginScreen = LoginScreen(app: app)
            .waitForPageToLoad()
        
        // When: 输入错误密码
        loginScreen.login(username: "testuser", password: "wrongpassword")
        
        // Then: 显示错误提示
        XCTAssertTrue(
            loginScreen.errorMessageLabel.waitForExistence(timeout: 5),
            "错误提示应在 5 秒内出现"
        )
        XCTAssertEqual(
            loginScreen.errorMessageLabel.label,
            "用户名或密码错误"
        )
    }
}
```

### 步骤 5：处理异步与稳定性问题

UI 测试中最常见的问题是 flaky tests（不稳定测试），主要由异步操作引起。

#### 5.1 识别 Flaky 场景

```
请分析以下测试代码，找出可能导致测试不稳定的点。

## 测试代码
[粘贴测试代码]

## 分析维度
1. 是否有未等待的异步操作（网络请求、动画、延迟加载）
2. 是否依赖硬编码的 sleep（应改为 waitForExistence）
3. 是否有元素查找竞态条件（多个相同类型元素）
4. 是否有键盘遮挡导致的点击失败

## 输出格式
- 列出每个风险点
- 给出修复建议（具体代码）
```

#### 5.2 应用稳定性修复

**常见修复模式：**

```swift
// ❌ 不稳定：直接点击可能失败（元素未加载）
app.buttons["submit"].tap()

// ✅ 稳定：等待元素出现后再操作
let submitButton = app.buttons["submit"]
XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
submitButton.tap()

// ❌ 不稳定：硬编码延迟
sleep(3)

// ✅ 稳定：等待特定状态
let loadingIndicator = app.activityIndicators["loading"]
XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 2))
// 等待加载指示器消失
let notExists = NSPredicate(format: "exists == false")
expectation(for: notExists, evaluatedWith: loadingIndicator)
waitForExpectations(timeout: 10)

// ❌ 不稳定：元素可能被键盘遮挡
submitButton.tap()

// ✅ 稳定：先收起键盘
if app.keyboards.element.exists {
    app.keyboards.buttons["Done"].tap()
}
submitButton.tap()
```

### 步骤 6：组织测试代码结构

推荐的测试工程结构：

```
UITests/
├── UITests.swift                  # 主测试 runner（自动生成）
├── PageObjects/                   # Page Object 模型
│   ├── LoginScreen.swift
│   ├── HomeScreen.swift
│   └── CheckoutScreen.swift
├── TestCases/                     # 测试用例（按功能模块分组）
│   ├── AuthenticationTests.swift
│   ├── ShoppingCartTests.swift
│   └── CheckoutFlowTests.swift
├── Helpers/                       # 辅助工具
│   ├── XCUIElement+Helpers.swift  # 扩展方法（如智能等待）
│   └── TestData.swift             # 测试数据生成器
└── Screenshots/                   # 失败截图存放目录（CI 自动生成）
```

使用 AI 生成辅助扩展：

```
请为 XCUIElement 创建扩展方法，提升测试稳定性。

## 需求方法
1. `waitAndTap(timeout:)` - 等待元素出现后点击
2. `clearAndType(text:)` - 清空输入框并输入文本
3. `waitForDisappear(timeout:)` - 等待元素消失
4. `isFullyVisible()` - 判断元素是否完全可见（未被遮挡）

## 输出格式
完整的 Swift 扩展文件
```

### 步骤 7：集成 CI/CD

将 UI 测试集成到持续集成流程：

```yaml
# .github/workflows/ui-tests.yml
name: UI Tests

on: [push, pull_request]

jobs:
  ui-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      
      - name: Run UI Tests
        run: |
          xcodebuild test \
            -scheme YourApp \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.2' \
            -testPlan UITestPlan \
            -resultBundlePath ./test-results \
            -enableCodeCoverage NO
      
      - name: Upload Test Results
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: ui-test-results
          path: ./test-results
      
      - name: Upload Screenshots
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: failure-screenshots
          path: ./UITests/Screenshots/
```

**优化 CI 执行速度：**
- 使用 Test Plans 分组运行（烟雾测试 vs 完整测试）
- 并行执行独立测试（`-parallel-testing-enabled YES`）
- 缓存 DerivedData（加速编译）

### 步骤 8：监控测试健康度

定期审查测试质量：

```
请分析以下 UI 测试执行报告，提出改进建议。

## 测试数据（最近 30 天）
- 总用例数：150
- Flaky 测试：12 个（flaky rate 8%）
- 平均执行时间：25 分钟
- 失败率最高的 5 个测试：
  1. test_checkout_withCreditCard - 15% 失败率
  2. test_search_withSpecialCharacters - 12% 失败率
  ...

## 分析要求
1. 识别 flaky 测试的共性（如都涉及网络请求）
2. 提出具体优化方向（如增加 mock、调整等待策略）
3. 建议拆分或合并测试用例

## 输出格式
Markdown 报告，包含问题、根因、解决方案
```

## ✅ 验证清单

- [ ] 所有关键用户流程都有对应测试用例
- [ ] Page Object 类职责单一，可复用
- [ ] 所有交互元素都有 Accessibility Identifier
- [ ] 测试用例命名清晰，遵循 `test_场景_结果` 格式
- [ ] 无硬编码 `sleep`，全部使用 `waitForExistence`
- [ ] Flaky rate < 5%（在 CI 上连续运行 10 次）
- [ ] 测试套件执行时间 < 30 分钟（完整回归测试）
- [ ] 失败时自动截图，便于排查
- [ ] 已在 CI 上集成，PR 必过 UI 测试

## 🐛 常见问题

### Q1: 测试偶尔失败，找不到元素

**根因**：异步加载未完成就尝试操作元素。

**排查步骤：**
1. 在失败位置添加断点，手动运行查看元素是否存在
2. 检查是否有网络请求或动画延迟
3. 查看 Xcode 的 UI Hierarchy（暂停时）

**解决方案：**
```swift
// 增加等待时间，并添加失败日志
let element = app.buttons["submit"]
XCTAssertTrue(
    element.waitForExistence(timeout: 10),
    "元素 'submit' 在 10 秒内未出现。当前页面：\(app.debugDescription)"
)
```

### Q2: Accessibility Identifier 与现有代码冲突

**问题**：添加标识符后，VoiceOver 用户体验受影响。

**解决**：
- `accessibilityIdentifier` 不影响 VoiceOver（它读取的是 `accessibilityLabel`）
- 如需同时优化 VoiceOver，分开设置：
  ```swift
  button.accessibilityIdentifier = "login_button_submit" // 用于测试
  button.accessibilityLabel = "登录按钮"                // 用于 VoiceOver
  ```

### Q3: Page Object 代码重复太多

**问题**：每个页面都有相似的 `waitForPageToLoad` 方法。

**解决**：提取 Base Page Object：

```swift
class BasePage {
    let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    @discardableResult
    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }
}

class LoginScreen: BasePage {
    var submitButton: XCUIElement {
        app.buttons["login_button_submit"]
    }
    
    func login(username: String, password: String) {
        waitForElement(submitButton)
        // ...
    }
}
```

### Q4: 键盘遮挡导致点击失败

**问题**：输入框操作后，键盘未收起，底部按钮被遮挡。

**解决**：
```swift
extension XCUIElement {
    func tapDismissingKeyboard() {
        // 方式 1：点击键盘的"完成"按钮
        if app.keyboards.element.exists {
            app.keyboards.buttons["Done"].tap()
        }
        
        // 方式 2：点击空白区域（SwiftUI 常用）
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        
        self.tap()
    }
}
```

### Q5: 滚动到元素后仍找不到

**问题**：列表中的元素需要滚动才能出现。

**解决**：
```swift
extension XCUIElement {
    func scrollToElement(_ element: XCUIElement) {
        while !element.exists {
            swipeUp()
        }
    }
}

// 使用
let tableView = app.tables.firstMatch
tableView.scrollToElement(app.cells["target_cell"])
```

## 🎓 最佳实践

### 1. 可达性标识命名规范

建议采用统一格式：`<模块>_<组件>_<用途>`

| 组件类型 | 命名示例 | 说明 |
|---------|---------|------|
| Button | `login_button_submit` | 登录页提交按钮 |
| TextField | `profile_textfield_email` | 个人资料页邮箱输入框 |
| Label | `cart_label_totalPrice` | 购物车总价标签 |
| Image | `home_image_avatar` | 首页用户头像 |
| Cell | `list_cell_product_0` | 列表第 0 个商品 cell |

### 2. Given-When-Then 测试结构

每个测试清晰分为三段：

```swift
func test_addToCart_increasesCartCount() {
    // Given: 用户在商品详情页，购物车为空
    let productScreen = ProductDetailScreen(app: app)
    let cartBadge = app.staticTexts["navbar_badge_cartCount"]
    XCTAssertEqual(cartBadge.label, "0")
    
    // When: 点击"加入购物车"按钮
    productScreen.addToCartButton.tap()
    
    // Then: 购物车数量变为 1
    XCTAssertTrue(cartBadge.waitForExistence(timeout: 5))
    XCTAssertEqual(cartBadge.label, "1")
}
```

### 3. 分层测试策略

| 测试层级 | 用途 | 执行频率 | 示例 |
|---------|------|---------|------|
| **烟雾测试** | 验证核心流程可用 | 每次 PR | 登录 → 浏览商品 → 退出 |
| **功能测试** | 覆盖所有用户场景 | 每日构建 | 购物车增删改查、多种支付方式 |
| **回归测试** | 防止已修复 bug 复现 | 发版前 | 历史 bug 对应的用例 |

使用 Xcode Test Plans 分组执行：
```
UITests.xctestplan
├── SmokeTests.xctestplan     (5 分钟，快速验证)
├── FullRegression.xctestplan (30 分钟，完整覆盖)
└── NightlyTests.xctestplan   (1 小时，包含性能测试)
```

### 4. Mock 网络请求

避免测试依赖真实后端（不稳定 + 慢），使用 Mock：

```swift
// 方案 1：通过 Launch Arguments 控制
override func setUp() {
    app.launchArguments = [
        "UI-Testing",
        "Mock-Network-Success"
    ]
    app.launch()
}

// 应用内检测
if ProcessInfo.processInfo.arguments.contains("Mock-Network-Success") {
    // 返回 Mock 数据
}

// 方案 2：使用 URLProtocol Mock（需应用内支持）
// 参考 prompts/mocking/protocol-to-urlprotocol.md
```

### 5. 定期重构测试代码

测试代码也是代码，需要维护：
- 每月审查一次，删除冗余测试
- 合并重复的辅助方法到 Helpers
- 更新过时的 Page Object（UI 改版后）

## 📚 扩展阅读

- [XCUITest 官方文档](https://developer.apple.com/documentation/xctest/user_interface_tests)
- [Accessibility for UIKit](https://developer.apple.com/documentation/uikit/accessibility_for_uikit)
- [Page Object Pattern](https://martinfowler.com/bliki/PageObject.html)
- [Fixing Flaky Tests (Google Testing Blog)](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html)

## 🔗 相关工作流

- [为 Swift 模块补充单元测试](./unit-test-generation.md)（本工作流的互补，聚焦单元测试）
- [使用 AI 进行代码 Review](./ai-code-review.md)
- [API 接口自动生成 Mock](./api-mock-generation.md)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-05  
**适用工具**：Cursor、Claude Code、GitHub Copilot
