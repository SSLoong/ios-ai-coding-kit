# 提示词：根因假设与修复草案

## 场景说明
在完成初步分诊后，结合崩溃点源码深入分析，输出 2-3 个可能的根本原因假设，并为每个假设提供修复代码草案。适用于精准定位崩溃根因、快速生成修复方案。

## 输入要求

### 必需
- 符号化后的完整崩溃栈（主线程 + 相关子线程）
- 崩溃点源码（崩溃方法及其上下文，前后各 10-20 行）
- 崩溃类型（EXC_BAD_ACCESS / SIGABRT / Watchdog 等）

### 可选
- 近期相关代码变更（git log 最近 5 次提交）
- 相关类的头文件或协议定义
- 崩溃发生时的用户操作路径
- 其他线程的调用栈（用于分析多线程问题）

## 提示词模板

```
我需要深入分析一个 iOS 崩溃的根本原因。请输出 2-3 个根因假设，并提供修复建议。

## 崩溃信息
- 异常类型：[异常类型，如 EXC_BAD_ACCESS (SIGSEGV)]
- 崩溃线程：[线程号，如 Thread 0 (Main Thread)]
- 崩溃点：[方法名，如 -[UserViewController loadUserData:] + 142]

## 完整崩溃栈
```
[粘贴符号化后的完整崩溃栈，包括：]
- 主线程（Thread 0）完整调用栈（至少 20 行）
- 如果是多线程问题，粘贴相关子线程的调用栈
```

## 崩溃点源码
```[语言，如 objc / swift]
[粘贴崩溃点方法的完整源码，包含上下文，例如：]

// UserViewController.m
@implementation UserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(userDidLogin:) 
                                                 name:@"UserDidLoginNotification" 
                                               object:nil];
    [self loadUserData:self.userID];
}

- (void)loadUserData:(NSString *)userId {
    [self.networkManager fetchUserWithID:userId completion:^(User *user, NSError *error) {
        if (user) {
            self.currentUser = user;
            [self.tableView reloadData];  // <- 崩溃点（第 234 行）
        }
    }];
}

- (void)dealloc {
    // 注意：这里可能遗漏了通知观察者的移除
}

@end
```

## 近期相关变更（可选）
```
[粘贴 git log，例如：]
commit abc123
Date: 2026-11-01
修复：优化网络请求取消逻辑

commit def456
Date: 2026-10-30
新增：购物车数量实时更新通知
```

## 分析要求
请按以下步骤输出：

### 1. 代码审查
- 分析崩溃点源码，列出可能导致崩溃的代码位置
- 检查内存管理（是否有循环引用、野指针风险）
- 检查多线程问题（是否有竞态条件、主线程检查）
- 检查空值处理（是否有强制解包、数组越界）

### 2. 根因假设（2-3 个）
为每个假设输出：
- **假设描述**：简述根本原因
- **可能性评估**：高 / 中 / 低
- **证据链**：从崩溃栈和源码中提取支持该假设的证据
- **触发条件**：说明在什么情况下会触发该崩溃

### 3. 修复建议
为每个假设提供：
- **修复代码**：完整的修复后代码片段（可直接替换）
- **修复说明**：解释修复的原理
- **副作用评估**：是否会引入新问题（性能、内存泄漏等）
- **验证方法**：如何验证修复是否有效（单元测试、复现步骤）

### 4. 优先建议
- 推荐优先实施哪个修复方案
- 如果无法确定唯一根因，建议实施哪些防护措施

## 输出格式
使用 Markdown，结构化输出，代码用语法高亮的 code block。
```

## 使用示例

### 输入

