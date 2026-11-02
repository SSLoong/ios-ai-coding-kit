# 工作流：使用 AI 辅助 Instruments 性能诊断

## 📋 背景

iOS 性能优化是技术负责人的核心职责，但在实践中常面临挑战：
- **数据量大**：Instruments 生成的 trace 数据动辄数十万行，人工定位耗时
- **专业性高**：Time Profiler、Allocations、Leaks 等工具门槛不低，新人难以上手
- **经验依赖**：热点函数、循环引用模式需要经验识别
- **优化决策难**：需要权衡性能收益、改动成本和风险

使用 AI 辅助 Instruments 诊断，可以：
- 快速解读 trace 数据，识别性能热点和异常模式
- 提供优化建议和代码示例
- 辅助分析内存泄漏的引用链路
- 对比优化前后的性能指标

## 🎯 目标

建立基于 AI 的性能诊断工作流，达到以下标准：
- **定位准确**：通过 AI 解读 trace 数据，15 分钟内定位主要性能瓶颈
- **建议可操作**：每个热点给出具体优化方向和代码示例
- **风险可控**：优化建议附带改动评估（影响范围、测试要求）
- **效果可量化**：优化前后对比关键指标（CPU 占用、内存峰值、启动时间）

## 🛠️ 适用场景

- ✅ 定位 CPU 热点（Time Profiler 数据解读）
- ✅ 分析内存泄漏（Leaks + Allocations 审计）
- ✅ 诊断主线程卡顿（Hang / Main Thread Checker）
- ✅ 优化启动性能（App Launch 模板分析）
- ✅ 审查循环引用（Retain Cycle 模式识别）
- ❌ 不适合替代实测（AI 基于静态数据，无法预测真实性能）
- ❌ 不适合端到端优化决策（需结合业务优先级和用户影响）

## 📝 工作流步骤

### 步骤 1：采集性能数据

在使用 AI 前，需在 Xcode Instruments 中完成数据采集。

#### 1.1 选择合适的模板

根据性能问题类型选择 Instruments 模板：

| 问题类型 | Instruments 模板 | 关键指标 |
|---------|-----------------|---------|
| CPU 占用高、卡顿 | Time Profiler | Heaviest Stack Trace、Self Time |
| 内存占用高 | Allocations | Live Bytes、Persistent Bytes |
| 内存泄漏 | Leaks | Leaks、Cycles & Roots |
| 启动慢 | App Launch | Total Time、Static Initializers |
| 主线程阻塞 | Hangs / Main Thread Checker | Hang Duration、Blocking Operations |

#### 1.2 运行测试场景

```bash
# 方式一：从 Xcode 启动（推荐）
# 1. Xcode → Product → Profile (Cmd+I)
# 2. 选择对应模板（如 Time Profiler）
# 3. 执行完整的用户场景（如：启动 App → 滚动列表 → 详情页 → 返回）
# 4. 点击停止录制

# 方式二：命令行启动（自动化场景）
xctrace record \
  --template 'Time Profiler' \
  --device 'iPhone 15 Simulator' \
  --launch com.yourcompany.YourApp \
  --output profile.trace
```

**采集要点**：
- **时长**：至少 30 秒，覆盖完整用户场景
- **真机**：性能问题尽量在真机采集（模拟器行为与真机不同）
- **Release 模式**：使用 Release 配置（编译优化会影响结果）
- **重复测试**：执行 3 次取平均值，避免偶然因素

#### 1.3 导出关键数据

Instruments 采集后，导出 AI 可分析的文本格式数据。

**Time Profiler 导出**：
1. 在 Instruments 中选择 Time Profiler track
2. 右键点击调用栈区域 → Export...
3. 选择格式：XML 或 Text（建议 Text，更易读）
4. 保存为 `time-profiler-export.txt`

**Allocations / Leaks 导出**：
1. 选择 Allocations 或 Leaks track
2. 在详细信息面板，筛选关键对象（如按类名过滤）
3. 右键 → Export...
4. 保存为 `allocations-export.txt` 或 `leaks-export.txt`

**启动时间数据采集**：
```bash
# 使用 App Launch 模板后，在统计面板查看：
# - Total Time（总启动时间）
# - Static Initializer Time（静态初始化时间）
# - Pre-main Time（main 前耗时）

# 手动记录到 launch-stats.txt
echo "Total Time: 1.8s" > launch-stats.txt
echo "Pre-main Time: 0.6s" >> launch-stats.txt
echo "Dynamic Linker: 0.4s" >> launch-stats.txt
echo "Static Initializers: 0.2s" >> launch-stats.txt
```

