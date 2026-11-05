# Time Profiler 热点分析提示词

## 场景说明
为 Xcode Instruments Time Profiler 导出的数据提供热点识别和优化建议，定位 CPU 性能瓶颈。

## 输入要求

### 必需
- Time Profiler 导出的调用栈数据（至少 Top 20）
- 测试场景说明（如：列表滚动、页面加载）
- 应用技术栈（UIKit/SwiftUI、数据层框架）

### 可选
- 相关代码片段（热点函数的实现）
- 性能目标（如：CPU < 50%、帧率 60 FPS）
- 已知问题描述

## 提示词模板

```
我需要分析 Time Profiler 的热点数据，定位 CPU 性能瓶颈。

## 测试场景
- 场景描述：[描述测试的用户操作，如"用户快速滚动包含 100 个商品的列表"]
- 测试设备：[如 iPhone 14 Pro, iOS 17.0]
- 编译配置：[Debug / Release]
- 测试时长：[如 60 秒]

## 技术栈
- UI 框架：[UIKit / SwiftUI / 混合]
- 架构模式：[MVVM / MVI / VIPER]
- 数据层：[Core Data / Realm / 网络直接加载]
- 图片加载：[SDWebImage / Kingfisher / 原生]
- 已知问题：[如"列表滚动时偶尔掉帧"]

## Time Profiler 数据
[粘贴 Instruments 导出的数据，格式示例：]
```
Heaviest Stack Trace (Self Time):
1. ProductListView.layoutSubviews() - 28.5% (285 ms)
2. UITableView.dequeueReusableCell() - 15.2% (152 ms)
3. JSONDecoder.decode() - 12.3% (123 ms)
4. SDWebImage.decodeImage() - 8.7% (87 ms)
5. NetworkService.processResponse() - 6.4% (64 ms)
...
```

## 分析要求

### 1. 热点分级
按严重程度分为三级：
- **P0 严重热点**：Self Time > 15% 且明显异常（如：简单计算耗时过高）
- **P1 次要热点**：Self Time 5%-15% 且有优化空间
- **P2 正常开销**：必要开销（如图片解码）或占比 < 5%

### 2. 对于每个 P0/P1 热点，输出
- **函数名**：完整的函数签名
- **耗时占比**：Self Time 和 Total Time
- **问题分析**：为什么慢？（算法复杂度、主线程阻塞、重复计算等）
- **可能原因**：列出 2-3 个最可能的根因
- **优化方向**：具体的优化思路（非空洞建议）
- **代码示例**：包含"优化前"和"优化后"对比代码
- **预期收益**：量化改进（如"CPU 时间减少 60%"、"帧率提升至 60 FPS"）
- **改动风险**：评估改动范围（低/中/高）和潜在副作用

### 3. 优先级排序
按"收益/成本比"排序优化建议：
- 优先推荐：高收益 + 低改动成本
- 次优推荐：高收益 + 中等改动成本
- 长期优化：需要大重构的方案

### 4. 合理性判断
对于以下情况，标记为"正常开销，无需优化"：
- 图片/视频解码（已在后台线程）
- 网络数据解析（数据量大且必要）
- 系统框架的必要调用（如 Auto Layout 计算）

## 输出格式

请按以下格式输出：

### 🔥 P0 严重热点（必须优化）

#### 热点 1：[函数名] - [占比]%
- **问题**：[一句话描述问题]
- **原因**：[根因分析]
- **优化方向**：[具体思路]
- **预期收益**：[量化指标]
- **改动风险**：[低/中/高]

**代码对比**：
```swift
// ❌ 当前实现（慢）
[粘贴或描述问题代码]

// ✅ 优化方案
[粘贴优化后的代码]
```

---

### ⚠️ P1 次要热点（建议优化）

[同上格式]

---

### ✅ 正常开销（无需优化）

- **[函数名]** - [占比]%
  - 判断：[为什么是正常开销]
  - 备注：[如需进一步优化的条件]

---

## 优化优先级建议

按收益/成本比排序：
1. [热点名称] - 预期收益 [X]%，改动风险低
2. [热点名称] - 预期收益 [Y]%，改动风险中
...
```

## 使用示例

### 输入

```
我需要分析 Time Profiler 的热点数据，定位 CPU 性能瓶颈。

## 测试场景
- 场景描述：用户快速滚动包含 50 个商品的垂直列表
- 测试设备：iPhone 14 Pro, iOS 17.0
- 编译配置：Release + Whole Module Optimization
- 测试时长：60 秒

## 技术栈
- UI 框架：UIKit (UITableView)
- 架构模式：MVVM
- 数据层：Alamofire + Core Data 缓存
- 图片加载：SDWebImage
- 已知问题：滚动时帧率下降到 40-50 FPS

## Time Profiler 数据
Heaviest Stack Trace (Self Time):
1. ProductCell.layoutSubviews() - 32.8% (1.97s)
2. UITableView.dequeueReusableCell(withIdentifier:for:) - 8.2% (492ms)
3. ProductViewModel.formattedPrice - 7.5% (450ms)
4. JSONDecoder.decode(_:from:) - 6.3% (378ms)
5. SDWebImageManager.loadImage() - 4.1% (246ms)

## 分析要求
[使用上述完整要求]
```

