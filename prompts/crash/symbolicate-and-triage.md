# 提示词：符号化后栈解读与分诊

## 场景说明
分析已符号化的 iOS 崩溃日志，快速识别崩溃类型、定位问题模块，并输出初步分诊结果。适用于批量崩溃分类、优先级判断。

## 输入要求

### 必需
- 符号化后的崩溃栈（至少主线程的 10-20 行调用栈）
- 异常类型（如 EXC_BAD_ACCESS、SIGABRT、0x8badf00d）
- 崩溃点方法名（如 `-[UserViewController loadData:]`）

### 可选
- 完整崩溃日志（包含 Device Info、Binary Images、其他线程栈）
- 应用版本号和 Build 号
- 崩溃频率统计（如影响 200 个用户 / 0.5% 崩溃率）

## 提示词模板

```
我需要对一个 iOS 崩溃日志进行快速分诊。请按以下格式输出分析结果。

## 崩溃信息
- 异常类型：[异常类型，如 EXC_BAD_ACCESS (SIGSEGV)]
- 崩溃线程：[线程号和名称，如 Thread 0 (Main Thread)]
- 应用版本：[版本号，如 1.2.3 Build 456]
- 设备信息：[设备型号和 iOS 版本，如 iPhone 14 Pro, iOS 17.2.1]

## 崩溃栈（已符号化）
```
[粘贴符号化后的崩溃栈，至少 10-20 行，例如：]
Thread 0 Crashed (Main Thread):
0   YourApp                   0x0000000100a1b2c4 -[UserViewController loadUserData:] + 142 (UserViewController.m:78)
1   YourApp                   0x0000000100a1b456 -[UserViewController viewDidLoad] + 78 (UserViewController.m:45)
2   UIKitCore                 0x00000001a3456789 -[UIViewController _sendViewDidLoadWithAppearanceProxyObjectTaggingEnabled] + 102
3   UIKitCore                 0x00000001a345abcd -[UIViewController loadViewIfRequired] + 988
...
```

## 分诊要求
请按以下步骤输出：

### 1. 崩溃类型识别
- 根据异常类型，判断崩溃类别（野指针、强制解包 nil、数组越界、未捕获异常、主线程超时、其他）
- 给出该类型崩溃的常见原因（列出 2-3 种）

### 2. 崩溃模块定位
- 从崩溃栈识别崩溃发生的模块和方法名
- 区分是应用代码崩溃、系统库崩溃还是第三方库崩溃

### 3. 初步优先级判断
根据以下因素评估优先级：
- 崩溃是否在主线程
- 是否影响核心功能（登录、支付、首页加载等）
- [如果提供崩溃频率] 影响用户数量和占比
- 优先级输出为：P0（紧急）/ P1（高）/ P2（中）/ P3（低）

### 4. 下一步分析建议
- 列出需要进一步收集的信息（如相关源码、近期变更、其他线程栈）
- 推荐的分析工具（如 Instruments Zombies、Address Sanitizer、Thread Sanitizer）

## 输出格式
使用 Markdown，结构化输出，便于快速浏览和归档。
```

## 使用示例

### 输入

```
## 崩溃信息
- 异常类型：EXC_BAD_ACCESS (SIGSEGV)
- 崩溃线程：Thread 0 (Main Thread)
- 应用版本：1.2.3 Build 456
- 设备信息：iPhone 14 Pro, iOS 17.2.1

## 崩溃栈（已符号化）
```
Thread 0 Crashed (Main Thread):
0   ShoppingApp               0x0000000102a1b2c4 -[ProductViewController updateCartBadge] + 68 (ProductViewController.m:234)
1   ShoppingApp               0x0000000102a1b456 -[ProductViewController cartDidUpdate:] + 120 (ProductViewController.m:189)
2   Foundation                0x00000001a8123456 __NSNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 12
3   Foundation                0x00000001a8123789 -[NSNotificationCenter postNotificationName:object:userInfo:] + 82
...
```
```

### 输出

```markdown
## 崩溃类型识别
**类别**：野指针访问（EXC_BAD_ACCESS / SIGSEGV）

**常见原因**：
1. 对象已被释放，但仍被访问（野指针）
2. 通知观察者未移除，对象释放后仍收到通知回调
3. 异步回调中访问已释放的 self

## 崩溃模块定位
- **崩溃模块**：ShoppingApp（应用自身代码）
- **崩溃方法**：`-[ProductViewController updateCartBadge]`
- **触发路径**：通知回调 → `cartDidUpdate:` → `updateCartBadge`

## 初步优先级判断
**优先级**：P1（高）

**理由**：
- 崩溃发生在主线程，影响用户体验
- 涉及购物车核心功能，可能影响转化率
- 通过通知触发，可能是高频场景

## 下一步分析建议

### 需要收集的信息
1. `ProductViewController.m` 第 234 行 `updateCartBadge` 方法的完整源码
2. 通知 `cartDidUpdate:` 的注册和移除位置
3. `ProductViewController` 的内存管理方式（是否使用 ARC、weak 引用）
4. 近期相关代码变更（搜索 git log 中涉及 ProductViewController 和购物车通知的提交）

### 推荐分析工具
- **Xcode Zombies**：检测已释放对象的访问
- **静态分析**：Xcode Analyze → 检查通知观察者是否正确移除
- **Address Sanitizer**：运行时检测内存访问错误

### 可能的根因假设（待源码确认）
1. `ProductViewController` 被释放后，通知观察者未移除，仍收到 `cartDidUpdate:` 回调
2. `updateCartBadge` 方法中访问了已释放的属性（如 `self.cartBadgeLabel`）
```

## 注意事项

- 如果崩溃栈未符号化（显示为 `0x1000abcde` 地址），先使用 `symbolicatecrash` 或 `atos` 符号化
- 对于系统库崩溃（如 UIKit、Foundation），需要结合应用代码调用栈判断是否是应用传入参数错误导致
- 批量分诊时，可以批量输入多个崩溃栈，让 AI 逐一输出分诊结果
- 优先级判断是初步评估，需要结合业务重要性和影响用户数最终确定

---

**适用场景**：快速崩溃分类、批量分诊、优先级排序  
**后续工作流**：[根因假设与修复建议](./root-cause-hypothesis.md)  
**维护者**：Loong (SSLoong)  
**更新日期**：2026-11-03