### 步骤 2：第一阶段 - CPU 热点快速识别

针对 Time Profiler 数据，使用 AI 快速定位 CPU 热点。

#### 2.1 准备上下文

创建 `profiling-context.md` 文件：

```markdown
## 应用场景
- 测试场景：用户滚动商品列表，加载 50 条数据
- 测试设备：iPhone 14 Pro (iOS 17.0)
- 配置：Release + 编译优化

## 技术栈
- UI 框架：SwiftUI + UIKit 混合
- 数据层：Core Data + Alamofire
- 图片加载：Kingfisher
- 已知问题：列表滚动时偶尔卡顿

## 优化目标
- 期望滚动帧率稳定在 60 FPS
- CPU 占用不超过 50%（主线程）
```

#### 2.2 使用热点识别提示词

在 Cursor/Claude 中，使用 [prompts/performance/time-profiler-hotspot.md](../prompts/performance/time-profiler-hotspot.md) 提示词。

示例对话：

```
我需要分析 Time Profiler 的热点数据，定位性能瓶颈。

## 场景上下文
[粘贴 profiling-context.md 内容]

## Time Profiler 数据
[粘贴 time-profiler-export.txt 内容，至少包含 Top 20 Heaviest Stack Traces]

## 分析要求
1. 识别 Top 3 热点函数（按 Self Time 排序）
2. 判断热点是否合理（如：JSON 解析、图片解码属于正常开销）
3. 对于异常热点，给出：
   - 可能原因
   - 优化方向
   - 代码示例
   - 预期收益（CPU 时间减少比例）

## 输出格式
按优先级分组输出，每个热点包含函数名、耗时占比、问题分析、优化建议。
```

#### 2.3 解读 AI 输出

AI 会输出类似以下格式的报告：

```markdown
### 🔥 P0 - 严重热点（必须优化）

- **ProductListView.layoutSubviews()** - 占比 28.5%
  - 问题：每次滚动都重新计算所有子视图布局
  - 原因：使用了嵌套 UIStackView，布局复杂度 O(n²)
  - 优化：改用 UICollectionView + DiffableDataSource
  - 预期收益：减少 70% 布局时间
  
  ```swift
  // ❌ 当前实现（慢）
  class ProductCell: UITableViewCell {
      let stackView = UIStackView()  // 嵌套层级深
      override func layoutSubviews() {
          // 每次滚动都触发
      }
  }
  
  // ✅ 优化方案
  class ProductCell: UICollectionViewCell {
      // 使用 Auto Layout + 缓存计算结果
      override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
          let cachedSize = // 从缓存读取
          return layoutAttributes
      }
  }
  ```

### ⚠️ P1 - 次要热点（建议优化）

- **JSONDecoder.decode()** - 占比 12.3%
  - 问题：主线程同步解析大 JSON（50 个商品对象）
  - 优化：移到后台队列 + 分批解码
  - 预期收益：主线程 CPU 下降 12%

### ✅ 正常开销（无需优化）

- **SDWebImage.decodeImage()** - 占比 8.7%
  - 判断：图片解码是必要开销，且已在后台线程
  - 备注：如需进一步优化，考虑降低图片分辨率
```

#### 2.4 验证热点分析

**人工判断检查清单**：
- [ ] Top 3 热点函数是否在 Self Time 列表中真实存在？
- [ ] AI 分析的"嵌套布局"等问题是否符合代码实际结构？
- [ ] 优化方案是否可行？（如改用 CollectionView 是否会影响现有功能）
- [ ] 预期收益是否合理？（可用 Instruments 对比优化前后）

### 步骤 3：第二阶段 - 内存泄漏审计

针对 Leaks 和 Allocations 数据，识别循环引用和泄漏对象。

#### 3.1 准备泄漏数据

在 Instruments Leaks 中：
1. 筛选 Leaked Blocks（显示红色的对象）
2. 查看 Cycles & Roots（循环引用链路）
3. 导出为 `leaks-export.txt`

