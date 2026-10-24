# 工作流：为 Swift 模块补充单元测试

## 📋 背景

在 iOS 项目演进过程中，早期代码常因快速迭代而缺少单元测试。这导致：
- 重构风险高，担心引入回归 bug
- 代码可维护性差，不敢大幅改动
- 新人接手困难，缺少可执行的功能说明

使用 AI 辅助补充单元测试，可以在保证质量的前提下，快速提升覆盖率。

## 🎯 目标

为指定 Swift 模块生成高质量单元测试，达到以下标准：
- **覆盖率**：核心业务逻辑 ≥ 80%
- **可读性**：测试用例名称清晰，遵循 Given-When-Then 结构
- **可维护性**：Mock 对象独立，测试间无依赖
- **编译通过**：所有测试用例可运行且通过

## 🛠️ 适用场景

- ✅ 补充遗留代码的单元测试
- ✅ 为新重构的模块添加测试保障
- ✅ 快速生成测试骨架后人工补充细节
- ❌ 不适合 UI 交互测试（需用 UI Testing）
- ❌ 不适合集成测试（需真实环境）

## 📝 工作流步骤

### 步骤 1：准备上下文

在 Cursor 中准备以下上下文信息：

#### 1.1 添加目标模块代码
```bash
# 在 Cursor 中打开目标 Swift 文件
# 例如：Sources/Core/NetworkManager.swift
```

#### 1.2 准备依赖类型定义
创建临时文档 `test-context.md`，包含：
```markdown
## 模块依赖
- 依赖的协议：NetworkServiceProtocol, CacheProtocol
- 依赖的类型：User, APIError, RequestConfig

## 测试策略
- Mock 所有外部依赖（网络、数据库、UserDefaults）
- 使用 XCTest 框架
- 遵循项目测试命名约定：test_<方法名>_<场景>_<预期结果>

## 现有测试示例
[粘贴一个项目中已有的测试用例作为风格参考]
```

### 步骤 2：生成测试骨架

使用以下提示词让 AI 生成测试结构：

```
我需要为 NetworkManager 类生成单元测试。

## 要求
1. 分析 NetworkManager 的所有公开方法和属性
2. 为每个方法列出需要测试的场景（正常流程、边界情况、错误处理）
3. 生成测试类骨架，包含：
   - setUp() 和 tearDown()
   - Mock 对象定义
   - 每个测试用例的方法签名和注释

## 输出格式
请先输出测试计划（Markdown 列表），确认后再生成代码。

## 上下文
- 测试框架：XCTest
- Mock 策略：手动创建 Mock 类，实现相关协议
- 命名约定：test_<方法名>_<场景>_<预期结果>
```

### 步骤 3：审查测试计划

AI 会先输出测试计划，例如：

```markdown
## NetworkManager 测试计划

### fetchUser(id:) 方法
1. ✅ test_fetchUser_withValidID_returnsUser
2. ✅ test_fetchUser_withInvalidID_throwsError
3. ✅ test_fetchUser_withNetworkFailure_throwsNetworkError
4. ✅ test_fetchUser_withCachedData_returnsCachedUser

### uploadData(_:) 方法
1. ✅ test_uploadData_withValidData_succeeds
2. ✅ test_uploadData_withEmptyData_throwsValidationError
3. ✅ test_uploadData_withNetworkTimeout_retriesThreeTimes
```

**人工审查要点：**
- 是否覆盖了关键分支（成功、失败、边界条件）？
- 是否有遗漏的异步回调场景？
- Mock 对象是否足够（网络、存储、时间等）？

### 步骤 4：生成测试代码

确认计划后，继续对话：

```
测试计划确认。请生成完整的测试代码，包括：
1. Mock 对象实现（MockNetworkService, MockCache 等）
2. 所有测试用例的完整实现
3. 必要的辅助方法（如创建测试数据的 helper）

要求：
- 使用 XCTAssertEqual、XCTAssertThrowsError 等断言
- 异步测试使用 XCTestExpectation
- 每个测试独立，不依赖其他测试的状态
```

### 步骤 5：验证与调试

#### 5.1 编译检查
```bash
# 在 Xcode 中编译测试 target
# 或使用命令行
xcodebuild test -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

**常见编译问题：**
- Mock 类未遵循协议的所有方法 → 补充缺失方法
- 导入语句缺失 → 添加 `@testable import YourModule`
- 访问权限问题 → 将目标类/方法标记为 `public` 或使用 `@testable`

#### 5.2 运行测试
```bash
# 在 Xcode 中按 Cmd+U 运行测试
# 或使用命令行运行特定测试
xcodebuild test -scheme YourApp -only-testing:YourAppTests/NetworkManagerTests
```

#### 5.3 覆盖率检查
```bash
# 在 Xcode 中查看覆盖率报告
# Product → Scheme → Edit Scheme → Test → Options → Code Coverage
```

### 步骤 6：人工优化

AI 生成的测试需要人工优化：

#### 6.1 补充边界用例
```swift
// AI 可能遗漏的边界情况
func test_fetchUser_withVeryLongID_handlesCorrectly() {
    let longID = String(repeating: "a", count: 10000)
    // ...
}

