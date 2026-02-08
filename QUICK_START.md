# ⚡ Quick Start - Build iOS với Codemagic

## TL;DR - 5 Bước Chính

### 1️⃣ Apple Developer Setup (15 phút)

```
1. Vào https://developer.apple.com/account
2. Tạo App ID: com.yourcompany.esimwebviewhost
3. Register device (lấy UDID từ iPhone)
4. Tạo API Key:
   - Keys → Add (+)
   - Name: "Codemagic CI"
   - Access: App Manager
   - Download file .p8
   - Lưu: Key ID, Issuer ID, .p8 file
```

### 2️⃣ Push Code lên GitHub (5 phút)

```bash
cd /home/hungtv/stock/java/android

# Init git (nếu chưa có)
git init
git add .
git commit -m "Initial commit"

# Tạo repo trên GitHub: https://github.com/new
# Tên repo: esim-webview-ios

# Push
git remote add origin https://github.com/YOUR_USERNAME/esim-webview-ios.git
git push -u origin main
```

### 3️⃣ Setup Codemagic (10 phút)

```
1. Đăng ký: https://codemagic.io/signup (dùng GitHub account)
2. Add application → Chọn repo vừa tạo
3. iOS code signing:
   - Connect Apple Developer Portal
   - Paste: Issuer ID, Key ID
   - Upload: .p8 file
   - Save
4. Done! Codemagic tự quản lý certificates
```

### 4️⃣ Update Config (2 phút)

**File: `codemagic.yaml`** (đã tạo sẵn)

Chỉnh 2 chỗ:
```yaml
vars:
  BUNDLE_ID: "com.yourcompany.esimwebviewhost"  # ← Đổi Bundle ID

publishing:
  email:
    recipients:
      - your.email@example.com  # ← Đổi email
```

Commit & push:
```bash
git add codemagic.yaml
git commit -m "Update Codemagic config"
git push
```

### 5️⃣ Build & Download (15 phút)

```
1. Codemagic tự động build sau khi push
2. Hoặc: Click "Start new build" trên Codemagic
3. Đợi build xong (~10-15 phút)
4. Download file .ipa từ Artifacts
5. Install lên iPhone:
   - Dùng Diawi: https://www.diawi.com
   - Upload .ipa → Copy link → Mở trên iPhone Safari
```

---

## 📋 Checklist Nhanh

### Apple Developer:
- [ ] App ID created
- [ ] Device UDID registered
- [ ] API Key created (.p8 downloaded)
- [ ] Issuer ID & Key ID copied

### GitHub:
- [ ] Repo created
- [ ] Code pushed
- [ ] codemagic.yaml có trong repo

### Codemagic:
- [ ] Account created
- [ ] App added
- [ ] Apple Developer Portal connected
- [ ] Build triggered

### Result:
- [ ] Build successful
- [ ] .ipa file downloaded
- [ ] App installed on iPhone
- [ ] eSIM feature tested

---

## 🚨 Common Errors

| Error | Fix |
|-------|-----|
| Bundle ID mismatch | Check: Apple Dev Portal, project.pbxproj, codemagic.yaml phải giống nhau |
| Device not registered | Add UDID trên Apple Developer → Devices |
| flutter_esim not found | Push cả 2 folders: `esim_webview_host` và `flutter_esim` lên Git |
| Provisioning profile error | Reconnect Apple Developer Portal trên Codemagic |

---

## 📁 File Structure (trên GitHub)

```
your-repo/
├── codemagic.yaml          ← Build config
├── CODEMAGIC_SETUP_GUIDE.md ← Full guide
├── QUICK_START.md          ← File này
├── esim_webview_host/      ← Main app
│   ├── pubspec.yaml
│   ├── ios/
│   └── lib/
└── flutter_esim/           ← SDK
    ├── pubspec.yaml
    ├── ios/
    └── lib/
```

---

## 🎯 Expected Timeline

| Task | Time |
|------|------|
| Apple Developer setup | 15 min |
| Git setup & push | 5 min |
| Codemagic account | 10 min |
| Update config | 2 min |
| First build | 10-15 min |
| **Total** | **~45 min** |

---

## 💰 Cost

- **Apple Developer**: $99/year (required)
- **Codemagic Free Tier**: $0 (500 build minutes/month)
- **Total**: $99/year

---

## 📞 Need Help?

1. Read full guide: `CODEMAGIC_SETUP_GUIDE.md`
2. Check build logs on Codemagic
3. Codemagic docs: https://docs.codemagic.io/flutter-code-signing/ios-code-signing/

---

**Ready? Let's go! 🚀**
