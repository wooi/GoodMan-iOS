# Goodman 工程架构文档

## 1. 项目定位

iOS 多币种汇率换算工具。主 App 提供以 USD / CNY 为基准的多币种实时换算，桌面 Widget 单独显示 USD→CNY 汇率。

## 2. 技术栈

| 层 | 选型 |
|---|---|
| UI | SwiftUI（iOS 17+：onChange 双参形式、`@FocusState`、`.focused` 等） |
| 状态 | `ObservableObject` + `@Published` |
| 并发 | Swift Concurrency（`async/await` + `Task`） |
| 网络 | Alamofire |
| HTML 解析 | SwiftSoup |
| 持久化 | `UserDefaults`（JSON 编码 `[ExchangeRateData]`） |
| Widget | WidgetKit + AppIntents |
| 构建 | Xcode（多 target：App / GMCommon / Widget） |

## 3. 目录结构

```
Goodman/
├── Goodman.xcodeproj
│
├── Goodman/                          # 主 App target
│   ├── GoodmanApp.swift              # @main 入口，挂 AppDelegate
│   ├── AppDelegate.swift             # 持有 CoreData 容器（当前未使用，待清理）
│   ├── ContentView.swift             # 主页面：顶部基准输入 + 列表
│   ├── ViewModel.swift               # 业务状态与汇率计算
│   ├── KeyboardResponder.swift       # 监听键盘高度，避让输入框
│   ├── Assets.xcassets               # App 图标等
│   └── Preview Content/
│
├── GMCommon/                         # 共享框架（App + Widget 共用）
│   ├── ApiRepository.swift           # 网络层：欧央行 HTML 抓取 + 备用 USD/CNY API
│   ├── ExchangeRateData.swift        # 单币种汇率 Model（class，便于 List 内联编辑）
│   ├── ExchangeRateDataList.swift    # 汇率列表容器
│   ├── ExchangeRateApiData.swift     # exchangerate-api.com 的 JSON Decodable
│   ├── Constant.swift                # API Key / CurrencyCode 枚举
│   ├── CountryConstant.swift         # 货币码 ↔ 国家三字码映射
│   ├── Ext.swift                     # 通用扩展（String / Double / Color / UIApplication）
│   └── Media.xcassets                # 国旗资源（Circle_Flag_*）
│
└── ExchangeWidget/                   # Widget target
    ├── ExchangeWidgetBundle.swift
    ├── ExchangeWidget.swift          # 桌面小组件
    ├── ExchangeWidgetLiveActivity.swift  # 灵动岛（模板代码，未接业务）
    └── AppIntent.swift               # Widget 配置意图
```

## 4. 模块划分

### 4.1 GMCommon（共享层）
- 不依赖 SwiftUI/UIKit 业务代码，仅 Model + 网络 + 工具。
- 同时被主 App 与 Widget 引用，避免重复实现。
- `Ext.swift` 当前混有 SwiftUI/UIKit 扩展，理论上应进一步拆分（按需）。

### 4.2 主 App
单视图结构，无路由。MVVM：
- View：`ContentView` + 派生子视图（`ExchangeItemView`、`CurrencyView`、`BaseCurrencyButton`）。
- ViewModel：`ViewModel`（单例式 `@ObservedObject`，承接业务状态与汇率运算）。
- Model：复用 `GMCommon` 的 `ExchangeRateData` / `ExchangeRateDataList`。

### 4.3 Widget
独立时间线 Provider，直接调 `ApiRepository.fetchData()`（基于 `exchangerate-api.com` 的 USD→CNY），不与主 App 共享运行时状态。Live Activity 目前是 Xcode 模板默认实现，未启用业务。

## 5. 数据流

### 5.1 启动 / 刷新
```
ContentView.onAppear ─▶ ViewModel.fetchData()
                          │
                          ├─▶ loadSaveData()         # UserDefaults 缓存兜底
                          │     └─▶ updateTime ← items[0].date
                          │
                          └─▶ Task {
                                ApiRepository.fetchEurBankHtml()
                                  └─▶ SwiftSoup parse <tbody><tr>
                                        过滤 numberSet 内的 10 种币
                                  └─▶ ExchangeRateDataList
                                ↓
                                MainActor:
                                  rateData = ...
                                  recalcItems()      # 按 baseCountryCode 全表换算
                                  updateTime = ...
                                  saveData()         # 写回 UserDefaults
                              }
```

### 5.2 用户输入（统一通过自定义 Binding）

不使用 `onChange` + `@FocusState`，改为在 `Binding(get:set:)` 的 `set` 中调用 `changeEdit`。这样**只有用户敲键**会进入 `set`，程序赋值（来自 `changeEdit` 内部对 `items[].price` / `basePrice` 的写入）不会回流，从源头消除反馈环。