func test_fetchUser_withSpecialCharactersInID_encodesCorrectly() {
    let specialID = "user@123!#"
    // ...
}
```

#### 6.2 优化断言精度
```swift
// ❌ AI 可能生成的模糊断言
XCTAssertNotNil(result)

// ✅ 优化后的精确断言
XCTAssertEqual(result.id, expectedUser.id)
XCTAssertEqual(result.name, expectedUser.name)
XCTAssertEqual(result.email, expectedUser.email)
```

#### 6.3 添加文档注释
```swift
/// 测试当网络请求超时时，NetworkManager 是否正确重试 3 次
/// 验证点：
/// 1. 重试次数为 3
/// 2. 每次重试间隔 1 秒
/// 3. 最终抛出 .networkTimeout 错误
func test_fetchUser_withNetworkTimeout_retriesThreeTimes() {
    // ...
}
```

### 步骤 7：集成到 CI

将测试集成到持续集成流程：

```yaml
# .github/workflows/test.yml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -scheme YourApp \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -enableCodeCoverage YES
      - name: Check Coverage
        run: |
          xcrun xccov view --report --only-targets \
            DerivedData/Logs/Test/*.xcresult
```

## ✅ 验证清单

使用以下清单确保工作流完成：

- [ ] 所有测试用例编译通过
- [ ] 所有测试用例运行通过（无 failed）
- [ ] 核心业务逻辑覆盖率 ≥ 80%
- [ ] 测试用例命名清晰，符合项目约定
- [ ] Mock 对象独立，可复用于其他测试
- [ ] 无 force unwrap (`!`) 在测试代码中（易崩溃）
- [ ] 异步测试正确使用 expectation 或 async/await
- [ ] 已添加注释说明复杂测试场景的意图

## 🐛 常见问题

### Q1: AI 生成的测试覆盖率不足 80%

**原因**：AI 可能只生成了正常流程的测试，忽略边界和错误场景。

**解决**：
1. 查看覆盖率报告，找到未覆盖的分支
2. 手动添加提示词：
   ```
   覆盖率报告显示 NetworkManager.swift:45-52 未覆盖。
   请为这段代码生成测试用例，这是处理网络超时重试的逻辑。
   ```

### Q2: Mock 对象过于复杂，难以维护

**原因**：AI 可能为每个测试单独创建 Mock，导致重复代码。

**解决**：
1. 重构 Mock 为可配置类：
   ```swift
   class MockNetworkService: NetworkServiceProtocol {
       var shouldFail: Bool = false
       var mockedResponse: Data?
       
       func fetch(url: URL) async throws -> Data {
           if shouldFail { throw APIError.networkFailure }
           return mockedResponse ?? Data()
       }
   }
   ```

2. 在每个测试中配置 Mock 状态，而非创建新实例

### Q3: 异步测试经常超时失败

**原因**：expectation 的 timeout 时间设置过短，或 fulfill() 未被调用。

**解决**：
1. 使用 Xcode 调试模式逐步检查异步流程
2. 增加 timeout：`wait(for: [expectation], timeout: 10.0)`
3. 或使用 Swift Concurrency：
   ```swift
   func test_fetchUser_async() async throws {
       let user = try await manager.fetchUser(id: "123")
       XCTAssertEqual(user.id, "123")
   }
   ```

### Q4: 测试用例间相互影响

**原因**：共享的单例或全局状态未在 `tearDown()` 中重置。

**解决**：
1. 在 `setUp()` 中创建全新的依赖对象
2. 在 `tearDown()` 中清理全局状态：
   ```swift
   override func tearDown() {
       UserDefaults.standard.removePersistentDomain(forName: "com.test")
       NetworkManager.shared = nil
       super.tearDown()
   }
   ```

## 🎓 最佳实践

### 1. 提供高质量上下文
- ✅ 粘贴完整的类定义（包括注释）
- ✅ 提供依赖协议的完整签名
- ✅ 给出一个现有测试作为风格参考
- ❌ 只给类名，期望 AI 推测实现

### 2. 分阶段生成
- ✅ 先生成测试计划，人工审查后再生成代码
- ✅ 按模块分批生成（每次一个类）
- ❌ 一次性要求生成整个 target 的测试

### 3. 重视人工审查
AI 生成的测试需要人工确认：
- 断言是否精确（不只是检查非空）
- 边界条件是否覆盖
- Mock 对象是否真实模拟了依赖行为

### 4. 持续迭代
- 每次发现 AI 遗漏的场景，更新提示词
- 将常见问题整理到团队知识库
- 定期回顾测试覆盖率，补充缺失测试

## 📚 扩展阅读

- [XCTest 官方文档](https://developer.apple.com/documentation/xctest)
- [Testing Swift Code (Swift.org)](https://swift.org/getting-started/#using-the-package-manager)
- [iOS Unit Testing Best Practices](https://www.swiftbysundell.com/articles/testing-swift-code/)

## 🔗 相关工作流

- [使用 AI 进行代码 Review](./ai-code-review.md)
- [Mock API 接口自动生成](./api-mock-generation.md)（计划中）
- [重构遗留代码的测试保障](./refactoring-with-tests.md)（计划中）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-10-23  
**适用工具**：Cursor、Claude Code、GitHub Copilot