示例数据格式：
```
Leaked Object: ProfileViewController (0x1a2b3c4d5)
  Retains: UserViewModel (0x2b3c4d5e6)
  Retains: NetworkService (0x3c4d5e6f7)
  Retains: ProfileViewController (0x1a2b3c4d5)  ← Cycle!
```

#### 3.2 使用循环引用审计提示词

在 Cursor/Claude 中，使用 [prompts/performance/retain-cycle-audit.md](../prompts/performance/retain-cycle-audit.md) 提示词。

示例对话：

```
我需要分析 Instruments Leaks 的数据，审计内存泄漏和循环引用。

## 泄漏数据
[粘贴 leaks-export.txt 内容]

## 相关代码
[粘贴 ProfileViewController.swift 的关键代码片段]

## 审计要求
1. 识别所有循环引用链路
2. 判断泄漏类型：
   - 强引用循环（closure capture、delegate）
   - 定时器未销毁
   - 通知未移除
   - KVO 未注销
3. 对于每个泄漏，给出：
   - 引用链路示意图
   - 根因分析
   - 修复代码（使用 [weak self]、unowned 或显式销毁）
   - 验证方法

## 输出格式
按泄漏对象分组，每个泄漏包含类型、引用链路、修复方案。
```

#### 3.3 解读 AI 输出

```markdown
### 🚨 循环引用 #1：ProfileViewController ↔ UserViewModel

**引用链路**：
```
ProfileViewController (强引用)
  └─ viewModel: UserViewModel (强引用)
      └─ onUpdate: () -> Void (closure 强捕获)
          └─ self (ProfileViewController) ← 循环！
```

**根因**：
```swift
// ❌ 问题代码
class ProfileViewController: UIViewController {
    let viewModel: UserViewModel
    
    override func viewDidLoad() {
        viewModel.onUpdate = {
            self.updateUI()  // 强捕获 self
        }
    }
}
```

**修复方案**：
```swift
// ✅ 方案 1：使用 [weak self]
viewModel.onUpdate = { [weak self] in
    self?.updateUI()
}

// ✅ 方案 2：使用 Combine（推荐）
viewModel.$user
    .sink { [weak self] user in
        self?.updateUI(user: user)
    }
    .store(in: &cancellables)
```

**验证方法**：
1. 在 `deinit` 中打印日志：`print("ProfileViewController deinitialized")`
2. 退出页面后查看日志是否打印
3. 再次运行 Instruments Leaks 确认泄漏消失

---

### 🚨 循环引用 #2：定时器未销毁

**问题**：
```swift
// ❌ Timer 强引用 self，且未在 deinit 中 invalidate
class BannerView: UIView {
    var timer: Timer?
    
    func startAutoPlay() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.nextPage()  // 强引用 self
        }
    }
}
```

**修复**：
```swift
// ✅ 在 deinit 中显式销毁
deinit {
    timer?.invalidate()
    timer = nil
}
```
```

#### 3.4 批量修复与验证

按 AI 给出的修复方案逐个修改代码：

```bash
# 修复后，再次运行 Leaks
# 1. Xcode → Product → Profile (Cmd+I)
# 2. 选择 Leaks 模板
# 3. 执行测试场景（进入页面 → 退出 → 重复 10 次）
# 4. 检查 Leaks 列表是否为空
```

### 步骤 4：第三阶段 - 启动性能优化

针对 App Launch 模板的数据，优化启动时间。

#### 4.1 分析启动阶段耗时

从 Instruments App Launch 模板获取：

```
## 启动耗时分解（总计 1.8s）
- Pre-main Time: 0.6s
  - Dynamic Linker: 0.4s (加载 dylib)
  - Static Initializers: 0.2s (+[AppDelegate load])
- Main() to First Frame: 1.2s
  - application:didFinishLaunching: 0.8s
  - rootViewController.viewDidLoad: 0.4s
```

#### 4.2 使用启动优化提示词

```
我需要优化 iOS App 的启动时间。

## 当前启动数据
[粘贴上述启动耗时分解]

## 代码上下文
[粘贴 AppDelegate.swift 和 RootViewController.swift 关键代码]

## 优化目标
- 总启动时间从 1.8s 降到 1.0s 以内
- Pre-main Time 不超过 0.3s
- didFinishLaunching 不超过 0.5s

## 分析要求
1. 识别每个阶段的优化点
2. 区分"必须启动时完成"和"可延迟加载"的任务
3. 给出优化方案和预期收益

## 输出格式
按启动阶段分组（Pre-main、didFinishLaunching、首屏加载），列出优化项。
```