### AI 输出

```markdown
### 🔥 P0 严重热点（必须优化）

#### 热点 1：ProductCell.layoutSubviews() - 32.8%
- **问题**：每次滚动都重新计算所有子视图布局，且使用嵌套 UIStackView
- **原因**：
  1. UIStackView 嵌套层级达到 4 层，布局复杂度 O(n²)
  2. 未缓存布局计算结果，每次 dequeue 都重新计算
  3. Auto Layout 约束数量过多（每个 cell 有 50+ 约束）
- **优化方向**：
  1. 改用手动布局（frame 或 Auto Layout + 缓存）
  2. 减少视图层级（扁平化，避免嵌套 StackView）
  3. 使用 `systemLayoutSizeFitting` 缓存高度
- **预期收益**：CPU 时间减少 70%，帧率提升至 58-60 FPS
- **改动风险**：中（需要重构 cell 布局代码，但不影响业务逻辑）

**代码对比**：
```swift
// ❌ 当前实现（慢）
class ProductCell: UITableViewCell {
    let containerStack = UIStackView()  // 第 1 层
    let topStack = UIStackView()        // 第 2 层
    let priceStack = UIStackView()      // 第 3 层
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // 每次滚动都触发，重新计算所有约束
        containerStack.layoutIfNeeded()  // 耗时操作
    }
}

// ✅ 优化方案 1：缓存高度，减少层级
class ProductCell: UITableViewCell {
    // 扁平化视图层级（去除嵌套 StackView）
    let imageView = UIImageView()
    let titleLabel = UILabel()
    let priceLabel = UILabel()
    
    private static var heightCache: [String: CGFloat] = [:]
    
    func configure(product: Product) {
        // 先查缓存
        let cacheKey = product.id
        if let cachedHeight = Self.heightCache[cacheKey] {
            // 直接使用缓存高度，避免重新计算
            return
        }
        
        // 首次计算后缓存
        layoutIfNeeded()
        Self.heightCache[cacheKey] = bounds.height
    }
}

// ✅ 优化方案 2：改用手动布局（最快，但代码较多）
class ProductCell: UITableViewCell {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 手动计算 frame（避免 Auto Layout 开销）
        let padding: CGFloat = 16
        imageView.frame = CGRect(x: padding, y: padding, width: 80, height: 80)
        
        let labelX = imageView.frame.maxX + 12
        let labelWidth = bounds.width - labelX - padding
        titleLabel.frame = CGRect(x: labelX, y: padding, width: labelWidth, height: 44)
        priceLabel.frame = CGRect(x: labelX, y: titleLabel.frame.maxY + 8, width: labelWidth, height: 20)
    }
}
```

---

#### 热点 2：ProductViewModel.formattedPrice - 7.5%
- **问题**：每次滚动重新格式化价格字符串（调用了 50 次 NumberFormatter）
- **原因**：
  1. 未缓存格式化结果，滚动时重复计算
  2. NumberFormatter 创建开销大（每次调用都 init）
- **优化方向**：
  1. 将格式化结果存储在 ViewModel 中（computed property 改为 stored property）
  2. 复用 NumberFormatter 实例（静态变量或依赖注入）
- **预期收益**：CPU 时间减少 90%（格式化从 450ms 降到 50ms）
- **改动风险**：低（仅修改 ViewModel，不影响 UI）

**代码对比**：
```swift
// ❌ 当前实现（慢）
class ProductViewModel {
    let price: Decimal
    
    var formattedPrice: String {
        let formatter = NumberFormatter()  // 每次调用都创建！
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }
}

// ✅ 优化方案 1：缓存格式化结果
class ProductViewModel {
    let price: Decimal
    private(set) lazy var formattedPrice: String = {
        Self.priceFormatter.string(from: price as NSDecimalNumber) ?? ""
    }()  // 仅计算一次
    
    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }()  // 复用实例
}

