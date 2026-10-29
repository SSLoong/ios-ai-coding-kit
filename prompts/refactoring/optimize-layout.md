# 优化 UIViewController 布局代码

## 场景说明
重构 UIKit ViewController 中的布局代码，将复杂的视图层级、约束设置、样式配置提取为清晰的结构，提升可读性和可维护性。

## 输入要求

### 必需
- 目标 ViewController 的 UI 布局代码（`viewDidLoad`、`setupUI`、约束设置等方法）
- 项目使用的布局方式：Auto Layout（NSLayoutConstraint / SnapKit / Cartography）

### 可选
- 项目 UI 代码风格指南
- 现有的 UI 组件封装示例
- 设计稿或界面截图（帮助 AI 理解布局意图）

## 提示词模板

```
我需要优化以下 ViewController 的 UI 布局代码。

## 当前代码
[粘贴 ViewController 的 UI 相关代码，包括视图创建、约束设置、样式配置]

## 项目布局方式
- 布局工具：[Auto Layout / SnapKit / 纯代码 frame]
- iOS 版本：支持 iOS [13+/14+/15+]
- 是否使用 SwiftUI：[否 / 部分混用]

## 优化目标

### 1. 职责分离
将 UI 代码按职责分组到独立方法：
- `setupViewHierarchy()`：添加子视图到层级
- `setupConstraints()`：配置 Auto Layout 约束
- `setupAppearance()`：配置颜色、字体、圆角等样式
- `setupActions()`：绑定按钮点击等交互

### 2. 减少嵌套层级
- 使用 `lazy var` 定义视图组件，延迟初始化
- 提取复杂视图到独立的自定义 UIView 子类
- 使用 UIStackView 简化线性布局

### 3. 常量提取
- 将边距、圆角、字体大小等提取到 `private enum Constants`
- 将颜色提取到统一的 `UIColor` extension 或 Design System

### 4. 约束可读性
- 使用清晰的变量名：`let nameLabel = UILabel()` 而非 `let label1 = UILabel()`
- 约束设置按视图分组，添加注释说明布局意图
- 如果使用原生 Auto Layout，考虑使用 anchor API 替代 NSLayoutConstraint

### 5. 避免的模式
- ❌ 在 `viewDidLoad()` 中混杂布局、样式、业务逻辑
- ❌ 硬编码的魔法数字：`view.frame = CGRect(x: 16, y: 100, width: 200, height: 50)`
- ❌ 超长的约束数组：`NSLayoutConstraint.activate([...])`（500+ 字符）
- ❌ 重复的样式代码（多个 Label 用相同的字体和颜色）

## 输出格式

### 步骤 1：分析现有布局结构
先输出布局结构分析：
- 视图层级（用树状图表示）
- 识别可提取的自定义视图
- 识别重复的样式代码

### 步骤 2：生成优化后的代码
确认分析后，输出：
1. 优化后的 ViewController 布局代码（分方法组织）
2. 提取的自定义 UIView 子类（如有）
3. 提取的常量定义（Constants、Appearance）
4. 样式 extension（如 UILabel.Styles）

## 附加约束
- 保持布局结果不变（像素级对齐）
- 遵循项目的 Swift 代码规范
- 不引入新的三方库（除非明确允许）
```

## 使用示例

### 输入

一个混乱的登录页面布局代码：

```swift
class LoginViewController: UIViewController {
    let emailTextField = UITextField()
    let passwordTextField = UITextField()
    let loginButton = UIButton()
    let titleLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // Title
        titleLabel.text = "欢迎登录"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0)
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Email
        emailTextField.placeholder = "邮箱"
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.layer.borderColor = UIColor.lightGray.cgColor
        emailTextField.layer.borderWidth = 1.0
        emailTextField.layer.cornerRadius = 8
        view.addSubview(emailTextField)
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emailTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Password (similar repetitive code...)
        passwordTextField.placeholder = "密码"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        passwordTextField.layer.borderColor = UIColor.lightGray.cgColor
        passwordTextField.layer.borderWidth = 1.0
        passwordTextField.layer.cornerRadius = 8
        view.addSubview(passwordTextField)
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            passwordTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Login Button
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = UIColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        view.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 32),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            loginButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    @objc private func loginTapped() {
        // Login logic...
    }
}
```

### AI 输出（第一步：布局结构分析）

```markdown
## 布局结构分析

### 视图层级
\`\`\`
UIViewController.view
├── titleLabel (标题)
├── emailTextField (邮箱输入框)
├── passwordTextField (密码输入框)
└── loginButton (登录按钮)
\`\`\`

### 问题识别
1. **职责混乱**：viewDidLoad() 中混杂视图创建、样式、约束、事件绑定
2. **重复代码**：emailTextField 和 passwordTextField 有重复的样式配置
3. **硬编码**：
   - 颜色：`UIColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0)`
   - 边距：`32`、`16`、`60`
   - 圆角：`8`、`12`
   - 高度：`50`、`56`
4. **可读性差**：200+ 行代码在一个方法中，难以定位具体视图

### 优化建议
1. 提取常量到 `Constants`
2. 使用 `lazy var` 延迟初始化视图（配置样式）
3. 分离方法：`setupViewHierarchy()`、`setupConstraints()`、`setupAppearance()`
4. 提取重复样式到 UITextField extension

是否确认这个优化方向？
```

### AI 输出（第二步：优化后的代码）