#### 4.3 典型优化建议

AI 可能给出以下建议：

**Pre-main 优化**：
- 减少动态库数量（合并或移除非必要依赖）
- 移除 `+load` 方法中的重逻辑
- 延迟初始化单例

**didFinishLaunching 优化**：
```swift
// ❌ 启动时初始化所有服务
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    setupFirebase()      // 0.3s
    setupAnalytics()     // 0.2s
    preloadCache()       // 0.3s
    return true
}

// ✅ 延迟非必要初始化
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // 仅初始化首屏必需的
    setupCrashReporting()
    
    // 延迟初始化其他服务
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.setupFirebase()
        self.setupAnalytics()
    }
    
    // 后台预加载缓存
    DispatchQueue.global(qos: .background).async {
        self.preloadCache()
    }
    
    return true
}
```

**首屏加载优化**：
- 使用占位符避免白屏
- 异步加载非首屏数据
- 优化首屏视图层级（减少嵌套）

### 步骤 5：人工决策与优化实施

#### 5.1 评估优化方案可行性

**风险评估清单**：
- [ ] 改动是否会影响现有功能？（如布局改动需完整回归测试）
- [ ] 是否需要适配多个 iOS 版本？（新 API 需要 @available 检查）
- [ ] 优化是否会引入新问题？（如后台任务可能被系统杀掉）
- [ ] 改动成本是否合理？（预期收益 vs 开发测试成本）

#### 5.2 分阶段实施

**建议顺序**：
1. **低风险高收益**：修复明显的循环引用、主线程阻塞
2. **中等改动**：优化布局代码、异步化耗时操作
3. **大重构**：替换底层架构（如 UITableView → UICollectionView）

#### 5.3 性能对比测试

每个优化后，使用 Instruments 再次采集数据对比：

```markdown
## 优化效果对比

### 优化项：列表布局改用 UICollectionView

| 指标 | 优化前 | 优化后 | 改善 |
|------|--------|--------|------|
| layoutSubviews() CPU 占比 | 28.5% | 6.2% | ↓ 78% |
| 滚动帧率（平均） | 48 FPS | 58 FPS | ↑ 21% |
| 主线程 CPU 占用 | 65% | 38% | ↓ 42% |
```

### 步骤 6：持续监控与回归

#### 6.1 建立性能基线

将关键指标记录为基线，用于回归检测：

```yaml
# performance-baseline.yml
metrics:
  launch_time:
    total: 1.0s
    pre_main: 0.3s
    did_finish_launching: 0.5s
  
  list_scrolling:
    fps_average: 58
    main_thread_cpu: 38%
  
  memory:
    peak_usage: 120MB
    leaks: 0
```

#### 6.2 集成自动化监控（可选）

在 CI 中集成性能测试：

```bash
# .github/workflows/performance-test.yml
- name: Run Performance Test
  run: |
    xcodebuild test \
      -scheme YourApp \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -testPlan PerformanceTests
    
    # 解析 XCTest 性能指标
    python scripts/parse_perf_metrics.py
    
    # 与基线对比，超过阈值则失败
    python scripts/compare_baseline.py
```

## ✅ 验证清单

### 数据采集完整性
- [ ] Instruments 数据采集时长 ≥ 30 秒，覆盖完整场景
- [ ] 使用 Release 配置 + 真机采集（模拟器数据仅供参考）
- [ ] 导出的 trace 数据包含 Top 20 热点函数
- [ ] 内存泄漏测试重复 10 次场景（进入-退出）

### AI 分析准确性
- [ ] AI 识别的热点函数在 Instruments 中真实存在
- [ ] 优化建议有具体代码示例（非空洞描述）
- [ ] 循环引用链路与代码实际结构一致
- [ ] 人工验证了 AI 给出的根因分析

### 优化效果验证
- [ ] 每个优化项都有优化前后的性能对比数据
- [ ] 关键指标达到预期（如启动时间 ≤ 1.0s）
- [ ] Leaks 列表为空（无内存泄漏）
- [ ] 回归测试通过（优化未引入新 bug）

## 🐛 常见问题

### Q1: AI 识别的热点与实际场景不符

**原因**：采集的测试场景与实际用户行为不一致。

