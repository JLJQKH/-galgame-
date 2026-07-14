# galgame 游玩记录 — 产品与技术文档

> 本文档是项目的"产品需求 + 技术章程"，会随开发推进持续更新。

---

## 第 0 章 · 项目协作原则（必读）

> ⚠️ **核心原则：所有技术决策，由 AI 提供方案，由用户拍板。**

本项目由一名**编程小白**主导，AI（Claude）协助开发。为保持用户对项目方向的知情权与决策权，约定如下：

1. **遇到任何技术相关的决策时**——包括但不限于：技术栈选择、第三方库的选择、架构方案、UI 框架、数据库设计、打包工具、目录结构等——AI 必须先**列出 2 个或以上候选方案**，并用表格或列表说明每个方案的**优势 / 劣势**，再由**用户最终选择**。
2. **AI 不能自行拍板技术决策。** AI 可以给出推荐和理由，但最终采用哪个方案必须等用户明确表态。如果某个决策用户一时看不懂，AI 有义务先用通俗语言解释清楚，再让用户选。
3. **交互格式约定**：每次涉及技术决策，AI 应这样呈现：
   - 列出候选方案
   - 给出对比表（维度：难度、体积、生态、对小白友好度等）
   - 标注 AI 的推荐项及理由
   - 等待用户回复"选 X"后再执行
4. **非技术决策**（例如：界面长什么样、功能要不要做、文案怎么写）也尽量先征求意见，但这些用户可以直接拍板，AI 给建议即可。

> 📌 这条原则适用于本项目的**整个开发过程**，请 AI 在后续每次交互中严格遵守。

---

## 第 1 章 · 产品概述

### 1.1 项目简介
- **是什么**：一个运行在 Windows 上的本地桌面应用，用于记录和管理个人 galgame 游玩记录。
- **给谁用**：个人使用（开发者本人）。
- **核心价值**：替代 Excel / 记事本，提供更结构化、更美观、更易检索的 galgame 游玩记录管理体验。

### 1.2 设计目标
- 简单易用：手动添加即可，不需要联网或抓取数据。
- 界面美观：galgame 主题偏重视觉体验，UI 应赏心悦目。
- 完全本地：数据存在本机，不外传，无需任何外部 API 或联网。

### 1.3 典型使用流程
添加游戏 → 标注类型 → 游玩中更新状态 → 完成后打分 → 日后按类型/状态/评分搜索回顾

---

## 第 2 章 · 功能需求清单

### 2.1 核心功能（MVP，第一批必须实现）

| # | 功能 | 描述 | 优先级 |
|---|------|------|--------|
| 1 | 手动添加游戏 | 填写游戏名称、封面、类型、备注等信息 | 必须 |
| 2 | 游戏类型分类 | 支持校园 / 恋爱 / 穿越 / 悬疑 / 科幻等，**一个游戏可属多个类型** | 必须 |
| 3 | 评分 | 0–10 分，**精确到小数点后一位**（如 8.5、9.3） | 必须 |
| 4 | 游玩状态 | 待玩 / 进行中 / 已完成，三选一 | 必须 |
| 5 | 搜索 | 按游戏名称搜索（后续可扩展为按类型/状态/评分筛选） | 必须 |
| 6 | 列表展示 | 以列表形式展示所有游戏（名称+状态+类型），点击打开详情 | 必须 |
| 7 | 编辑 / 删除 | 在详情信息框中修改和删除已有记录（删除需二次确认） | 必须 |
| 8 | 游戏详情 | 点击游戏弹出可缩放信息框：封面+评分+时长+回忆模块（截图收藏） | 必须 |
| 9 | 回忆模块 | 每游戏独立截图收藏，统一根目录+相对路径存储，淡入淡出轮播展示 | 必须 |
| 10 | 游戏排序 | 按名称/添加日期/评分排序，排序栏在新增按钮上方 | 必须 |
| 11 | 游玩时长 | 选填，只记录小时 | 必须 |

### 2.2 数据字段定义（每条游戏记录）

| 字段 | 类型 | 是否必填 | 示例 |
|------|------|----------|------|
| 游戏名称 | 文本 | 必填 | 《CLANNAD》 |
| 封面图片 | 本地文件路径 | 选填 | D:/covers/clannad.jpg |
| 类型标签 | 多选文本 | 必填 | 校园、恋爱 |
| 评分 | 小数 0.0–10.0 | 选填 | 9.3 |
| 游玩状态 | 枚举（待玩/进行中/已完成） | 必填 | 已完成 |
| 游玩时长 | 整数（小时） | 选填 | 50 |
| 开始日期 | 日期 | 选填 | 2026-06-01 |
| 完成日期 | 日期 | 选填 | 2026-07-05 |
| 备注/感想 | 长文本 | 选填 | "非常治愈，结局很感动……" |

> 📌 字段后续可增减，增减需用户确认。

### 2.3 界面需求（初步）
- 主界面：顶部搜索栏 + 状态/类型筛选区 + 下方游戏卡片列表。
- 添加/编辑入口：一个"添加游戏"按钮打开表单。
- 整体风格：简洁、留白舒适、galgame 味（具体配色待 UI 阶段与用户讨论）。

### 2.4 非功能需求
- 平台：Windows 10 / 11。
- 数据规模：几十到几百条记录。
- 响应速度：本地操作应即时（毫秒级）。
- 数据安全：本地存储，支持手动备份/恢复。

---

## 第 3 章 · 技术方案对比与决策

### 3.1 候选方案总览

经筛选，给出 **3 个适合"小白 + AI 协助开发"的方案**（C# WPF、Flutter Desktop、Python PyQt 已排除，原因见 3.5）。

| 维度 | 方案 A：Electron + Vue 3 | 方案 B：Python + CustomTkinter | 方案 C：Tauri + Vue 3 |
|------|--------------------------|-------------------------------|------------------------|
| 技术栈 | Vue 3 + Electron + Vite | Python 3.11+ + CustomTkinter | Vue 3 + Tauri 2.0 + Rust |
| 推荐数据存储 | SQLite (better-sqlite3) | SQLite (Python 内置) | SQLite (tauri-plugin-sql) |
| AI 友好度 | ★★★★★ | ★★★★☆ | ★★★☆☆ |
| 学习曲线 | 低 | 最低 | 中高（因 Rust） |
| 产物体积 | 大 (60–120 MB) | 中 (30–60 MB) | 小 (5–15 MB) |
| UI 精美度上限 | 高 | 中 | 高 |
| 打包难度 | 中 | 中 | 中偏低 |
| AI 推荐排序 | **🥇 第 1（最推荐）** | 🥈 第 2 | 🥉 第 3 |

### 3.2 各方案详细说明

**方案 A：Electron + Vue 3（最推荐）**
- 优势：AI 对这套组合代码生成最熟练、出错率最低；用标准 HTML/CSS/JS，任何 UI 问题都好搜答案、好向 AI 描述；生态最成熟；UI 能做到非常精美（适合 galgame 视觉需求）。
- 劣势：安装包大（60–120 MB），内存占用偏高；需理解"主进程/渲染进程"概念；打包配置项较多。
- 适合：看重开发顺畅度 + UI 效果，不在意体积。

**方案 B：Python + CustomTkinter（最不易出错）**
- 优势：安装最简单（装 Python 即可，一条 pip 命令装 UI 库）；数据存储零依赖（Python 内置 sqlite3）；代码量少、结构简单，最易看懂。
- 劣势：UI 精美度上限低于 Web 方案；打包成 exe 偶有资源路径问题；未来想做复杂动画/瀑布流会受限。
- 适合：电脑性能一般、希望代码尽量简单。**如果你拿不准选哪个，选这个最稳。**

**方案 C：Tauri + Vue 3（最优雅但最难）**
- 优势：产物极小（5–15 MB），技术栈现代；前端 UI 表现力和方案 A 一样强。
- 劣势：后端必须用 **Rust**，AI 生成 Rust 的准确率低于 JS/Python，编译错误对小白不友好；需装 Rust + VS C++ Build Tools，Windows 配置较麻烦。
- 适合：对安装包体积有硬性要求、愿意承担更高开发难度。

**方案 D：Qt + C++（用户最终选定 ✅）**
- 技术栈：C++ + Qt 6（UI 方式 Qt Widgets / QML 待定，见 3.6）；数据存储用 Qt 自带的 QtSql 模块操作 SQLite。
- 优势：原生 C++ 性能极高、资源占用小；Qt 是业界成熟的 GUI 框架，控件丰富，能做出精美界面；自带数据库/图表等模块和 Qt Creator IDE；授权（LGPL）比 PyQt 灵活。
- 劣势：C++ 是最难学的语言之一，对小白门槛极高；AI 生成 C++ 的出错率高于 JS/Python，编译错误信息冗长难懂；环境配置最复杂（需装 Qt、编译器、配置 CMake）；每次改代码都要编译，反馈循环慢。
- 说明：AI 此前不建议小白首选此方案，但用户充分知情后坚持选择，已尊重用户决定。后续 AI 全程协助解决 C++ / Qt / 环境问题。

### 3.3 技术栈最终决策

> ✅ **已选定：方案 D — Qt + C++（2026-07-08）**
> 用户在听取 AI 对 Qt C++ 优劣分析（含"对小白难度最高"的建议）后，坚持选择此方案。AI 尊重用户决定，后续据此推进。

### 3.4 数据存储方案决策

| 方案 | 说明 | 优势 | 劣势 |
|------|------|------|------|
| SQLite | 轻量关系型数据库，单文件 | 查询/筛选/排序强，适合搜索功能；扩展性好 | 需写少量 SQL |
| JSON 文件 | 纯文本存所有数据 | 最简单，人眼可读可手改 | 数据多了搜索/筛选要自己写逻辑 |

> ✅ **已选定：SQLite（2026-07-08）** — 通过 Qt 自带的 QtSql 模块操作，契合搜索/筛选需求。

### 3.5 被排除的方案（供了解）
- **C# WPF**：XAML 学习曲线陡，AI 生成 WPF 代码准确率低于 Web 方案，样式系统对小白不友好。
- **Flutter Desktop**：Windows 桌面支持尚在成熟中，AI 对其 API 熟悉度不如 Web。
- **Python PyQt**：有商业授权问题（GPL，商用需付费），且工作流对小白偏重；CustomTkinter 能覆盖同样需求且更简单。

### 3.6 Qt UI 方式决策（选定 Qt 后的子决策）

> 选定 Qt + C++ 后，还需决定用哪种方式做界面。建议二选一（不建议小白混用）。

| 方式 | 说明 | 优势 | 劣势 |
|------|------|------|------|
| **Qt Widgets** | 传统桌面控件（按钮/表格/对话框），用 C++ 或可视化 .ui 设计器开发 | 概念传统、上手相对直接；最适合"表单+列表+搜索"这类桌面应用；可用 QSS（类 CSS）美化 | 视觉上限不及 QML，动画/特效较弱 |
| **QML / Qt Quick** | 声明式语言（JSON+JS 风格）描述 UI，C++ 写后端逻辑 | 能做出非常精美、带流畅动画的现代界面，契合 galgame 视觉需求 | 要额外学 QML 语言，且 QML 与 C++ 交互有学习成本 |

> ✅ **已选定：QML / Qt Quick（2026-07-08）** — 用户看重界面精美与现代感。
> 架构说明：C++ 写后端逻辑（含 SQLite 数据读写），QML 写前端界面，二者通过 Qt 的信号槽/对象注册机制交互。这条链路比纯 Widgets 复杂，AI 全程协助。

---

## 第 4 章 · 项目结构与技术约定

> 📝 本章在技术方案确定后，由 AI 提供建议、用户确认后填充。

- 4.1 项目目录结构（2026-07-09 定，src/+qml/ 分类）：
  - `APP1/`（项目根 / git 仓库根）下：
    - `.gitignore`、`galgame.md`（本文档）、`CMakeLists.txt`（CMake 构建配置）
    - `src/` — C++ 后端代码（入口 `main.cpp`；后续如 `databasemanager.h/.cpp`）
    - `qml/` — QML 界面代码（入口 `main.qml`；后续各界面文件）
    - `data/` — 运行时数据（`galgame.db`，程序运行后自动生成，见 4.4）
    - `build/` — 构建产物（Qt Creator 生成，已被 .gitignore 忽略）
- 4.2 代码风格 / 命名规范：`[待补充]`
- 4.3 开发环境搭建步骤（✅ 已于 2026-07-09 完成并验证）：
  - **安装 Qt 6.11.1 + Qt Creator**：含 MinGW 64-bit 编译器，安装目录 `D:\qt`
  - **安装 CMake**：通过 Qt 维护工具安装，版本 3.30.5，路径 `D:\qt\Tools\CMake_64\bin\cmake.exe`
  - **在 Qt Creator 中注册 CMake**：`选项` → 左侧 `构建和运行` → `CMake` → `添加` → `浏览` 选中上述 cmake.exe（因 Qt 装在 D 盘非默认位置，Qt Creator 未自动识别，需手动添加）
  - **Kit 配置**：Automatically Managed Kit（Desktop Qt 6.11.1 MinGW 64-bit）自动关联 CMake 3.30.5，状态绿勾 ✅
  - **验证**：新建 `Qt Quick Application - Empty`（CMake 构建）测试项目 test1，成功编译并运行出空白窗口 ✅
- 4.4 数据库设计（SQLite）（✅ 2026-07-09 设计定稿）：
  - **存储方案**：类型标签用 **JSON 数组列**（方案 C），如 `["校园","恋爱"]`。选定理由：比"逗号字符串"规范、比"多表关联"简单，且 SQLite 原生支持 JSON 查询。
  - **数据库文件**：`APP1/data/galgame.db`（程序首次运行时自动创建）。
  - **`games` 表结构**（11 列）：
    - `id` — INTEGER，自增主键，自动
    - `name` — TEXT，游戏名称，必填（如《CLANNAD》）
    - `cover_path` — TEXT，封面图片路径，选填
    - `types` — TEXT(JSON)，类型标签，必填（如 `["校园","恋爱"]`）
    - `rating` — REAL，评分 0.0–10.0，选填
    - `status` — TEXT，游玩状态，必填（待玩/进行中/已完成，存中文）
    - `play_time` — INTEGER，游玩时长（小时），选填，默认 0
    - `start_date` — TEXT，开始日期，选填（`YYYY-MM-DD`）
    - `finish_date` — TEXT，完成日期，选填（`YYYY-MM-DD`）
    - `notes` — TEXT，备注/感想，选填
    - `created_at` — TEXT，添加时间，自动
  - **`bg_images` 表结构**（5 列，2026-07-10 新增）：
    - `id` — INTEGER，自增主键，自动
    - `image_path` — TEXT，背景图片路径，必填
    - `opacity` — REAL，透明度 0.0–1.0，默认 0.35
    - `blur` — REAL，模糊度 0.0–1.0，默认 0.5
    - `created_at` — TEXT，添加时间，自动
  - **实现约定**：`status` 直接存中文；`created_at` 自动记录；日期统一 `YYYY-MM-DD`；评分 0.0–10.0 在应用层校验；`bg_images` 同路径不重复添加（已存在则更新 opacity/blur）。
  - **`screenshots` 表结构**（9 列，2026-07-10 新增，2026-07-12 增加 crop_mode 列，2026-07-13 增加 offset_x/offset_y 列，回忆模块方案A）：
    - `id` — INTEGER，自增主键，自动
    - `game_id` — INTEGER，关联 games.id，必填（删除游戏时同步删除该游戏所有回忆记录+文件+子文件夹+播放参数）
    - `image_path` — TEXT，相对路径（如 `5/screenshot_20260710143000123.jpg`），必填
    - `sort_order` — INTEGER，排序序号（上移/下移调整），默认 0
    - `scale` — REAL，图片缩放比例（0.1–10.0），默认 1.0
    - `crop_mode` — INTEGER，显示模式（0=适配空白填充 PreserveAspectFit / 1=填充裁剪 PreserveAspectCrop），默认 0（2026-07-12 新增，含 ALTER TABLE 迁移）
    - `offset_x` — REAL，图片横向位置偏移（-0.5~0.5，正值右移/负值左移，相对容器宽度的比例），默认 0.0（2026-07-13 新增，含 ALTER TABLE 迁移）
    - `offset_y` — REAL，图片纵向位置偏移（-0.5~0.5，正值下移/负值上移，相对容器高度的比例），默认 0.0（2026-07-13 新增，含 ALTER TABLE 迁移）
    - `created_at` — TEXT，添加时间，自动
  - **ID 重排引用同步**：resetIds() 重排 games 表 id 时，先建立 old_id→new_id 映射，重排后同步 UPDATE screenshots.game_id，避免回忆记录成为孤儿引用
  - **回忆播放参数**（存储在 app_settings 表）：`ss_interval_<gameId>`（播放间隔ms，默认3000）、`ss_fade_<gameId>`（淡入淡出ms，默认800）
  - **`app_settings` 表结构**（2 列，2026-07-10 新增）：
    - `key` — TEXT，主键（如 `memory_root`）
    - `value` — TEXT，设置值
  - **回忆模块方案A（统一根目录+相对路径）**：用户在设置中配置回忆根目录（如 `D:/galgame_memories/`），每个游戏自动创建子文件夹 `{根目录}/{game_id}/`，数据库存储相对路径 `{game_id}/filename`，运行时拼接完整路径。

---

## 第 5 章 · 开发计划

### 5.1 阶段划分（初步）
1. **Phase 1**：确定技术方案 → 搭建项目 → 设计数据库结构
2. **Phase 2**：实现"添加 / 编辑 / 删除游戏"
3. **Phase 3**：游戏列表展示 + 类型/状态筛选
4. **Phase 4**：搜索功能
5. **Phase 5**：UI 美化（galgame 风格）
6. **Phase 6**：打包成可分发的 .exe

