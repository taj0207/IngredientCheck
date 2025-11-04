# 📸 相機功能使用指南

## 已創建的文件

我們新增了 3 個文件來實現相機拍照功能：

### 1. **CameraManager.swift**
相機管理器，處理權限和狀態

### 2. **ImagePicker.swift**
UIImagePickerController 的 SwiftUI 包裝器

### 3. **CameraScanView_Updated.swift**
更新後的掃描頁面（含相機功能）

---

## 📋 如何使用

### 步驟 1: 替換舊文件

將 `CameraScanView_Updated.swift` 的內容複製到 `CameraScanView.swift`：

```bash
# 在專案目錄執行
cp IngredientCheck/Presentation/Screens/Camera/CameraScanView_Updated.swift \
   IngredientCheck/Presentation/Screens/Camera/CameraScanView.swift
```

或者在 Xcode 中：
1. 打開 `CameraScanView_Updated.swift`
2. 全選內容 (Cmd + A)
3. 複製 (Cmd + C)
4. 打開 `CameraScanView.swift`
5. 全選 (Cmd + A) 並貼上 (Cmd + V)

### 步驟 2: 確認權限設定

確保 `Info.plist` 包含相機權限說明（我們已經添加了）：

```xml
<key>NSCameraUsageDescription</key>
<string>IngredientCheck needs access to your camera to scan ingredient labels.</string>
```

### 步驟 3: 在 Xcode 中添加新文件

將新文件加入專案：
1. 右鍵點擊 `Presentation/Common/Components/` 資料夾
2. 選擇 "Add Files to IngredientCheck..."
3. 選擇 `CameraManager.swift` 和 `ImagePicker.swift`
4. 勾選 "Copy items if needed" 和目標 target

---

## 🎯 工作流程

```
用戶點擊 "Take Photo"
    ↓
【CameraButton】檢查相機可用性
    ↓
【CameraManager】檢查/請求權限
    ↓
權限已授予？
├─ Yes → 顯示系統相機界面 (UIImagePickerController)
└─ No  → 顯示錯誤 Alert（含"打開設定"按鈕）
    ↓
用戶拍照並確認
    ↓
【ImagePicker.Coordinator】接收圖片
    ↓
【CameraScanViewModel】處理圖片
    ↓
OCR + ECHA 查詢
    ↓
顯示結果
```

---

## 🔑 關鍵代碼解析

### 1. CameraManager - 權限處理

```swift
class CameraManager: ObservableObject {
    @Published var showCamera = false
    @Published var cameraError: CameraError?

    func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        }
    }

    func requestCameraAndShow() async {
        let hasPermission = await checkCameraPermission()

        if hasPermission {
            showCamera = true
        } else {
            cameraError = .permissionDenied
            showError = true
        }
    }
}
```

**作用:**
- ✅ 檢查相機權限狀態
- ✅ 請求權限（如果尚未決定）
- ✅ 處理被拒絕的情況
- ✅ 發布 UI 更新事件

### 2. ImagePicker - UIKit 橋接

```swift
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType  // .camera 或 .photoLibrary
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType

        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear  // 使用後置相機
        }

        return picker
    }

    class Coordinator: UIImagePickerControllerDelegate {
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image  // 傳回圖片
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
```

**作用:**
- ✅ 將 UIKit 的 UIImagePickerController 包裝成 SwiftUI View
- ✅ 使用 Coordinator 模式處理 delegate 回調
- ✅ 支援相機和相簿兩種來源

### 3. CameraButton - 組合組件

```swift
struct CameraButton: View {
    @ObservedObject var cameraManager: CameraManager
    let action: (UIImage) -> Void

    var body: some View {
        Button(action: {
            Task {
                await cameraManager.requestCameraAndShow()
            }
        }) {
            Label("Take Photo", systemImage: "camera.fill")
        }
        .fullScreenCover(isPresented: $cameraManager.showCamera) {
            ImagePicker(sourceType: .camera, selectedImage: $cameraManager.capturedImage)
        }
        .onChange(of: cameraManager.capturedImage) { newImage in
            if let image = newImage {
                action(image)  // 執行回調
            }
        }
        .alert("Camera Error", isPresented: $cameraManager.showError) {
            if cameraManager.cameraError == .permissionDenied {
                Button("Open Settings") {
                    // 打開系統設定頁面
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                }
            }
        }
    }
}
```

**作用:**
- ✅ 完整的相機按鈕組件
- ✅ 自動處理權限請求
- ✅ 顯示相機界面
- ✅ 錯誤處理（含"打開設定"功能）
- ✅ 執行用戶提供的回調

---

## 🔄 完整使用流程

### 在 CameraScanView 中使用