```
## 崩溃信息
- 异常类型：EXC_BAD_ACCESS (SIGSEGV)
- 崩溃线程：Thread 0 (Main Thread)
- 崩溃点：-[ProductViewController updateCartBadge] + 68

## 完整崩溃栈
```
Thread 0 Crashed (Main Thread):
0   ShoppingApp               0x0000000102a1b2c4 -[ProductViewController updateCartBadge] + 68 (ProductViewController.m:234)
1   ShoppingApp               0x0000000102a1b456 -[ProductViewController cartDidUpdate:] + 120 (ProductViewController.m:189)
2   Foundation                0x00000001a8123456 __NSNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__ + 12
3   Foundation                0x00000001a8123789 -[NSNotificationCenter postNotificationName:object:userInfo:] + 82
4   ShoppingApp               0x0000000102a2c890 -[CartManager addItem:] + 340 (CartManager.m:67)
...
```

## 崩溃点源码
```objc
// ProductViewController.m
@implementation ProductViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(cartDidUpdate:) 
                                                 name:@"CartDidUpdateNotification" 
                                               object:nil];
}

- (void)cartDidUpdate:(NSNotification *)notification {
    [self updateCartBadge];
}

- (void)updateCartBadge {
    NSInteger count = [CartManager shared].itemCount;
    self.cartBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)count];  // <- 崩溃点
}

- (void)dealloc {
    // 未移除通知观察者
}

@end
```

## 近期相关变更
```
commit abc123 - 2026-11-01
新增：购物车实时更新通知，优化用户体验
修改：CartManager.m, ProductViewController.m
```
```

### 输出

```markdown
## 代码审查

### 潜在问题点
1. **通知观察者未移除**：`dealloc` 中未调用 `removeObserver`
2. **异步回调无保护**：虽然是通知回调，但无法保证 `self` 仍有效
3. **UI 对象访问**：直接访问 `self.cartBadgeLabel` 未检查是否为 `nil`

### 内存管理分析
- `ProductViewController` 被释放后，通知中心仍持有观察者引用
- 当购物车更新时，通知发送到已释放的对象，导致野指针访问

### 多线程分析
- 崩溃发生在主线程
- 通知回调也在主线程，无竞态条件

---

## 根因假设

### 假设 1：通知观察者未移除，ViewController 释放后仍收到通知
**可能性**：⭐⭐⭐⭐⭐ 高

**证据链**：
1. 崩溃栈显示通过通知回调触发：`__NSNOTIFICATIONCENTER_IS_CALLING_OUT_TO_AN_OBSERVER__`
2. 源码中 `dealloc` 方法为空，未调用 `removeObserver`
3. 崩溃类型为 `EXC_BAD_ACCESS`，典型的野指针访问

**触发条件**：
- 用户进入商品详情页（ProductViewController 初始化）
- 用户返回上一页（ProductViewController 被释放）
- 用户在其他页面添加商品到购物车
- 通知发送到已释放的 ProductViewController，触发崩溃

**修复代码**：
```objc
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

**修复说明**：
在 `dealloc` 中移除通知观察者，避免对象释放后仍收到通知回调。

**副作用评估**：
- ✅ 无副作用
- ✅ 性能开销极小
- ✅ ARC 兼容

**验证方法**：
1. **单元测试**：
   ```objc
   func testProductViewController_whenDeallocated_shouldNotReceiveNotification() {
       var vc: ProductViewController? = ProductViewController()
       vc?.viewDidLoad()
       
       let expectation = XCTestExpectation(description: "Should not crash")
       vc = nil  // 释放 VC
       
       NotificationCenter.default.post(name: NSNotification.Name("CartDidUpdateNotification"), object: nil)
       
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
           expectation.fulfill()
       }
       
       wait(for: [expectation], timeout: 2.0)
   }
   ```

2. **手动复现**：
   - 进入商品详情页
   - 返回上一页
   - 在其他页面添加商品到购物车
   - 观察是否崩溃

---

### 假设 2：cartBadgeLabel 为 nil 或已被释放
**可能性**：⭐⭐ 低

**证据链**：
1. `cartBadgeLabel` 可能是 `weak` 属性，在回调时已被释放
2. 如果 `cartBadgeLabel` 是子视图，可能在 ViewController 释放过程中先被移除

