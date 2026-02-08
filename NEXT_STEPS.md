# 🚀 BƯỚC TIẾP THEO - Setup Apple Developer & Codemagic

## ✅ Đã Hoàn Thành:
- [x] Code pushed lên GitHub: https://github.com/tung1506/esim-project.git
- [x] `codemagic.yaml` đã được tạo
- [x] `pubspec.yaml` đã config đúng Git dependency

---

## 📋 CÒN 3 BƯỚC CHÍNH:

### **BƯỚC 1: Setup Apple Developer Portal** (15 phút)
### **BƯỚC 2: Setup Codemagic** (10 phút)
### **BƯỚC 3: Build & Download IPA** (15 phút)

---

## 🍎 BƯỚC 1: Setup Apple Developer Portal

### 1.1 Tạo App ID

1. Đăng nhập: https://developer.apple.com/account
2. Vào **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **+** (Add button)
4. Chọn **App IDs** → Click **Continue**
5. Chọn **App** → Click **Continue**
6. Điền thông tin:
   ```
   Description: eSIM WebView Host
   Bundle ID: Explicit
   Bundle ID: com.tung1506.esimwebviewhost
   ```
7. **Capabilities** (scroll xuống):
   - ☑️ Tất cả để mặc định
   - Không cần chọn thêm gì (trừ khi app cần)
8. Click **Continue** → **Register**

✅ **XONG! App ID đã tạo.**

---

### 1.2 Register Device (iPhone UDID)

#### Cách 1: Lấy UDID bằng Website (Dễ nhất)

1. **Trên iPhone**, mở **Safari** (phải là Safari, không dùng Chrome)
2. Truy cập: **https://www.udid.io/**
3. Click **"Tap to find UDID"**
4. Click **"Allow"** để cài profile
5. Vào **Settings** → **General** → **VPN & Device Management**
6. Tap vào **"UDID"** → **Install**
7. Nhập passcode
8. Click **Install** → **Install** → **Done**
9. Quay lại Safari, page sẽ show UDID
10. **COPY UDID** (dạng: `00008030-001A12B456C78D90`)

#### Cách 2: Lấy UDID bằng iTunes (Windows/Mac)

1. Cắm iPhone vào máy tính
2. Mở **iTunes**
3. Click vào **device icon**
4. Click vào **Serial Number** → sẽ đổi thành **UDID**
5. Right-click → **Copy**

#### Register UDID trên Apple Developer

1. Vào: https://developer.apple.com/account/resources/devices/list
2. Click **+** (Register Device)
3. Chọn Platform: **iOS**
4. Điền:
   ```
   Device Name: Tung iPhone 15
   Device ID (UDID): <paste UDID vừa copy>
   ```
5. Click **Continue** → **Register**

✅ **XONG! Device đã được register.**

---

### 1.3 Tạo App Store Connect API Key (Quan trọng nhất!)

1. Vào: **https://appstoreconnect.apple.com/access/api**
2. Click tab **Keys**
3. Click **+** (Generate API Key)
4. Điền:
   ```
   Name: Codemagic CI/CD
   Access: App Manager
   ```
5. Click **Generate**

6. **⚠️ QUAN TRỌNG - LƯU NGAY 3 THÔNG TIN:**

   **a) Key ID** (hiển thị trên table):
   ```
   Ví dụ: AB1CD2EF34
   ```
   
   **b) Issuer ID** (ở góc trên bên phải):
   ```
   Ví dụ: 12345678-1234-1234-1234-123456789012
   ```
   
   **c) Download Private Key** (file .p8):
   - Click **Download API Key**
   - Lưu file `AuthKey_AB1CD2EF34.p8`
   - **⚠️ CHỈ DOWNLOAD ĐƯỢC 1 LẦN DUY NHẤT!**

7. Lưu 3 thông tin vào notepad:
   ```
   Key ID: AB1CD2EF34
   Issuer ID: 12345678-1234-1234-1234-123456789012
   Private Key File: AuthKey_AB1CD2EF34.p8 (đã download)
   ```

✅ **XONG! API Key đã tạo và lưu.**

---

## ⚙️ BƯỚC 2: Setup Codemagic

### 2.1 Tạo Codemagic Account

1. Truy cập: https://codemagic.io/signup
2. Click **"Sign up with GitHub"**
3. Login GitHub
4. Click **"Authorize Codemagic"**

✅ Account created!

---

### 2.2 Add Application

1. Vào Codemagic Dashboard
2. Click **"Add application"**
3. Chọn **"GitHub"**
4. Tìm repository: **"tung1506/esim-project"**
5. Click repo → Click **"Finish: Add application"**

✅ App added!

---

### 2.3 Configure iOS Code Signing (Quan trọng!)

#### Option A: Automatic Code Signing (Khuyên dùng)

1. Trong app vừa add, vào tab **"Settings"**
2. Scroll xuống **"iOS code signing"**
3. Click **"Connect Apple Developer Portal"**
4. Paste 3 thông tin từ Bước 1.3:
   ```
   Issuer ID: <paste Issuer ID>
   Key ID: <paste Key ID>
   Private Key: <upload file .p8>
   ```
