# 🚀 Hướng Dẫn Build iOS App với Codemagic

## 📋 Prerequisites

- ✅ Apple Developer Account (đã có)
- ✅ GitHub/GitLab account
- ✅ Codemagic account (free tier OK)
- ✅ iOS device UDID

---

## PHẦN 1: Setup Apple Developer Account

### 1.1 Tạo App ID

1. Truy cập: https://developer.apple.com/account
2. Vào **Certificates, Identifiers & Profiles**
3. Click **Identifiers** → **➕ Add**
4. Chọn **App IDs** → Continue
5. Chọn **App** → Continue
6. Điền:
   ```
   Description: eSIM WebView Host
   Bundle ID: com.yourcompany.esimwebviewhost
   
   Capabilities (nếu cần):
   - App Groups
   - Push Notifications
   ```
7. Click **Continue** → **Register**

### 1.2 Register Device (để test trên device thật)

1. Lấy UDID của iPhone:
   - **Windows/Linux**: Dùng tool https://www.uniqueidentifier.net/
   - Hoặc cắm iPhone vào máy và dùng iTunes
   - Hoặc vào Settings → General → About → Copy UDID

2. Vào **Devices** → **➕ Add**
3. Chọn **iOS**
4. Điền:
   ```
   Device Name: My iPhone 15 Pro
   Device ID (UDID): xxxxx-xxxxx-xxxxx-xxxxx
   ```
5. Click **Continue** → **Register**

### 1.3 Tạo API Key cho Codemagic

**Đây là cách TỐT NHẤT** thay vì upload certificates manually:

1. Vào https://developer.apple.com/account
2. Click **Keys** (bên trái)
3. Click **➕** để tạo key mới
4. Điền:
   ```
   Key Name: Codemagic CI/CD
   Access: App Manager (chọn tất cả)
   ```
5. Click **Continue** → **Register**
6. **Download** key file (`.p8` file) - CHỈ DOWNLOAD ĐƯỢC 1 LẦN!
7. Lưu lại:
   - **Key ID**: `ABC123XYZ` (hiển thị trên trang)
   - **Issuer ID**: Vào Account → Membership → Copy Issuer ID
   - **Key file**: File `.p8` vừa download

⚠️ **LƯU Ý**: Không mất file `.p8`! Không download lại được!

---

## PHẦN 2: Chuẩn Bị Git Repository

### 2.1 Tạo Git Repository

#### Option A: Monorepo (Cả 2 projects trong 1 repo - RECOMMENDED)

```bash
cd /home/hungtv/stock/java/android

# Init git
git init
git add esim_webview_host flutter_esim codemagic.yaml
git commit -m "Initial commit with iOS Universal Link support"

# Tạo repo trên GitHub
# Vào https://github.com/new
# Tên repo: esim-webview-ios
# Public hoặc Private (Codemagic support cả 2)

# Push lên GitHub
git remote add origin https://github.com/YOUR_USERNAME/esim-webview-ios.git
git branch -M main
git push -u origin main
```

**File structure trên GitHub sẽ là:**
```
your-repo/
├── codemagic.yaml
├── esim_webview_host/
│   ├── pubspec.yaml
│   ├── ios/
│   └── lib/
└── flutter_esim/
    ├── pubspec.yaml
    ├── ios/
    └── lib/
```

#### Option B: Separate Repos (Nếu muốn tách riêng)

**1. Tạo repo cho flutter_esim:**
```bash
cd /home/hungtv/stock/java/android/flutter_esim
git init
git add .
git commit -m "flutter_esim SDK with iOS Universal Link"
git remote add origin https://github.com/YOUR_USERNAME/flutter_esim.git
git push -u origin main
```

**2. Update pubspec.yaml của esim_webview_host:**
```yaml
dependencies:
  flutter_esim:
    git:
      url: https://github.com/YOUR_USERNAME/flutter_esim.git
      ref: main
```

**3. Tạo repo cho esim_webview_host:**
```bash
cd /home/hungtv/stock/java/android/esim_webview_host
git init
git add .
git commit -m "eSIM WebView Host app"
git remote add origin https://github.com/YOUR_USERNAME/esim-webview-host.git
git push -u origin main
```

### 2.2 Update Bundle ID (nếu cần)

Nếu bạn đã đổi Bundle ID trên Apple Developer, cần update trong code:

**File: `esim_webview_host/ios/Runner.xcodeproj/project.pbxproj`**

Tìm và đổi:
```
PRODUCT_BUNDLE_IDENTIFIER = com.tung1506.esimwebviewhost;
```
Thành:
```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.esimwebviewhost;
```

