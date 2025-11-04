# IngredientCheck Setup Guide

## 快速開始指南

### 步驟 1: 創建 Secrets.swift

1. 複製範本文件：
```bash
cp IngredientCheck/Core/Configuration/Secrets.swift.example IngredientCheck/Core/Configuration/Secrets.swift
```

2. 編輯 `Secrets.swift` 並填入您的 API 金鑰：
```swift
enum Secrets {
    static let openAIAPIKey = "sk-proj-YOUR_ACTUAL_KEY_HERE"
    static let googleOAuthClientID: String? = nil
}
```

### 步驟 2: 獲取 OpenAI API Key

1. 訪問 https://platform.openai.com/api-keys
2. 登入或註冊 OpenAI 帳號
3. 點擊 "Create new secret key"
4. 複製 API key (格式: `sk-proj-...`)
5. 貼到 `Secrets.swift` 的 `openAIAPIKey` 中

### 步驟 3: 創建 Xcode 專案

由於我們用的是 Swift Package Manager，需要創建 Xcode 專案：

**方式 A: 使用 Xcode (推薦)**

1. 打開 Xcode
2. File → New → Project
3. 選擇 "iOS" → "App"
4. 填寫資訊：
   - Product Name: `IngredientCheck`
   - Organization Identifier: `com.yourname` (您的唯一識別符)
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: **None**
5. 儲存到 `D:/github/taj0207/IngredientCheck` 資料夾
6. 刪除 Xcode 自動生成的以下文件（我們已經創建好了）：
   - `IngredientCheckApp.swift`
   - `ContentView.swift`
   - `Assets.xcassets` (保留但可能需要合併)

**方式 B: 手動創建專案配置**

如果您熟悉 Xcode 專案結構，可以手動創建 `.xcodeproj` 文件。

### 步驟 4: 添加文件到 Xcode 專案

1. 在 Xcode 的 Project Navigator 中，刪除自動生成的文件
2. 右鍵點擊 `IngredientCheck` 資料夾
3. 選擇 "Add Files to IngredientCheck..."
4. 選擇我們創建的所有資料夾：
   - `App/`
   - `Core/`
   - `Domain/`
   - `Data/`
   - `Services/`
   - `Presentation/`
   - `DependencyInjection/`
   - `Resources/`
5. 確保勾選 "Create groups" 和 "Add to target: IngredientCheck"

### 步驟 5: 配置專案設定

在 Xcode 的 Project Settings 中：

1. **General Tab:**
   - Minimum Deployments: iOS 16.0
   - Bundle Identifier: com.yourname.IngredientCheck

2. **Build Settings:**
   - Swift Language Version: Swift 5

3. **Info Tab:**
   - 確認已添加相機和相簿權限說明

### 步驟 6: 建置和運行

```bash
# 使用 Xcode
Cmd + R (Run)

# 或使用命令列
xcodebuild -scheme IngredientCheck \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  build
```

## 專案結構

```
IngredientCheck/
├── App/                          # App 入口點
│   └── IngredientCheckApp.swift
├── Core/                         # 核心配置和工具
│   ├── Configuration/
│   │   ├── Environment.swift
│   │   ├── APIConfig.swift
│   │   ├── FeatureFlags.swift
│   │   └── Secrets.swift        # ⚠️ 需要手動創建！
│   └── Utilities/
│       ├── Logger.swift
│       └── Constants.swift
├── Domain/                       # 領域模型和協議
│   ├── Models/
│   │   ├── Ingredient.swift
│   │   ├── SafetyInfo.swift
│   │   ├── ScanResult.swift
│   │   └── User.swift
│   └── Protocols/
│       ├── Services/
│       └── Repositories/
├── Data/                         # 數據層
│   ├── DataSources/
│   │   └── Remote/
│   │       ├── NetworkClient.swift
│   │       ├── LLMOCRClient.swift     # GPT-5-mini OCR
│   │       └── ECHAAPIClient.swift    # ECHA 安全資料庫
│   └── Repositories/
│       ├── IngredientRepositoryImpl.swift
│       └── UserRepositoryImpl.swift
├── Services/                     # 業務邏輯層
│   ├── OCRServiceImpl.swift
│   ├── IngredientServiceImpl.swift
│   └── AuthenticationServiceImpl.swift
├── Presentation/                 # UI 層
│   └── Screens/
│       ├── Home/
│       │   ├── HomeView.swift
│       │   └── HomeViewModel.swift
│       └── Camera/
│           ├── CameraScanView.swift
│           └── CameraScanViewModel.swift
├── DependencyInjection/
│   └── DIContainer.swift         # 依賴注入容器
└── Resources/
    └── Info.plist

```

## 功能特性

✅ **已實作:**
- GPT-5-mini OCR 成分提取
- ECHA 安全資料庫整合
- Repository Pattern (易於遷移到後端)
- MVVM 架構
- SwiftUI UI
- 本地快取
- 掃描歷史記錄
- 匿名登入

⏳ **待實作 (TODO):**
- 相機拍照功能 (目前只支援相簿選圖)
- Sign in with Apple
- Google Sign In
- 本地化 (繁體中文/英文)
- 分享功能
- 成分詳情頁面

## 使用流程

1. **啟動 App** → 自動匿名登入
2. **首頁** → 查看最近掃描記錄
3. **掃描** → 選擇圖片 → 等待分析
4. **查看結果** → 成分列表 + 安全評級
5. **歷史記錄** → 查看所有掃描

## 成本估算

使用 GPT-5-mini OCR:
- **每次掃描**: ~$0.001 (0.1¢)
- **每月 1000 次掃描**: ~$1
- **ECHA API**: 免費

## 疑難排解

### 編譯錯誤: "Cannot find 'Secrets' in scope"
→ 您忘記創建 `Secrets.swift` 文件。請參考步驟 1。

### 運行時錯誤: "Invalid API key"
→ 檢查您的 OpenAI API key 是否正確填入 `Secrets.swift`

### OCR 返回空結果
→ 確保圖片清晰，成分列表可讀

### ECHA 資料找不到
→ 某些成分可能沒有在 ECHA 資料庫中註冊，這是正常的

## 後續開發

當需要添加後端時：

1. 修改 `FeatureFlags.swift`:
```swift
static var useBackend = true
```

2. 實作 `BackendIngredientRepository` (實作 `IngredientRepositoryProtocol`)

3. 更新 `DIContainer.swift`:
```swift
lazy var ingredientRepository: IngredientRepositoryProtocol = {
    if FeatureFlags.useBackend {
        return BackendIngredientRepository()
    } else {
        return DirectECHARepository()
    }
}()
```

**ViewModels 和 Views 完全不需要修改！** ✨

## 資源

- [OpenAI API 文檔](https://platform.openai.com/docs)
- [ECHA API 文檔](https://echa.europa.eu/support/diss-dissemination-platform)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [CLAUDE.md](./CLAUDE.md) - 詳細架構文檔

## 技術支援

遇到問題？檢查：
1. [CLAUDE.md](./CLAUDE.md) - 架構說明
2. [README.md](./README.md) - 專案概覽
3. GitHub Issues