**触发条件**：
- `cartBadgeLabel` 被提前移除（如视图重建）
- ViewController 在释放过程中收到通知

**修复代码**：
```objc
- (void)updateCartBadge {
    if (!self.cartBadgeLabel) {
        NSLog(@"[Crash Fix] cartBadgeLabel is nil, skipping update");
        return;
    }
    
    NSInteger count = [CartManager shared].itemCount;
    self.cartBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}
```

**修复说明**：
在访问 `cartBadgeLabel` 前检查是否为 `nil`，增加防护。

**副作用评估**：
- ✅ 无副作用
- ⚠️ 治标不治本，如果根因是假设 1，仍会有其他崩溃风险

**验证方法**：
- 添加日志监控，观察是否有 `cartBadgeLabel is nil` 日志

---

### 假设 3：CartManager shared 单例被释放
**可能性**：⭐ 极低

**证据链**：
- 崩溃点在访问 `self.cartBadgeLabel`，而非 `[CartManager shared]`
- 如果是单例问题，崩溃栈会显示在 `CartManager` 内部

**触发条件**：
- 不太可能，单例通常不会被释放

**修复代码**：
```objc
- (void)updateCartBadge {
    CartManager *cartManager = [CartManager shared];
    if (!cartManager) return;
    
    NSInteger count = cartManager.itemCount;
    self.cartBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}
```

**修复说明**：
防御性编程，检查单例是否为 `nil`。

**副作用评估**：
- ✅ 无副作用
- ⚠️ 可能性极低，不推荐优先实施

---

## 优先建议

### 推荐修复方案：实施假设 1 + 假设 2
**理由**：
1. 假设 1 的可能性最高（通知观察者未移除是经典野指针崩溃原因）
2. 假设 2 的防护代码成本低，可以作为额外保险

**修复代码（组合）**：
```objc
- (void)updateCartBadge {
    // 防护：检查 UI 对象是否有效
    if (!self.cartBadgeLabel) {
        NSLog(@"[Crash Fix] cartBadgeLabel is nil");
        return;
    }
    
    NSInteger count = [CartManager shared].itemCount;
    self.cartBadgeLabel.text = [NSString stringWithFormat:@"%ld", (long)count];
}

- (void)dealloc {
    // 根本修复：移除通知观察者
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
```

### 验证计划
1. 本地复现测试（按上述步骤）
2. 添加崩溃监控埋点
3. 灰度发布 10% 用户，观察 3 天
4. 监控该崩溃是否消失（目标：崩溃率下降 > 90%）

### 后续优化建议
- 考虑使用 `NSNotificationCenter` 的 block-based API（iOS 9+），自动管理观察者生命周期：
  ```objc
  self.cartUpdateObserver = [[NSNotificationCenter defaultCenter] 
      addObserverForName:@"CartDidUpdateNotification" 
                  object:nil 
                   queue:[NSOperationQueue mainQueue] 
              usingBlock:^(NSNotification *note) {
                  [self updateCartBadge];
              }];
  ```
- 在 `dealloc` 中移除：
  ```objc
  [[NSNotificationCenter defaultCenter] removeObserver:self.cartUpdateObserver];
  ```
```

## 注意事项

- AI 的假设是基于代码静态分析，必须通过复现测试或单元测试验证
- 如果提供的源码不完整（如缺少属性定义、初始化逻辑），AI 的假设可能不准确
- 对于复杂的多线程崩溃，建议提供所有相关线程的调用栈
- 修复代码应保持与项目现有代码风格一致（Objective-C / Swift、命名约定等）
- 如果 AI 给出的假设都不对，补充更多上下文信息（如近期变更、用户操作路径）重新分析

---

**适用场景**：精准定位根因、快速生成修复方案、灰度发布验证  
**前置工作流**：[符号化后栈解读与分诊](./symbolicate-and-triage.md)  
**维护者**：Loong (SSLoong)  
**更新日期**：2026-11-03