5. Click **"Save"**

Codemagic sẽ tự động:
- Tạo certificates
- Tạo provisioning profiles
- Manage signing cho bạn

✅ **iOS Code Signing configured!**

---

### 2.4 Configure Workflow

1. Vào tab **"Build"**
2. Codemagic sẽ tự detect `codemagic.yaml`
3. Chọn workflow: **"ios-workflow"**
4. Branch: **"master"**

✅ Ready to build!

---

## 🏗️ BƯỚC 3: Build & Download IPA

### 3.1 Start Build

1. Click **"Start new build"**
2. Hoặc: Push code lên Git sẽ tự động trigger build

### 3.2 Monitor Build (~10-15 phút)

Watch build logs:
- 🔵 **Blue**: Building...
- ✅ **Green**: Success!
- ❌ **Red**: Failed (check logs)

Build steps:
1. Clone repository ✓
2. Install Flutter ✓
3. Get dependencies ✓
4. Install pods ✓
5. Code signing ✓
6. Build IPA ✓
7. Archive artifacts ✓

### 3.3 Download IPA

Khi build **SUCCESS**:
1. Click vào build
2. Tab **"Artifacts"**
3. Download file: **`esim_webview_host.ipa`**

✅ **IPA downloaded!**

---

## 📱 BƯỚC 4: Install IPA lên iPhone

### Cách 1: Diawi (Easiest - Recommended)

1. Truy cập: **https://www.diawi.com**
2. **Drag & drop** file `.ipa` vào
3. Đợi upload (1-2 phút)
4. **Copy link** (dạng: `https://i.diawi.com/ABC123`)
5. **Mở link bằng Safari trên iPhone** (PHẢI là Safari!)
6. Click **"Install"**
7. Nhập passcode nếu cần
8. App bắt đầu install

**Trust Developer:**
1. Vào **Settings** → **General** → **VPN & Device Management**
2. Tap vào developer profile
3. Tap **"Trust"**
4. Confirm

✅ **App installed! Mở và test thôi!**

---

### Cách 2: TestFlight (Professional)

1. Upload IPA lên App Store Connect
2. Add internal testers (email)
3. Testers install qua TestFlight app

---

## ✅ CHECKLIST HOÀN CHỈNH

```
Apple Developer Portal:
☐ App ID created: com.tung1506.esimwebviewhost
☐ Device UDID registered
☐ API Key created (Issuer ID, Key ID, .p8 saved)

Codemagic:
☐ Account created (GitHub login)
☐ App added: esim-project
☐ Apple Developer Portal connected
☐ Code signing configured

Build & Deploy:
☐ Build triggered
☐ Build successful (green)
☐ IPA downloaded
☐ App installed on iPhone
☐ App tested (eSIM WebView works)
```

---

## 🚨 Troubleshooting

### Build Failed?

**1. Check Bundle ID**
```bash
# Verify Bundle ID khớp:
- Apple Developer: com.tung1506.esimwebviewhost
- codemagic.yaml: com.tung1506.esimwebviewhost
- project.pbxproj: com.tung1506.esimwebviewhost
```

**2. Check Device Registration**
- Device UDID phải được register trên Apple Developer Portal
- Provisioning profile phải include device đó

**3. Check API Key**
- Key ID, Issuer ID, .p8 file phải đúng
- Key chưa bị revoke

### Install Failed on iPhone?

**1. Must use Safari**
- Diawi links chỉ work với Safari
- Chrome/Firefox không install được

**2. Trust Developer**
- Settings → General → VPN & Device Management
- Trust profile

**3. Device Not Registered**
- Add UDID vào Apple Developer Portal
- Rebuild app

---

## 📞 Support

Nếu gặp vấn đề:
1. Check build logs trên Codemagic (có error message chi tiết)
2. Verify checklist trên
3. Google error message
4. Codemagic docs: https://docs.codemagic.io/

---

## 🎯 Expected Timeline

| Task | Time |
|------|------|
| Setup Apple Developer | 15 min |
| Setup Codemagic | 10 min |
| First build | 10-15 min |
| Install on iPhone | 5 min |
| **TOTAL** | **~45 min** |

---

## 💰 Cost

- **Apple Developer Program**: $99/year (required)
- **Codemagic Free Tier**: 
  - 500 build minutes/month (FREE)
  - Enough cho vài builds/tháng
- **Total**: $99/year only

---

**BẮT ĐẦU THÔI! LET'S DO THIS! 🚀**

---

## 📧 Lưu ý quan trọng

1. **Backup .p8 file** - Chỉ download được 1 lần!
2. **Lưu Key ID & Issuer ID** - Cần cho Codemagic
3. **Device UDID** - Phải register trước khi build
4. **Bundle ID** - Phải khớp ở mọi nơi

✅ Làm từng bước một, cẩn thận, sẽ thành công!