```swift
// MARK: - LoginViewController (优化后)

class LoginViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "欢迎登录"
        label.font = Typography.title
        label.textColor = Colors.primary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "邮箱"
        textField.keyboardType = .emailAddress
        textField.applyFormFieldStyle()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "密码"
        textField.isSecureTextEntry = true
        textField.applyFormFieldStyle()
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登录", for: .normal)
        button.backgroundColor = Colors.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Typography.button
        button.layer.cornerRadius = Constants.buttonCornerRadius
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewHierarchy()
        setupConstraints()
        setupAppearance()
    }
    
    // MARK: - Setup
    
    private func setupViewHierarchy() {
        view.addSubview(titleLabel)
        view.addSubview(emailTextField)
        view.addSubview(passwordTextField)
        view.addSubview(loginButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: Constants.titleTopMargin
            ),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Email TextField
            emailTextField.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: Constants.titleToFieldSpacing
            ),
            emailTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: Constants.horizontalMargin
            ),
            emailTextField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -Constants.horizontalMargin
            ),
            emailTextField.heightAnchor.constraint(
                equalToConstant: Constants.textFieldHeight
            ),
            
            // Password TextField
            passwordTextField.topAnchor.constraint(
                equalTo: emailTextField.bottomAnchor,
                constant: Constants.fieldSpacing
            ),
            passwordTextField.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalTo: emailTextField.heightAnchor),
            
            // Login Button
            loginButton.topAnchor.constraint(
                equalTo: passwordTextField.bottomAnchor,
                constant: Constants.buttonTopMargin
            ),
            loginButton.leadingAnchor.constraint(equalTo: emailTextField.leadingAnchor),
            loginButton.trailingAnchor.constraint(equalTo: emailTextField.trailingAnchor),
            loginButton.heightAnchor.constraint(
                equalToConstant: Constants.buttonHeight
            )
        ])
    }
    
    private func setupAppearance() {
        view.backgroundColor = Colors.background
    }
    
    // MARK: - Actions
    
    @objc private func loginTapped() {
        // Login logic...
    }
}

// MARK: - Constants

private extension LoginViewController {
    enum Constants {
        static let titleTopMargin: CGFloat = 60
        static let titleToFieldSpacing: CGFloat = 40
        static let fieldSpacing: CGFloat = 16
        static let buttonTopMargin: CGFloat = 32
        static let horizontalMargin: CGFloat = 32
        
        static let textFieldHeight: CGFloat = 50
        static let buttonHeight: CGFloat = 56
        
        static let textFieldCornerRadius: CGFloat = 8
        static let textFieldBorderWidth: CGFloat = 1.0
        static let buttonCornerRadius: CGFloat = 12
    }
    
    enum Colors {
        static let primary = UIColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0)
        static let background = UIColor.white
        static let textFieldBorder = UIColor.lightGray
    }
    
    enum Typography {
        static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let button = UIFont.systemFont(ofSize: 17, weight: .semibold)
    }
}

// MARK: - UITextField Style Extension

extension UITextField {
    func applyFormFieldStyle() {
        borderStyle = .roundedRect
        layer.borderColor = LoginViewController.Colors.textFieldBorder.cgColor
        layer.borderWidth = LoginViewController.Constants.textFieldBorderWidth
        layer.cornerRadius = LoginViewController.Constants.textFieldCornerRadius
    }
}
```

### 优化效果

**优化前：**
- 198 行代码在 `viewDidLoad()` 中
- 10+ 个硬编码的魔法数字
- 重复的样式配置代码

**优化后：**
- `viewDidLoad()` 仅 3 行，职责清晰
- 所有常量集中管理
- 可复用的 UITextField 样式 extension
- 易于维护和修改（如调整间距，只需改 Constants）

## 注意事项

### ✅ 好的做法
- 使用 `lazy var` 配置视图组件，保持声明和配置在一起
- 将常量提取到独立 enum，便于调整和复用
- 约束设置按视图分组，使用空行和注释分隔
- 对于重复样式（如多个相同的 Button），提取 extension 方法

### ❌ 避免的做法
- 过度提取：简单的 2-3 个视图不需要复杂的层级结构
- 提取为全局变量：常量应作为类型的私有成员
- 使用魔法数字的常量名：`static let value1 = 16` 不如 `static let horizontalMargin = 16`
- 在 extension 中访问具体 ViewController 的属性（降低复用性）

### 🔧 常见调整

如果生成的代码不符合项目风格，追加指令：

```
请调整以下内容：
1. 使用 SnapKit 替代原生 Auto Layout（项目使用 SnapKit）
2. 将 Colors/Typography 移到全局的 DesignSystem.swift 文件
3. 使用 UIStackView 简化线性布局（标题 + 表单）
4. 添加对深色模式的支持（使用 UIColor.systemBackground）
```

## 高级用法

### 场景一：使用 UIStackView 简化布局

```
请使用 UIStackView 优化以下垂直排列的视图：
- titleLabel
- subtitleLabel
- inputStackView (包含 emailTextField + passwordTextField)
- loginButton

要求：
- 统一使用 spacing 管理间距
- 减少约束数量
- 保持布局灵活性（适配不同屏幕尺寸）
```

### 场景二：提取复杂视图到自定义 UIView

```
以下 ViewController 中的用户资料卡片（头像 + 姓名 + 简介）重复出现在多个页面。

请提取为独立的 UserProfileCardView：
- 封装内部布局逻辑
- 提供 `configure(with: User)` 方法
- 支持自定义样式（如卡片圆角、阴影）
```

### 场景三：响应式布局（支持横竖屏）

```
当前布局在竖屏下正常，横屏时标题和按钮超出屏幕。

请优化为响应式布局：
- 使用 traitCollection 判断横竖屏
- 竖屏：垂直排列
- 横屏：标题和表单左右分布
```

## 相关资源
- [工作流：用 AI 重构遗留 UIKit 代码](../../workflows/uikit-refactoring.md)
- [提示词：提取业务逻辑到 ViewModel](./extract-viewmodel.md)
- [提示词：重构为协议化设计](./protocol-oriented.md)
- [Apple: Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-29  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