// ✅ 优化方案 2：在 Model 层预先格式化
struct Product: Codable {
    let price: Decimal
    let formattedPrice: String  // 服务端返回或本地初始化时生成
}
```

---

### ⚠️ P1 次要热点（建议优化）

#### 热点 3：JSONDecoder.decode(_:from:) - 6.3%
- **问题**：主线程同步解析 JSON
- **原因**：网络请求回调在主线程，直接调用 decode
- **优化方向**：移到后台队列解析，解析完成后回主线程更新 UI
- **预期收益**：主线程 CPU 下降 6%，滚动更流畅
- **改动风险**：低（仅调整线程，不改解析逻辑）

**代码对比**：
```swift
// ❌ 当前实现
func fetchProducts(completion: @escaping ([Product]) -> Void) {
    networkService.request(endpoint) { data in
        let products = try? JSONDecoder().decode([Product].self, from: data)  // 主线程
        completion(products ?? [])
    }
}

// ✅ 优化方案
func fetchProducts(completion: @escaping ([Product]) -> Void) {
    networkService.request(endpoint) { data in
        DispatchQueue.global(qos: .userInitiated).async {
            let products = try? JSONDecoder().decode([Product].self, from: data)  // 后台线程
            DispatchQueue.main.async {
                completion(products ?? [])
            }
        }
    }
}
```

---

### ✅ 正常开销（无需优化）

- **SDWebImageManager.loadImage()** - 4.1%
  - 判断：图片下载和解码是必要开销，且已在后台线程执行
  - 备注：如需进一步优化，考虑：
    1. 降低图片分辨率（服务端返回缩略图）
    2. 使用 WebP 格式（压缩率更高）
    3. 预加载可见范围外的图片

- **UITableView.dequeueReusableCell()** - 8.2%
  - 判断：Cell 复用是系统机制，8% 属于正常范围
  - 备注：如果超过 15%，检查 `prepareForReuse` 是否有重逻辑

---

## 优化优先级建议

按收益/成本比排序：
1. **ProductViewModel.formattedPrice** - 预期收益 90% (450ms→50ms)，改动风险低，优先级最高
2. **ProductCell.layoutSubviews** - 预期收益 70% (1.97s→600ms)，改动风险中，收益巨大
3. **JSONDecoder 异步化** - 预期收益 6%，改动风险低，快速修复

**建议实施顺序**：
- 第一阶段（1 人日）：修复 formattedPrice + JSON 异步化（低风险快速见效）
- 第二阶段（2-3 人日）：重构 Cell 布局（高收益，需完整回归测试）
```

## 注意事项

### ✅ 好的做法
- 提供完整的测试场景（AI 才能判断热点是否合理）
- 粘贴真实的 Profiler 数据（不要手动总结）
- 说明性能目标（帮助 AI 判断优化是否足够）
- 要求量化预期收益（避免空洞建议）

### ❌ 避免的做法
- 只给函数名不给耗时占比（AI 无法判断严重性）
- 混合多个场景的数据（如同时包含启动和滚动的热点）
- 不说明技术栈（AI 可能给出不适用的建议）
- 接受"优化算法"这种空洞建议（要求具体代码）

### 🔧 追加调整

如果 AI 输出不符合预期，追加指令：

```
请调整以下内容：
1. 对于热点 1，请给出"不重构 Cell，仅优化布局计算"的方案
2. 预期收益改为具体数值（如"从 1.97s 降到 600ms"）而非百分比
3. 补充代码：如何缓存 layoutSubviews 的计算结果
4. 添加风险评估：重构 Cell 是否会影响现有 UI 自动化测试
```

## 高级用法

### 场景一：对比多个优化方案

```
请为热点 ProductCell.layoutSubviews 给出三个方案：
1. 最小改动：仅缓存高度，不改布局方式
2. 中等改动：减少 StackView 层级，保留 Auto Layout
3. 完全重构：改用手动布局（frame）

每个方案输出：代码示例、预期收益、改动成本（人日）、风险评估
```

### 场景二：结合实际代码深度分析

```
[粘贴 ProductCell.swift 完整代码]

请基于实际代码，分析为什么 layoutSubviews 耗时 32%：
1. 指出具体的性能瓶颈代码行
2. 计算 Auto Layout 约束数量
3. 识别重复计算（如多次调用 layoutIfNeeded）
```

### 场景三：生成性能测试代码

```
优化完成后，请生成 XCTest 性能测试代码：
1. 测试 layoutSubviews 的平均耗时
2. 测试滚动 100 个 Cell 的总耗时
3. 设置基准线（baseline）：layoutSubviews < 10ms per call
```

## 相关资源
- [工作流：Instruments 性能诊断](../../workflows/performance-profiling.md)
- [Prompts：循环引用审计](./retain-cycle-audit.md)
- [Apple: Time Profiler 官方文档](https://help.apple.com/instruments/mac/current/#/dev44b2b437)

---

**作者**：Loong (SSLoong)  
**更新日期**：2026-11-02  
**适用模型**：Claude 3.5 Sonnet, GPT-4, Cursor AI