**解决**：
1. **采集真实场景**：
   - 使用埋点数据分析用户高频操作路径
   - 针对性采集（如：80% 用户会滚动列表 → 重点测试滚动）

2. **分段采集**：
   ```
   场景 1：冷启动 → 首屏加载（采集 30s）
   场景 2：列表滚动（采集 1 分钟）
   场景 3：详情页操作（采集 30s）
   ```

3. **在提示词中明确场景**：
   ```
   本次 Profiling 仅测试列表滚动场景，请忽略启动阶段的热点。
   ```

### Q2: AI 建议的优化方案改动成本太高

**原因**：AI 倾向于给出"理想方案"，忽略现实约束。

**解决**：
1. **明确约束条件**：
   ```
   ## 优化约束
   - 改动范围：仅限 ProductListView 单个类
   - 时间限制：1 人日内完成
   - 不可改动：底层 Model 层（其他模块依赖）
   
   请给出"快速优化"方案，而非大重构。
   ```

2. **要求分阶段方案**：
   ```
   请提供三个层次的优化方案：
   - P0：1 小时内快速修复（如去除明显的冗余计算）
   - P1：1 人日改动（如优化布局算法）
   - P2：长期重构（如替换底层架构）
   ```

### Q3: 修复循环引用后 Leaks 仍然存在

**原因**：
- Instruments Leaks 有误报（对象未被立即释放）
- 存在其他未识别的引用链路
- 系统框架持有对象（如 UIKit 的 Responder Chain）

**排查步骤**：
1. **验证 deinit 是否调用**：
   ```swift
   deinit {
       print("✅ \(Self.self) deinitialized")
   }
   ```

2. **使用 Memory Graph 确认**：
   - Xcode → Debug → Memory Graph (Cmd+Shift+M)
   - 搜索泄漏对象类名
   - 查看 References（谁持有该对象）

3. **让 AI 分析 Memory Graph**：
   ```
   [截图 Memory Graph 的引用关系图]
   请分析为什么 ProfileViewController 未被释放。
   ```

4. **排查系统持有**：
   - 检查是否注册了通知但未移除
   - 检查是否设置了 delegate 但未置 nil
   - 检查是否持有了 UIViewController 的强引用

### Q4: 启动时间优化后首屏加载变慢

**原因**：延迟初始化导致首屏数据未就绪。

**解决**：
1. **区分"首屏必需"和"可延迟"**：
   ```
   首屏必需：
   - 网络服务（获取首屏数据）
   - 用户认证状态（决定显示登录页或主页）
   
   可延迟：
   - 第三方 SDK（Analytics、Crash Reporting）
   - 后台数据预加载（非首屏）
   ```

2. **使用占位符**：
   ```swift
   // 显示骨架屏，避免白屏
   override func viewDidLoad() {
       showSkeletonView()
       
       Task {
           let data = await fetchData()
           hideSkeletonView()
           updateUI(data: data)
       }
   }
   ```

3. **优化加载优先级**：
   ```swift
   // 先加载关键数据，再加载次要数据
   Task {
       // 高优先级：首屏商品列表
       let products = await fetchProducts()
       updateProductList(products)
       
       // 低优先级：推荐商品
       let recommendations = await fetchRecommendations()
       updateRecommendations(recommendations)
   }
   ```

### Q5: Instruments 数据太大，AI 分析超时或截断

**原因**：导出的 trace 数据可能有数十 MB，超过 AI 上下文窗口。

**解决**：
1. **仅导出 Top 50 热点**：
   - 在 Instruments 中按 Self Time 排序
   - 选择前 50 行导出

2. **分段分析**：
   ```
   第一轮：分析 Top 10 热点
   第二轮：针对单个热点，粘贴完整调用栈
   ```

3. **使用统计摘要**：
   ```
   不要粘贴完整 trace，手动整理摘要：
   
   | 函数名 | Self Time | Total Time | Call Count |
   |--------|-----------|------------|------------|
   | layoutSubviews() | 28.5% | 35.2% | 1200 |
   | decode(_:) | 12.3% | 15.8% | 50 |
   ```

4. **Claude Code 分片上传**：
   - 将大文件上传到项目文件夹
   - 在 Cursor 中 @mention 文件路径
   - AI 可读取完整文件而不受消息长度限制

## 🎓 最佳实践

### 1. 数据采集规范