Có 3 chỗ cần đổi (Debug, Profile, Release).

---

## PHẦN 3: Setup Codemagic

### 3.1 Tạo Codemagic Account

1. Truy cập: https://codemagic.io/signup
2. Đăng ký bằng GitHub account
3. Authorize Codemagic truy cập GitHub repos

### 3.2 Add Application

1. Click **Add application**
2. Chọn repository: `your-username/esim-webview-ios`
3. Click **Next**
4. Chọn project type: **Flutter App**
5. Click **Finish: Add application**

### 3.3 Configure iOS Code Signing (QUAN TRỌNG!)

#### Method 1: Automatic Code Signing (RECOMMENDED) ✅

1. Trong Codemagic app settings, vào **iOS code signing**
2. Click **Apple Developer Portal integration**
3. Click **Connect**
4. Điền thông tin:
   ```
   Issuer ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   Key ID: ABC123XYZ
   API Key: (upload file .p8)
   ```
5. Click **Save**
6. Codemagic sẽ tự động:
   - Tạo certificates
   - Tạo provisioning profiles
   - Manage signing

#### Method 2: Manual Code Signing (Phức tạp hơn)

**Nếu không dùng API Key**, bạn cần:

1. Tạo certificates trên Mac (hoặc dùng online tool)
2. Download provisioning profiles
3. Upload lên Codemagic

**❌ KHÔNG RECOMMEND** vì phức tạp và dễ lỗi.

### 3.4 Configure Workflow

1. Vào **Workflow settings**
2. **iOS code signing**:
   - Distribution type: **Ad Hoc** (để install trên device)
   - Bundle ID: `com.yourcompany.esimwebviewhost`
   - Provisioning profile: (Codemagic tự chọn nếu dùng automatic)

3. **Build arguments** (optional):
   ```
   --release
   --dart-define=FLAVOR=production
   ```

4. **Environment variables**:
   ```
   BUNDLE_ID = com.yourcompany.esimwebviewhost
   ```

### 3.5 Update codemagic.yaml

File đã được tạo sẵn, nhưng cần update:

**File: `codemagic.yaml`**
```yaml
workflows:
  ios-workflow:
    name: iOS Build
    max_build_duration: 60
    instance_type: mac_mini_m1
    
    environment:
      flutter: stable
      xcode: latest
      
      vars:
        # ⚠️ THAY ĐỔI BUNDLE ID
        BUNDLE_ID: "com.yourcompany.esimwebviewhost"
        APP_NAME: "eSIM WebView Host"
        
      # iOS code signing
      ios_signing:
        distribution_type: ad_hoc
        bundle_identifier: $BUNDLE_ID
        
    scripts:
      - name: Get dependencies
        script: |
          cd esim_webview_host
          flutter pub get
          
      - name: Install CocoaPods
        script: |
          cd esim_webview_host/ios
          pod install
          
      - name: Build IPA
        script: |
          cd esim_webview_host
          flutter build ipa --release
            
    artifacts:
      - esim_webview_host/build/ios/ipa/*.ipa
      
    publishing:
      email:
        recipients:
          - your.email@example.com  # ⚠️ THAY ĐỔI EMAIL
```

---

## PHẦN 4: Build iOS App

### 4.1 Trigger Build

**Method 1: Push code lên GitHub**
```bash
cd /home/hungtv/stock/java/android
git add .
git commit -m "Update Codemagic config"
git push
```
Codemagic sẽ tự động trigger build.

**Method 2: Manual trigger trên Codemagic**
1. Vào app trong Codemagic
2. Click **Start new build**
3. Chọn branch: `main`
4. Click **Start new build**

### 4.2 Monitor Build Progress

1. Vào **Build** tab
2. Xem real-time logs
3. Các bước:
   ```
   ✅ Clone repository
   ✅ Install Flutter
   ✅ flutter pub get
   ✅ pod install
   ✅ Code signing
   ✅ flutter build ipa
   ✅ Archive artifacts
   ```

### 4.3 Download IPA

Sau khi build thành công:

1. Click vào build
2. Scroll xuống **Artifacts**
3. Click **Download** file `.ipa`

**File IPA path:**
```
esim_webview_host.ipa
```

---

## PHẦN 5: Install IPA lên iPhone

### 5.1 Dùng Testflight (Recommended)

Nếu muốn deploy lên TestFlight:

**Update codemagic.yaml:**
```yaml
ios_signing:
  distribution_type: app_store  # Đổi từ ad_hoc
  
publishing:
  app_store_connect:
    api_key: $APP_STORE_CONNECT_KEY_IDENTIFIER
    submit_to_testflight: true
```

