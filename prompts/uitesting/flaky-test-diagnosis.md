# Flaky 测试诊断与修复

## 场景说明
诊断不稳定的 UI 自动化测试（Flaky Tests），找出根因并提供具体修复方案。Flaky 测试指的是在相同代码和环境下，有时通过有时失败的测试用例，严重影响 CI/CD 可靠性。

## 输入要求

### 必需
- 不稳定的测试代码（完整测试方法）
- 失败现象描述（如：找不到元素、超时、断言失败）
- 失败频率（如：10 次运行中失败 3 次）

### 可选
- 失败时的截图或日志
- 测试运行环境（模拟器型号、iOS 版本、CI 配置）
- 相关的 Page Object 代码
- 应用代码中的异步操作（网络请求、动画时长）

## 提示词模板

```
请分析以下 UI 测试代码，诊断导致测试不稳定（Flaky）的原因并提供修复方案。

## 测试代码
```swift
[粘贴完整的测试方法代码]
```

## 失败现象
- **失败类型**：[如：找不到元素 "login_button_submit"、断言失败、超时]
- **失败频率**：[如：10 次运行中失败 3 次]
- **失败环境**：[如：仅在 CI 上失败，本地运行正常]
- **错误信息**：
  ```
  [粘贴 Xcode 或 CI 的错误日志]
  ```

## 相关上下文（可选）
- **Page Object 代码**：
  ```swift
  [如果使用了 Page Object，粘贴相关代码]
  ```

- **应用侧异步操作**：
  [如：登录按钮点击后，有 2 秒的网络请求，然后播放 0.3 秒的转场动画]

- **运行环境**：
  - 模拟器：iPhone 15 Pro, iOS 17.2
  - Xcode 版本：15.2
  - CI 平台：GitHub Actions (macOS 14)

## 分析要求

### 1. 根因分析
从以下维度诊断问题：
- **异步时序问题**：是否有未等待完成的异步操作（网络、动画、延迟加载）
- **元素查询问题**：是否有多个匹配元素、元素尚未渲染、元素被遮挡
- **输入竞态问题**：键盘未收起、输入法干扰、焦点未转移
- **环境差异问题**：本地 vs CI 的性能差异、时区/语言设置不同
- **硬编码延迟**：使用 `sleep()` 而非智能等待
- **资源竞争问题**：并行测试修改了共享状态（UserDefaults、数据库、Mock 服务）

### 2. 修复方案
针对每个问题，提供：
- **问题描述**：用一句话说明根因
- **现有代码片段**：标注问题所在行
- **修复代码**：提供完整的替换代码
- **修复原理**：解释为何修复后能消除不稳定性

### 3. 验证建议
- 如何验证修复有效（如：在 CI 上连续运行 20 次）
- 是否需要增加超时时间
- 是否需要调整 CI 配置（如：禁用并行测试）

## 输出格式

### 诊断报告

#### 问题 1：异步加载未等待
**问题描述**：点击登录按钮后，直接断言首页元素存在，但网络请求和页面跳转需要时间。

**现有代码（问题行）**：
```swift
submitButton.tap()
XCTAssertTrue(homeScreen.avatarImage.exists) // ❌ 可能失败：元素尚未加载
```

**根因**：
- `tap()` 是同步方法，立即返回
- 应用内登录请求需要 1-3 秒（取决于网络）
- 测试代码未等待页面跳转完成，直接断言元素存在

**修复代码**：
```swift
submitButton.tap()

// 等待首页头像出现（最多 10 秒）
let avatarImage = homeScreen.avatarImage
XCTAssertTrue(
    avatarImage.waitForExistence(timeout: 10),
    "首页头像应在 10 秒内出现，但未找到"
)
XCTAssertTrue(avatarImage.exists)
```

**修复原理**：
- `waitForExistence(timeout:)` 会轮询检查元素是否存在，最多等待 10 秒
- 超时时间应大于正常场景的最大延迟（网络请求 3 秒 + 动画 0.5 秒，留 buffer 设为 10 秒）
- 失败时断言消息明确，便于排查

---

#### 问题 2：键盘遮挡导致点击失败
**问题描述**：输入密码后，键盘未收起，底部的登录按钮被遮挡，`tap()` 失败。

**现有代码（问题行）**：
```swift
passwordTextField.tap()
passwordTextField.typeText("password")
submitButton.tap() // ❌ 可能失败：按钮被键盘遮挡
```

**根因**：
- UIKit 的 TextField 输入后，键盘保持显示
- `tap()` 无法点击不可见或被遮挡的元素

**修复代码**：
```swift
passwordTextField.tap()
passwordTextField.typeText("password")

