# DevFlow — 技術規格文件 v1.0

> 個人開發者的專案管理 + 任務 + 番茄鐘 + 月曆整合工具
> 
> 目標平台：Windows 11 · Web · iOS
> 
> 文件版本：v1.0 (2026-04-20)
>
> 專案代號：**DevFlow**（可後續更名，例：`FlowDesk`、`Pomoko`、`Tempo`）

---

## 目錄

1. [專案概述](#1-專案概述)
2. [技術棧](#2-技術棧)
3. [系統架構](#3-系統架構)
4. [功能模組](#4-功能模組)
5. [資料模型](#5-資料模型)
6. [同步機制](#6-同步機制)
7. [UI/UX 設計規範](#7-uiux-設計規範)
8. [跨平台適配](#8-跨平台適配)
9. [非功能性需求](#9-非功能性需求)
10. [開發 Roadmap](#10-開發-roadmap)

---

## 1. 專案概述

### 1.1 目標使用者

單一個人開發者（solo developer），同時處理多個軟體開發專案，需要在單一工具內完成：

- 管理多個進行中的專案
- 拆解並追蹤任務
- 使用番茄鐘保持專注節奏
- 以月曆視角回顧與規劃

### 1.2 核心價值主張

- **資料互聯**：番茄鐘綁定任務、任務歸屬專案、月曆呈現一切，所有資料在同一處流動，不像拼湊獨立 app 那樣割裂
- **離線優先**：任何時刻都能操作，網路僅作為同步通道
- **跨裝置一致性**：Windows 工作、iOS 移動查看、Web 做為備用，資料即時同步
- **克制的設計**：Notion 風格的溫潤極簡，不喧賓奪主，適合長時間駐留

### 1.3 非目標（明確排除）

為避免範圍蔓延，以下明確排除：

- 多人協作、團隊共享
- Git commit 追蹤與整合
- 時間追蹤計費（billable hours）
- Markdown 筆記編輯（專案描述僅為單行文字）
- 複雜趨勢分析與自訂報表
- 專注模式（使用者明確表示暫不需要）

### 1.4 目標平台

| 平台 | 版本需求 | 主要使用場景 |
|---|---|---|
| Windows 11 | 22H2+ | 主要開發工作站，桌面常駐 |
| iOS | 16.0+ | 移動查看、記錄靈感、月曆瀏覽 |
| Web | Chrome/Edge/Safari 最新兩版 | 備用存取、臨時裝置 |

---

## 2. 技術棧

### 2.1 Flutter 與語言

- **Flutter 最新 stable 版本**（開發啟動時鎖版本，避免中途升級）
- **Dart 3.x**，啟用 sound null safety
- **Impeller 渲染引擎**：Windows 與 iOS 皆啟用
- **Web 編譯模式**：CanvasKit（文字渲染穩定性優於 HTML renderer）

### 2.2 核心套件清單

| 套件 | 用途 | 備註 |
|---|---|---|
| `flutter_riverpod` + `riverpod_generator` | 狀態管理 | 型別安全、支援 code gen |
| `drift` + `drift_flutter` | 本地 SQLite 資料庫 | 三平台 schema 統一 |
| `sqlite3_flutter_libs` | SQLite 原生綁定 | Windows/iOS |
| `supabase_flutter` | 同步後端 SDK | Auth + Realtime + Database |
| `go_router` | 路由 | 聲明式、支援 deep link |
| `flutter_local_notifications` | 本地通知 | 番茄鐘結束提醒 |
| `window_manager` | Windows 視窗控制 | 系統匣、懸浮視窗 |
| `tray_manager` | Windows 系統匣 | 關閉視窗時縮到托盤 |
| `table_calendar` | 月曆元件 | 基礎月/週視圖 |
| `fl_chart` | 統計圖表 | 長條圖 |
| `google_sign_in` | Google 登入 | Windows/Web |
| `sign_in_with_apple` | Apple 登入 | iOS 必要 |
| `connectivity_plus` | 網路狀態監控 | 離線/上線切換 |
| `uuid` | UUID 產生 | 客戶端產生 ID |
| `intl` | 日期與數字格式化 | 繁中本地化 |
| `freezed` + `json_serializable` | 不可變資料類 | 配合 Riverpod |
| `path_provider` | 檔案路徑 | 資料庫位置、匯出 |

### 2.3 開發工具

- **IDE**：VS Code 或 Android Studio
- **Lint**：`flutter_lints` + 自訂 analysis_options
- **格式化**：`dart format` + pre-commit hook
- **狀態檢查**：Riverpod DevTools
- **版本控制**：Git + GitHub（private repo）

---

## 3. 系統架構

### 3.1 整體架構（離線優先）

```
┌─────────────────────────────────────────────┐
│               Flutter UI Layer              │
│  (Screens / Widgets / Material 3 themed)    │
└────────────────────┬────────────────────────┘
                     │ watch / invalidate
┌────────────────────▼────────────────────────┐
│             Riverpod Providers              │
│  (State, Notifier, Async, Family)           │
└────────────────────┬────────────────────────┘
                     │ call
┌────────────────────▼────────────────────────┐
│               Repository Layer              │
│  (ProjectRepo, TaskRepo, PomodoroRepo, ...)│
└────┬───────────────────────────────┬────────┘
     │ read/write                    │ enqueue
┌────▼──────────────┐       ┌────────▼────────┐
│  Drift (SQLite)   │◄──────┤   Sync Queue    │
│ Source of Truth   │       │  (pending ops)  │
└───────────────────┘       └────────┬────────┘
                                     │ flush
                        ┌────────────▼────────────┐
                        │      Sync Service       │
                        │ (push + pull + retry)   │
                        └────────────┬────────────┘
                                     │
                        ┌────────────▼────────────┐
                        │   Supabase Cloud        │
                        │  Postgres + Realtime    │
                        │  + Auth + Storage*      │
                        └─────────────────────────┘
                                (*Storage 保留擴充)
```

### 3.2 核心設計原則

1. **Single Source of Truth**：UI 永遠從本地 Drift 讀取，不直接打 Supabase
2. **寫入即同步**：任何本地寫入都會進入 sync queue，由背景服務推送
3. **樂觀更新**：UI 立即反映本地變更，雲端失敗再重試
4. **事件驅動**：Supabase Realtime 推播遠端變更，觸發本地 merge
5. **關注點分離**：Repository 封裝資料來源，UI 不感知同步狀態（除必要的同步指示器）

### 3.3 目錄結構建議

```
lib/
├── main.dart
├── app/
│   ├── app.dart                  # MaterialApp 根元件
│   ├── router.dart               # go_router 定義
│   └── theme.dart                # Notion 風格主題
├── core/
│   ├── constants.dart
│   ├── extensions/
│   └── utils/
├── data/
│   ├── local/
│   │   ├── database.dart         # Drift DB 入口
│   │   ├── tables/               # Table 定義
│   │   └── daos/                 # Data Access Object
│   ├── remote/
│   │   └── supabase_client.dart
│   └── sync/
│       ├── sync_service.dart
│       ├── sync_queue.dart
│       └── conflict_resolver.dart
├── domain/
│   ├── models/                   # Freezed 領域模型
│   └── repositories/             # Repo 介面與實作
├── features/
│   ├── auth/
│   ├── projects/
│   ├── tasks/
│   ├── pomodoro/
│   ├── calendar/
│   ├── stats/
│   └── settings/
└── shared/
    ├── widgets/                  # 共用元件（Button, Card, Badge...）
    └── providers/                # 跨功能 provider
```

---

## 4. 功能模組

### 4.1 身份驗證（Authentication）

**功能需求**

- 首次啟動引導畫面：Logo + 標語 + 登入按鈕
- 支援登入方式：
  - Google 登入（Windows / Web / iOS 皆支援）
  - Apple 登入（iOS 必須提供，其他平台可選）
- Session 持久化：登入後長期保持，直到手動登出
- 登出功能：清空本地資料庫後返回登入畫面
- 離線啟動：若本地有有效 session token，直接進入主畫面，背景驗證

**畫面**

- `LoginScreen`：品牌展示 + 登入選項
- `AccountScreen`：顯示頭像、Email、登出按鈕、帳號刪除連結

**業務規則**

- 登入後若為新使用者，自動建立 `default` 專案（讓 app 首次開啟不是空白）
- 首次登入以裝置時區為準建立偏好設定

---

### 4.2 專案管理（Projects）

**功能需求**

- 建立、編輯、封存、刪除專案
- 欄位：
  - 名稱（必填，最多 50 字）
  - 描述（可選，單行，最多 200 字）
  - 顏色（從預設 12 色中選，對應 Notion 配色系）
  - 狀態：進行中 / 暫停 / 已封存
  - 技術標籤（可複選，建議從常用清單挑選：Next.js、Flutter、Swift、FastAPI 等）
  - Git Repo URL（可選，可一鍵跳轉瀏覽器）
- 專案列表視圖：卡片式，顯示名稱、顏色標記、狀態徽章、當週番茄鐘數、進行中任務數
- 專案詳細頁：任務清單（該專案下所有任務） + 基本統計
- 封存的專案預設隱藏，設定中可切換「顯示已封存」

**畫面**

- `ProjectListScreen`：所有專案卡片
- `ProjectDetailScreen`：單一專案總覽 + 任務
- `ProjectFormBottomSheet`：新增 / 編輯表單（底部彈出）

**業務規則**

- 刪除專案時：若有關聯任務，彈出確認「將刪除 N 個任務與 M 個番茄鐘記錄」
- 封存不影響資料，僅從預設清單隱藏
- 「無專案」為系統虛擬分類，用於獨立任務（不可編輯刪除）

---

### 4.3 任務管理（Tasks / TO-DO）

**功能需求**

- 建立、編輯、完成、刪除任務
- 欄位：
  - 標題（必填，最多 100 字）
  - 描述（可選，多行，最多 1000 字）
  - 所屬專案（可選，可設為「無」）
  - 父任務（可選，最多一層子任務；UI 不允許建立三層以上）
  - 優先級：P0（緊急） / P1（高） / P2（中，預設） / P3（低）
  - 預計番茄鐘數（可選，0-99）
  - 實際番茄鐘數（唯讀，由系統累計）
  - 截止日期（可選）
  - 標籤（多選，使用者自訂）
  - 狀態：待辦 / 進行中 / 已完成 / 已封存
- 任務清單視圖：
  - 今日視圖：截止日期為今日或更早的未完成任務 + 進行中任務
  - 專案視圖：依所屬專案分組
  - 全部視圖：依狀態分組
- 任務排序：可拖曳調整順序（以 `sort_order` 欄位記錄）
- 快速操作：
  - 點擊圓圈 → 切換完成狀態
  - 長按 / 右鍵 → 脈絡選單（編輯、刪除、開始番茄鐘、設定截止日）
- 快捷鍵（Windows/Web）：
  - `Cmd/Ctrl + N`：新增任務
  - `Space`：切換選中任務的完成狀態
  - `Enter`：開啟編輯

**畫面**

- `TodayScreen`：今日應做任務
- `TaskListScreen`（含於 ProjectDetailScreen 與 AllTasksScreen）
- `TaskDetailSheet`：單一任務詳情（側邊抽屜或底部彈出）
- `QuickAddDialog`：快速新增（標題 + 專案選擇即可送出）

**業務規則**

- 完成任務時：
  - 記錄 `completed_at` 時間戳
  - 若有子任務未完成，提示確認
- 刪除任務：
  - 有關聯番茄鐘 → 保留番茄鐘記錄但解除關聯（`task_id` 設為特殊「已刪除任務」占位值，或保留 task 的 soft delete 讓統計仍可查詢）
- 子任務完成度：父任務旁顯示「3/5」進度標示

---

### 4.4 番茄鐘（Pomodoro）

**功能需求**

- 預設時長：工作 25 分 / 短休 5 分 / 長休 15 分（每 4 個工作循環後）
- 可於設定中調整時長（5-60 分鐘範圍）
- **啟動需綁定任務**：點擊任一任務的「開始番茄鐘」按鈕或從番茄鐘頁選擇任務
- 運作狀態：
  - 就緒（Ready）
  - 工作中（Working）
  - 短休（Short Break）
  - 長休（Long Break）
  - 暫停（Paused）
- 控制按鈕：開始 / 暫停 / 繼續 / 放棄
- 視覺化：大型圓形進度環 + 數字倒數（等寬字型）
- 番茄鐘完成時：
  - 本地通知推送
  - 播放完成音效（可於設定關閉）
  - 彈出「記一筆」對話框：可補記這段時間做了什麼（一行文字，可略過）
  - 自動累加任務的 `actual_pomodoros`
- 中途放棄：記錄實際時長但標記為 `completed = false`，不計入統計

**畫面**

- `PomodoroScreen`：主要番茄鐘畫面（倒數環 + 當前任務資訊 + 控制按鈕）
- `MiniPomodoroWidget`：迷你懸浮指示器（側邊欄常駐，顯示剩餘時間）
- `CompletionDialog`：番茄鐘完成後的筆記輸入

**業務規則**

- 同一時刻僅允許一個進行中的番茄鐘
- 切換任務需先結束或放棄當前番茄鐘
- 已完成的番茄鐘記錄不可編輯（append-only）
- 番茄鐘記錄同步到月曆視圖作為「已發生」的區段
- 倒數計時以 `Date.now()` 差值計算，不依賴 `Timer` tick，確保：
  - 裝置休眠後恢復，時間仍準確
  - Web 分頁切到背景不失準
  - 跨平台一致

**通知行為**

- Windows：系統通知 + 短音效
- iOS：本地通知（前景時用 app 內橫幅，背景時標準通知）
- Web：Browser Notification API（需首次請求權限）

---

### 4.5 月曆（Calendar）

**功能需求**

- 三種視圖：月 / 週 / 日
- 顯示內容（以圖層概念組合）：
  - **任務層**：任務截止日期（圓點標記，點擊展開任務清單）
  - **番茄鐘層**：已完成的番茄鐘區段（半透明色塊，依專案顏色）
  - **事件層**：手動新增的月曆事件（實心色塊）
- 顏色系統：
  - 預設以任務/事件的所屬專案顏色呈現
  - 手動事件可覆寫顏色
- 互動：
  - 點擊日期 → 顯示當日詳情面板（番茄鐘總數、完成任務、事件清單）
  - 點擊事件 → 編輯
  - 長按空白時段（週/日視圖）→ 快速新增事件
  - 拖曳事件 → 移動時段（僅週/日視圖）
- 快捷跳轉：今日按鈕、月份選擇器
- 月曆事件欄位：
  - 標題（必填）
  - 備註（可選）
  - 起始時間、結束時間
  - 關聯專案（可選）
  - 關聯任務（可選）
  - 顏色（可選，預設繼承專案）

**畫面**

- `CalendarScreen`：主畫面（視圖切換 + 月曆）
- `DayDetailPanel`：當日詳情（月視圖下方展開或日視圖主內容）
- `EventFormBottomSheet`：新增 / 編輯事件

**業務規則**

- 番茄鐘區段為唯讀（顯示於月曆但不可於此處編輯）
- 事件可跨日（起訖分別在不同日期），視圖中以截斷形式顯示
- 刪除事件不影響關聯的任務或番茄鐘

---

### 4.6 統計（Stats）

單頁面，非重點功能，僅提供基本指標：

**今日區塊**

- 完成番茄鐘數
- 專注總時長（時/分）
- 完成任務數
- 進行中任務數

**本週區塊**

- 7 天番茄鐘長條圖（fl_chart 基本 bar chart）
- 本週完成任務總數
- 本週活躍專案（有番茄鐘的專案）排行，前 5 名

**畫面**

- `StatsScreen`：單頁純檢視，無互動操作

**業務規則**

- 統計資料全由本地資料庫計算，不額外發送請求
- 週的定義：週一為起始日（可於設定更改為週日）

---

### 4.7 設定（Settings）

**分區項目**

- **帳號**：頭像、Email、登出、刪除帳號
- **番茄鐘**：
  - 工作時長（預設 25 分）
  - 短休時長（預設 5 分）
  - 長休時長（預設 15 分）
  - 長休循環間隔（預設每 4 個工作番茄鐘）
  - 完成音效（開 / 關 / 音量）
  - 自動開始下一階段（開 / 關）
- **外觀**：
  - 主題：淺色 / 深色 / 跟隨系統
  - 強調色：預設 Notion Blue，可選 6 種替代色
- **日期與時間**：
  - 週起始日（週一 / 週日）
  - 日期格式（YYYY-MM-DD / YYYY/MM/DD）
- **同步**：
  - 最後同步時間顯示
  - 手動觸發同步按鈕
  - 同步衝突紀錄檢視（若有）
- **資料**：
  - 匯出所有資料為 JSON
  - 匯入（覆蓋模式 / 合併模式，合併預設）
  - 清除本地快取（保留雲端）
- **關於**：版本號、開源授權、隱私政策、問題回報

---

## 5. 資料模型

### 5.1 實體關聯總覽

```
User (Supabase Auth)
  │
  ├──< Project
  │       │
  │       ├──< Task ──< SubTask (self-ref)
  │       │       │
  │       │       └──< PomodoroSession
  │       │
  │       └──< CalendarEvent
  │
  └──< UserPreferences (1:1)
```

### 5.2 核心表格欄位規格

#### `projects`

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | UUID | 主鍵，客戶端產生 |
| user_id | UUID | 所有者，對應 auth.users |
| name | text | 專案名稱（最多 50 字） |
| description | text? | 單行描述（最多 200 字） |
| color | text | Hex 色碼，預設 `#0075DE` |
| status | enum | active / paused / archived |
| tech_tags | text[] | 技術標籤陣列 |
| git_url | text? | Repo URL |
| sort_order | int | 列表排序 |
| created_at | timestamptz | 建立時間 |
| updated_at | timestamptz | 最後更新時間（用於衝突判斷） |
| deleted_at | timestamptz? | 軟刪除時間，null 代表未刪除 |

#### `tasks`

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | UUID | 主鍵 |
| user_id | UUID | 所有者 |
| project_id | UUID? | 所屬專案（null 代表無專案） |
| parent_task_id | UUID? | 父任務（僅允許一層） |
| title | text | 標題（最多 100 字） |
| description | text? | 描述（最多 1000 字） |
| priority | smallint | 0 = P0 ... 3 = P3，預設 2 |
| due_date | timestamptz? | 截止日期 |
| estimated_pomodoros | smallint | 預計番茄鐘數 |
| actual_pomodoros | smallint | 累計實際番茄鐘數（trigger 維護） |
| status | enum | todo / in_progress / done / archived |
| tags | text[] | 使用者自訂標籤 |
| sort_order | int | 排序 |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| completed_at | timestamptz? | |
| deleted_at | timestamptz? | |

#### `pomodoro_sessions`（append-only）

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | UUID | 主鍵 |
| user_id | UUID | |
| task_id | UUID | 關聯任務（必填） |
| started_at | timestamptz | 起始時間 |
| ended_at | timestamptz | 結束時間（含中途放棄） |
| duration_minutes | smallint | 預期時長（用於區分工作/短休/長休時段） |
| type | enum | work / short_break / long_break |
| note | text? | 完成時的一行筆記 |
| completed | boolean | true = 完整完成，false = 中途放棄 |
| created_at | timestamptz | |

> **特性**：此表無 `updated_at` 與 `deleted_at`，資料一旦寫入不可變動（除非使用者在設定中「清除歷史」觸發硬刪除）。

#### `calendar_events`

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | UUID | |
| user_id | UUID | |
| project_id | UUID? | |
| task_id | UUID? | |
| title | text | |
| note | text? | |
| start_at | timestamptz | |
| end_at | timestamptz | |
| color | text? | null 代表繼承專案顏色 |
| created_at | timestamptz | |
| updated_at | timestamptz | |
| deleted_at | timestamptz? | |

#### `user_preferences`（1:1 with user）

| 欄位 | 型別 | 說明 |
|---|---|---|
| user_id | UUID | 主鍵 |
| work_duration | smallint | 工作時長（分鐘） |
| short_break_duration | smallint | |
| long_break_duration | smallint | |
| long_break_interval | smallint | 幾個工作後長休 |
| sound_enabled | boolean | |
| sound_volume | smallint | 0-100 |
| auto_start_next | boolean | |
| theme | enum | light / dark / system |
| accent_color | text | |
| week_starts_on | smallint | 0 = 週日，1 = 週一 |
| date_format | text | |
| updated_at | timestamptz | |

### 5.3 索引策略

Supabase 端建議索引：

- `tasks (user_id, project_id)` where `deleted_at is null`
- `tasks (user_id, due_date)` where `status != 'done' and deleted_at is null`
- `pomodoro_sessions (user_id, started_at desc)`
- `pomodoro_sessions (user_id, task_id)`
- `calendar_events (user_id, start_at, end_at)` where `deleted_at is null`
- `projects (user_id, status)` where `deleted_at is null`

本地 Drift 對應建立相同索引，確保查詢效能一致。

### 5.4 Row Level Security（RLS）

所有使用者資料表啟用 RLS，policy 一律為：

```
user_id = auth.uid()
```

`user_preferences` 另加 `INSERT` policy 確保僅能建立自己的偏好紀錄。

---

## 6. 同步機制

### 6.1 同步策略總覽

採用前段討論確認的 **Row-level Last-Write-Wins + Append-only + Tombstone** 混合策略：

| 資料類別 | 策略 | 說明 |
|---|---|---|
| `pomodoro_sessions` | Append-only | 完成後不可修改，各裝置純新增 |
| `projects`, `tasks`, `calendar_events`, `user_preferences` | Row-level LWW | 以 `updated_at` 判斷新舊 |
| 所有可刪資料 | Soft delete + Tombstone | `deleted_at` 設值，30 天後 cleanup |

### 6.2 同步服務職責

`SyncService` 是背景運行的單例，負責：

1. **Push**：讀取 `sync_queue` 中的本地變更，逐筆推送到 Supabase
2. **Pull**：訂閱 Supabase Realtime 頻道，接收遠端變更寫入本地
3. **Full Sync**：啟動時或手動觸發時，比對雙方 `updated_at` 最大值，補齊遺漏
4. **重試與退避**：失敗操作以指數退避（1s, 2s, 4s, ... 最多 60s）重試

### 6.3 Sync Queue 設計

本地表 `sync_queue`：

| 欄位 | 型別 | 說明 |
|---|---|---|
| id | int | auto-increment 主鍵 |
| entity_type | text | projects / tasks / ... |
| entity_id | UUID | 目標資料的 ID |
| operation | enum | insert / update / delete |
| payload | text | JSON 序列化內容（insert/update 用） |
| retry_count | int | 失敗次數 |
| last_error | text? | 最後錯誤訊息 |
| created_at | timestamptz | |
| last_attempted_at | timestamptz? | |

**流程**：

1. Repository 層寫入本地 Drift 成功 → 自動插入一筆 sync_queue 記錄
2. SyncService 以 2 秒 debounce 觸發 flush
3. Flush 時依 `created_at` 順序逐筆推送
4. 推送成功 → 從 queue 刪除
5. 推送失敗 → 增加 retry_count、記錄錯誤、排入下次重試

### 6.4 衝突處理細則

**Push 時衝突**（本地 update，但雲端版本較新）：

- 比對 payload 中的 `updated_at` vs 雲端當前 `updated_at`
- 若雲端較新 → 丟棄本次 push，觸發該筆 pull
- 若本地較新 → 正常覆蓋

**Pull 時衝突**（收到 Realtime 事件，但本地有 pending 變更）：

- 檢查 sync_queue 是否有對應 entity_id 的 pending
- 若有 → 暫時忽略 pull，等本地 push 完成後重新 pull
- 若無 → 直接寫入本地

**刪除衝突**：

- 若 A 刪除、B 仍在編輯 → B 同步時會發現雲端已軟刪除，提示「該資料已於其他裝置刪除，是否保留您的修改？」（恢復 `deleted_at = null`）
- 使用者確認恢復則視為 update，依 LWW 處理

### 6.5 Realtime 訂閱

登入後訂閱以下頻道（以 user_id 為過濾條件）：

- `projects` 的 INSERT / UPDATE / DELETE 事件
- `tasks` 的 INSERT / UPDATE / DELETE 事件
- `calendar_events` 的 INSERT / UPDATE / DELETE 事件
- `user_preferences` 的 UPDATE 事件
- `pomodoro_sessions` 的 INSERT 事件（append-only 僅關心新增）

登出或網路中斷時取消訂閱，恢復後重新建立並觸發一次 full sync。

### 6.6 初始同步（首次登入）

1. 從 Supabase 分頁拉取所有使用者資料（每頁 500 筆，依 `updated_at asc`）
2. 寫入本地 Drift（批次 transaction）
3. 建立 Realtime 訂閱
4. 完成後在設定頁顯示「最後同步時間」

### 6.7 同步狀態視覺化

右上角持續顯示極簡狀態指示：

- **已同步**（whisper 綠點）：一切正常
- **同步中**（藍色轉圈）：有 pending 操作
- **離線**（灰色雲朵斜線）：網路不可用
- **錯誤**（橘色驚嘆號）：連續重試失敗，點擊看詳情

---

## 7. UI/UX 設計規範

### 7.1 設計哲學

採用 **Notion 風格**的溫潤中性美學（詳見附件 DESIGN-notion.md）：

- **空白畫布**：介面退到背景，內容為主角
- **溫潤中性**：所有灰階帶黃棕底色（#f6f5f4 / #31302e / #615d59 / #a39e98），非冷藍灰
- **低調分隔**：1px rgba(0,0,0,0.1) whisper 邊框，不用重陰影
- **多層柔光**：4-5 層陰影疊加（單層透明度 ≤ 0.05），創造自然景深
- **克制用色**：Notion Blue (#0075DE) 為唯一主要強調色，用於 CTA 與連結

### 7.2 色彩系統（對應到 app 語義）

| 角色 | 色碼 | 用途 |
|---|---|---|
| 主文字 | `rgba(0,0,0,0.95)` | 標題、正文 |
| 次文字 | `#615d59` | 說明、中繼資料 |
| 弱化文字 | `#a39e98` | 占位、禁用、時戳 |
| 主背景 | `#ffffff` | 主要頁面 |
| 次背景 | `#f6f5f4` | 側邊欄、卡片底、段落交替 |
| 深色介面（深色模式） | `#31302e` | 深色背景 |
| 主強調 | `#0075de` | 主要按鈕、連結、選中狀態 |
| 強調按下 | `#005bab` | 按鈕按下態 |
| 焦點環 | `#097fe8` | 鍵盤焦點 2px 外框 |
| 邊框 | `rgba(0,0,0,0.1)` | 所有分隔線、卡片邊框 |

**語義色（用於任務優先級、狀態徽章、月曆）**

| 名稱 | 色碼 | 用途 |
|---|---|---|
| Teal | `#2a9d99` | 成功、完成 |
| Green | `#1aae39` | 確認徽章 |
| Orange | `#dd5b00` | 警示、P1 優先級 |
| Red | `#d93838` | P0 緊急 |
| Pink | `#ff64c8` | 裝飾 |
| Purple | `#391c57` | 深色強調 |
| Brown | `#523410` | 暖調強調 |

**專案顏色選項**（使用者從此挑選）

`#0075de` / `#2a9d99` / `#1aae39` / `#dd5b00` / `#d93838` / `#ff64c8` / `#391c57` / `#523410` / `#615d59` / `#097fe8` / `#8c52ff` / `#00a6a0`

### 7.3 字型系統

**字型家族**

- 主字型：`Inter`（Google Fonts，免費商用，最接近 NotionInter）
- 中文：`Noto Sans TC`（與 Inter 搭配協調）
- 等寬（倒數計時、技術標籤）：`JetBrains Mono`

**階層對應**

| 角色 | 字型 | Size | Weight | Line Height | Letter Spacing |
|---|---|---|---|---|---|
| Display（空狀態大標） | Inter | 48px | 700 | 1.00 | -1.5px |
| Page Title | Inter | 26px | 700 | 1.23 | -0.625px |
| Section Heading | Inter | 22px | 700 | 1.27 | -0.25px |
| Card Title | Inter | 16px | 600 | 1.50 | normal |
| Body | Inter / Noto Sans TC | 16px | 400 | 1.50 | normal |
| UI / Button | Inter | 15px | 600 | 1.33 | normal |
| Caption | Inter | 14px | 500 | 1.43 | normal |
| Badge | Inter | 12px | 600 | 1.33 | 0.125px |
| Pomodoro Countdown | JetBrains Mono | 72px | 500 | 1.00 | -1px |

**中英字型混排**：於 Flutter 中使用 `FontFamilyFallback` 指定 `Inter → Noto Sans TC`，英數由 Inter 渲染、中文落到 Noto Sans TC，取得最佳視覺整合。

### 7.4 間距與圓角

**間距刻度**（以 8px 為基準，保留有機微調）

2 / 4 / 6 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 80

**圓角系統**

| 等級 | 數值 | 用於 |
|---|---|---|
| Micro | 4px | 按鈕、輸入框 |
| Subtle | 5px | 連結、清單項 |
| Standard | 8px | 小卡片、標籤容器 |
| Comfortable | 12px | 標準卡片、專案卡片 |
| Large | 16px | Hero、重點卡片 |
| Pill | 9999px | 徽章、狀態標籤、圓形按鈕 |

### 7.5 景深系統

| 層級 | 處理 | 用於 |
|---|---|---|
| Flat | 無陰影無邊框 | 頁面背景 |
| Whisper | `1px solid rgba(0,0,0,0.1)` | 標準卡片邊框、分隔線 |
| Soft Card | 4 層陰影疊（max opacity 0.04） | 內容卡片、徽章 |
| Deep Card | 5 層陰影疊（max opacity 0.05, 52px blur） | Modal、底部彈出、重要提示 |
| Focus | `2px solid #097fe8` 外框 | 鍵盤焦點 |

具體陰影值參考 DESIGN-notion.md 章節 2 與 6。

### 7.6 主要元件規範

**Primary Button**

- 背景 `#0075de`，文字白色
- 內距 8px / 16px
- 圓角 4px
- Hover：背景變 `#005bab`
- Active：scale 0.95
- Focus：2px 外框 + 陰影增強

**Secondary Button**

- 背景 `rgba(0,0,0,0.05)`，文字近黑
- 其餘同 Primary

**Ghost Button**

- 透明背景，文字近黑
- Hover：底線浮現

**Pill Badge**

- 背景 `#f2f9ff`，文字 `#097fe8`
- 內距 4px / 8px
- 圓角 9999px
- 字型 12px / weight 600 / letter-spacing 0.125px
- 語義變體：成功（teal tint）、警示（orange tint）、錯誤（red tint）

**Card**

- 背景白色
- Whisper 邊框
- 圓角 12px
- Soft Card 陰影
- Hover：陰影微微加深（過渡 200ms）

**Input / Textarea**

- 背景白色
- 邊框 `1px solid #dddddd`
- 內距 8px
- 圓角 4px
- Focus：邊框變 `#0075de` + 2px 外框
- Placeholder：`#a39e98`

**Checkbox（任務完成圈）**

- 未完成：24px 圓形邊框 `1.5px solid #a39e98`
- Hover：邊框變 `#0075de`
- 已完成：填滿 `#0075de` + 白色勾號
- 帶 200ms 過渡動畫

**Color Swatch（專案顏色選擇）**

- 24px 圓形
- 選中時外加 2px 白色內環 + 對應色 2px 外環

### 7.7 主要畫面結構

**桌面版（Windows / Web ≥ 1080px）**

```
┌────────────┬──────────────────────────────────┐
│            │  Top Bar (同步狀態 + 使用者選單)     │
│  Sidebar   ├──────────────────────────────────┤
│            │                                  │
│  • 今日    │                                  │
│  • 月曆    │         Content Area             │
│  • 番茄鐘  │                                  │
│  • 統計    │                                  │
│            │                                  │
│  專案清單   │                                  │
│  ├─ Proj A │                                  │
│  ├─ Proj B │                                  │
│  └─ + New  │                                  │
│            │                                  │
│  ─────     │                                  │
│  設定      │                                  │
└────────────┴──────────────────────────────────┘
```

- 側邊欄寬 240px，背景 `#f6f5f4`
- 內容區白色背景，左右內距 48px，上內距 32px
- 側邊欄可收合為 56px 的圖示列（桌面視窗 < 1200px 時自動收合）

**iOS**

- 底部 Tab Bar：今日 / 月曆 / 番茄鐘 / 專案 / 更多
- 「更多」內含統計、設定
- 內容區滿版
- 按 iOS Human Interface Guidelines，主要操作採 Navigation Bar 右上或底部浮動按鈕

### 7.8 空狀態（Empty State）

每個主要視圖都要有設計過的空狀態，而非冷漠的「沒有資料」：

- 今日無任務：「今天沒有待辦事項。要新增一個，或查看所有專案嗎？」
- 無專案：引導「建立你的第一個專案」
- 番茄鐘無任務：「選一個任務開始專注」+ 任務選擇器
- 月曆空日：顯示淺色「尚無記錄」文字與「新增事件」按鈕

### 7.9 動畫原則

- 預設過渡時長：200ms
- 緩動函數：`Curves.easeOutCubic`（Notion 風格的柔和停止）
- 頁面切換：桌面無動畫、iOS 使用系統預設 Cupertino 轉場
- 列表項目進場：12px Y 軸位移 + opacity fade，150ms
- 不使用彈跳、浮誇效果

---

## 8. 跨平台適配

### 8.1 Windows 11 特定

- **視窗控制**：最小寬 800px、最小高 600px；啟動時記憶上次視窗尺寸與位置
- **系統匣**：關閉視窗時縮到托盤（可於設定改為直接退出），右鍵選單含「開始番茄鐘」「打開 app」「退出」
- **番茄鐘懸浮視窗**：番茄鐘進行中可開啟 180×120px 的迷你永遠置頂視窗，只顯示倒數
- **鍵盤快捷鍵**：全域快捷鍵（可於設定啟用）
  - `Ctrl + Shift + P`：啟動/暫停番茄鐘
  - `Ctrl + Shift + N`：快速新增任務
- **通知**：使用系統原生通知中心

### 8.2 iOS 特定

- **登入**：必須提供 Apple 登入（App Store 審核要求）
- **通知權限**：首次使用番茄鐘時請求
- **背景處理**：
  - 番茄鐘倒數使用系統本地通知（設定觸發時間即可，不依賴持續運行）
  - 若 app 被系統終止，以通知作為完成提醒
- **Safe Area**：所有主要容器遵守 Safe Area，避開瀏海與 Home Bar
- **Haptic Feedback**：完成任務、番茄鐘結束觸發輕度震動
- **Dynamic Type**：字級隨系統調整（上下限制在 -2 到 +3 級之間）

### 8.3 Web 特定

- **Browser**：Chrome、Edge、Safari 最新兩版
- **番茄鐘倒數**：
  - 以 `Date.now()` 差值計算，避免分頁切到背景後 setInterval 被節流導致失準
  - 分頁標題動態更新顯示剩餘時間（如 `25:00 · DevFlow`）
  - 返回分頁時使用 Page Visibility API 重新校準
- **通知**：Browser Notification API，首次番茄鐘啟動時請求
- **音效**：需在使用者互動後初始化 Audio Context，避免 autoplay policy 阻擋
- **SQLite Wasm**：使用 `drift_flutter` 的 Web 支援，資料存於 IndexedDB 包裝的 OPFS
- **OAuth**：
  - Google 登入用 redirect flow（而非 popup，避免第三方 cookie 限制）
  - 登入成功後回到原先頁面
- **快捷鍵**：同 Windows，但限 app 焦點內（非全域）
- **PWA**：提供 `manifest.json` 讓使用者可「加到桌面」

### 8.4 響應式斷點

| 斷點 | 寬度 | 佈局 |
|---|---|---|
| Mobile | < 600px | 單欄、底部 Tab（iOS 模式） |
| Tablet | 600-1080px | 收合側邊欄、內容滿版 |
| Desktop | 1080-1440px | 標準側邊欄 + 內容 |
| Large | > 1440px | 側邊欄固定、內容置中最大寬 1200px |

---

## 9. 非功能性需求

### 9.1 效能

- 冷啟動到可操作 ≤ 2 秒（桌面）、≤ 3 秒（iOS）
- 任何列表操作 UI 反應 ≤ 100ms（樂觀更新保證）
- 月曆月份切換 ≤ 200ms
- 單次同步週期（1000 筆以內變更）≤ 5 秒

### 9.2 可靠性

- 離線可使用所有功能（登入除外）
- 同步失敗自動重試，永不遺失本地資料
- 資料庫 WAL 模式，崩潰後可恢復
- Supabase RLS 保證不同帳號資料隔離

### 9.3 隱私與安全

- 本地資料庫不加密（個人使用權衡簡單性）
- 傳輸層：Supabase 全程 HTTPS
- 不蒐集使用分析、崩潰報告（除使用者主動回報）
- 帳號刪除：雲端資料 30 天內完全清除（Supabase Edge Function 執行）

### 9.4 可維護性

- 所有公開 API 有 Dartdoc 註解
- 關鍵流程（同步、番茄鐘狀態機）有單元測試覆蓋
- Git 規範：Conventional Commits
- 版本管理：Semantic Versioning

### 9.5 可存取性

- 所有互動元件可鍵盤操作
- Focus 指示清楚可見（2px 藍色外框）
- 色彩對比達 WCAG AA
- iOS 支援 VoiceOver（所有主要元件有語義標籤）

---

## 10. 開發 Roadmap

### Phase 1：本地核心（約 3 週）

**目標**：Windows 單平台可完整使用（無同步）

交付項目：

- [ ] 專案骨架（目錄結構、主題、路由）
- [ ] Drift 資料庫建立（全部 schema）
- [ ] Auth 畫面 UI（僅介面，真實登入於 Phase 2）
- [ ] 專案 CRUD + 列表
- [ ] 任務 CRUD + 今日視圖 + 專案內任務
- [ ] 番茄鐘完整流程（含通知、計時、記錄）
- [ ] 月曆基本月/週/日視圖
- [ ] 基本統計頁
- [ ] 設定頁（不含同步相關項目）

### Phase 2：雲端同步（約 2 週）

**目標**：Supabase 完整整合，多裝置同步可用

交付項目：

- [ ] Supabase 專案建置（schema + RLS + trigger）
- [ ] Google 登入串接（Windows/Web）
- [ ] SyncService 實作（push / pull / full sync）
- [ ] SyncQueue 與重試機制
- [ ] Realtime 訂閱
- [ ] 衝突處理
- [ ] 同步狀態指示器
- [ ] 匯出 / 匯入功能

### Phase 3：iOS 平台（約 2 週）

**目標**：iOS 版完整上架

交付項目：

- [ ] Apple 登入
- [ ] iOS 通知適配
- [ ] 底部 Tab 佈局
- [ ] Haptic Feedback
- [ ] Safe Area 全面處理
- [ ] 圖示、啟動畫面、App Store 素材
- [ ] TestFlight 內測

### Phase 4：Web 平台（約 1 週）

**目標**：Web 版可於 claude.ai 等分頁工作流中備用

交付項目：

- [ ] sqlite wasm 初始化
- [ ] 番茄鐘 Web 適配（Date.now 計算 + 分頁標題）
- [ ] Browser Notification 整合
- [ ] Google OAuth redirect flow
- [ ] PWA manifest
- [ ] 部署至 Vercel 或 Cloudflare Pages

### Phase 5：打磨（約 1 週）

- [ ] 全平台效能優化
- [ ] 邊緣情境處理（極大資料量、長期離線重連）
- [ ] 微互動與動畫調整
- [ ] 文件（使用者 README、開發者 CONTRIBUTING）

**預估總工期**：9 週

---

## 附錄 A：外部連結

- Flutter 官方：<https://flutter.dev>
- Drift 文件：<https://drift.simonbinder.eu>
- Supabase Flutter：<https://supabase.com/docs/reference/dart>
- Notion 設計參考：附件 DESIGN-notion.md

## 附錄 B：後續版本建議（不在本次範圍）

- 自然語言任務輸入（「明天下午 3 點開會」→ 自動填日期）
- AI 任務拆解（描述目標 → 拆成子任務建議）
- 專注模式
- 進階統計（熱力圖、趨勢分析）
- Markdown 支援任務描述
- 快捷片段（Snippets）
- Apple Watch 番茄鐘控制
- Windows Widgets 整合

## 附錄 C：待決定項目（下次 review 時需確認）

- 最終 app 名稱（目前暫用 DevFlow）
- 應用程式圖示與品牌主視覺
- Supabase 方案（Free / Pro，視使用量預估）
- 是否購買付費字型（NotionInter 商用需授權，本方案用 Inter 替代即可）
- App Store / Microsoft Store 發布策略

---

*文件結束 · DevFlow Tech Spec v1.0 · 2026-04-20*