### 5.2 当前进度
**✅ Phase 1~4 完成 + 多项增强（截至 2026-07-13）**
- 环境就绪（Qt 6.11.1 + MinGW + CMake 3.30.5，见 4.3）；数据库 `games` 表 + `bg_images` 表 + `screenshots` 表 + `app_settings` 表（见 4.4）
- 已实现功能：
  - 增删改查：**添加 / 编辑 / 删除**、**按名称搜索**、评价/备注、**封面图片**（复制到 `data/covers/`）
  - 列表 + 统计：游戏列表（点击打开详情）、**总游戏数**、状态分布（待玩/进行中/已完成）、**类型分布 QtCharts 饼图**
  - 列表简化：主界面列表只显示**游戏名称、状态、类型**，点击游戏弹出**详情信息框**（可缩放窗口）
  - 游戏详情信息框：左右布局，左侧封面（**自适应宽度**展示整个封面），右侧上方名称（**24px大字体**）+评分+游玩时长+状态，中间回忆模块（**GridView 全部展示**所有回忆缩略图+编辑按钮），**游戏评价显示在回忆模块下方**（2026-07-13 新增），右侧整体使用 Flickable 可滚动内容（底部按钮锚定不被边框遮挡），底部编辑/删除按钮
  - 回忆模块（方案A）：**统一根目录+相对路径**，用户在设置中配置回忆根目录，每游戏自动建子文件夹，截图复制到本地后存储相对路径；**回忆编辑对话框**支持添加/删除回忆（直接删除无需确认）、上移/下移排序、调整播放间隔与淡入淡出时间（统一配置）、**图片缩放编辑**（0.3–3.0等比缩放）、**显示模式切换**（适配=PreserveAspectFit空白填充 / 填充=PreserveAspectCrop部分裁剪）、**图片位置偏移拖拽**（offset_x/offset_y，2026-07-13 新增，预览区拖拽调整位置）、实时预览轮播效果；**删除游戏时级联清理**回忆文件+记录+子文件夹+播放参数
  - **回忆编辑对话框嵌套于详情窗**（2026-07-13 重构）：从主页面弹出改为 `parent: gameDetailDialog.contentItem` 嵌套，requestActivate() 返回父级；左面板（36%宽）缩略图 ListView + 上移/下移/删除/添加按钮，右面板预览区+缩放滑块+适配/填充切换+位置重置+轮播间隔/淡入淡出滑块
  - 游戏**排序**：主页面排序栏（名称/添加日期/评分），排序栏位于新增按钮上方
  - 增强：**深色模式**（主题切换）、**16:9 自适应布局**（顶部工具栏+总计栏+列表）、**导入/导出**（JSON/TXT/Excel-CSV）、**校验**（除评价外必填）、**ID 重排**（删除后连续）、**状态筛选**（点总计栏卡片）、**多语言**（简中/繁中/英/日，QML 翻译表）
  - UI 美化：**主题色**(天蓝/绿/黄/粉/黑/灰/白)、**背景图**+透明度/模糊度调节(MultiEffect)、**背景图历史**(bg_images 表，保存图片+透明度+模糊度)、**背景图裁剪**(选区拖拽+四角/四边缩放)、**背景图二次编辑**(实时效果预览+滑块调整+保存更新)
  - 对话框设计：**圆角半透明风格**、统一按钮组件(BtnOk/BtnCancel/BtnClose/BtnSave/BtnImport/BtnGhost)、对话框背景跟随主题(cBg)、DragHeader 可拖拽移动、打开自动居中
  - 评分系统：**半星评分**(5星10分制，点击左半星得奇数分，右半星得偶数分)
  - 设置模块：**设置对话框**(夜晚模式/语言切换/时钟开关/外观设置入口/回忆根目录配置)
  - 自定义主题：**自定义强调色+背景色+主文本色+次要文本色**(预设色块点击换色+十六进制输入+自定义颜色选择对话框，Settings 持久化)
  - 时间模块：**大字体时钟**(28px，HH:mm:ss)+日期+星期+农历，可显示/隐藏(🕐按钮)，Settings 持久化
  - 文件功能：**导入/导出整合**为统一"📁 文件"入口(JSON/TXT/CSV 导出 + JSON 导入)
  - 主页面区块设计：工具栏→时间区块→搜索+统计卡片→排序栏→添加按钮+饼图卡片→游戏列表
  - 主页面**自动隐藏滚动条**：鼠标靠近右侧24px区域时显示，移开后250ms淡出（2026-07-12 改为 Flickable 整页滚动：所有内容区块包裹在 Flickable+Column 中，ListView 设为非交互式 height:contentHeight，滚动条自动隐藏）
  - **封面裁剪编辑**：编辑对话框新增"编辑封面"按钮，复用 cropDialog(mode=cover)进行裁剪/替换；详情窗封面自适应宽度展示完整封面
  - **对话框返回上一界面**：编辑/裁剪/回忆编辑/删除确认等对话框完成后返回详情窗而非直接关闭
  - 代码简化：提取 10 个内联组件(DragHeader/DlgBg/StarDisplay/StarInput/BtnOk/BtnCancel/BtnClose/BtnSave/BtnImport/BtnGhost/InputBg/FooterRow)消除重复代码
  - **回忆轮播功能**（2026-07-13 新增）：详情窗全屏 carouselOverlay 覆盖层，双 Image 交叉淡入淡出（opacity Behavior 动画），Timer 切换；播放间隔/淡入淡出时间在回忆编辑对话框调整；Scale transform 用 id 引用属性修改（不能用 JS 重新赋值 transform）
  - **对话框缩放 ResizeHandles 组件**（2026-07-13 新增）：8 方向（四角+四边）缩放手柄，mapToGlobal 跟踪拖拽，z:1000 覆盖内容上层；应用到所有 14+ 个对话框（addDialog/editDialog/deleteDialog/fileDialog/appearanceDialog/memoriesEditDialog/settingsDialog/bgHistoryDialog/editBgDialog/cropDialog/customAccentDialog/customBgColorDialog/customTextColorDialog/customSubColorDialog/deleteBgDialog/exportFormatDialog/importTipDialog）
  - **对话框高度调整**（2026-07-13）：fileDialog 700→380（展示所有内容即可）、appearanceDialog 600→700
  - **回忆编辑删除功能重设计**（2026-07-13）：左面板缩略图 ListView 选中项后点删除按钮直接执行，播放顺序通过上移/下移按钮调整（完善：列表选中态高亮+按钮 disabled 边界处理）
  - **回忆编辑对话框第 4 轮重构**（2026-07-13）：①修复添加/删除按钮位置不对（添加按钮独立一行固定底部、删除按钮独立✕按钮）；②图片编辑器改进（缩放倍数 0.1–10.0 扩大、滚轮缩放、中心十字辅助线、底部实时显示缩放/位置数值、全部重置按钮）；③播放顺序改为鼠标拖拽（去▲/▼按钮、改用 MouseArea drag+DropArea+reorderScreenshot 事务排序）；④对话框高度调整（addDialog/editDialog 500→460、fileDialog 380→340、appearanceDialog 700→580、settingsDialog 320→360+Flickable、自定义颜色 420→360）；⑤settingsDialog 添加 Flickable 滚动条
  - **回忆展示模式切换**（2026-07-13，第 4 轮）：详情窗回忆区新增展示模式切换按钮（轮播/网格），默认轮播内嵌（双 Image 交叉淡入淡出+Timer），可切换为网格 GridView 全部展示
  - **第 4 轮 UI 优化**（2026-07-13）：①删除所有对话框 ResizeHandles 伸缩功能（仅保留 DragHeader 拖拽移动）；②修复回忆编辑删除键无法使用（拖拽 MouseArea 覆盖整个 delegate→改为仅拖拽手柄区域可拖拽）；③回忆编辑对话框居中+与外层边框至少 20px 间隔；④填充模式优化（Image anchors.fill+transform: Scale+Translate，与轮播展示行为一致）；⑤外观对话框高度 580→460；⑥文件对话框宽度 420→480；⑦所有对话框滚动条统一为主页面设计（MainSB 组件：width:10、radius:5、自动隐藏 800ms 淡出）；⑧所有 Column width 统一为 dialog.width - 48（24px 间隔*2）
  - **第 5 轮重构**（2026-07-13）：①删除独立全屏轮播功能（carouselOverlay/startCarousel/carouselFront 全部移除），保留回忆展示区内的内嵌轮播；②游戏详情页内联编辑（点击名称/评分/评价/封面即可修改，editingName/editingRating/editingNotes 状态切换 Text↔TextField/TextArea，封面点击打开 FileDialog→importCover→updateGame）；③回忆编辑对话框布局重排（添加回忆按钮移至顶部、删除按钮移至底部、中间为拖拽排序列表）；④回忆编辑按钮间隔修复（spacing 增大至 10、delegate 高度 70、按钮宽度充足避免重叠）；⑤回忆编辑文字重叠修复（信息列 3 行分开：名称/缩放/模式各一行，宽度 parent.width-20-56-8*2）；⑥回忆编辑对话框居中于游戏详情窗（onOpened 计算 Math.max(24, (parent.width-dialog.width)/2)）；⑦历史背景图片对话框高度减小（560→440，ListView 440→320）
  - **第 6 轮修复+优化**（2026-07-13）：①修复回忆编辑对话框无法居中（尺寸 880×660 太大超过父窗口 820×580→改为 720×540）；②修复拖拽排序无效（原 memDelegateBg.y/step 计算错误，改为 mapToItem(memList.contentItem,0,0) 映射到 ListView 坐标系；drag.minimumY/maximumY 改为相对于 delegate 位置 -index×step 到 (count-1-index)×step）；③修复文本重叠（信息列从 3 行精简为 2 行：名称+缩放/模式合并，缩略图 56→48、手柄 20→18、spacing 8→6）；④轮播删除图片后重置（refreshScreenshots 中检查 curIdx 越界则重置为 0+front=true）；⑤右侧图片编辑器 UI 优化（移除冗余"图片编辑"标题、按钮高度 28→26、spacing 10→8、淡入淡出显示统一为秒）；⑥清理未使用翻译键（imageEditor/milliseconds/zoomIn/zoomOut/startCarousel/stopCarousel，4 语言同步）
  - **第 7 轮重构**（2026-07-13）：①删除游戏详情页底部编辑按钮，只保留删除按钮；②评分改为直接点击星星修改（移除 editingRating/TextField，5 颗星可点击左半星/右半星分别得奇数/偶数分，点击即保存）；③游戏类型标签显示+独立对话框编辑（详情页显示圆角 Tag 标签，点击弹出 typeEditDialog 标签式编辑器：当前类型可✕删除+TextField添加新类型+保存/取消）；④单一编辑互斥机制（commitCurrentEdit 函数：开启名称/评价/类型/封面编辑前自动保存上一次编辑，editingName/editingNotes 互斥）；⑤回忆编辑对话框改为 Window（从 Dialog 改为 Window+transientParent+flags:Qt.Dialog，x/y 绑定 gameDetailDialog.x+偏移实现居中，startSystemMove 拖拽标题栏）；⑥删除图片填充功能（移除 cropMode 按钮和 curCropMode 属性，fillMode 固定 PreserveAspectFit）；重置缩放按钮移到缩放滑块行最右侧；⑦图片适配空白区域用主题色半透明填充（预览区背景从 #1a1a24 改为 Qt.rgba(cAccent,0.08)）；⑧回忆编辑信息列改为单行显示（"#序号 缩放x.x"，文件名用 ToolTip tooltip 显示，彻底避免多行文本重叠）
  - **第 8 轮优化**（2026-07-13）：①轮播展示样式与编辑预览一致（inlineImg1/inlineImg2 添加 Translate transform 应用 offset_x/offset_y，Timer 切换时同步更新 inlineTrans1/inlineTrans2）；②预览区状态文字移到预览区下方（不再叠在图片上挡图，预览区高度从 height-140 改为 height-170 容纳状态行）；③图片位置偏移改为无限制（移除 Math.max(-0.5,Math.min(0.5,...)) 限制，用户可自由拖拽图片到任意位置含负数）；④修复类型编辑点击无效（原 Row 中 MouseArea anchors.fill 不生效→改为 Item 包裹 Row+MouseArea）；⑤三个重置按钮同一行靠右（重置缩放|重置位置|全部重置，Item 占位填充左侧空间）；⑥封面改为复用 cropDialog 进行裁剪缩放（新增 coverDetail 模式，changeCover→coverPickerForDetail→cropDialog.openCoverForDetail→doCrop/replaceCover 保存，与背景图流程一致）
  - **第 9 轮重构**（2026-07-13）：①游戏类型详情页改为垂直 Column 一列显示（类型字符串超过10字符截断显示"…"，高度动态自适应 Math.max(26, typeTagCol.implicitHeight+8)）；②类型编辑对话框重新设计为列表式（每行：序号+类型名(双击编辑/✓确认)+✕删除，底部添加新类型输入框 maxLength:10+保存/取消，新增 editingTypeIdx 状态+add 翻译键4语言）；③封面裁剪对话框在 coverDetail 模式嵌套于 gameDetailDialog（parent: cropDialog.mode==="coverDetail" ? gameDetailDialog.contentItem : null，裁剪对话框出现在详情页面内而非主页面）；④回忆展示区改为 16:9 比例（height: Math.round(parent.width*9/16)）；⑤网格模式每格改为 16:9（cellWidth:160, cellHeight:90，fillMode 改为 PreserveAspectFit+Scale+Translate 与轮播一致）；⑥回忆编辑预览区改为 16:9 等比例真实展示（height: Math.round(parent.width*9/16)，Image PreserveAspectFit 保持图片真实比例）；⑦修复拖拽排序无效（原 mapToItem 在 Window 中坐标映射不正确→改为 index+Math.round(memDelegateBg.y/step) 直接用 delegate 内偏移计算目标索引）
  - **第 10 轮修复**（2026-07-13）：①修复 TextField 不存在 maxLength 属性错误（改为 onTextChanged: if(text.length>10) text=text.substring(0,10) 手动截断）；②typeEditDialog 从 Dialog 改为 Window（修复点击添加类型按钮会跳出对话框的问题，Dialog 作为 popup 嵌套在 Window 中有 CloseOnPressOutside 误判）；③修复回忆编辑后轮播不更新（refreshScreenshots 只更新数组，Image 绑定基于 curIdx 不重算→强制刷新 inlineImg1/inlineImg2 的 source/scale/translate）；④修复游戏状态无法改变（状态 Text 无点击事件→添加 cycleStatus() 函数点击状态循环切换待玩/进行中/已完成）；⑤类型编辑后内容合并问题初步修复（Column 加 width:parent.width，childrenRect.height 替代 implicitHeight）
  - **第 11 轮重构**（2026-07-13）：①游戏类型显示改为横向 GridView 5 列自动换行（cellWidth: Math.max(60, width/5)，超出5个自动移到下一行）；②**彻底修复类型编辑后内容整合成一条**（根因：C++ updateGame 第3参数是 QStringList，原 property string detailGameTypes 存的是逗号字符串→传给 QStringList 变成单元素→C++ 再 JSON 包装成 `[["校园,恋爱"]]`；修复：property var detailGameTypes: [] 改为数组类型，openWith 中 JSON.parse(types) 解析为数组，所有 updateGame 调用直接传数组，QML 自动转换为 QStringList，typeEditDialog.openWith 接受数组，GridView model 直接绑定数组）；③删除游戏对话框从根级 Dialog 改为 Window+transientParent:gameDetailDialog（与 typeEditDialog/memoriesEditDialog 嵌套模式一致，openWith(gid,gname) 函数初始化，onVisibleChanged 返回详情窗）
  - **第 12 轮修复**（2026-07-13）：①修复拖拽排序无效（根因：memDragHandle MouseArea 在 ListView(Flickable) 内，默认 preventStealing:false 导致 ListView 偷走拖拽事件→添加 preventStealing:true 让 MouseArea 保留拖拽控制权）；②修复回忆编辑后图片修改不立刻反映到回忆展示（根因：memoriesEditDialog 的 onVisibleChanged 只调用 saveSettings()+requestActivate()，没有调用 refreshScreenshots()→添加 gameDetailDialog.refreshScreenshots() 调用；同时改进 refreshScreenshots() 同时刷新两帧 inlineImg1/inlineImg2，避免 Timer 切换时显示旧数据）
  - **第 13 轮修复+优化**（2026-07-13）：①彻底修复拖拽排序（第 12 轮 preventStealing 仍不够→拖拽时 memList.interactive=false 禁用 ListView 滚动，释放时恢复 interactive=true，并在 onReleased 中先内存重排数组再持久化到数据库，立即反映视觉变化）；②默认主题色确认天蓝（currentTheme:"blue"，cAccent #3a9fff），customBgColor 从浅灰 #f5f5f8 改为淡蓝 #e8f0fe 与 blue 主题背景一致；③回忆列表 delegate 信息文本删除"#编号 缩放x.x"，改为只显示文件名（modelData.path.split("/").pop()）；④类型编辑对话框 typeAddField placeholderText 从 tt("type") 改为 tt("typeOneHint")"输入一个类型即可"（新增 4 语言翻译键 typeOneHint）；⑤类型分隔符从逗号改为空格（addDialog/editDialog 的 split(",") 改为 split(/\s+/)，jsonToText 的 join(",") 改为 join(" ")，4 语言 placeholderText 提示文案同步更新"逗号分隔"→"空格分隔"）；⑥导入导出无需调整（数据库 types 始终是 JSON 数组字符串格式，与 QML 端输入分隔符无关；Txt 用"、"、Csv 用"/"显示为导出展示格式）
  - **第 14 轮重构**（2026-07-13）：①**拖拽排序改为 DropArea+DragHandler 方案**（第 12-13 轮 MouseArea drag 在 ListView 中始终失效，根因：delegate Item 由 ListView 定位不能手动改 y，drag.target:memDelegateBg 是 delegate 子 Rectangle 改 y 后视觉被 delegate 高度裁切；方案 B：delegate 根 Item 加 DragHandler 拖拽整个 delegate，DropArea 接收其他 delegate 拖入，onEntered 中 slice+splice 内存重排立即反映+dbManager.reorderScreenshot 持久化+refresh 刷新，Drag.active/dragType:Automatic/keys:["memItem"]，property int memIndex:index 传递源索引）；②游戏状态改变后重新统计（cycleStatus 中加 root.refreshStats() 刷新待玩/进行中/已完成数量）；③回忆列表隐藏图片文件名，序号移到最后（删除 modelData.path.split("/").pop()，改为显示 "#"+(index+1)，因 model 是 screenshots 数组，删除/排序改动后 delegate 自动重排序号刷新）；④详情页添加游玩时长显示+内联编辑（位置在状态后方，editingPlayTime 状态切换 Text↔TextField，startEditPlayTime/saveInlinePlayTime 函数，commitCurrentEdit 互斥，onTextChanged 只允许数字+最多5位，onAccepted/onActiveFocusChanged 自动保存）
  - **第 15 轮拖拽优化**（2026-07-13）：①**拖拽排序回退为 MouseArea drag 方案**（DragHandler 在 ListView 中与 Flickable 手势冲突不彻底；改回 MouseArea drag.target:memDelegate（delegate 根 Item），preventStealing:true + onPressed 时 memList.interactive=false 禁用 ListView 滚动 + onReleased 时恢复，mapToItem(memList.contentItem,0,height/2) 计算释放时 delegate 中心在 contentItem 中的 y 位置，Math.round(absY/step) 计算目标索引，恢复 memDelegate.y=0 让 ListView 重新定位）；②**排序完成后更新播放顺序**（refresh() 中重置 inlineCarousel.curIdx=0+front=true，确保轮播从新顺序的第 0 张开始播放）；③**网格展示同步更新**（ssGrid.model 绑定 gameDetailDialog.screenshots 属性，refreshScreenshots() 中 screenshots=dbManager.getScreenshots() 重新赋值整个数组，QML 自动触发 GridView 重新渲染，网格顺序与轮播顺序同步）
  - **第 16 轮内联编辑+拖拽修复**（2026-07-13）：①**内联编辑去掉保存/取消按钮，点击空白处确定**（名称/评价/游玩时长 TextField/TextArea 用 onActiveFocusChanged 失焦自动保存，Esc 取消，名称高度自适应、评价 TextArea implicitHeight 自适应）；②**彻底修复拖拽排序（浮动克隆方案）**（根因1：memDelMouse 在 Row 之后声明导致 z 层在上覆盖拖拽手柄→移到 Row 之前；根因2：dragCloneItem 在 ListView 内被 clip 裁切+坐标映射不匹配→移出 ListView 作为 Window 直接子元素 z:1000）
  - **第 17 轮修复点击空白处+名称自适应+回退评价**（2026-07-13）：①**修复点击空白处确定**（根因：onActiveFocusChanged 在点击 MouseArea 时不触发→Flickable 内添加底层 MouseArea+propagateComposedEvents 事件穿透，编辑态启用 onPressed 调 commitCurrentEdit；saveInlineRating/saveInlineTypes/cycleStatus 首行加 commitCurrentEdit）；②**游戏名称宽度自适应**（Item width 从 parent.width 改为跟随 nameDisplayText.implicitWidth，去掉 elide）；③**回退游戏评价修改**（恢复保存/取消按钮，去掉 onActiveFocusChanged 失焦保存）
  - **第 26 轮夜晚模式自定义+导出后缀+GIF背景+取色器**（2026-07-13）：①**effDark 亮度判断模式**（custom 模式下不再用全局 isDark 决定派生色，改为计算 customBgColor 的相对亮度 customBgLuminance=0.299×r+0.587×g+0.114×b，customIsDarkBg=luminance<0.5，effDark=currentTheme==="custom"?customIsDarkBg:isDark，cCard/cInput/cBorder/cText/cSub 全部改用 effDark，使暗色模式+自定义浅色背景或亮色模式+自定义深色背景时卡片/文字色自动协调）；②**GIF 双组件方案**（QML Image 不支持 GIF 动画，AnimatedImage 支持；主背景和 editBgDialog 预览均拆分为 Image(静态)+AnimatedImage(GIF)双组件，按 bgImagePath.toLowerCase().endsWith(".gif") 切换 visible 和 source；GIF 跳过裁剪对话框因裁剪会丢失动画帧）；③**共享 ColorDialog 取色器**（单个 colorPickerDialog 实例+property var targetDialog 记录目标对话框，4 个颜色选择 Window 各有一个"取色器"按钮设置 targetDialog 后 open()，onAccepted 回写 selectedColor）