```swift
struct CameraScanView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var viewModel: CameraScanViewModel

    var body: some View {
        // ...

        CameraButton(cameraManager: cameraManager) { image in
            Task {
                await viewModel.processImage(image)
            }
        }
    }
}
```

**執行順序:**
1. 用戶點擊按鈕
2. `cameraManager.requestCameraAndShow()` 執行
3. 檢查權限 → 請求權限（如果需要）
4. 權限通過 → `showCamera = true`
5. `.fullScreenCover` 觸發，顯示 `ImagePicker`
6. 用戶拍照 → `UIImagePickerController` delegate 回調
7. `capturedImage` 更新
8. `.onChange` 觸發，執行回調 `viewModel.processImage(image)`
9. OCR 和 ECHA 查詢開始

---

## 📱 實際使用體驗

### 首次使用（無權限）

```
用戶: 點擊 "Take Photo"
App:  顯示系統權限對話框
      "IngredientCheck would like to access the camera"
      [Don't Allow] [OK]

用戶: 點擊 OK
App:  顯示相機界面

用戶: 拍照
App:  處理中... (顯示 loading)
      → 顯示結果
```

### 權限被拒絕

```
用戶: 點擊 "Take Photo"
App:  顯示 Alert
      "Camera Error"
      "Camera permission was denied. Please enable it in Settings."
      [OK] [Open Settings]

用戶: 點擊 "Open Settings"
App:  打開系統設定 → IngredientCheck → 相機權限
```

### 再次使用（已有權限）

```
用戶: 點擊 "Take Photo"
App:  直接顯示相機界面（無需再次請求權限）
```

---

## 🛠️ 相機設定

### 自定義相機選項

在 `ImagePicker.makeUIViewController()` 中：

```swift
// 切換前/後置相機
picker.cameraDevice = .rear  // 或 .front

// 允許編輯（裁剪、旋轉）
picker.allowsEditing = true

// 隱藏相機控制項（需自訂 UI）
picker.showsCameraControls = false

// 設定閃光燈模式
picker.cameraFlashMode = .auto  // 或 .on, .off
```

### 支援視頻拍攝

```swift
picker.mediaTypes = [
    UTType.image.identifier,
    UTType.movie.identifier  // 支援視頻
]
picker.cameraCaptureMode = .video
```

---

## ⚠️ 常見問題

### 1. 模擬器無法使用相機

**問題:** iOS 模擬器不支援相機硬體

**解決:**
```swift
// CameraManager 自動檢查
func isCameraAvailable() -> Bool {
    UIImagePickerController.isSourceTypeAvailable(.camera)
}

// 模擬器會返回 false，顯示錯誤訊息
```

**測試:** 使用真實 iOS 設備或選擇相簿圖片

### 2. 權限被拒絕後無法再次請求

**問題:** iOS 不允許 app 多次請求同一權限

**解決:** 提供"打開設定"按鈕（已實作）

```swift
Button("Open Settings") {
    if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
    }
}
```

### 3. 拍照後圖片方向錯誤

**問題:** UIImage 的 `orientation` 屬性可能不正確

**解決:**
```swift
extension UIImage {
    func fixOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return normalizedImage ?? self
    }
}

// 在處理前修正
let fixedImage = capturedImage.fixOrientation()
await viewModel.processImage(fixedImage)
```

---

## 🎨 進階: 自定義相機 UI (AVFoundation)

如果需要完全自定義的相機界面（取代系統相機），可以使用 AVFoundation：

```swift
import AVFoundation

class CustomCameraView: UIViewController {
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()

    override func viewDidLoad() {
        super.viewDidLoad()

        // 配置相機會話
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }

        captureSession.addInput(input)
        captureSession.addOutput(photoOutput)

        // 顯示預覽
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}
```

但對於我們的需求，**UIImagePickerController 已經足夠**！

---

## ✅ 總結

### 已實現功能

✅ 相機拍照
✅ 權限檢查
✅ 權限請求
✅ 錯誤處理
✅ 打開系統設定
✅ 相簿選圖（原有功能）
✅ OCR 處理
✅ 結果顯示

### 使用步驟

1. 替換 `CameraScanView.swift`
2. 添加 `CameraManager.swift` 和 `ImagePicker.swift` 到專案
3. 在真實設備上測試
4. 完成！

### 測試清單

- [ ] 首次打開相機（權限請求）
- [ ] 拍照並確認
- [ ] 取消拍照
- [ ] 權限被拒絕後的錯誤處理
- [ ] 打開設定按鈕功能
- [ ] OCR 識別準確度
- [ ] 相簿選圖仍可正常使用

---

需要任何協助或有問題嗎？歡迎詢問！ 🚀