### 5.2 Dùng Diawi (Online Tool)

1. Truy cập: https://www.diawi.com/
2. Upload file `.ipa`
3. Copy link download
4. Mở link trên iPhone Safari
5. Click **Install**

### 5.3 Dùng iTunes/Finder (có Mac)

1. Kết nối iPhone với Mac
2. Mở Finder
3. Drag & drop file `.ipa` vào device

### 5.4 Dùng Xcode (có Mac)

1. Kết nối iPhone
2. Xcode → Window → Devices and Simulators
3. Click vào device
4. Click **➕** ở Installed Apps
5. Select file `.ipa`

### 5.5 Dùng AltStore (Windows/Mac)

1. Download AltStore: https://altstore.io/
2. Install AltServer trên PC
3. Connect iPhone qua USB
4. Install AltStore lên iPhone
5. Open AltStore trên iPhone
6. Import file `.ipa`

⚠️ **Lưu ý**: App sẽ expire sau 7 ngày (với free Apple Developer) hoặc 1 năm (với paid).

---

## PHẦN 6: Troubleshooting

### ❌ Error: "Provisioning profile doesn't include signing certificate"

**Fix:**
1. Vào Codemagic → iOS code signing
2. Re-generate certificates
3. Download lại provisioning profiles
4. Rebuild

### ❌ Error: "Bundle identifier doesn't match"

**Fix:**
1. Check Bundle ID trong:
   - Apple Developer portal
   - `project.pbxproj`
   - `codemagic.yaml`
2. Phải giống nhau 100%

### ❌ Error: "Device not registered"

**Fix:**
1. Vào Apple Developer → Devices
2. Add device UDID
3. Regenerate provisioning profile
4. Rebuild

### ❌ Error: "flutter_esim not found"

**Fix:**
- **Monorepo**: Check relative path trong `pubspec.yaml`: `path: ../flutter_esim`
- **Separate repo**: Check git URL và ref

### ❌ Error: "CocoaPods install failed"

**Fix:**
```yaml
scripts:
  - name: Update CocoaPods
    script: |
      cd esim_webview_host/ios
      pod repo update
      pod install
```

### ❌ Error: "Xcode build failed"

**Fix:**
1. Check Xcode version trong `codemagic.yaml`
2. Kiểm tra iOS deployment target
3. Check dependencies compatibility

---

## 📊 Build Time & Costs

### Free Tier (Codemagic)
- ✅ 500 build minutes/month
- ✅ Concurrent builds: 1
- ✅ macOS M1 instances
- ✅ Unlimited apps

### Typical Build Time
- First build: ~10-15 minutes
- Subsequent builds: ~5-8 minutes (cached dependencies)

### Cost Estimate
- Free tier: $0 (đủ cho testing)
- Paid tier: $95/month (unlimited builds)

---

## 🎯 Best Practices

1. ✅ **Use API Key** thay vì manual certificates
2. ✅ **Use monorepo** nếu flutter_esim chưa public
3. ✅ **Version control** codemagic.yaml
4. ✅ **Test locally** trước khi push (nếu có Mac)
5. ✅ **Use environment variables** cho sensitive data
6. ✅ **Enable notifications** (email/Slack)
7. ✅ **Tag releases** trên Git cho production builds

---

## 📝 Checklist

### Before Build:
- [ ] Apple Developer account ready
- [ ] API Key created & downloaded (.p8 file)
- [ ] Device UDID registered
- [ ] Git repository created
- [ ] Code pushed to GitHub
- [ ] Codemagic account created
- [ ] Bundle ID updated everywhere
- [ ] codemagic.yaml configured

### During Build:
- [ ] Monitor build logs
- [ ] Check for errors
- [ ] Wait for artifacts

### After Build:
- [ ] Download IPA file
- [ ] Install on device (Diawi/AltStore/TestFlight)
- [ ] Test app functionality
- [ ] Test eSIM installation (iOS Universal Link)

---

## 🔗 Useful Links

- **Apple Developer**: https://developer.apple.com/account
- **Codemagic**: https://codemagic.io
- **Diawi**: https://www.diawi.com (install IPA online)
- **AltStore**: https://altstore.io (install IPA on Windows)
- **UDID Finder**: https://www.uniqueidentifier.net

---

## 📞 Support

Nếu gặp vấn đề:
1. Check build logs trên Codemagic
2. Check troubleshooting section
3. Codemagic docs: https://docs.codemagic.io
4. GitHub Issues của project

---

**Good luck! 🚀**

**Estimated time**: 1-2 hours (first time setup)  
**Difficulty**: Medium  
**Prerequisites**: Apple Developer account ($99/year)