- ✅ **真机测试**：模拟器性能与真机差异大（尤其是图形渲染）
- ✅ **Release 配置**：使用 Release + Whole Module Optimization
- ✅ **重复测试**：每个场景测试 3 次，取平均值
- ✅ **完整场景**：覆盖真实用户路径（不要只测单个页面）
- ❌ 不要在 Debug 模式下采集（性能数据不准确）
- ❌ 不要采集时长过短（< 10 秒数据不稳定）

### 2. AI 分析技巧

- ✅ **提供完整上下文**：场景说明、技术栈、已知问题
- ✅ **明确优化目标**：量化指标（如启动 < 1s）而非"尽可能快"
- ✅ **要求优先级分级**：P0/P1/P2，避免"全都要"
- ✅ **索要代码示例**：不接受空洞建议（如"优化算法"）
- ❌ 不要期望 AI 预测真实性能（需实测验证）
- ❌ 不要盲目采纳建议（评估改动成本和风险）

### 3. 优化决策框架

| 热点类型 | 是否优化 | 判断标准 |
|---------|---------|---------|
| 业务逻辑计算 | ✅ 优化 | 可移到后台或优化算法 |
| 系统框架调用 | ⚠️ 慎重 | 如 UIKit 布局，可优化视图层级 |
| 必要开销 | ❌ 接受 | 如图片解码、网络请求 |
| 第三方 SDK | ⚠️ 慎重 | 评估是否可替换或延迟加载 |

### 4. 人机协作分工

| 任务 | AI 擅长 | 人工擅长 |
|------|---------|---------|
| 识别热点函数 | ✅ | ❌ |
| 解读调用栈 | ✅ | ⚠️ 复杂场景需人工 |
| 给出优化代码 | ✅ | ❌ |
| 评估改动成本 | ❌ | ✅ |
| 验证优化效果 | ❌ | ✅ |
| 性能回归测试 | ❌ | ✅ |

### 5. 优化效果量化

每个优化都应记录对比数据：

```markdown
## 优化记录：修复循环引用导致的内存泄漏

**问题**：ProfileViewController 未释放
**根因**：closure 强捕获 self
**改动**：添加 [weak self]（1 行代码）
**验证**：deinit 正常调用

| 指标 | 优化前 | 优化后 |
|------|--------|--------|
| 内存峰值（进入页面 10 次） | 180 MB | 95 MB |
| Leaks 数量 | 10 个 ProfileViewController | 0 |

**上线日期**：2026-11-02
**负责人**：Loong
```

### 6. 建立性能文化

- ✅ 每个 PR 都检查 Instruments（至少 Leaks）
- ✅ 定期（每月）对主流程进行 Time Profiler 采集
- ✅ 记录优化案例，沉淀团队知识
- ✅ 新人入职培训包含 Instruments 使用
- ❌ 不要"等出问题再优化"（预防大于治疗）
- ❌ 不要优化无关紧要的指标（如启动已 < 1s）

## 📚 扩展阅读

### Apple 官方文档
- [Instruments User Guide](https://help.apple.com/instruments/)
- [Improving Your App's Performance](https://developer.apple.com/documentation/xcode/improving-your-app-s-performance)
- [Diagnosing Memory, Thread, and Crash Issues Early](https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early)

### 性能优化最佳实践
- [WWDC: Optimizing App Startup Time](https://developer.apple.com/videos/play/wwdc2019/423/)
- [Swift.org: Performance Tips](https://github.com/apple/swift/blob/main/docs/OptimizationTips.rst)
- [Kodeco: Instruments Tutorial](https://www.kodeco.com/16126261-instruments-tutorial-getting-started)

### 内存管理
- [iOS Memory Deep Dive (WWDC)](https://developer.apple.com/videos/play/wwdc2018/416/)
- [Understanding Swift Performance (WWDC)](https://developer.apple.com/videos/play/wwdc2016/416/)

## 🔗 相关工作流

- [Prompts：Time Profiler 热点分析](../prompts/performance/time-profiler-hotspot.md)
- [Prompts：循环引用审计](../prompts/performance/retain-cycle-audit.md)
- [使用 AI 进行代码 Review](./ai-code-review.md)（可结合性能检查）
- [为 Swift 模块补充单元测试](./unit-test-generation.md)（优化后需补充性能测试）

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-02  
**适用工具**：Xcode Instruments + Cursor/Claude