// 方案 1：点击键盘的"完成"按钮
if app.keyboards.element.exists {
    app.keyboards.buttons["Done"].tap()
}

// 等待键盘消失
let keyboardNotExists = NSPredicate(format: "exists == false")
let keyboardExpectation = XCTNSPredicateExpectation(
    predicate: keyboardNotExists,
    object: app.keyboards.element
)
_ = XCTWaiter().wait(for: [keyboardExpectation], timeout: 2)

submitButton.tap()
```

或使用扩展方法（推荐）：

```swift
// XCUIElement+Helpers.swift
extension XCUIElement {
    func tapDismissingKeyboard() {
        if app.keyboards.element.exists {
            app.keyboards.buttons["Done"].tap()
            
            // 等待键盘消失
            let notExists = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(
                predicate: notExists,
                object: app.keyboards.element
            )
            _ = XCTWaiter().wait(for: [expectation], timeout: 2)
        }
        self.tap()
    }
}

// 使用
submitButton.tapDismissingKeyboard()
```

**修复原理**：
- 显式收起键盘，确保按钮可见
- 等待键盘消失动画完成（约 0.3 秒，设置 2 秒 buffer）

---

#### 问题 3：使用 `sleep()` 硬编码延迟
**问题描述**：使用固定延迟 `sleep(3)`，但实际加载时间波动较大（CI 上可能更慢）。

**现有代码（问题行）**：
```swift
loginScreen.login(username: "test", password: "pass")
sleep(3) // ❌ 硬编码延迟：可能不够或浪费时间
XCTAssertTrue(homeScreen.isVisible)
```

**根因**：
- `sleep()` 无法适应动态加载时间
- CI 环境性能较差，3 秒可能不够
- 本地环境性能好，3 秒浪费时间（拖慢测试套件）

**修复代码**：
```swift
loginScreen.login(username: "test", password: "pass")

// 等待首页特征元素出现
let homeIndicator = homeScreen.navigationBar
XCTAssertTrue(
    homeIndicator.waitForExistence(timeout: 10),
    "首页导航栏应在 10 秒内出现"
)
```

**修复原理**：
- 智能等待：加载快时立即返回，加载慢时等到 timeout
- 适应不同环境的性能差异

---

（继续列出其他问题...）

## 修复优先级建议

| 问题类型 | 优先级 | 修复成本 | 影响范围 |
|---------|-------|---------|---------|
| 异步未等待 | P0 | 低 | 高（最常见） |
| 键盘遮挡 | P1 | 中 | 中 |
| 硬编码延迟 | P1 | 低 | 高 |
| 元素查询歧义 | P2 | 中 | 中 |
| 环境差异 | P2 | 高 | 低 |

## 验证建议

### 修复后验证步骤
1. 本地运行 20 次：`xcodebuild test -scheme YourApp -only-testing:YourTests/TestClass/testMethod -run-tests-until-failure`
2. CI 上运行 20 次（配置 GitHub Actions matrix）
3. 监控 Flaky 率：目标 < 5%

### CI 配置优化（可选）
```yaml
# .github/workflows/ui-tests.yml
strategy:
  matrix:
    run: [1, 2, 3, 4, 5] # 运行 5 次验证稳定性
```
```

## 使用示例

### 输入

```
请分析以下 UI 测试代码，诊断导致测试不稳定的原因。

## 测试代码
```swift
func test_addToCart_updatesCartBadge() {
    let productScreen = ProductDetailScreen(app: app)
    productScreen.addToCartButton.tap()
    
    let cartBadge = app.staticTexts["navbar_badge_cartCount"]
    XCTAssertEqual(cartBadge.label, "1")
}
```

## 失败现象
- **失败类型**：断言失败，`cartBadge.label` 仍为 "0"
- **失败频率**：10 次运行中失败 4 次
- **失败环境**：主要在 CI 上失败
- **错误信息**：
  ```
  XCTAssertEqual failed: ("0") is not equal to ("1")
  ```

## 相关上下文
- **应用侧异步操作**：点击"加入购物车"后，会发起网络请求保存到服务器，成功后更新角标。网络请求通常需要 1-2 秒。
```