```
[顶部 TextField  Binding.set]      ─▶ changeEdit(newPrice, baseCountryCode)
[列表行 TextField Binding.set]      ─▶ changeEdit(newPrice, items[i].countryCode)
                                            │
                                            ▼
                                    if countryCode == baseCountryCode:
                                        basePrice = newPrice
                                    for item in list:
                                        if 编辑行: item.price = newPrice
                                        else:    item.price = recalc(rate)
                                                 if item == base: basePrice = item.price
                                    self.items = list   # 触发 @Published
```

### 5.3 切换基准币
```
BaseCurrencyButton.tap ─▶ ViewModel.switchBase(countryCode)
                            │
                            ├─ baseCountryCode = countryCode
                            └─ recalcItems()
                                 # basePrice 不变（100 USD 切到 CNY = 100 CNY）
                                 # items 全表按新基准重算，包括基准币那一行 price = basePrice
```

## 6. 状态约定

| 状态 | 类型 | 含义 |
|---|---|---|
| `items: [ExchangeRateData]` | `@Published` | 列表数据，每行带最新换算价 |
| `basePrice: String` | `@Published` | 顶部输入框值 = 当前基准币种的金额 |
| `baseCountryCode: String` | `@Published` | `"USA"` 或 `"CHN"` |
| `updateTime: String` | `@Published` | 显示用日期（来自 ECB H3） |
| `rateData: ExchangeRateDataList?` | private | 原始抓取结果，含汇率与日期 |

派生属性：`baseCurrencyName`（"美元"/"人民币"）、`baseCurrencyCode`（"USD"/"CNY"）。

## 7. 关键设计决策

1. **`ExchangeRateData` 用 `class`**：列表内联编辑场景下用引用语义更顺，否则修改 `items[i].price` 要走值拷贝。代价是 `Equatable` 由 `Identifiable` 默认实现承担，且需要小心 `JSONEncoder` 序列化语义。
2. **不依赖 `onChange` 区分输入来源**：`onChange` 同时触发于用户输入和程序赋值，靠 `@FocusState` 守卫存在时序窗口（焦点切换瞬间）。改用自定义 Binding 是更可靠的来源切分。
3. **基准币切换不重置输入金额**：100 USD 切到 CNY 显示为 100 CNY，沿用同一数字、改变语义。`switchBase` 因此**不**走 `changeEdit`，而是走 `recalcItems()`，避免 `changeEdit` 中"跳过被编辑币种"的语义不匹配。
4. **网络源**：主 App 用 ECB HTML（无 key、稳定），Widget 用 exchangerate-api.com（带 key，但只取一对汇率，不用解析 HTML）。两个数据源解耦。

## 8. 持久化

- Key：`ExchangeRateDataKey`
- 内容：`JSONEncoder().encode(items)`（即 `[ExchangeRateData]`）
- 时机：`fetchData()` 成功后写入；启动时 `loadSaveData()` 读取作冷启动兜底。
- 注意：未持久化 `rateData`（`ExchangeRateDataList`），因此冷启动后到首次抓取完成前，`switchBase` 不会重算（已 `guard rateData != nil`）。

## 9. 已知问题 / TODO

| 优先级 | 问题 | 位置 |
|---|---|---|
| 高 | API Key 硬编码进仓 | `Constant.swift` |
| 高 | `Task` 内 `DispatchQueue.main.sync` 易死锁 | `ViewModel.fetchData` |
| 中 | `CurrencyView` 货币符号写死 `$`，多币种应按 `currencyCode` 区分 | `ContentView.CurrencyView` |
| 中 | 网络 / 解析失败无 UI 反馈，仅 `print` | `ApiRepository` |
| 中 | `+` / `gear` / `sheet` 是占位，无实际逻辑 | `ContentView` |
| 中 | `Live Activity` 仍是 Xcode 模板代码 | `ExchangeWidgetLiveActivity` |
| 低 | `AppDelegate` 里的 CoreData 容器未使用 | `AppDelegate` |
| 低 | `stripTrailingZeros` 会把 "1." 这类输入中间态格式化掉，影响小数输入手感 | `Ext.swift` |
| 低 | `rateData` 未持久化，冷启动期间切换基准不重算 | `ViewModel` |

## 10. 拓展指引

- **加新币种**：扩展 `ApiRepository.parseHTML` 的 `numberSet` 与 `CountryConstant.currencyToAlpha3Mapping`，并在 `Media.xcassets` 加 `Circle_Flag_<code>` 资源。
- **多基准币**：把 `baseCountryCode` 候选从 `{USA, CHN}` 扩展，并改 `BaseCurrencyButton` 列为可滚动；`baseCurrencyName/Code` 改成查表。
- **替换数据源**：实现新的 `fetch*` 返回 `ExchangeRateDataList?` 即可，`ViewModel` 只关心 `rateData?.exchangeDataList` 和 `rateData?.date`。
- **共享数据给 Widget**：当前 Widget 独立取数，如果要共享主 App 的 `items`，需启用 App Group + `UserDefaults(suiteName:)`，并把 `dataKey` 移到 GMCommon。