- C++/QML：QML_ELEMENT 正规注册；列表用 QAbstractListModel；多语言用 QML 翻译表（非 Qt 官方 .ts/.qm，因后者对 QML 运行时切换复杂）
- 移除：总计栏"平均分"卡片、统计面板"平均评分"行（按用户要求）

**下一步候选**（第 6 章 Backlog）：游戏排序、打包 .exe、UI 美化等。

> ⚠️ **关键踩坑（务必记住）**：QtCharts 的 QML `ChartView` 内部依赖 QGraphicsView/QtWidgets，**必须用 `QApplication`（而非 `QGuiApplication`）+ 在 CMakeLists 链接 `Qt6::Widgets`**，否则创建 ChartTitle 时崩在 `QWidgetTextControl`。当时用 `QSG_RHI_BACKEND` 等图形后端参数都无效，是因为根因不在 GPU 渲染层而在 Widgets 文本——靠调试器堆栈才定位。详见 [main.cpp](src/main.cpp) 与 [CMakeLists.txt](CMakeLists.txt)。

---

## 第 6 章 · 待定功能（Backlog）

> 以下功能尚未纳入正式需求，等想到更多或讨论后再决定是否实现及优先级。用户可随时往这里加一行。

- [x] 游戏封面图片上传与显示 ✅（2026-07-09）
- [x] 数据导入 / 导出（JSON / TXT / Excel-CSV）✅（2026-07-09）
- [x] 数据统计面板（状态分布、类型分布饼图）✅（2026-07-09；平均分按用户要求移除）
- [x] 游戏排序（按评分 / 添加日期 / 名称）✅（2026-07-10）
- [x] 深色模式 / 主题切换 ✅（2026-07-09）
- [x] 多语言支持 ✅（2026-07-09，简中/繁中/英/日）
- [x] 背景图片历史记录 ✅（2026-07-10，bg_images 表保存图片+透明度+模糊度）
- [x] 背景图片裁剪 ✅（2026-07-10，选区拖拽+四角/四边缩放）
- [x] 背景图片二次编辑 ✅（2026-07-10，实时效果预览+滑块调整+保存更新）
- [x] 设置模块整合 ✅（2026-07-10，夜晚模式/语言/外观设置统一入口）
- [x] 半星评分系统 ✅（2026-07-10，5星10分制，半星点击）
- [x] 对话框圆角半透明美化 ✅（2026-07-10，统一按钮组件+InputBg/BtnGhost）
- [x] 自定义主题色（强调色+背景色）✅（2026-07-10，预设色块+十六进制输入+颜色选择对话框，Settings 持久化）
- [x] 时间模块（时钟+日期+农历+星期）✅（2026-07-10，可显示/隐藏，Settings 持久化）
- [x] 导入导出整合为文件功能 ✅（2026-07-10，统一"📁 文件"入口）
- [x] 主页面区块设计 ✅（2026-07-10，工具栏/时间/搜索统计/添加饼图/列表分区）
- [x] 图片背景时对话框跟随主题色 ✅（2026-07-10，cBg 不再因背景图回退到固定色）
- [x] 游玩时长记录 ✅（2026-07-10，选填，只记录小时）
- [x] 截图 / 名场面收藏 ✅（2026-07-10，回忆模块方案A：统一根目录+相对路径，screenshots 表，淡入淡出轮播）
- [x] 自定义文本颜色 ✅（2026-07-10，主文本色+次要文本色，预设色块+十六进制输入+颜色选择对话框，Settings 持久化）
- [x] 主页面自动隐藏滚动条 ✅（2026-07-10，鼠标靠近右侧24px区域显示，移开250ms淡出）
- [x] 封面裁剪编辑 ✅（2026-07-10，复用 cropDialog mode=cover，编辑对话框新增编辑封面/替换封面入口）
- [x] 详情窗封面自适应 ✅（2026-07-10，按图片宽高比自适应宽度展示完整封面）
- [x] 对话框返回上一界面 ✅（2026-07-10，编辑/裁剪/回忆编辑/删除确认完成后返回详情窗）
- [x] 回忆编辑对话框 ✅（2026-07-10，添加/删除回忆+上移下移排序+播放间隔/淡入淡出统一配置+图片缩放编辑+实时预览轮播）
- [x] 回忆展示优化 ✅（2026-07-10，移除位置/数量指示，PreserveAspectFit+缩放空白填充，删除移至回忆编辑内直接执行）
- [x] 对话框逐级返回 ✅（2026-07-10，裁剪/编辑/删除确认完成后返回上一级对话框直至主界面）
- [x] 背景历史对话框UI统一 ✅（2026-07-10，BtnGhost按钮+半透明卡片+圆角缩略图+主题色滚动条）
- [x] 详情窗回忆全部展示 ✅（2026-07-12，GridView 网格同时展示所有回忆缩略图+编辑按钮入口，替代双图轮播）
- [x] 主页面整页滚动 ✅（2026-07-12，Flickable 包裹所有内容区块于同一 Column，ListView 非交互式，滚动条自动隐藏）
- [x] 回忆图片部分显示 ✅（2026-07-12，crop_mode 显示模式切换：适配=PreserveAspectFit 空白填充 / 填充=PreserveAspectCrop 裁剪部分显示）
- [x] 游戏删除同步清理回忆 ✅（2026-07-12，deleteGame 级联删除回忆文件+记录+子文件夹+播放参数；resetIds 重排时同步 screenshots.game_id 引用）
- [x] 回忆编辑对话框嵌套于详情窗 ✅（2026-07-13，从主页面弹出改为 parent: gameDetailDialog.contentItem 嵌套，requestActivate() 返回父级）
- [x] 回忆图片位置偏移拖拽 ✅（2026-07-13，screenshots 表新增 offset_x/offset_y 列，预览区拖拽调整位置，setScreenshotOffset 接口）
- [x] 游戏详情窗游戏评价显示 ✅（2026-07-13，游戏评价显示在回忆模块下方，Flickable 可滚动内容）
- [x] 回忆轮番出现功能 ✅（2026-07-13，详情窗全屏 carouselOverlay 双 Image 交叉淡入淡出，Timer 切换，间隔/淡入淡出在回忆编辑调整）
- [x] 对话框四角/四边缩放 ✅（2026-07-13，ResizeHandles 组件 8 方向缩放手柄，应用到所有 14+ 个对话框）
- [x] 回忆编辑删除功能重设计 ✅（2026-07-13，左面板缩略图选中后删除按钮直接执行，播放顺序上移/下移完善）
- [x] 详情窗按钮显示完整修复 ✅（2026-07-13，右侧 Flickable 可滚动内容+底部按钮锚定，不被边框遮挡）
- [x] 对话框高度调整 ✅（2026-07-13，fileDialog 700→380、appearanceDialog 600→700）
- [x] 回忆编辑 UI 修复+图片编辑器改进 ✅（2026-07-13，添加/删除按钮位置修复、缩放倍数 0.1–10.0、滚轮缩放、中心十字辅助线、全部重置按钮）
- [x] 拖拽排序 ✅（2026-07-13，播放顺序改为鼠标拖拽，reorderScreenshot 事务排序，移除▲/▼按钮）
- [x] 对话框滚动条 ✅（2026-07-13，settingsDialog 添加 Flickable+ScrollBar，所有对话框根据内容自适应高度）
- [x] 回忆展示模式切换 ✅（2026-07-13，默认轮播内嵌双 Image 交叉淡入淡出，可切换网格 GridView 展示）
- [x] 删除对话框伸缩功能 ✅（2026-07-13，移除 ResizeHandles 组件及所有调用，仅保留 DragHeader 拖拽移动）
- [x] 回忆编辑删除键修复 ✅（2026-07-13，拖拽 MouseArea 从覆盖整个 delegate 改为仅拖拽手柄区域，删除按钮可正常点击）
- [x] 回忆编辑填充模式优化 ✅（2026-07-13，Image anchors.fill+transform: Scale+Translate，与轮播展示行为一致）
- [x] 对话框滚动条统一设计 ✅（2026-07-13，MainSB 组件：width:10、radius:5、自动隐藏 800ms 淡出，与主页面一致）
- [x] 对话框 UI 边缘间隔 ✅（2026-07-13，所有 Column width 统一为 dialog.width - 48，24px 间隔*2）
- [ ] （用户补充……）

---

## 第 7 章 · 变更记录