### AI 输出（部分）

**诊断报告**

#### 问题 1：未等待网络请求完成

**问题描述**：点击加入购物车后，立即断言角标数量，但此时网络请求尚未完成，角标未更新。

**现有代码（问题行）**：
```swift
productScreen.addToCartButton.tap()
let cartBadge = app.staticTexts["navbar_badge_cartCount"]
XCTAssertEqual(cartBadge.label, "1") // ❌ 失败：网络请求未完成
```

**修复代码**：
```swift
productScreen.addToCartButton.tap()

// 等待角标更新（网络请求 + UI 刷新）
let cartBadge = app.staticTexts["navbar_badge_cartCount"]
let predicate = NSPredicate(format: "label == '1'")
let expectation = XCTNSPredicateExpectation(predicate: predicate, object: cartBadge)
let result = XCTWaiter().wait(for: [expectation], timeout: 10)

XCTAssertEqual(result, .completed, "购物车角标应在 10 秒内更新为 '1'")
XCTAssertEqual(cartBadge.label, "1")
```

**修复原理**：
- 使用 `NSPredicate` 等待角标文本变为 "1"
- 轮询检查，最多等待 10 秒（覆盖网络延迟 + buffer）
- CI 环境网络较慢，10 秒足够

**验证建议**：
- 在 CI 上连续运行 20 次，确认失败率降至 0
- 如仍有偶发失败，增加 timeout 到 15 秒

## 注意事项

### ✅ 好的做法
- **优先使用智能等待**：`waitForExistence(timeout:)` 或 `NSPredicate` 等待状态变化
- **超时时间留 buffer**：正常 2 秒，设置 5-10 秒（CI 环境更慢）
- **失败消息详细**：断言失败时，输出当前实际值和期望值
- **分析失败模式**：如果只在 CI 失败，可能是性能问题；如果随机失败，可能是异步问题

### ❌ 避免的做法
- 简单增加 `sleep()` 时间（治标不治本）
- 忽略偶发失败（"重跑一次就过了"）
- 修复后未验证（本地过了，CI 仍可能失败）
- 删除不稳定的测试（丧失测试覆盖）

### 🔧 常见调整

如果 AI 的诊断不够深入，可以追加指令：

```
请补充以下内容：
1. 分析为何本地运行正常，CI 上失败率更高（性能差异？）
2. 提供通用的 XCUIElement 扩展方法，封装智能等待逻辑
3. 建议是否需要在应用侧添加测试钩子（如：禁用动画、Mock 网络）
4. 给出 CI 配置优化建议（如：增加模拟器内存、禁用并行测试）
```

## 高级用法

### 场景一：批量诊断多个 Flaky 测试

```
请分析以下 5 个不稳定的测试，找出共性问题。

## 测试列表
1. test_login_success - 失败率 10%
2. test_addToCart - 失败率 8%
3. test_checkout - 失败率 12%
4. test_searchProduct - 失败率 5%
5. test_updateProfile - 失败率 7%

[分别粘贴测试代码]

## 分析要求
- 识别共性问题（如：都涉及网络请求、都有键盘操作）
- 提出统一的修复方案（如：引入 BasePage 的智能等待）
- 优先修复影响面最大的问题
```

### 场景二：生成 Flaky 测试监控报告

```
请根据以下测试执行记录，生成 Flaky 测试分析报告。

## 数据（最近 30 天，100 次 CI 运行）
- test_login_success: 通过 90 次，失败 10 次
- test_addToCart: 通过 85 次，失败 15 次
- ...

## 输出要求
- 按失败率排序
- 标注超过 5% flaky rate 的用例（需立即修复）
- 给出每个用例的可能原因假设
```

## 相关资源
- [工作流：XCUITest UI 自动化测试](../../workflows/xcuitest-generation.md)
- [提示词：UI 测试用例规划](./test-case-planning.md)
- [提示词：Page Object 生成](./page-object-generation.md)
- [Google Testing Blog: Flaky Tests](https://testing.googleblog.com/2016/05/flaky-tests-at-google-and-how-we.html)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-05  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