| 日期 | 变更内容 | 决策者 |
|------|----------|--------|
| 2026-07-08 | 文档创建 | 用户 |
| 2026-07-08 | 技术栈决策：选定 Qt + C++（方案 D）；AI 曾建议另选，用户充分知情后坚持 | 用户 |
| 2026-07-08 | 子决策：UI 选 QML / Qt Quick（AI 曾推荐 Widgets）；存储选 SQLite | 用户 |
| 2026-07-09 | 开发环境搭建完成并验证：Qt 6.11.1 + MinGW + CMake 3.30.5，test1 运行通过 | 用户 + AI |
| 2026-07-09 | 数据库设计定稿（games 表，方案 C JSON 类型）；清理 test1 遗留，galgame 骨架就绪（src/+qml/） | 用户 + AI |
| 2026-07-09 | Phase 2 主体完成：增删改查 / 搜索 / 评价 / 封面 / 总数 / 统计面板（QtCharts 饼图）。踩坑修复：QtCharts 需 QApplication + 链接 Qt6::Widgets（调试器堆栈定位） | 用户 + AI |
| 2026-07-09 | 增强：深色模式、16:9 自适应布局、导入导出(JSON/TXT/CSV)、校验必填、ID 重排、状态筛选、多语言(简中/繁中/英/日)；移除平均分（用户要求） | 用户 + AI |
| 2026-07-09 | UI 美化：主题色(天蓝/绿/黄/粉/黑/灰/白) + 背景图 + 透明度/模糊度调节(MultiEffect)；修复主题色不生效（标题/工具栏底线/卡片色条改用 cAccent） | 用户 + AI |
| 2026-07-10 | 设置模块：将夜晚模式/外观设置/语言切换从工具栏移至独立设置对话框(⚙️按钮)；添加按钮移至游戏列表上方独立横条 | 用户 + AI |
| 2026-07-10 | 半星评分系统：5星10分制(整星=2分,半星=1分)，添加/编辑对话框中点击左半星得奇数分、右半星得偶数分 | 用户 + AI |
| 2026-07-10 | 背景图历史增强：bg_images 表新增 opacity/blur 列(含 ALTER TABLE 迁移)；历史记录保存图片+透明度+模糊度，点击"使用"恢复全部参数 | 用户 + AI |
| 2026-07-10 | 对话框统一美化：背景跟随主题(cBg)、圆角按钮(BtnOk/BtnCancel/BtnClose/BtnSave/BtnImport)、Cancel半透明红色、DragHeader可拖拽+自动居中 | 用户 + AI |
| 2026-07-10 | 代码简化：提取10个内联组件(DragHeader/DlgBg/StarDisplay/StarInput/Btn*/InputBg/FooterRow)消除重复代码 | 用户 + AI |
| 2026-07-10 | 背景图历史优化：重新设计列表布局(更大缩略图+修改按钮)；新增背景图编辑对话框(实时效果预览+透明度/模糊度滑块+保存更新)；C++新增 updateBgImage 方法 | 用户 + AI |
| 2026-07-10 | 添加游戏对话框美化：圆角半透明输入框(InputBg)+圆角半透明按钮(BtnGhost)+半透明保存按钮 | 用户 + AI |
| 2026-07-10 | 自定义主题色：自定义模式下预设色块点击换色(强调色+背景色各10色)+十六进制输入+自定义颜色选择对话框(预设色块+预览+OK/Cancel)；Settings 持久化保证重启不丢失 | 用户 + AI |
| 2026-07-10 | 评分输入框+编辑对话框+设置对话框 UI 统一：TextField/TextArea/ComboBox 全部使用 InputBg 圆角半透明背景；外观设置按钮改用 BtnGhost | 用户 + AI |
| 2026-07-10 | 时间模块增强：显示日期+星期+农历(内置农历转换算法 1900-2100)；时间区块高度 72px，时钟 28px + 日期 13px 双行 | 用户 + AI |
| 2026-07-10 | 导入导出整合为文件功能：工具栏"📁 文件"按钮统一入口，替代原分开的导出/导入按钮 | 用户 + AI |
| 2026-07-10 | 图片背景时对话框跟随主题色：cBg 不再因 bgImagePath 回退到固定色，始终使用当前主题色 | 用户 + AI |
| 2026-07-10 | 游戏排序功能：主页面添加排序栏，支持按名称/添加日期/评分排序；数据库添加 play_time 列支持游玩时长记录 | 用户 + AI |
| 2026-07-10 | 图标更新：外观设置→👕衣服，时间设置→🕐时钟，语言选择前→🌍地球 | 用户 + AI |
| 2026-07-10 | 多语言完善：排序/时长/导入说明等新增模块添加简中/繁中/英/日翻译 | 用户 + AI |
| 2026-07-10 | 导入说明示例完善：新增 play_time 字段和更多示例数据 | 用户 + AI |
| 2026-07-10 | 排序栏移至新增按钮上方；列表简化：只显示名称+状态+类型，点击游戏弹出详情信息框 | 用户 + AI |
| 2026-07-10 | 游戏详情信息框：可缩放Window，左右布局(封面等比例+右侧名称/评分/时长/回忆模块/编辑删除)，删除二次确认 | 用户 + AI |
| 2026-07-10 | 回忆模块(方案A)：screenshots表+app_settings表，统一根目录+相对路径，用户设置中配置根目录，每游戏自动建子文件夹 | 用户 + AI |
| 2026-07-10 | 回忆模块动态展示：截图淡入淡出轮播(双Image交叉透明度动画，3秒间隔)，添加/删除截图 | 用户 + AI |
| 2026-07-10 | 编辑/删除移入详情信息框；删除游戏同时删除截图文件和记录 | 用户 + AI |
| 2026-07-10 | 多语言更新：游戏详情/回忆/截图等新增模块简中/繁中/英/日翻译 | 用户 + AI |
| 2026-07-10 | Bug修复：①GameListModel::refresh() SQL拼接缺少空格导致"FROM gamesORDER BY"语法错误，prepare()失败后exec()报"参数数量不匹配"，游戏列表无法加载；②gameDetailDialog(Window)内部颜色/函数/属性引用缺少root./gameDetailDialog.前缀导致QML作用域解析失败("detailGameStatus is not defined") | AI |
| 2026-07-10 | 主页面自动隐藏滚动条：ListView 右侧24px MouseArea 检测悬停，ScrollBar opacity 动画(250ms)，移开自动淡出 | 用户 + AI |
| 2026-07-10 | 删除对话框优化：居中于游戏详情窗(x/y 绑定 gameDetailDialog 坐标)，取消时重新激活详情窗 | 用户 + AI |
| 2026-07-10 | 自定义文本颜色：cText/cSub 改为动态属性，自定义模式下读取 customTextColor/customSubColor；外观设置新增主文本色+次要文本色选择器(色块+十六进制+颜色选择对话框)，Settings 持久化 | 用户 + AI |
| 2026-07-10 | 封面裁剪编辑：cropDialog 新增 mode 属性(bg/cover)，openCover()/openBg() 分模式调用；编辑对话框新增"编辑封面"按钮；封面裁剪后自动更新路径并返回编辑对话框 | 用户 + AI |
| 2026-07-10 | 详情窗封面自适应：coverBox 按图片宽高比(Image.sourceSize)计算宽度，上限40%父宽度，展示完整封面无多余裁剪 | 用户 + AI |
| 2026-07-10 | 对话框返回上一界面：编辑保存→详情窗、封面裁剪→编辑对话框、回忆编辑→详情窗、删除确认→详情窗/回忆编辑窗，均调用 requestActivate() 重新激活 | 用户 + AI |
| 2026-07-10 | 回忆编辑对话框(memoriesEditDialog)：左侧截图列表(添加/删除/上移/下移)+右侧预览区(双Image淡入淡出轮播)+参数区(播放间隔1000-10000ms/淡入淡出0-3000ms滑块)；C++新增 moveScreenshot/getScreenshotSettings/setScreenshotSettings/getScreenshotCount 方法；screenshots 表新增 sort_order 列；app_settings 存储 ss_interval_/ss_fade_ 键值 | 用户 + AI |
| 2026-07-10 | 主页面滚动条重新设计：移除阻挡交互的MouseArea，改用 onContentYChanged+Timer(800ms)自动隐藏+悬停/拖拽时保持显示，interactive:true 可拖拽 | 用户 + AI |
| 2026-07-10 | 回忆编辑优化：删除按钮直接执行删除(无需独立确认框)；移除详情窗底部的截图删除栏和位置/数量指示；添加截图→添加回忆(全语言更新)；添加回忆按钮嵌入回忆编辑模块 | 用户 + AI |
| 2026-07-10 | 回忆编辑UI整改：对话框宽度760px，左侧290px列表(64px缩略图+上移下移+直接删除)，右侧预览+缩放控制+参数滑块，布局更紧凑 | 用户 + AI |
| 2026-07-10 | 回忆图片缩放编辑：screenshots表新增scale列(REAL DEFAULT 1.0)；C++新增setScreenshotScale方法；QML使用PreserveAspectFit+Scale transform实现等比缩放(0.3-3.0)，缩放后空白区域留白；详情窗和回忆编辑预览均支持缩放显示 | 用户 + AI |
| 2026-07-10 | 游戏名称字体放大：详情窗游戏名称从20px增至24px | 用户 + AI |
| 2026-07-10 | 对话框逐级返回完善：裁剪(bg模式)→背景历史、编辑背景→背景历史、删除背景→背景历史、裁剪(cover模式)→编辑对话框，所有路径均requestActivate上一级 | 用户 + AI |
| 2026-07-10 | 背景历史对话框UI统一：按钮改用BtnGhost圆角半透明风格，删除按钮红底，卡片半透明背景，缩略图圆角，滚动条主题色 | 用户 + AI |
| 2026-07-12 | 游戏详情对话框回忆全部展示：移除双图轮播(ssImg1/ssImg2/ssTimer)，改用 GridView 网格同时展示所有回忆缩略图(cellWidth 130/cellHeight 100)，每张图支持 scale 缩放显示；保留"编辑回忆"按钮入口 | 用户 + AI |
| 2026-07-12 | 主页面整页滚动：移除原 ListView 独立滚动+悬停检测 MouseArea，改为 Flickable 包裹所有内容区块(timeBlock/搜索统计/排序栏/添加饼图/列表)于同一 Column，ListView 设为 interactive:false + height:contentHeight，ScrollBar 自动隐藏(onContentYChanged+Timer 800ms) | 用户 + AI |
| 2026-07-12 | 回忆编辑显示模式切换(crop_mode)：screenshots 表新增 crop_mode 列(INTEGER DEFAULT 0，含 ALTER TABLE 迁移)；C++ 新增 setScreenshotCropMode 方法；QML 预览图 fillMode 动态切换(0=PreserveAspectFit 适配空白填充 / 1=PreserveAspectCrop 填充裁剪部分显示)；UI 增加适配/填充切换按钮，Timer 轮播时同步 crop_mode | 用户 + AI |
| 2026-07-12 | 游戏删除级联清理：deleteGame() 增强，除原截图文件+记录外，新增 QDir::removeRecursively() 删除回忆子文件夹({memory_root}/{gameId}/)，并 DELETE app_settings 中 ss_interval_<id>/ss_fade_<id> 播放参数键，避免残留 | 用户 + AI |
| 2026-07-12 | ID 重排引用同步：resetIds() 重排 games 表 id 时，先建立 old_id→new_id 映射(QList<QPair>)，DROP+重建 games 表后，遍历映射 UPDATE screenshots.game_id，修复删除游戏后回忆记录成为孤儿引用的 Bug | 用户 + AI |
| 2026-07-13 | 回忆编辑对话框重构：从主页面弹出改为 `parent: gameDetailDialog.contentItem` 嵌套于游戏详情窗，requestActivate() 返回父级；左面板(36%宽)缩略图 ListView + 上移/下移/删除/添加按钮，右面板预览区+缩放滑块+适配/填充切换+位置重置+轮播间隔/淡入淡出滑块 | 用户 + AI |
| 2026-07-13 | 回忆图片位置偏移：screenshots 表新增 offset_x/offset_y 列(REAL DEFAULT 0.0，含 ALTER TABLE 迁移)；C++ 新增 setScreenshotOffset 方法；QML 预览区 MouseArea 拖拽计算偏移比例(-0.5~0.5)，实时写入数据库 | 用户 + AI |
| 2026-07-13 | 游戏详情窗按钮显示修复：右侧改为 Flickable 可滚动内容(height: parent.height - 48)，底部编辑/删除/回忆编辑按钮行锚定底部，解决按钮被边框遮挡问题；同时新增游戏评价显示在回忆模块下方 | 用户 + AI |
| 2026-07-13 | 回忆轮番播放功能：详情窗新增 carouselOverlay 全屏覆盖层，双 Image(carouselImg1/carouselImg2) 交叉淡入淡出(opacity Behavior 动画)，Timer 按间隔切换；Scale transform 用 id 引用(carouselScale1/carouselScale2)在 JS 中修改 xScale/yScale 属性(不能用 JS 重新赋值 transform)；播放间隔/淡入淡出时间在回忆编辑对话框滑块调整 | 用户 + AI |
| 2026-07-13 | ResizeHandles 通用缩放组件：8 方向(四角+四边)缩放手柄 MouseArea，mapToGlobal 跟踪拖拽，z:1000 覆盖内容上层，minW/minH 边界保护；应用到全部 14+ 个对话框(add/edit/delete/file/appearance/memoriesEdit/settings/bgHistory/editBg/crop/customAccent/customBgColor/customTextColor/customSubColor/deleteBg/exportFormat/importTip) | 用户 + AI |
| 2026-07-13 | 对话框高度调整：fileDialog 700→380(展示所有内容即可)、appearanceDialog 600→700 | 用户 + AI |
| 2026-07-13 | 回忆编辑删除功能重设计：左面板缩略图 ListView 选中项高亮，选中后点删除按钮直接执行(无需确认)；播放顺序上移/下移按钮完善(列表选中态+按钮 disabled 边界处理)；解决回忆编辑对话框按钮显示不全问题(FooterRow + ResizeHandles) | 用户 + AI |
| 2026-07-13 | 回忆编辑对话框第 4 轮重构：①修复添加回忆按钮位置(从 Row 内移至独立行固定底部 width:parent.width)、删除按钮改为独立✕按钮；②图片编辑器改进：缩放滑块 0.1–10.0(原 0.3–3.0)、滚轮缩放(MouseArea onWheel)、中心十字辅助线、底部实时显示缩放/位置数值、resetCurrent() 全部重置按钮；③memoriesEditDialog 尺寸 780x580→880x660、minW 480→600 | 用户 + AI |
| 2026-07-13 | 拖拽排序：C++ 新增 reorderScreenshot(id, newIndex) 方法(事务批量更新 sort_order)；QML 移除▲/▼按钮，改用 MouseArea drag.target+drag.axis:YAxis+onReleased 计算目标索引调用 reorderScreenshot；delegate 内 Rectangle 去 anchors 改 x/y/width/height 手动定位以便拖动；moveDisplaced Transition 动画；拖拽手柄⠿图标提示 | 用户 + AI |
| 2026-07-13 | 对话框高度全面调整：addDialog/editDialog 500→460、fileDialog 380→340、appearanceDialog 700→580、settingsDialog 320→360(新增 Flickable+ScrollBar 包裹 settingsCol)、4个自定义颜色对话框 420→360；所有对话框均已有 ResizeHandles 可伸缩调整 | 用户 + AI |
| 2026-07-13 | 翻译键新增：dragToReorder(拖拽排序)、rotate/resetRotate/brightness/contrast(预留)、resetAll(全部重置)、imageEditor(图片编辑)、zoomIn/zoomOut(放大/缩小)——4 语言(zh_CN/zh_TW/en/ja)同步更新 | 用户 + AI |
| 2026-07-13 | 回忆展示模式切换：详情窗回忆区新增轮播/网格切换按钮(displayMode/carouselMode/gridMode 翻译键 4 语言)，默认 carousel 轮播内嵌(双 Image 交叉淡入淡出+Timer+计数指示)，可切 grid 网格 GridView 展示；保留▶轮播全屏入口 | 用户 + AI |
| 2026-07-13 | 删除对话框伸缩功能：移除 ResizeHandles 组件定义及所有 17 处调用，仅保留 DragHeader 拖拽移动；所有对话框固定尺寸(通过 Flickable 滚动展示内容) | 用户 + AI |
| 2026-07-13 | 回忆编辑删除键修复：拖拽 MouseArea 原覆盖整个 delegate(anchors.fill:parent)拦截了删除按钮点击事件→改为仅拖拽手柄(⠿)区域(22px 宽)可拖拽，缩略图/信息列/删除按钮各自独立 MouseArea，互不干扰 | 用户 + AI |
| 2026-07-13 | 回忆编辑对话框居中+边框间隔：onOpened 中 Math.max(20, (parent.width-dialog.width)/2) 确保至少 20px 间隔；填充模式优化：Image anchors.fill:parent + transform:[Scale(origin 中心+xScale/curScale), Translate(curOffsetX*width/curOffsetY*height)]，与轮播展示行为一致 | 用户 + AI |
| 2026-07-13 | 对话框滚动条统一为主页面设计：新建 MainSB 内联组件(width:10、radius:5、contentItem color: cAccent 0.7、opacity 自动隐藏 800ms Timer 淡出)；替换所有对话框 ScrollBar(addDialog/editDialog/fileDialog/exportFormatDialog/importTipDialog/settingsDialog/appearanceDialog/bgHistoryDialog/editBgDialog/gameDetailDialog Flickable/ssGrid/memList 共 13 处) | 用户 + AI |
| 2026-07-13 | 对话框 UI 边缘间隔统一：所有 Column width 从 dialog.width-32 改为 dialog.width-48(24px 间隔*2)；fileDialog 宽度 420→480；appearanceDialog 高度 580→460 | 用户 + AI |
| 2026-07-13 | 第 5 轮·删除独立全屏轮播：移除 carouselOverlay Rectangle(全屏覆盖层)、startCarousel() 函数、carouselFront 属性、▶轮播按钮、onClosing 中的 carouselOverlay.hide() 调用；保留回忆展示区内的内嵌轮播(inlineCarousel 双 Image 交叉淡入淡出) | 用户 + AI |
| 2026-07-13 | 第 5 轮·游戏详情页内联编辑：新增 editingName/editingRating/editingNotes 布尔属性切换显示/编辑模式；名称(Text↔TextField+保存/取消按钮)、评分(StarDisplay↔TextField+✓/✕按钮)、评价(Rectangle↔TextArea+保存/取消按钮)点击即编辑；封面 hover 显示"✎ 编辑封面"提示，点击打开 coverPickerForDetail FileDialog→dbManager.importCover()→updateGame()→refresh；新增 saveInlineName/saveInlineRating/saveInlineNotes/changeCover 函数；新增 clickToEdit/editName/editRating/editNotes/editCover/saveNotes/cancelEdit 翻译键(4 语言) | 用户 + AI |
| 2026-07-13 | 第 5 轮·回忆编辑布局重排：添加回忆按钮移至左面板顶部(width:parent.width 独立行)、删除当前选中回忆按钮移至底部(width:parent.width)、中间为拖拽排序列表 ListView；按钮间隔修复(Column spacing 8、Row spacing 8、delegate height 70、按钮 implicitHeight 34、按钮宽度充足避免重叠) | 用户 + AI |
| 2026-07-13 | 第 5 轮·回忆编辑文字重叠修复：delegate 信息列改为 3 行独立 Text(名称行：#序号+文件名、缩放行：imageScale: x.xx、模式行：fitMode/cropMode)，宽度计算 parent.width-20-56-8*2(拖拽手柄 20+缩略图 56+两处 spacing 8*2)避免文字视觉重叠 | 用户 + AI |
| 2026-07-13 | 第 5 轮·回忆编辑对话框居中：onOpened 中 var mx=Math.max(24,(gameDetailDialog.width-memoriesEditDialog.width)/2)、var my=Math.max(24,(gameDetailDialog.height-memoriesEditDialog.height)/2)，确保对话框居中于游戏详情窗且与外层边框至少 24px 间隔 | 用户 + AI |
| 2026-07-13 | 第 5 轮·历史背景图片对话框高度减小：bgHistoryDialog height 560→440、内部 ListView height 440→320(展示约 3-4 项+滚动条)，与第 4 轮对话框高度减小风格一致 | 用户 + AI |
| 2026-07-13 | 第 6 轮·回忆编辑对话框居中修复：原尺寸 880×660 超过父窗口 gameDetailDialog(820×580)导致无法居中；改为 720×540，onOpened 中 Math.max(24,(parent.width-dialog.width)/2) 正确计算居中位置 | 用户 + AI |
| 2026-07-13 | 第 6 轮·拖拽排序修复：原 onReleased 中 memDelegateBg.y/step 计算错误(memDelegateBg.y 是相对 delegate 的坐标非 ListView 坐标)；改为 mapToItem(memList.contentItem,0,0) 映射到 ListView contentItem 坐标系再除以 step；drag.minimumY/maximumY 从 0~contentHeight 改为 -index×step~(count-1-index)×step(相对 delegate 起始位置) | 用户 + AI |
| 2026-07-13 | 第 6 轮·回忆编辑文本重叠修复：信息列从 3 行(名称/缩放/模式)精简为 2 行(名称+缩放·模式合并)，两行均加 elide:Text.ElideRight；缩略图 56→48px、拖拽手柄 20→18px、Row spacing 8→6，信息列宽度 parent.width-18-48-6*2 充足 | 用户 + AI |
| 2026-07-13 | 第 6 轮·轮播删除图片后重置：refreshScreenshots() 中新增 if(inlineCarousel.curIdx>=screenshots.length){curIdx=0;front=true}，避免删除当前图片后 curIdx 越界导致轮播白屏 | 用户 + AI |
| 2026-07-13 | 第 6 轮·图片编辑器 UI 优化：移除右侧冗余"图片编辑"标题(对话框标题已是"编辑回忆")；按钮高度 28→26、Row spacing 10→8；淡入淡出时间显示从毫秒改为秒(ssFade/1000.toFixed(1)+"秒")与播放间隔统一；预览区高度从 height-250 改为 height-180(更紧凑) | 用户 + AI |
| 2026-07-13 | 第 6 轮·代码清理：删除 4 语言翻译表中未使用的翻译键 imageEditor/milliseconds/zoomIn/zoomOut/startCarousel/stopCarousel(前一轮删除全屏轮播和图片编辑标题后遗留) | 用户 + AI |
| 2026-07-13 | 第 7 轮·删除游戏详情页编辑按钮：底部 Row 中移除编辑按钮(原 onClicked 打开 editDialog)，只保留删除按钮，Item 占位从 parent.width-180 改为 parent.width-90 | 用户 + AI |
| 2026-07-13 | 第 7 轮·评分改为点击星星修改：移除 editingRating 属性和 ratingEditField TextField+✓/✕按钮；用 Repeater 5 颗星替换 StarDisplay，每颗星左半区点击得 index*2+1(奇数分)、右半区点击得 (index+1)*2(偶数分)，onClick 直接调用 saveInlineRating(value) 立即保存 | 用户 + AI |
| 2026-07-13 | 第 7 轮·游戏类型标签显示+独立对话框编辑：详情页新增类型标签 Row(Repeater 解析 detailGameTypes JSON→圆角 Rectangle Tag+Text)；点击弹出 typeEditDialog(Dialog parent:gameDetailDialog.contentItem 360×280)：当前类型标签可✕删除+TextField 输入新类型+添加按钮+保存/取消；新增 saveInlineTypes(newTypesJson) 函数；新增 editType/currentTypes 翻译键(4语言) | 用户 + AI |
| 2026-07-13 | 第 7 轮·单一编辑互斥机制：新增 commitCurrentEdit() 函数(检查 editingName→saveInlineName、editingNotes→saveInlineNotes)；新增 startEditName()/startEditNotes() 函数(先 commitCurrentEdit 再开启新编辑)；名称/评价点击改调 startEditName()/startEditNotes()；封面 changeCover() 先 commitCurrentEdit；类型编辑先 commitCurrentEdit | 用户 + AI |
| 2026-07-13 | 第 7 轮·回忆编辑对话框改为 Window：从 Dialog 改为 Window(flags:Qt.Dialog|Qt.WindowTitleHint, transientParent:gameDetailDialog, color:cBg, 680×500)；x/y 绑定 gameDetailDialog.x+Math.max(24,(parent.width-width)/2) 实现居中；open()→show()、close()→hide()；onClosed→onVisibleChanged；自定义标题栏(Rectangle+MouseArea startSystemMove)；自定义底部按钮栏(Rectangle+BtnSave/BtnClose) | 用户 + AI |
| 2026-07-13 | 第 7 轮·删除图片填充功能：移除 curCropMode 属性、fitMode/cropMode 按钮、setScreenshotCropMode 调用；fillMode 固定 Image.PreserveAspectFit；resetCurrent() 仍调用 setScreenshotCropMode(id,0) 重置数据库；重置缩放按钮移到缩放滑块行最右侧(紧跟数值显示后) | 用户 + AI |
| 2026-07-13 | 第 7 轮·图片适配空白主题色填充：预览区 Rectangle color 从固定 "#1a1a24" 改为 Qt.rgba(cAccent.r,cAccent.g,cAccent.b,0.08) 主题色半透明填充；底部状态文字颜色从 #aaaaaa/#888888 改为 cSub | 用户 + AI |
| 2026-07-13 | 第 7 轮·回忆编辑信息列改单行+tooltip：delegate 信息列从 2 行 Column 改为单行 Text("#序号  缩放x.x")；文件名用 ToolTip.text=modelData.path.split("/").pop()+ToolTip.visible=memDelMouse.containsMouse 显示；Text width 绑定 parent.width-18-48-6*3 确保不溢出；elide:Text.ElideRight 截断 | 用户 + AI |
| 2026-07-13 | 第 8 轮·轮播展示样式与编辑预览一致：inlineImg1/inlineImg2 transform 从单一 Scale 改为 [Scale, Translate]；新增 inlineTrans1/inlineTrans2 Translate 元素绑定 offset_x*img.width/offset_y*img.height；Timer onTriggered 中切换图片时同步更新 inlineTrans1/inlineTrans2.x/y；移除 crop_mode 判断(fillMode 固定 PreserveAspectFit) | 用户 + AI |
| 2026-07-13 | 第 8 轮·预览区状态文字移到预览区下方：从预览区 Rectangle 内 anchors.bottom 叠加改为预览区外独立 Row(左侧提示文字+右侧数值显示)；预览区高度从 parent.height-140 改为 parent.height-170 容纳新增状态行；文字不再挡住图片 | 用户 + AI |
| 2026-07-13 | 第 8 轮·图片位置偏移无限制：onPositionChanged 中移除 Math.max(-0.5,Math.min(0.5,...)) 限制，改为 nx=startOffX+dx/ny=startOffY+dy 直接赋值，用户可自由拖拽图片到任意位置(含负数偏移) | 用户 + AI |
| 2026-07-13 | 第 8 轮·修复类型编辑点击无效：原 Row 中 MouseArea anchors.fill:parent 不生效(Row 是 positioner 管理子项位置，anchors 冲突导致 MouseArea 宽度为 0)；改为 Item(width:parent.width,height:26) 包裹 Row(anchors.left)+MouseArea(anchors.fill:parent)，点击类型标签区域即可弹出 typeEditDialog | 用户 + AI |
| 2026-07-13 | 第 8 轮·三个重置按钮同一行靠右：合并为单行 Row(重置缩放 72px | 重置位置 90px | 全部重置 80px，spacing:8)；左侧用 Item(width:parent.width-72-90-80-8*3) 占位填充实现靠右对齐 | 用户 + AI |
| 2026-07-13 | 第 8 轮·封面复用 cropDialog 裁剪缩放：cropDialog 新增 mode="coverDetail" 和 openCoverForDetail(src) 函数；coverPickerForDetail onAccepted 改为调用 cropDialog.openCoverForDetail(urlToPath(currentFile))；doCrop 中 coverDetail 模式 importCover+updateGame+更新 detailGameCover+refresh；replaceCover 按钮 visible 增加 coverDetail 模式，onClick 中区分 cover/coverDetail 分别更新 editCoverPath/detailGameCover；onClosed 增加 coverDetail 返回 gameDetailDialog | 用户 + AI |
| 2026-07-13 | 第 9 轮·类型显示改为垂直一列：详情页类型标签从 Row 横向改为 Column 垂直排列；类型字符串超过10字符截断显示 modelData.substring(0,10)+"…"；Item 高度动态自适应 Math.max(26,typeTagCol.implicitHeight+8) | 用户 + AI |
| 2026-07-13 | 第 9 轮·类型编辑对话框列表式重设计：从标签云式改为 ListView 列表式(每行34px：序号+类型名(双击编辑 TextField+✓确认)+✕删除按钮)；新增 editingTypeIdx 状态控制编辑行；添加类型输入框 maxLength:10；对话框高度 280→340；新增 add 翻译键(4语言) | 用户 + AI |
| 2026-07-13 | 第 9 轮·封面裁剪嵌套于详情页：cropDialog parent 改为条件绑定 cropDialog.mode==="coverDetail" ? gameDetailDialog.contentItem : null；coverDetail 模式时裁剪对话框作为详情页子级弹出，而非主页面 | 用户 + AI |
| 2026-07-13 | 第 9 轮·回忆展示区 16:9：Rectangle height 从固定 220 改为 Math.round(parent.width*9/16) 动态计算；网格 cellWidth 136→160/cellHeight 106→90(16:9)；网格 Image fillMode 从 PreserveAspectCrop 改为 PreserveAspectFit+Scale+Translate(与轮播一致) | 用户 + AI |
| 2026-07-13 | 第 9 轮·回忆编辑预览 16:9 等比例真实展示：预览区 Rectangle height 从 parent.height-170 改为 Math.round(parent.width*9/16)；Image fillMode 保持 PreserveAspectFit 确保图片按真实比例等比缩放显示，空白用主题色填充 | 用户 + AI |
| 2026-07-13 | 第 9 轮·拖拽排序修复：原 mapToItem(memList.contentItem,0,0) 在 Window 中坐标映射不正确(返回错误坐标)；改为 index+Math.round(memDelegateBg.y/step) 直接用 delegate 内 y 偏移计算目标索引，无需坐标映射，彻底解决 Window 中拖拽无效问题 | 用户 + AI |
| 2026-07-13 | 第 10 轮·修复 maxLength 错误：QML TextField 不存在 maxLength 属性(报错 Cannot assign to non-existent property "maxLength")；改为 onTextChanged: if(text.length>10) text=text.substring(0,10) 手动截断到10字符 | 用户 + AI |
| 2026-07-13 | 第 10 轮·typeEditDialog 改为 Window：原 Dialog 作为 popup 嵌套在 gameDetailDialog(Window) 中，点击添加类型按钮会触发 CloseOnPressOutside 误判导致对话框跳出；改为 Window+transientParent:gameDetailDialog+flags:Qt.Dialog|Qt.WindowTitleHint，与其他嵌套对话框(memoriesEditDialog)模式一致；onVisibleChanged 返回 gameDetailDialog.requestActivate() | 用户 + AI |
| 2026-07-13 | 第 10 轮·修复回忆编辑后轮播不更新：refreshScreenshots() 原只更新 screenshots 数组，inlineImg1/inlineImg2 的 source 绑定基于 curIdx 不重算；新增强制刷新逻辑(检查 curIdx 越界→重置 0+front=true，根据 front 标志手动设置 inlineImg1/inlineImg2 的 source/scale/translate) | 用户 + AI |
| 2026-07-13 | 第 10 轮·修复游戏状态无法改变：原状态 Text 无点击事件；新增 cycleStatus() 函数(statuses=["待玩","进行中","已完成"]，indexOf 当前状态+1 取模切换)，状态 Text 添加 MouseArea onClicked:gameDetailDialog.cycleStatus() | 用户 + AI |
| 2026-07-13 | 第 10 轮·类型编辑后内容合并初步修复：Column 加 width:parent.width，height 用 childrenRect.height 替代 implicitHeight(但未彻底解决，根因在 property string 类型，见第11轮) | 用户 + AI |
| 2026-07-13 | 第 11 轮·类型显示改为横向 GridView 5 列：详情页类型标签从 Column 垂直排列改为 GridView 横向排列；cellWidth:Math.max(60,width/5) 确保每行5个，cellHeight:26，interactive:false(仅展示不滚动)；height:contentHeight 自适应行数；Item 高度 detailGameTypes.length===0?28:Math.max(28,typeTagGrid.contentHeight+8)；空类型时显示"✎ 点击编辑"提示文字 | 用户 + AI |
| 2026-07-13 | 第 11 轮·彻底修复类型编辑后内容整合成一条(根因修复)：①property string detailGameTypes→property var detailGameTypes:[](从字符串改为数组类型)；②openWith 中 detailGameTypes=JSON.parse(types)(解析 JSON 字符串为数组)；③所有 dbManager.updateGame 调用直接传 detailGameTypes 数组(不 JSON.stringify，因 C++ updateGame 第3参数是 QStringList，QML 自动将 JS 数组转换为 QStringList；若传 JSON.stringify 字符串则整个字符串变成单元素，C++ 再包装成 [["..."]] 导致所有类型合并成一条)；④saveInlineTypes(newTypesArr) 接受数组参数直接赋值；⑤editDialog 保存 gameDetailDialog.detailGameTypes=types 去掉 JSON.stringify(types=JS 数组直接赋值)；⑥GridView model 直接绑定 gameDetailDialog.detailGameTypes(无需 JSON.parse)；⑦typeEditDialog.openWith(typesArr) 接受数组 typeList=typesArr.slice()；⑥保存按钮 saveInlineTypes(typeEditDialog.typeList) 去掉 JSON.stringify | 用户 + AI |
| 2026-07-13 | 第 11 轮·删除游戏对话框嵌套到游戏详情：deleteDialog 从根级 Dialog(modal:true,header:DragHeader,footer:FooterRow) 改为 Window(flags:Qt.Dialog|Qt.WindowTitleHint,transientParent:gameDetailDialog,color:cBg,title:tt("deleteTitle"))；新增 openWith(gid,gname) 函数初始化属性并 show()；onVisibleChanged 返回 gameDetailDialog.requestActivate()；底部按钮改为自定义 Row(取消=灰色 cancelEdit + 删除=红色 del)；删除按钮 onClicked 调用改为 deleteDialog.openWith(detailGameId,detailGameName) | 用户 + AI |
| 2026-07-13 | 第 12 轮·修复拖拽排序无效(根因修复)：memDragHandle MouseArea 在 ListView(Flickable) 内，QML 默认 preventStealing:false 导致 ListView 偷走拖拽事件(用户拖拽时 ListView 滚动而非 delegate 移动)；添加 preventStealing:true 让 MouseArea 保留拖拽控制权，drag.target:memDelegateBg 正常工作 | 用户 + AI |
| 2026-07-13 | 第 12 轮·修复回忆编辑后图片修改不立刻反映到回忆展示(根因修复)：memoriesEditDialog 的 onVisibleChanged 只调用 saveSettings()+requestActivate()，没有调用 gameDetailDialog.refreshScreenshots()；添加 refreshScreenshots() 调用确保关闭编辑对话框时刷新轮播；同时改进 refreshScreenshots() 从只刷新当前一帧改为同时刷新两帧(inlineImg1+inlineImg2)，计算 nextIdx 并设置另一帧的 source/scale/translate，避免 Timer 切换时显示编辑前的旧数据 | 用户 + AI |
| 2026-07-13 | 第 13 轮·彻底修复拖拽排序：第 12 轮的 preventStealing:true 仍不足以阻止 ListView 偷事件；改为 onPressed 时 memList.interactive=false 完全禁用 ListView 滚动，onReleased 时 memList.interactive=true 恢复；同时在 onReleased 中先在内存中重排数组(slice+splice)立即反映视觉变化，再调用 dbManager.reorderScreenshot 持久化到数据库 | 用户 + AI |
| 2026-07-13 | 第 13 轮·默认主题色确认天蓝+背景透明淡蓝：currentTheme:"blue"(天蓝主题色 cAccent #3a9fff，已有)；customBgColor 从浅灰 #f5f5f8 改为淡蓝 #e8f0fe(与 blue 主题背景 themeBg.light.blue 一致)，确保自定义模式默认也是淡蓝背景 | 用户 + AI |
| 2026-07-13 | 第 13 轮·回忆列表删除冗余文本：delegate 信息 Text 从 "#序号 缩放x.x"(tt("imageScale")+scale.toFixed(1)) 改为只显示文件名 modelData.path.split("/").pop()，去掉 #编号 和 缩放 文本，文件名完整路径用 ToolTip 显示 | 用户 + AI |
| 2026-07-13 | 第 13 轮·类型编辑提示改为单字符串：typeEditDialog 的 typeAddField placeholderText 从 tt("type")("类型，空格分隔...") 改为 tt("typeOneHint")("输入一个类型即可")，因为该对话框每次只添加一个类型不需要分隔符提示；新增 typeOneHint 翻译键 4 语言(zh_CN:输入一个类型即可/zh_TW:輸入一個類型即可/en:Enter one type/ja:一つのタイプを入力) | 用户 + AI |
| 2026-07-13 | 第 13 轮·类型分隔符从逗号改为空格：addDialog typeField.split(",")→split(/\s+/)，editDialog editTypeField.split(",")→split(/\s+/)，jsonToText 的 join(",")→join(" ")；4 语言 placeholderText 同步更新(zh_CN:"类型，空格分隔（如：校园 恋爱）"/zh_TW:"類型，空格分隔（如：校園 戀愛）"/en:"Types, space-separated (e.g. School Romance)"/ja:"タイプ（スペース区切り、例：学園 恋愛）")；导入导出无需调整(数据库 types 始终是 JSON 数组字符串，与输入分隔符无关) | 用户 + AI |
| 2026-07-13 | 第 14 轮·拖拽排序改为 DropArea+DragHandler 方案(根因修复)：第 12-13 轮使用 MouseArea drag 在 ListView 中始终失效，根因是 delegate Item 由 ListView 定位不能手动改 y，drag.target:memDelegateBg 是 delegate 子 Rectangle 改 y 后视觉被 delegate 高度 64 裁切；方案 B：delegate 根 Item 加 DragHandler(target:memDelegate, yAxis.enabled:true, xAxis.enabled:false) 拖拽整个 delegate，每个 delegate 内 DropArea(keys:["memItem"]) 接收其他 delegate 拖入，onEntered 中 drag.source.memIndex 取源索引+index 取目标索引，slice+splice 内存重排立即反映视觉+dbManager.reorderScreenshot 持久化+refresh 刷新；Drag.active/dragType:Drag.Automatic/keys:["memItem"]/property int memIndex:index 配套 | 用户 + AI |
| 2026-07-13 | 第 14 轮·游戏状态改变后重新统计：cycleStatus() 函数中 dbManager.updateGame 后添加 root.refreshStats() 调用，确保状态切换后顶部统计卡片(待玩/进行中/已完成数量)立即更新 | 用户 + AI |
| 2026-07-13 | 第 14 轮·回忆列表隐藏文件名+序号移到最后：delegate 信息 Text 从 modelData.path.split("/").pop() 改为 "#"+(index+1)；因 model 是 memoriesEditDialog.screenshots 数组，删除图片或拖拽排序改动后 delegate 自动重新渲染，序号自动刷新为正确的连续编号 | 用户 + AI |
| 2026-07-13 | 第 14 轮·详情页添加游玩时长显示+内联编辑：位置从原评分后(被状态挤到前面)移到状态后方；editingPlayTime 状态切换 Text(⏱ Xh)↔TextField；startEditPlayTime() 函数(commitCurrentEdit 互斥+playTimeEditField.selectAll)；saveInlinePlayTime(newVal) 函数(parseInt 校验+负数归零+updateGame 持久化+gameListModel.refresh 刷新列表)；commitCurrentEdit 中加 editingPlayTime 检查；TextField onTextChanged 只允许数字+最多5位；onAccepted/onActiveFocusChanged 自动保存(失焦即保存) | 用户 + AI |
| 2026-07-13 | 第 15 轮·拖拽排序回退 MouseArea drag 方案：DragHandler 在 ListView 中与 Flickable 手势冲突不彻底；改回 MouseArea drag.target:memDelegate(delegate 根 Item 而非子 Rectangle)，preventStealing:true 阻止 ListView 偷事件，onPressed 时 memList.interactive=false 禁用 ListView 滚动，onReleased 时恢复 interactive=true；释放时 mapToItem(memList.contentItem,0,height/2) 计算 delegate 中心在 contentItem 中的绝对 y 位置，Math.round(absY/step) 计算目标索引(step=delegate.height+spacing)，恢复 memDelegate.y=0 让 ListView 重新定位 delegate | 用户 + AI |
| 2026-07-13 | 第 15 轮·排序完成后更新播放顺序：memoriesEditDialog.refresh() 中添加 gameDetailDialog.inlineCarousel.curIdx=0 + gameDetailDialog.inlineCarousel.front=true，确保拖拽排序后轮播从新顺序的第 0 张开始播放，播放顺序与新排序一致 | 用户 + AI |
| 2026-07-13 | 第 15 轮·网格展示同步更新：ssGrid.model 绑定 gameDetailDialog.screenshots(property var 数组)，refreshScreenshots() 中 screenshots=dbManager.getScreenshots() 重新赋值整个数组触发 QML 属性变更通知，GridView 自动重新渲染，网格展示顺序与轮播播放顺序同步更新 | 用户 + AI |
| 2026-07-13 | 第 16 轮·内联编辑去掉保存/取消按钮，点击空白处确定：游戏名称 TextField 用 onActiveFocusChanged:if(!activeFocus&&editingName)saveInlineName(text) 失焦自动保存+Keys.onEscapePressed 取消；游戏评价 TextArea 用 onActiveFocusChanged 失焦自动保存+implicitHeight:Math.max(100,contentHeight+12) 自适应高度；游玩时长 TextField 同样失焦自动保存(第 14 轮已实现)；名称编辑 Item 高度自适应 editingName?44:Math.min(60,nameDisplayText.implicitHeight+4) | 用户 + AI |
| 2026-07-13 | 第 16 轮·彻底修复拖拽排序(浮动克隆方案)：前 5 轮(MouseArea drag→preventStealing→DropArea+DragHandler→MouseArea drag 根Item)均失效，根因有二：①memDelMouse(MouseArea anchors.fill:parent)声明在 Row 之后，QML 中后声明兄弟元素在上层，memDelMouse 覆盖整个 delegate 拦截了拖拽手柄 dragHandleMA 的 press 事件→修复：将 memDelMouse 移到 Row 之前声明，让 Row 子元素(含 dragHandleMA)在上层；②dragCloneItem 原放在 ListView 内部，被 ListView clip:true 裁切且坐标映射 mapToItem(memoriesEditDialog.contentItem) 与 dragCloneItem 父元素(ListView)坐标系不匹配→修复：将 dragCloneItem 移出 ListView 作为 Window 直接子元素(z:1000 最上层不被裁切)，坐标映射 memoriesEditDialog.contentItem 即 dragCloneItem 父坐标系正确 | 用户 + AI |
| 2026-07-13 | 第 17 轮·修复点击空白处确定+名称宽度自适应+回退评价修改：①点击空白处确定未实现的根因：TextField 的 onActiveFocusChanged 在点击其他 MouseArea 时不触发(MouseArea 默认不抢夺 activeFocus)→修复：在 Flickable 内 Column 之前添加底层 MouseArea(propagateComposedEvents:true+mouse.accepted:false 事件穿透)，editingName/editingPlayTime 时启用，onPressed 调用 commitCurrentEdit()；同时 saveInlineRating/saveInlineTypes/cycleStatus 函数首行加 commitCurrentEdit()；②游戏名称文本宽度自适应：Item width 从 parent.width 改为 editingName?parent.width:Math.min(parent.width, nameDisplayText.implicitWidth+4)，去掉 elide:Text.ElideRight(宽度自适应无需省略)；③回退游戏评价修改：TextArea 的 onActiveFocusChanged 失焦自动保存改回显式保存/取消按钮(Column 包裹 TextArea+Row 两个 Button)，去掉 onActiveFocusChanged | 用户 + AI |
| 2026-07-13 | 第 18 轮·自定义对话框宽度减半+名称编辑框自适应：①4 个自定义颜色对话框(customAccent/customBgColor/customTextColor/customSubColor)宽度从 360 改为 300(外观对话框 600 的一半)；②游戏名称编辑框宽度自适应：编辑态 Item width 从 parent.width 改为 Math.min(parent.width, nameEditField.implicitWidth+8)跟随 TextField 内容宽度，TextField 从 anchors.fill:parent 改为 width:parent.width+anchors.verticalCenter，显示态和编辑态均自适应文本宽度 | 用户 + AI |
| 2026-07-13 | 第 19 轮·自定义颜色对话框宽度调整：回退第 18 轮的"宽度减半"方案(300 太窄导致预设色块拥挤)；4 个自定义颜色对话框(customAccent/customBgColor/customTextColor/customSubColor)宽度从 300 改为 320(按 12 个预设色块 6 列布局 6×32+5×8+padding 计算，既保证内容舒适展示又不过于宽大) | 用户 + AI |
| 2026-07-13 | 第 20 轮·修复图片选中+圆球滑块+拖动退出：①图片无法选中根因：点击拖拽手柄(⠿)区域时 dragHandleMA 只有拖拽逻辑无 onClicked，且 onReleased 因异常未触发时 dragFromIndex 未重置导致 memDelMouse.onClick 检查 dragFromIndex<0 失败→修复：dragHandleMA.onReleased 中偏移<5px 视为点击调用 selectImage(index)，添加 onCanceled 确保异常时状态重置(dragFromIndex=-1+memList.interactive=true+opacity=1.0)；②圆球滑块：定义 RoundSlider 内联组件(background 细线轨道 4px 高+已选区 cAccent 着色，handle 16×16 圆球 radius:8+cAccent 填充+白色 2px 边框+pressed 变亮)，替换全部 7 处 Slider(图片缩放/轮播间隔/淡入淡出/背景透明度/背景模糊/编辑背景透明度/编辑背景模糊)；③拖动完成后退出拖动模式：onReleased 中确保 dragFromIndex=-1+memList.interactive=true+dragCloneItem.visible=false+opacity=1.0 全部重置 | 用户 + AI |
| 2026-07-13 | 第 21 轮·回退圆球滑块修改：用户要求回退第 20 轮的第二个修改(圆球滑块)；删除 RoundSlider 内联组件定义，7 处 RoundSlider 全部改回原生 Slider(图片缩放/轮播间隔/淡入淡出/背景透明度/背景模糊/编辑背景透明度/编辑背景模糊)，恢复系统默认滑块样式；第 20 轮的①修复图片选中+③拖动退出保留 | 用户 + AI |
| 2026-07-13 | 第 22 轮·背景历史整合+设置改 Window+持久化：①背景图片历史整合到"编辑"对话框：历史列表每项只保留一个"编辑"按钮(去掉使用原图/裁剪/删除三个独立按钮)，editBgDialog footer 改为操作按钮行(使用按钮直接应用背景+裁剪按钮+删除按钮+保存按钮)，"使用原图"文案保持(useFull 翻译键不变)；②settingsDialog 从 Dialog 改为 Window(独立 OS 窗口，可缩放，flags:Qt.Window\|WindowTitleHint\|WindowCloseButtonHint\|WindowMinMaxButtonsHint，transientParent 无即顶层)，appearanceDialog 改为子 Window(transientParent:settingsDialog)，4 个颜色选择对话框(customAccent/customBgColor/customTextColor/customSubColor)改为子 Window(transientParent:appearanceDialog)，bgHistoryDialog 改为子 Window(transientParent:appearanceDialog)，editBgDialog 改为子 Window(transientParent:bgHistoryDialog)，deleteBgDialog 改为子 Window(transientParent:editBgDialog)；层级关系：root→settingsDialog→appearanceDialog→{customAccentDialog/customBgColorDialog/customTextColorDialog/customSubColorDialog/bgHistoryDialog→editBgDialog→deleteBgDialog}；③外观设置实时持久化：已通过 Settings alias 实现属性变更自动保存到 QSettings(language/theme/customAccent/customBgColor/customTextColor/customSubColor/customTextColorSet/customSubColorSet/darkMode/clockVisible)，无需额外代码 | 用户 + AI |
| 2026-07-13 | 第 23 轮·修复设置窗口无法开启：根因：Window 类型应用 show() 而非 open()(open() 是 Dialog 的方法)；修复：7 处 Window 的打开调用全部改为 show()：settingsDialog.show()/appearanceDialog.show()/customAccentDialog.show()/customBgColorDialog.show()/customTextColorDialog.show()/customSubColorDialog.show()/bgHistoryDialog.show()；FileDialog 的 open() 保留不变 | 用户 + AI |
| 2026-07-13 | 第 24 轮·全 Dialog 改 Window+删裁剪背景按钮+背景历史回退：①全 Dialog 改 Window：6 个 Dialog 全部改为 Window 类型(addDialog/editDialog/fileDialog/exportFormatDialog/importTipDialog/cropDialog)，统一属性(title/modality:Qt.WindowModal/width/height/minimumWidth/minimumHeight/color:root.cBg/flags:Qt.Window\|WindowTitleHint\|WindowCloseButtonHint\|WindowMinMaxButtonsHint/x/y 居中/palette)，调用方式 open()→show()；cropDialog 特殊处理：transientParent 按 mode 动态选择(cover→editDialog/coverDetail→gameDetailDialog/bg→bgHistoryDialog或appearanceDialog或root)，onClosed 改为 onVisibleChanged(if !visible)；editDialog/exportFormatDialog/importTipDialog 分别设置 transientParent(fileDialog/editDialog/fileDialog)；②删除外观对话框中"背景图片"区域的"裁剪背景"按钮(cropBg)，保留 selectImage/bgHistoryBtn/clearBg 三按钮；③背景历史回退到原 UI：bgHistory 列表 delegate 恢复四个按钮横排(使用原图/编辑/裁剪/删除)，editBgDialog 底部操作行回退为保存+取消两按钮，deleteBgDialog.transientParent 从 editBgDialog 改回 bgHistoryDialog | 用户 + AI |
| 2026-07-13 | 第 25 轮·打包可分发 exe：①创建 Release 构建目录 build/Desktop_Qt_6_11_1_MinGW_64_bit_Release，CMake 配置(-DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=D:/qt/6.11.1/mingw_64 -DCMAKE_CXX_COMPILER=D:/qt/Tools/mingw1310_64/bin/g++.exe -DCMAKE_MAKE_PROGRAM=D:/qt/Tools/Ninja/ninja.exe)；②Ninja 构建 Release 版本 galgame.exe(13.9MB)；③创建 release 目录，复制 galgame.exe；④运行 windeployqt --release --qmldir qml/ 收集所有依赖(Qt6*.dll 53个+MinGW 运行时 3个+opengl32sw.dll+D3Dcompiler_47.dll+platforms/styles/imageformats/iconengines/sqldrivers/qml/qmltooling/tls/networkinformation/generic/translations 插件目录)；⑤最终 release 目录 131.85MB/1495 文件，可直接打包 zip 分发，目标机器无需安装 Qt | 用户 + AI |
| 2026-07-13 | 第 26 轮·夜晚模式自定义修复+导出后缀补全+GIF背景+取色器：①**修复夜晚模式下无法自定义**（根因：custom 模式下 cBg 用 customBgColor 默认浅色 #e8f0fe，但 cCard/cInput/cBorder 用 isDark 判断→暗色模式下卡片/输入框为深色与浅色背景冲突，cText/cSub 在 customTextColorSet=false 时用 isDark 判断→暗色模式下默认浅色文字与浅色背景重叠不可读；修复：新增 customBgLuminance=0.299×r+0.587×g+0.114×b 计算 customBgColor 亮度，customIsDarkBg=luminance<0.5，effDark=currentTheme==="custom"?customIsDarkBg:isDark，cCard/cInput/cBorder 改用 effDark，cText/cSub 的 custom 模式默认值改用 effDark，使派生色随 customBgColor 亮度自动协调）；②**导出文件自动补全后缀**（exportDialog.onAccepted 中检查路径是否以 "."+fileSuffix 结尾，未包含则追加，确保即使用户手动输入文件名不带后缀也能正确生成 .json/.txt/.csv 文件）；③**背景图片支持 GIF 动画**（bgImageDialog nameFilters 添加 *.gif；GIF 文件跳过裁剪对话框直接设为背景——因裁剪会丢失动画帧；主背景图层拆分为 Image(静态)+AnimatedImage(GIF)双组件，按文件扩展名 .gif 切换可见性，两者均支持 layer.effect MultiEffect 模糊；editBgDialog 效果预览同步拆分为 Image+AnimatedImage 双组件，预览背景色从 isDark 改为 effDark 适配自定义模式）；④**颜色选择新增取色器模式**（新增共享 ColorDialog colorPickerDialog，property var targetDialog 记录目标对话框，onAccepted 时 targetDialog.selectedColor=selectedColor；4 个颜色选择 Window(customAccent/customBgColor/customBgColor/customSubColor)底部按钮行各添加"取色器"按钮 BtnGhost，点击时设置 targetDialog+selectedColor 初始值后 open()；新增 pickColor 翻译键 4 语言：取色器/取色器/Color Picker/カラーピッカー） | 用户 + AI |
| 2026-07-13 | 第 27 轮·开启黑夜模式强制跳出 custom：settingsDialog 夜晚模式 Switch 的 onToggled 从 `isDark = checked` 改为 `{ isDark = checked; if (checked && root.currentTheme === "custom") root.currentTheme = "blue"; }`，开启黑夜模式时若当前为 custom 主题则自动切回 blue 主题（关闭黑夜模式不强制切回 custom，保留用户当前主题选择） | 用户 + AI |
| 2026-07-13 | 第 28 轮·黑夜模式禁用自定义+取色器UI统一+取色器修复：①**黑夜模式禁用自定义**（customSwitch 添加 `enabled: !isDark`，黑夜模式时开关灰显不可操作；自定义模式标签颜色在 isDark 时用 cSub 弱化；新增提示标签"黑夜模式下不可用"在 isDark 时显示；新增 customDisabledDark 翻译键 4 语言：黑夜模式下不可用/夜間模式下不可用/Not available in Night Mode/夜間モードでは使用不可）；②**取色器 UI 统一**（4 个颜色选择窗口的"取色器"按钮从底部 footer Row 移至 hexCode TextField 右侧，统一布局为 Row{TextField(width:parent.width-100)+BtnGhost(implicitWidth:92)}，footer 恢复为 Item spacer+Cancel+OK 三元素，spacer 宽度从 parent.width-278 改回 parent.width-180）；③**修复取色器无法正常取色**（根因：ColorDialog 无 modality 导致可能被模态颜色选择 Window 遮挡或无法交互；修复：ColorDialog 添加 `modality: Qt.WindowModal`，每次 open() 前动态设置 `colorPickerDialog.parent = <调用者窗口>` 确保 ColorDialog 作为调用者窗口的模态子对话框显示在最前） | 用户 + AI |
| 2026-07-13 | 第 29 轮·修复取色器无法打开：根因：第 28 轮给 ColorDialog 动态设置 `parent = <Window>` 导致打开失败——ColorDialog 继承自 QtQuick.Dialogs.Dialog，其 parent 属性期望 Item 类型，动态赋值 Window 会导致 open() 无效；同时 `modality: Qt.WindowModal` 对 popup overlay 类型的 Dialog 可能造成显示冲突；修复：①移除 4 处按钮中的 `colorPickerDialog.parent = xxx` 代码；②移除 `modality: Qt.WindowModal`，改用 `options: ColorDialog.DontUseNativeDialog` 强制使用 Qt Quick 实现的颜色选择器（避免原生对话框在模态 Window 内的兼容性问题，确保跨平台一致行为） | 用户 + AI |
| 2026-07-13 | 第 30 轮·用自实现屏幕取色器替换 Qt ColorDialog 吸管：根因：Qt6 ColorDialog 的 Eye Dropper 按钮在 Windows + DontUseNativeDialog 模式下依赖 QScreen::grabWindow 抓屏，但在模态 Window 内启动时存在已知缺陷（坐标映射、像素抓取失败、UI 卡死等），无法可靠取色；方案：弃用 ColorDialog 改为完全自实现的屏幕取色器。①**C++ 新增 grabScreenColor(int x, int y)**（databasemanager.h/.cpp）：通过 `QGuiApplication::primaryScreen()->grabWindow(0, x, y, 1, 1)` 抓取虚拟桌面指定坐标的 1×1 像素 QPixmap，转 QImage 后用 `pixelColor(0,0)` 返回 QColor，注册为 Q_INVOKABLE 供 QML 调用；新增 include <QGuiApplication>/<QScreen>/<QPixmap>/<QColor>；②**QML 新增全屏取色器 Window colorPickerDialog**（替代原 ColorDialog）：flags=FramelessWindowHint|WindowStaysOnTopHint|Tool，visibility=FullScreen 覆盖全屏透明，function pickFromScreen(target) 记录目标对话框+初始化预览色+show()；MouseArea hoverEnabled+CrossCursor，onPositionChanged 实时调用 dbManager.grabScreenColor(mouseX,mouseY) 更新 previewColor，onClicked 抓取颜色写入 targetDialog.selectedColor 后 hide()；跟随光标的放大镜 Rectangle 显示当前色块+十六进制值+Esc 取消提示，自动避开屏幕边缘；Shortcut Escape 取消；③4 个颜色选择窗口按钮统一调用 `colorPickerDialog.pickFromScreen(<dialog>)`；④新增 escToCancel 翻译键 4 语言：Esc 取消/Esc 取消/Esc to Cancel/Esc でキャンセル | 用户 + AI |
| 2026-07-13 | 第 31 轮·吸管取色器 DPI 修正+点击稳定性修复（方案 B：实时抓屏+DPI 修正）：根因：第 30 轮实现存在三个问题——①**DPI 坐标错位**：QML MouseArea 的 mouseX/mouseY 是逻辑坐标，而 QScreen::grabWindow 的 x/y 参数是物理像素坐标，在 DPI 缩放≠100% 的显示器上（如 150% 缩放）鼠标位置与抓取像素位置错位，导致取到的颜色不是鼠标所指像素；②**点击瞬间重复抓屏状态不稳**：onClicked 再次调用 grabScreenColor，点击瞬间窗口状态可能变化导致抓到错误颜色；③**放大镜可能遮挡鼠标点**：放大镜在鼠标右下方 +20px 偏移，当鼠标靠近右下边缘时放大镜偏移到左上方但仍可能覆盖鼠标点；修复：①C++ grabScreenColor 内部乘以 `screen->devicePixelRatio()` 将逻辑坐标转为物理坐标（`qRound(x * dpr)`），确保抓取的像素与鼠标位置精确对应；②QML onClicked 改为直接使用 hover 时已抓取的 previewColor，不再重新调用 grabScreenColor，避免点击瞬间状态不稳；③放大镜偏移逻辑保持 +20px（鼠标右下方），越界时偏移到左上方 -width-20，确保不覆盖鼠标点 | 用户 + AI |
| 2026-07-13 | 第 32 轮·重新构建取色系统（方案 C：HSV 色轮+色板，放弃屏幕吸管）：根因：屏幕吸管方案（方案 B 实时抓屏）在 DPI 缩放、多显示器、全屏窗口遮挡等场景下始终存在不可靠问题；方案：完全弃用屏幕取色，改为内置 HSV 颜色选择器。①**C++ 移除 grabScreenColor**（databasemanager.h/.cpp）：删除 grabScreenColor 方法声明和实现，移除 include <QColor>/<QGuiApplication>/<QScreen>/<QPixmap>；②**QML 移除全屏取色器 Window colorPickerDialog**（原 flags=FramelessWindowHint|WindowStaysOnTopHint|Tool 的全屏透明窗口+MouseArea+放大镜+Shortcut Escape）；③**新增 HSV 颜色选择器 Component hsvPickerComp**：Item 内含 currentColor 属性+内部 hue/sat/val 状态+updating 防循环标志；onCurrentColorChanged 将 color→HSV（标准 RGB→HSV 转换算法）；hsvToColor(h,s,v) 将 HSV→Qt.rgba（6 段色相插值）；emitColor() 设 updating=true 避免回调循环；SV 方块 Canvas（260×180）：底色纯色相+左到右白色渐变（饱和度 1→0）+上到下黑色渐变（明度 1→0），MouseArea onPressed/onPositionChanged 更新 sat/val；色相条 Canvas（24×180 垂直彩虹）：6 色相 stop 渐变，MouseArea 更新 hue；两个指示器 Rectangle（白边+黑外框）；④**4 个颜色选择窗口重构**：窗口高度 400→540，Column 布局改为：预览条(40px)+Loader(hsvPickerComp)+预设色块(28×28)+十六进制输入(全宽)+footer(取消/确定)；Loader 用 Binding 将 selectedColor→item.currentColor，Connections 将 item.currentColor→selectedColor 双向同步；移除取色器按钮 BtnGhost；⑤**翻译键清理**：移除 pickColor 和 escToCancel（4 语言），clickToSelect 描述更新为"拖动 SV 方块和色相条选色" | 用户 + AI |
| 2026-07-13 | 第 33 轮·HSV 取色器双向同步修复+实时预览+色块同步+拖拽手柄加宽+导出默认文件名：5 个需求一并处理。①**HSV 选择器颜色不改变**（需求1）：根因：第 32 轮 Loader 用 Binding 的 target 为 `parent.item`（引用不可靠）且内部 emitColor() 修改 currentColor 后 Binding 会覆盖回外部值造成循环/不更新；修复：属性名 currentColor→selectedColor、标志 updating→internalChange（语义更清晰）；4 个窗口的 Loader 各给独立 id（accentPickerLoader/bgColorPickerLoader/textColorPickerLoader/subColorPickerLoader）；onLoaded 中初始化 `item.selectedColor = dialog.selectedColor`；Binding 的 when 条件加 `!loader.item.internalChange`，拖动时（internalChange=true）禁用外部→内部回写，避免覆盖内部拖动驱动的颜色；Connections 监听 onSelectedColorChanged 将内部颜色回写外部。②**取色预览实时变化**（需求2）：4 个窗口的预览条 Rectangle.color 绑定 `dialog.selectedColor`；TextField text 绑定 `dialog.selectedColor.toString().toUpperCase()`，拖动 SV 方块/色相条时 selectedColor 变化自动反映到预览条和输入框（无需手动刷新）。③**色块取色后十六进制同步**（需求3）：点击预设色块 `dialog.selectedColor = modelData`，因 internalChange 为 false，Binding 将外部 selectedColor 同步到 Loader.item.selectedColor，onSelectedColorChanged 更新内部 HSV 状态，TextField text 自动更新十六进制值。④**拖动排序范围提到前面**（需求4）：拖拽手柄 Rectangle width 18→28、图标 font.pixelSize 14→16，便于抓取；序号区从 Text 改为 Item 包含 Text（width: parent.width - 28 - 48 - 6*3），序号区可作为拖拽延伸区域。⑤**导出默认名称+后缀显示**（需求5）：exportDialog 新增 `property string defaultName: "galgame游玩记录"` 和 `function openWith(suffix)` 函数——设置 fileSuffix、预设 `selectedFile = defaultName + "." + suffix`（用户可在对话框中修改名称）、open()；6 处调用（fileDialog 内 3 处+exportFormatDialog 内 3 处）统一改为 `exportDialog.openWith("json"/"txt"/"csv")`；defaultSuffix: fileSuffix 确保对话框显示后缀 | 用户 + AI |
| 2026-07-13 | 第 34 轮·拖拽手柄回缩18px+拖动后取消选中+背景历史按钮改2字：3 个需求处理（吸管工具方案待用户选择，见下）。①**拖拽手柄回缩 18px**（需求1）：第 33 轮将手柄加宽到 28px/16px，用户要求改回；拖拽手柄 Rectangle width 28→18、Text font.pixelSize 16→14，序号区 width 计算从 `parent.width - 28 - 48 - 6*3` 改回 `parent.width - 18 - 48 - 6*3`；克隆项 dragCloneItem 内的手柄已是 18px/14px 保持一致。②**拖动完成后取消选中**（需求2）：用户确认"退出拖动模式"=取消选中所有图片；在 dragHandleMA.onReleased 的 else 分支（位移>=5 的真正拖动）末尾添加 `memoriesEditDialog.selectImage(-1)`——selectImage(-1) 设置 currentIdx=-1 并清空 curScale/curOffsetX/curOffsetY，预览区随之清空；小位移（<5）仍保留 selectImage(index) 当作点击选中；onCanceled 不变（异常取消不取消选中）。③**背景历史按钮"使用原图"改 2 字**（需求4）：翻译键 useFull 4 语言从"使用原图/使用原圖/Use Full/元画像使用"改为"原图/原圖/Full/原画"，全局生效（bgHistory 列表项按钮+cropDialog 裁剪窗口按钮统一缩短）。④**吸管工具方案**（需求3，待用户选择）：提出 4 个方案——A.Qt 原生 ColorDialog Eye Dropper（第 30 轮已验证不可靠）；B.自实现屏幕吸管实时抓屏+DPI修正（第 31 轮已验证仍有问题）；C.Win32 API GetPixel（仅 Windows，有时序问题）；D.截图缓存取色（推荐，取色启动时截全屏存 QPixmap，QML 显示静态截图取色，无遮挡无 DPI 问题） | 用户 + AI |
| 2026-07-13 | 第 35 轮·拖拽手柄z层+全屏取色器+网格回退：3 个需求处理。①**拖拽手柄唯一可拖动**（需求1）：给拖拽手柄 Rectangle 和 dragHandleMA 添加 `z: 10`，确保手柄区域在 memDelMouse（覆盖整个 delegate）之上，只有 18px ⠿ 手柄能触发拖拽排序，其他区域只能点击选中。②**全屏取色器（方案 D 截图缓存取色）**（需求2）：C++ 新增 `captureScreen()`——用 `QScreen::grabWindow(0)` 截全屏存 QImage m_screenCapture + 保存临时 PNG 文件返回路径；新增 `pickColorAt(int x, int y)`——从 m_screenCapture 取像素，内部乘以 devicePixelRatio 将逻辑坐标转物理坐标，返回 #RRGGBB；新增 include <QGuiApplication>/<QScreen>/<QPixmap>/<QColor>/<QImage>。QML 新增全屏取色窗口 screenPickerDialog——flags=FramelessWindowHint|WindowStaysOnTopHint，visibility=FullScreen；pickFromScreen(target) 调用 captureScreen 截图+show()；Image 显示截图，MouseArea hoverEnabled 实时调用 pickColorAt 更更新预览色，onClicked 写入 targetDialog.selectedColor 后 hide()；跟随光标的放大镜（120×120，色块+十六进制+Esc 取消提示）；Shortcut Escape 取消。4 个颜色选择窗口的 hex 输入区改为 Row{TextField+BtnGhost(吸管取色)}，点击调用 screenPickerDialog.pickFromScreen(对话框)。新增翻译键 pickColor/escToCancel 4 语言。③**网格拖动排序回退**（需求3）：用户要求回退第 35 轮的网格预览区修改——右侧预览区从 GridView 网格恢复为原来的单图预览模式（16:9 比例 Image+Scale/Translate transform+十字辅助线+拖拽调整位置+滚轮缩放）；删除 gridDragClone 浮动克隆项；状态信息恢复为"拖拽图片调整位置·滚轮缩放"。**CMakeLists.txt 新增 MinGW 大文件支持**：`if(MINGW) add_compile_options(-Wa,-mbig-obj) endif()`，解决 QML 文件过大导致的"too many sections (32773)"链接错误 | 用户 + AI |
| 2026-07-13 | 第 36 轮·删除吸管+修复拖动后无法选中+背景按钮改名：3 个需求处理。①**删除取色器吸管功能**（需求1）：完全移除第 35 轮实现的屏幕吸管——删除 QML 的 screenPickerDialog 全屏取色窗口（含 Image/MouseArea/放大镜/Shortcut）、4 个颜色选择窗口 hex 输入区的 Row{TextField+BtnGhost} 恢复为全宽 TextField、删除翻译键 pickColor/escToCancel（4 语言）；C++ 删除 captureScreen()/pickColorAt() 方法、m_screenCapture 成员、include <QGuiApplication>/<QScreen>/<QPixmap>/<QColor>（保留 <QImage> 因其他方法用）。②**修复拖动后无法选择其他图片**（需求2）：第 34 轮添加的 `selectImage(-1)` 在 refresh() 之后执行，但 refresh 内部 selectImage(currentIdx) 会因 currentIdx<0 重置为 0，导致状态混乱且取消选中后用户难以继续编辑；修复：移除 selectImage(-1)，改为在排序成功后 `selectImage(targetIdx)` 选中拖动图片的新位置，用户可继续编辑该图片或点击其他图片切换。③**背景历史按钮"原图"改"使用"**（需求3）：翻译键 useFull 4 语言从"原图/原圖/Full/原画"改为"使用/使用/Use/使用" | 用户 + AI |
| 2026-07-13 | 第 37 轮·拖拽手柄唯一化+删除遗留吸管按钮+视频背景支持：4 个需求处理。①**编辑代码在移动之上，只有⠿手柄可拖动**（需求1）：删除 memDelMouse（覆盖整个 delegate 的 MouseArea，会干扰 dragHandleMA），改为缩略图和序号区各自独立 MouseArea 处理 onClicked selectImage；dragHandleMA 保持 z:10 确保唯一可触发拖拽排序，其余区域（缩略图 48px+序号区剩余空间）只能点击选择图片。②**删除颜色选择中遗留的 picker 按钮**（需求2）：第 36 轮删除吸管时遗漏了 bgColor 和 textColor 两个窗口的 BtnGhost 按钮（仍引用已删除的 screenPickerDialog）；将这两个窗口的 hex 输入区从 Row{TextField width:parent.width-92 + BtnGhost} 恢复为全宽 TextField；删除遗留的 pickColor/escToCancel 翻译键（zh_TW 和 ja 两处）。③**同步语言更新**（需求3）：翻译键 selectImage 4 语言从"选择图片/選擇圖片/Select Image/画像選択"改为"选择图片/视频/選擇圖片/影片/Select Image/Video/画像/動画選択"；翻译键 bgImage 4 语言从"背景图片/背景圖片/Background Image/背景画像"改为"背景图片/视频/背景圖片/影片/Background Image/Video/背景画像/動画"。④**背景新增视频载入（仅 MP4）**（需求4）：CMakeLists.txt 添加 `Multimedia` 到 find_package COMPONENTS；QML 添加 `import QtMultimedia`；新增 `isVideoFile(path)` 函数判断 `.mp4` 后缀；新增 VideoOutput（id:bgVideo, anchors.fill:parent, z:-1）+ MediaPlayer（id:bgMediaPlayer, loops:Infinite, videoOutput:bgVideo）背景视频组件，视频自动适配窗口（anchors.fill）；bgImageDialog nameFilters 新增"视频文件 (*.mp4)"；onAccepted 中视频跳过裁剪直接设为背景（同 GIF 逻辑）；Image/GIF 可见条件排除视频文件；背景历史列表中视频文件显示"▶ MP4"占位符（黑色背景+白色文字），裁剪按钮对视频隐藏（visible:!isVideoFile） | 用户 + AI |
| 2026-07-13 | 第 37 轮后续·Qt 6.11 MediaPlayer API 兼容性修复：Debug 版运行时连续 3 次 QML 加载失败，逐一定位并修复 Qt 6.11 MediaPlayer 与 Qt 5 的 API 差异。①**`running` 属性不存在**（Main.qml:556）：Qt 6.11 MediaPlayer 无 `running` 属性（Qt 5 旧 API）；移除该属性，改用 `onSourceChanged` 信号处理器在 source 变化时判断 `root.bgImagePath.length>0 && isVideoFile(root.bgImagePath) && root.visible` 调用 `play()`，否则 `stop()`。②**`audioTrack` 属性不存在**（Main.qml:555）：Qt 6.11 MediaPlayer 无 `audioTrack` 属性；直接移除该行，背景视频静音改由 `audioOutput` 实现。③**`muted` 属性不存在**（Main.qml:554）：Qt 6.11 MediaPlayer 移除了 `muted` 属性；改用 `audioOutput: AudioOutput { volume: 0.0 }` 实现静音。④**可见性与路径变化联动**：新增 `Connections { target: root }` 监听 `onVisibleChanged` 和 `onBgImagePathChanged`，在窗口显示/隐藏或背景路径变化时调用 `bgMediaPlayer.play()`/`stop()`，确保视频在窗口隐藏时停止播放节省资源。**经验**：Qt 6 MediaPlayer 与 Qt 5 API 差异巨大，无 running/audioTrack/muted 属性，需用 onSourceChanged+Connections+AudioOutput 组合实现播放控制 | 用户 + AI |
| 2026-07-13 | 第 37 轮后续·默认回忆根目录：DatabaseManager::getMemoryRoot() 在 app_settings 表无 `memory_root` 键或值为空时，默认返回 `QCoreApplication::applicationDirPath() + "/memories"`（即 galgame.exe 同目录下的 memories 子目录），并调用 `QDir().mkpath(defaultRoot)` 自动创建该目录；用户仍可通过设置面板自定义路径覆盖默认值。这样打包后的程序首次运行即可使用回忆模块，无需用户先配置回忆根目录 | 用户 + AI |
| 2026-07-13 | 第 38 轮·EXE 打包到 demo/1.0：①**Release 构建**：在 Qt Creator 中以 Release 模式构建，生成 14,736,836 字节（14.7 MB）的 galgame.exe；②**创建 demo/1.0 目录**：在项目根下新建 `demo/1.0/` 作为打包输出目录，将 Release 版 galgame.exe 复制进去；③**windeployqt 收集依赖**：从正确路径 `D:\qt\6.11.1\mingw_64\bin\windeployqt.exe` 运行（之前误用 C:\Qt 路径失败），命令参数 `--release --no-translations --no-system-d3d-compiler --no-opengl-sw --qmldir qml demo/1.0/galgame.exe`；④**依赖收集结果**：1474 个文件、125.07 MB，包含：MinGW 运行时 DLL（libgcc_s_seh-1/libstdc++-6/libwinpthread-1）、Qt6 核心模块 DLL（Qt6Core/Gui/Qml/Quick/QuickControls2/Sql/Widgets/Network/OpenGL/Svg/Multimedia/Charts/LabsSettings 等）、FFmpeg DLL（avcodec-61/avformat-61/avutil-59/swresample-5/swscale-8，视频解码支持）、QML 插件目录（qml/QtCharts、qml/QtMultimedia、qml/Qt/labs/settings、qml/Qt/labs/folderlistmodel、qml/QtQuick/Controls 等）、平台插件（platforms/qwindows.dll）、图像格式插件（imageformats/）、SQL 驱动（sqldrivers/qsqlite.dll）、样式插件（styles/）、多媒体插件（multimedia/）、TLS/网络信息插件等。打包后 demo/1.0/ 为独立可分发的完整应用目录 | 用户 + AI |
| 2026-07-13 | 第 39 轮·视频背景声音/静音模式：原视频背景固定静音（AudioOutput volume 硬编码 0.0），新增可切换的声音/静音模式。①**新增属性** `property bool bgVideoMuted: true`（Main.qml:319，默认静音保持原有行为）。②**AudioOutput 绑定属性**：`audioOutput: AudioOutput { id: bgAudioOutput; volume: root.bgVideoMuted ? 0.0 : 1.0 }`（Main.qml:560），volume 随 bgVideoMuted 自动联动。③**外观对话框新增切换按钮**（Main.qml:2437-2441）：BtnGhost 仅在当前背景为视频时可见（`visible: root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)`），text 根据 bgVideoMuted 显示 tt("videoMuted")/tt("videoSound")，onClicked 切换 `root.bgVideoMuted = !root.bgVideoMuted`。④**4 语言翻译键**：videoMuted/videoSound（zh:"静音"/"声音"、zh_TW:"靜音"/"聲音"、en:"Muted"/"Sound"、ja:"ミュート"/"音声"） | 用户 + AI |
| 2026-07-13 | 第 40 轮·视频应用模式+主页面声音模块：3 个需求处理。①**视频应用图片模式**（需求1）：VideoOutput 添加 `fillMode: VideoOutput.PreserveAspectCrop`（Main.qml:550），与 Image/AnimatedImage 的 `Image.PreserveAspectCrop` 保持一致，视频背景与图片背景的填充行为统一（保持比例裁剪填满窗口）。②**主页面底部新增视频声音模块**（需求2+3）：在 Flickable 之后新增 `videoSoundBar`（Rectangle，anchors.bottom:parent.bottom，height:44），仅在背景为视频时可见（`visible: root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath)`）；模块包含 ①静音/声音切换按钮（Button，根据 bgVideoMuted 显示"🔇 静音"/"🔊 声音"，背景色随状态切换 cSub/cAccent）②音量标签（Label，显示"音量：xx%"）③音量滑块（Slider，from:0 to:1，value 绑定 root.bgVideoVolume，静音时 disabled+opacity:0.5）。Flickable 的 anchors.bottom 改为 `videoSoundBar.visible ? videoSoundBar.top : parent.bottom` 自适应避让。③**新增属性** `property real bgVideoVolume: 1.0`（Main.qml:324，音量 0.0-1.0）；AudioOutput volume 改为 `root.bgVideoMuted ? 0.0 : root.bgVideoVolume`（Main.qml:561）实现静音/音量联动。④**移除外观对话框切换按钮**：原第 39 轮加在外观对话框的 BtnGhost 静音/声音按钮已移至主页面声音模块，外观对话框背景行恢复为 3 按钮（选择/历史/清除）。⑤**4 语言新增翻译键** videoVolume/videoSoundModule（zh:"音量"/"视频背景声音"、zh_TW:"音量"/"影片背景聲音"、en:"Volume"/"Video Background Sound"、ja:"音量"/"動画背景サウンド"） | 用户 + AI |
| 2026-07-13 | 第 41 轮·持久化+语言全面国际化+设置页清理：5 个需求处理。①**背景设置持久化**（需求1+5）：Settings {} 块新增 5 个 alias：bgImagePath/bgOpacity/bgBlur/bgVideoMuted/bgVideoVolume（Main.qml:356-360），视频储存设置与背景图片模式一致，所有外观修改持久化保存，下次打开无需重新设置。②**导出文件名国际化**（需求2）：exportDialog 删除硬编码 `property string defaultName: "galgame游玩记录"`，openWith 函数改为 `selectedFile = tt("exportDefaultName") + "." + suffix`（Main.qml:2263），每次打开导出对话框时根据当前语言动态生成默认文件名。③**时钟日期全面国际化**（需求3）：getWeekday 函数改为从 `root.tr[root.currentLang].weekdays` 数组取值（Main.qml:418-420），4 语言各添加 weekdays 数组（zh/zh_TW:["星期日"..."星期六"]、en:["Sunday"..."Saturday"]、ja:["日曜日"..."土曜日"]）；时钟日期标签从硬编码"年"+"月"+"日"+"农历"改为 `tt("yearStr")+tt("monthStr")+tt("dayStr")+tt("lunarPrefix")`（Main.qml:679），4 语言添加 yearStr/monthStr/dayStr/lunarPrefix 翻译键（zh:"年"/"月"/"日"/"农历"、zh_TW:"年"/"月"/"日"/"農曆"、en:"-"/"-"/""/"Lunar"、ja:"年"/"月"/"日"/"農暦"）。④**空列表消息国际化**（需求3）：ListView 空列表 Label 从硬编码"没找到匹配的游戏"/"还没有游戏\n..."改为 `tt("noMatchGame")/tt("emptyGameList")`（Main.qml:811），4 语言添加 noMatchGame/emptyGameList 翻译键。⑤**移除设置页时钟切换**（需求4）：删除 settingsDialog 中的时钟切换 Row（原"🕐 显示时钟"+Switch），时钟切换仅保留在顶部工具栏的🕐按钮；settingsDialog 高度 440→400、minimumHeight 380→360 适配。⑥**4 语言新增翻译键**：exportDefaultName/weekdays(数组)/yearStr/monthStr/dayStr/lunarPrefix/noMatchGame/emptyGameList | 用户 + AI |
| 2026-07-13 | 第 42 轮·视频背景删除保留本体：DatabaseManager::deleteBgImage 修改（databasemanager.cpp:550-566）。原逻辑：删除背景历史记录时一律调用 `QFile::remove(path)` 删除实际文件。问题：视频背景采用路径引用模式（addBgImage 仅存储路径不复制文件），删除历史记录时把用户原视频文件也删了。修复：新增 isVideo 判断（`path.toLower().endsWith(".mp4")`），视频文件跳过 QFile::remove，仅删除 bg_images 表中的历史记录；图片文件维持原有删除文件行为。视频本体在删除历史记录后保留不变，用户可再次通过"选择图片/视频"重新引用 | 用户 + AI |
| 2026-07-13 | 第 43 轮·视频背景精简+全面国际化+外观持久化(方案C)：3 个需求处理。①**视频背景仅保留声音调节+背景历史**（需求1）：外观对话框中 bgOpacity 透明度滑块和 bgBlur 模糊度滑块在视频背景模式下隐藏（`visible: !(root.bgImagePath.length > 0 && isVideoFile(root.bgImagePath))`），因为视频背景无需透明度/模糊度调节，仅保留声音模块（主页面底部 videoSoundBar）和背景历史。②**全面国际化**（需求2，含色块名称补充）：替换所有硬编码中文为翻译键调用 `tt(key)`：窗口标题 `title: "🎮 " + tt("appTitle")`（原"galgame 游玩记录"）、warnDialog 标题 `tt("warnTitle")`（原"提示"）、工具栏文件按钮 `tt("fileBtn")`（原"📁 文件"）、addCoverDialog/editCoverDialog 标题 `tt("selectCoverPic")`（原"选择封面图片"）、导入示例标签 `tt("exampleLabel")`（原"示例："）、导入提示 `tt("importTip")`（原硬编码提示）、颜色预览文字 `tt("aaBbText")`/`tt("aaBbDesc")`（原"AaBb 文字"/"AaBb 说明"）；**色块名称国际化**：主题色预设色块模型从 `name:"天蓝"` 改为 `nameKey:"cBlue"`，显示文本改为 `tt(modelData.nameKey)`，4 语言新增 cBlue/cGreen/cYellow/cPink/cBlack/cGray/cWhite（zh:"天蓝/绿/黄/粉/黑/灰/白"、zh_TW:"天藍/綠/黃/粉/黑/灰/白"、en:"Sky Blue/Green/Yellow/Pink/Black/Gray/White"、ja:"スカイブルー/緑/黄/ピンク/黒/灰/白"）。③**外观设置持久化方案 C**（需求3）：用户从 3 个方案中选定 C（存入 app_settings 表，与回忆根目录等设置统一）。**C++ 侧**：databasemanager.h 新增 `Q_INVOKABLE QString getSetting(const QString &key, const QString &defaultValue = QString())` 和 `Q_INVOKABLE bool setSetting(const QString &key, const QString &value)`（databasemanager.h:64-65）；databasemanager.cpp 实现 getSetting（SELECT value FROM app_settings WHERE key=:k）和 setSetting（INSERT...ON CONFLICT(key) DO UPDATE）。**QML 侧**：移除 `import Qt.labs.settings` 和原 `Settings {}` 块；新增 `loadAppearance()` 函数在 Component.onCompleted 中调用，从 app_settings 读取 15 个外观属性（language/theme/isDark/clockVisible/customAccent/customBgColor/customTextColor/customSubColor/customTextColorSet/customSubColorSet/bgImagePath/bgOpacity/bgBlur/bgVideoMuted/bgVideoVolume）；新增 15 个属性变化处理器 `onXxxChanged: dbManager.setSetting(key, value)` 实现自动持久化。外观修改后立即写入数据库，下次打开程序自动恢复上次设置 | 用户 + AI |
| 2026-07-13 | 第 44 轮·清理 data/crops/ 冗余：解决封面裁剪流程产生的中间文件累积问题。原流程：cropImage 把裁剪结果存到 `data/crops/bg_crop_时间戳.jpg`，随后 importCover 复制一份到 `data/covers/`，但 `data/crops/` 的源文件永久残留。**双重清理机制**：①**importCover 自动清理**（databasemanager.cpp:693-703）：复制成功后检查 sourcePath 是否位于 `data/crops/` 目录内（用 QFileInfo.absoluteFilePath 规范化后 startsWith 比较，大小写不敏感），是则删除源文件——封面裁剪(mode=cover/coverDetail)的中间产物会被立即清理；用户原图和背景裁剪(mode=bg，不走 importCover)不受影响。②**启动时清理历史**（cleanupCropsDir，databasemanager.cpp:736-764）：initializeDatabase 建表成功后调用；扫描 `data/crops/` 所有文件，收集 bg_images 表中所有 image_path（背景裁剪结果直接作为背景路径使用，需保留），删除不在引用集合中的文件——清理历史累积的封面裁剪冗余。**安全边界**：只删除 `data/crops/` 内不被 bg_images 引用的文件；用户原图片、data/covers/ 封面、背景裁剪结果均保留。databasemanager.h 新增私有方法声明 `void cleanupCropsDir()`；databasemanager.cpp 新增 `#include <QSet>` 用于引用集合查找 | 用户 + AI |
| 2026-07-13 | 第 45 轮·视频背景冗余清理+游戏删除同步封面：2 个需求处理。①**移除视频背景冗余代码**（需求1+2）：VideoOutput（Main.qml:613-618）原有 `opacity: root.bgOpacity`、`layer.enabled: root.bgBlur > 0 && visible`、`layer.effect: MultiEffect { blur... }` 三行残留绑定——第 43 轮已在外观对话框隐藏了视频模式下的透明度/模糊度滑块，但 VideoOutput 仍绑定这两个属性，导致：a) 视频背景默认按 bgOpacity=0.35 显示为 35% 半透明（潜在 bug）；b) bgBlur 默认 0.5 触发 MultiEffect 模糊渲染白白消耗 GPU。修复：移除这三行，视频背景固定不透明、无模糊，与"视频模式仅保留声音调节"的设计一致。②**游戏删除同步清理封面文件**（需求3）：deleteGame（databasemanager.cpp:801-866）原已清理 screenshots 记录/文件、回忆子文件夹 {memory_root}/{id}/、回忆播放参数 ss_interval_/ss_fade_，但未清理封面文件（data/covers/cover_时间戳.ext）。新增：删除 games 表记录前先 SELECT cover_path，若路径位于 `data/covers/` 目录内（QFileInfo.absoluteFilePath 规范化后 startsWith 比较，大小写不敏感）则 QFile::remove 删除——安全边界确保不误删用户外部原图。日志输出更新为"已删除游戏 id: X（含回忆文件/记录/参数/封面）" | 用户 + AI |
| 2026-07-13 | 第 46 轮·背景历史视频按钮精简+游戏状态全面国际化：2 个需求处理。①**背景历史视频模式只保留"使用"+"删除"按钮**（需求1）：bgHistory delegate 原有 4 按钮（使用/编辑/裁剪/删除），裁剪按钮第 37 轮已对视频隐藏；本轮对"编辑"按钮（editBg）增加 `visible: !isVideoFile(modelData.imagePath)`，视频模式下隐藏；同时隐藏视频条目的透明度/模糊度信息文本（视频不使用这两个参数，显示无意义）。结果：视频历史条目仅显示"使用"+"删除"两个按钮，与视频背景精简设计一致。②**游戏状态文本全面国际化**（需求2）：原游戏状态（待玩/进行中/已完成）在多处硬编码中文显示，语言切换时不变化。**设计方案**：数据库仍存中文（保持向后兼容，不改库结构），显示时通过 `statusText()` 函数映射为当前语言翻译。**新增**：`readonly property var statusKeys: ["待玩", "进行中", "已完成"]`（内部键，与库存储一致）+ `function statusText(s)`（中文键→tt翻译：待玩→tt("todo")、进行中→tt("playing")、已完成→tt("done")）。**4 处显示更新**：a) 列表 delegate（Main.qml:854）`gameStatus`→`statusText(gameStatus)`；b) 详情窗状态标签（Main.qml:1372）`[detailGameStatus]`→`[root.statusText(detailGameStatus)]`；c) 饼图标签（refreshMainPie）`name:"待玩"`→`name:tt("todo")` 等；d) 添加/编辑对话框 ComboBox model 从 `["待玩","进行中","已完成"]` 改为 `root.currentLang.length >= 0 ? [tt("todo"), tt("playing"), tt("done")] : []`（显式引用 currentLang 确保语言切换时重算），保存时改用 `root.statusKeys[statusField.currentIndex]`（按索引取内部键，避免存翻译文本）。**语言切换刷新**：onCurrentLangChanged 增加 `reloadList()`（刷新列表状态文本）+ `refreshStats()`（刷新饼图标签）。统计卡片 status 字段保持中文（作为 C++ 筛选键传递，不显示）。**踩坑**：QML 内联绑定不支持 `{ var _ = ...; return ... }` 块语法（编译报 Unexpected token `;`），改用三元表达式 `root.currentLang.length >= 0 ? [...] : []` 显式建立 currentLang 依赖 | 用户 + AI |
| 2026-07-13 | 第 47 轮·英文日期格式修复：时钟日期标签（Main.qml:727-732）原统一用 `y + tt("yearStr") + mo + tt("monthStr") + da + tt("dayStr") + "  " + getWeekday(d) + "  " + tt("lunarPrefix") + getLunarDate(d)` 拼接。中文环境显示"2026年07月13日  星期日  农历..."；但英文环境下 yearStr/monthStr/dayStr 翻译为"-"/"-"/""，拼成"2026-07-13  Sunday  Lunar..."——格式不符合英文习惯（应为"Sunday, July 13, 2026"），且英文环境下显示"Lunar+农历日期"不自然。修复：按 currentLang 分支处理，英文模式用 `getWeekday(d) + ", " + Qt.formatDate(d, "MMMM d, yyyy")` 生成"Sunday, July 13, 2026"格式（月份用英文全称 MMMM，Qt.formatDate 自动按系统 locale 本地化），且不显示农历；中/日维持原有"年月日 星期 农历"格式不变 | 用户 + AI |
| 2026-07-14 | 第 48 轮·回忆编辑缩放修复+详情页文本遮挡+外观文字模块格式：3 个需求处理。①**回忆编辑窗口缩放文本跳出/重叠修复**（需求1）：memRightPane 右侧面板多个 Row 用硬编码宽度占位 `Item { width: parent.width - 360 }` 等，窗口缩放时这些硬编码值不随宽度变化，导致文本跳出文本框或重叠。修复：a) 状态信息行（dragToAdjustPos + imageScale/imagePosition）改用 `Item { Layout.fillWidth: true }` 弹性占位 + 两端 Text 用 `width: Math.min(implicitWidth, parent.width*0.5)` + `elide: ElideRight` 限定最大宽度；b) 缩放滑块行 Slider 增加 `Layout.fillWidth: true`；c) 三个重置按钮行改用 `layoutDirection: Qt.RightToLeft` 从右向左排列，去除硬编码 `parent.width - 72 - 90 - 80 - 8*3` 占位；d) 轮播间隔/淡入淡出滑块行 Slider 增加 `Layout.fillWidth: true`，Text 加 `elide: ElideRight`；e) 详情页回忆模块标题行（memories+displayMode+buttons）也用 `Layout.fillWidth` 替换硬编码 `parent.width - 360`。②**游戏详情页日语/英语文本遮挡修复**（需求2）：评分/状态/时长行 `Row { spacing: 16 }` 无宽度限定和 clip，日语/英语下状态文本比中文长（"進行中"/"Playing"），窄窗时溢出遮挡后续内容。修复：a) Row 增加 `clip: true` 防止溢出；b) spacing 16→10 节省空间；c) 状态 Text 增加 `elide: Text.ElideRight; maximumLength: 20` 防止超长。③**外观自定义文字模块格式统一**（需求3）：原 textColor 是 customCol 内部子标题（cSub 12），与同级 accentColor/bgColor 一致但与顶级 themeColor/bgImage（bold 14 cText）不一致——用户要求文字模块提升为与背景/主题同级的顶级分类。修复：将 textColor 从 customCol 内部移出为顶级 Label（`font.bold: true; color: cText; font.pixelSize: 14`，与 themeColor/bgImage 同格式），mainTextColor/subTextColor 作为其下级 Column 内容（cSub 12，与 accentColor/bgColor 同格式），删除原内部分隔线（顶级分类之间不再需要分隔线，与 themeColor→bgImage 之间无分隔线一致） | 用户 + AI |
| 2026-07-14 | 第 49 轮·QML 错误修复+代码自检：第 48 轮引入的两处 QML 属性误用导致构建/加载失败。①**`Layout.fillWidth` 在普通 `Row` 中使用**（Main.qml:1440）：`Layout.*` 附加属性只在 `RowLayout`/`ColumnLayout`/`GridLayout` 中生效，普通 `Row` 内使用会报 `Non-existent attached object`。修复：移除 `Layout.fillWidth`，改用计算宽度 `width: Math.max(50, parent.width - 36 - 42 - 8)`。②**`maximumLength` 在 `Text` 上使用**（Main.qml:1378）：`maximumLength` 是 `TextField`/`TextInput` 的属性，`Text` 组件没有该属性，报 `Cannot assign to non-existent property "maximumLength"`。修复：替换为 `width: Math.min(implicitWidth + 2, 120)` + `elide: Text.ElideRight` 实现等价的文本截断效果。③**代码自检**：用户要求"每次修改完成后进行代码检验"，使用 Grep 扫描 `maximumLength`、`Layout\.fillWidth`、`parent\.width - \d+ - \d+ - \d+` 等可疑模式，确认无其他遗漏的非法属性使用。**经验**：QML 附加属性有严格的作用域限制（Layout.* 仅在 Layout 系列容器中生效），组件属性继承自特定基类（maximumLength 来自 TextInput），使用前需确认目标组件类型 | 用户 + AI |
| 2026-07-14 | 第 50 轮·工具栏改造+文档移入设置+8对话框Flickable化：6 个需求处理。①**语言切换放主页面**（需求1，决策1方案A）：原设置对话框的语言切换移至主页面工具栏，🌍 地球图标按钮 + Menu 下拉菜单（4 个 MenuItem：简体中文/繁體中文/English/日本語，checkable+checked 跟随 root.currentLang），背景色 cAccent 半透明 + 边框，点击 langMenu.open() 展开。②**文档功能移入设置**（需求2）：原工具栏"📁 文件"按钮移入 settingsDialog，作为"📁 文件"分类标题 + 4 个 BtnGhost 子项（json/txt/csv 导出 + 导入入口），exportFormatDialog/importTipDialog 的 transientParent 从 fileDialog 改为 settingsDialog；原 fileDialog Window 整块删除（成为孤儿无入口）。③**夜晚模式放主页面**（需求3）：🌙/☀️ 图标按钮根据 root.isDark 切换显示，夜晚激活时背景色加深（cAccent 透明度 0.3），点击切换 isDark 并在 custom 主题下回退到 blue 主题（避免自定义背景色与暗色模式冲突）。④**自定义文字背景色翻译验证**（需求4）：检查 textColor/mainTextColor/subTextColor/presetColors/hexCode 等 4 语言翻译键，全部存在无遗漏。⑤**8 对话框改 Flickable+ColumnLayout**（需求5，决策2方案B）：统一缩放方案，所有对话框内容区改用 Flickable 滚动 + ColumnLayout 弹性布局。经核查 8 个对话框中 5 个已是 Flickable 结构（addDialog/editDialog/gameDetailDialog/bgHistoryDialog + memoriesEditDialog 右面板），实际改造 4 个颜色选择对话框（customAccentDialog/customBgColorDialog/customTextColorDialog/customSubColorDialog）：外层 `Column` → `Flickable { anchors.bottomMargin: 52; ScrollBar.vertical: MainSB {} }` + 内层 `ColumnLayout { id: xxxCol; width: parent.width; spacing: 10 }`，所有子项 width:parent.width → Layout.fillWidth:true，Loader 高度改用 Layout.preferredHeight:180，底部 BtnCancel/BtnOk 按钮行从 Column 内移出为独立 Row（anchors.bottom:parent.bottom 固定底部），删除原 `Item { width:1; height: parent.height - ... }` 硬编码占位。⑥**工具栏布局调整**：原 Row（rightMargin:8 spacing:4）保留 🌍 语言 + 🌙/☀️ 夜晚 + 🕐 时钟 + ⚙️ 设置 4 个按钮。**构建验证**：cmake --build 通过（exit code 0，14/14 步骤完成），galgame.exe 链接成功。**经验**：Loader 在 ColumnLayout 中需用 Layout.preferredHeight 而非固定 height，否则布局不参与高度计算；底部固定按钮行需从 Flickable 内移出避免随内容滚动 | 用户 + AI |
| 2026-07-14 | 第 51 轮·夜晚模式主题恢复：修复退出黑夜模式无法回到之前自定义主题的问题。①**新增 lastTheme 属性**（Main.qml:18）：`property string lastTheme: "blue"` 记录进入黑夜模式前的主题。②**夜晚按钮逻辑改造**（Main.qml:686-697）：进入黑夜时先 `lastTheme = currentTheme` 记录当前主题，再切换 isDark，custom 主题切到 blue；退出黑夜时 `currentTheme = lastTheme` 恢复之前的主题（custom/blue/green 等均可正确恢复）。③**持久化 lastTheme**：loadAppearance 加载（L385）+ onLastThemeChanged 保存（L414），确保程序重启后退出黑夜仍能恢复正确主题。**经验**：仅靠 isDark/currentTheme 两个属性无法实现"退出恢复"——需要第三个属性 lastTheme 记录历史状态，且必须持久化否则重启后丢失 | 用户 + AI |
| 2026-07-14 | 第 52 轮·评分Canvas绘制+视频背景副本管理：2 个需求处理。①**评分显示改方案 C（Canvas 绘制精确半星）**（需求1）：原实现用"空心☆ + 半透明黄色矩形覆盖右半"叠加，半星颜色偏淡、边缘有矩形 radius 痕迹，与整星风格不统一。**新增 StarCanvas 组件**（Main.qml:523-568）：Canvas 绘制五角星路径，底层灰色空星 + 顶层黄色填充星按 fillRatio 精确裁剪（ctx.rect + ctx.clip），颜色完全统一，支持任意小数评分比例。五角星路径函数 drawStar：10 个顶点（5 外 5 内交替），外半径 R = starSize*0.45，内半径 r = R*0.382（黄金比例），从顶部开始每 36 度一个顶点。property：rating(0-10)/starSize/starGap/fillColor/emptyColor，onRatingChanged 触发 requestPaint 刷新。**3 处替换**：a) StarDisplay（列表 delegate，starSize:16）；b) StarInput（添加/编辑对话框，starSize:28，5 个透明 MouseArea 叠加处理半星/整星点击）；c) 详情页评分行（starSize:18，同样 MouseArea 叠加）。所有旧 ★/☆ Text + Rectangle 覆盖代码已清除。②**视频背景副本管理**（需求2）：原视频背景采用路径引用模式（直接存用户原视频路径，删除历史记录时保留本体），与图片处理不一致。改为与图片一致的副本管理模式：a) **新增 importBgVideo**（databasemanager.h:25 + .cpp:707-731）：复制视频到 `data/bg_videos/bg_video_时间戳.mp4`，返回副本路径；b) **QML bgImageDialog**（Main.qml:2960-2963）：视频分支调用 `dbManager.importBgVideo(p)` 复制副本，用副本路径设为 bgImagePath 和 addBgImage；c) **deleteBgImage 移除视频特殊逻辑**（.cpp:581-603）：删除 isVideo 判断和"视频保留本体"分支，图片和视频副本统一 `QFile::remove(path)` 删除文件。**构建验证**：首次构建报 `Property names cannot begin with an upper case letter`（StarCanvas 的 `property real R`），修复为 `starR` 后构建通过（exit code 0，10/10 步骤）。**经验**：QML 属性名必须小写开头（大写开头会被误认为组件类型）；Canvas 绘制需在 property 变化时手动 requestPaint 刷新；五角星黄金比例内半径 = 外半径 * 0.382 | 用户 + AI |
| 2026-07-14 | 第 53 轮·评分点击修复+数字输入+范围限制+详情页评分编辑：3 个问题处理。①**评分点击不生效修复**：StarCanvas 和 MouseArea Row 在 Row 容器中水平并排排列而非叠加，点击落在 StarCanvas 上无 MouseArea。改用 Item 作为容器，StarCanvas 和点击层 Row 都放在 Item 内，点击层 `anchors.fill: parent` 覆盖在 StarCanvas 上方（StarInput L583-597 + 详情页 L1472-1486）。②**StarInput TextField 范围限制 0.0-10.0**：添加 DoubleValidator（bottom:0.0 top:10.0 decimals:1 locale:"C"）+ onTextChanged 实时过滤：只允许数字和小数点、限制单个小数点、超 10 强制设为"10.0"、负数设为"0.0"。placeholderText 改为"0.0-10.0"。③**详情页评分数字输入**（editingRating 模式）：新增 property bool editingRating + commitCurrentEdit 添加 ratingEditField 提交 + startEditRating 函数（填充当前值、forceActiveFocus、selectAll）+ saveInlineRating 改进（parseFloat 处理字符串、isNaN 保持原值、Math.round(r*10)/10 保留 1 位小数、值未变时不写库、成功后 editingRating=false）。详情页评分行：Text 显示评分数字（rating>0 显示 toFixed(1)，否则显示 ✎），点击进入 editingRating 模式 → TextField（width:56 DoubleValidator+onTextChanged 范围限制 onAccepted/onActiveFocusChanged 保存 Keys.onEscapePressed 取消）。点击空白处提交条件加入 editingRating（L1423）。**构建验证**：cmake --build 通过（exit code 0，7/7 步骤）。**经验**：Row 中的子项是水平排列不是叠加，需要 Item 作为容器才能实现 z 轴叠加；DoubleValidator 的 locale:"C" 确保小数点用 . 而非本地化符号 | 用户 + AI |
| 2026-07-14 | 第 54 轮·主页面列表增加评分显示：游戏列表 delegate（L938-966）右侧增加大字体评分数字。原 Column 锚点 `anchors.right: parent.right; anchors.rightMargin: 12` 改为 `anchors.right: ratingBox.left; anchors.rightMargin: 8` 给评分区让出空间。新增 ratingBox（Item width:48 height:parent.height，anchors.right:parent.right + verticalCenter + rightMargin:12），内含 Text 显示 `gameRating.toFixed(1)`，font.bold:true font.pixelSize:20 color:"#ffc107"（金色大字体垂直居中）。**构建验证**：cmake --build 通过（exit code 0，7/7 步骤） | 用户 + AI |
| 2026-07-14 | 第 55 轮·历史背景透明度模糊度同步：当用户在外观设置修改 bgOpacity/bgBlur 时，若当前背景对应历史记录中的某条，则同步更新该历史记录。①**新增 currentBgHistoryId 属性**（L362）：`property int currentBgHistoryId: -1`（-1=未对应历史记录）。②**onBgImagePathChanged 自动查找对应历史 ID**（L423-432）：路径变化时调用 dbManager.getBgImages() 遍历匹配 imagePath，找到则设置 currentBgHistoryId 为对应记录的 id，未找到则设为 -1。③**onBgOpacityChanged/onBgBlurChanged 同步更新历史记录**（L433-441）：保存 setting 后，若 currentBgHistoryId >= 0 则调用 dbManager.updateBgImage(id, opacity, blur) 更新对应历史记录。**设计**：路径匹配自动查找 ID 方式无需在每处设置背景的代码中手动维护 ID（addBgImage 后新增记录、useBgHistory 使用历史记录、clearBg 清除背景等情况都能自动适配）。**构建验证**：cmake --build 通过（exit code 0，7/7 步骤） | 用户 + AI |

---

> 📌 **文档使用说明**：这是一份"活的文档"，每次 AI 协助开发后相关章节应同步更新。所有技术决策遵循第 0 章的协作原则。
