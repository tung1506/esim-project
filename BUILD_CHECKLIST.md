# ✅ BUILD iOS APP - VISUAL CHECKLIST

```
┌─────────────────────────────────────────────────────────────┐
│  🎯 MỤC TIÊU: Build file .ipa và cài lên iPhone            │
│  ⏱️  THỜI GIAN: ~45 phút                                     │
│  💰 CHI PHÍ: $99/năm (Apple Developer)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## 📋 PHASE 1: Apple Developer Portal (15 phút)

```
┌──────────────────────────────────────────────────────┐
│ 1️⃣  TẠO APP ID                                        │
└──────────────────────────────────────────────────────┘
   📍 URL: https://developer.apple.com/account
   
   Steps:
   ☐ Login → Certificates, Identifiers & Profiles
   ☐ Identifiers → + (Add)
   ☐ App IDs → Continue → App → Continue
   ☐ Description: eSIM WebView Host
   ☐ Bundle ID: com.tung1506.esimwebviewhost
   ☐ Continue → Register
   
   ✅ App ID Created!

┌──────────────────────────────────────────────────────┐
│ 2️⃣  REGISTER DEVICE (Get UDID)                       │
└──────────────────────────────────────────────────────┘
   📱 On iPhone (Safari only):
   
   Steps:
   ☐ Open Safari → https://www.udid.io/
   ☐ Tap "Tap to find UDID"
   ☐ Allow → Install profile
   ☐ Settings → General → VPN & Device Management
   ☐ Tap UDID → Install → Enter passcode
   ☐ Copy UDID (00008030-...)
   
   💻 On Apple Developer:
   ☐ Devices → + (Add)
   ☐ Platform: iOS
   ☐ Device Name: Tung iPhone
   ☐ Device ID: <paste UDID>
   ☐ Continue → Register
   
   ✅ Device Registered!

┌──────────────────────────────────────────────────────┐
│ 3️⃣  CREATE API KEY (Most Important!)                 │
└──────────────────────────────────────────────────────┘
   📍 URL: https://appstoreconnect.apple.com/access/api
   
   Steps:
   ☐ Keys → + (Generate API Key)
   ☐ Name: Codemagic CI/CD
   ☐ Access: App Manager
   ☐ Generate
   
   ⚠️  SAVE IMMEDIATELY (can't retrieve later):
   ☐ Key ID: _________________ (e.g., AB1CD2EF34)
   ☐ Issuer ID: _________________ (top right corner)
   ☐ Download .p8 file → Save securely!
   
   ✅ API Key Created & Saved!
```

---

## ⚙️ PHASE 2: Codemagic Setup (10 phút)

```
┌──────────────────────────────────────────────────────┐
│ 4️⃣  CREATE CODEMAGIC ACCOUNT                         │
└──────────────────────────────────────────────────────┘
   📍 URL: https://codemagic.io/signup
   
   Steps:
   ☐ Click "Sign up with GitHub"
   ☐ Login GitHub
   ☐ Authorize Codemagic
   
   ✅ Account Created!

┌──────────────────────────────────────────────────────┐
│ 5️⃣  ADD APPLICATION                                  │
└──────────────────────────────────────────────────────┘
   Steps:
   ☐ Dashboard → Add application
   ☐ Select: GitHub
   ☐ Find: tung1506/esim-project
   ☐ Click repo → Finish: Add application
   
   ✅ App Added!

┌──────────────────────────────────────────────────────┐
│ 6️⃣  CONFIGURE CODE SIGNING                          │
└──────────────────────────────────────────────────────┘
   Steps:
   ☐ App → Settings → iOS code signing
   ☐ Click "Connect Apple Developer Portal"
   ☐ Paste Issuer ID: _________________
   ☐ Paste Key ID: _________________
   ☐ Upload .p8 file
   ☐ Save
   
   ⏳ Codemagic will:
   • Create certificates
   • Create provisioning profiles
   • Manage signing automatically
   
   ✅ Code Signing Configured!
```

---

## 🏗️ PHASE 3: Build & Deploy (15 phút)

```
┌──────────────────────────────────────────────────────┐
│ 7️⃣  START BUILD                                      │
└──────────────────────────────────────────────────────┘
   Steps:
   ☐ App → Build tab
   ☐ Workflow: ios-workflow
   ☐ Branch: master
   ☐ Click "Start new build"
   
   ⏳ Building... (~10-15 minutes)
   
   Build Progress:
   🔵 Clone repository
   🔵 Setup Flutter
   🔵 Get dependencies
   🔵 Install pods
   🔵 Code signing
   🔵 Build IPA
   🔵 Archive
   
   ✅ Build Successful! (Green checkmark)
   ❌ Build Failed? (Check logs)

┌──────────────────────────────────────────────────────┐
│ 8️⃣  DOWNLOAD IPA                                     │
└──────────────────────────────────────────────────────┘
   Steps:
   ☐ Click on build
   ☐ Artifacts tab
   ☐ Download: esim_webview_host.ipa
   
   ✅ IPA Downloaded!
```

---

## 📱 PHASE 4: Install on iPhone (5 phút)

```
┌──────────────────────────────────────────────────────┐
│ 9️⃣  UPLOAD TO DIAWI                                  │
└──────────────────────────────────────────────────────┘
   📍 URL: https://www.diawi.com
   
   Steps:
   ☐ Drag & drop .ipa file
   ☐ Wait for upload (1-2 min)
   ☐ Copy link: https://i.diawi.com/ABC123
   
   ✅ Upload Complete!

┌──────────────────────────────────────────────────────┐
│ 🔟 INSTALL ON IPHONE                                 │
└──────────────────────────────────────────────────────┘
   📱 On iPhone (Safari only!):
   
   Steps:
   ☐ Open Safari (NOT Chrome!)
   ☐ Paste Diawi link
   ☐ Click "Install"
   ☐ Enter passcode if needed
   ☐ Wait for installation
   
   Trust Developer:
   ☐ Settings → General
   ☐ VPN & Device Management
   ☐ Tap developer profile
   ☐ Trust → Confirm
   
   ✅ App Installed!
   
┌──────────────────────────────────────────────────────┐
│ ✅ OPEN APP & TEST                                    │
└──────────────────────────────────────────────────────┘
   Steps:
   ☐ Find app on home screen
   ☐ Open app
   ☐ Test eSIM WebView feature
   ☐ Test Universal Link (iOS)
   
   ✅ SUCCESS! 🎉
```

---

## 🔍 VERIFICATION CHECKLIST

```
BEFORE BUILD:
☐ Bundle ID khớp:
  - Apple Dev: com.tung1506.esimwebviewhost
  - codemagic.yaml: com.tung1506.esimwebviewhost
  - Xcode project: com.tung1506.esimwebviewhost
  
☐ Device registered (UDID added)
☐ API Key saved (Key ID, Issuer ID, .p8)
☐ Code pushed to Git
☐ codemagic.yaml exists in repo

DURING BUILD:
☐ Build logs show no errors
☐ Code signing successful
☐ IPA created in artifacts

AFTER BUILD:
☐ IPA downloaded
☐ Diawi link created
☐ App installed on iPhone
☐ Developer trusted
☐ App opens successfully
☐ eSIM feature works
```

---

## 🚨 TROUBLESHOOTING

```
ERROR: "No matching provisioning profile"
FIX: 
  ☐ Re-connect Apple Developer Portal on Codemagic
  ☐ Verify device UDID is registered
  ☐ Check Bundle ID matches everywhere

ERROR: "Code signing failed"
FIX:
  ☐ Verify API Key is correct (Key ID, Issuer ID, .p8)
  ☐ Check key hasn't been revoked
  ☐ Re-upload credentials on Codemagic

ERROR: "flutter_esim not found"
FIX:
  ☐ Verify pubspec.yaml Git dependency is correct
  ☐ Check repo contains both folders
  ☐ Run `flutter pub get` locally to test

ERROR: "Can't install on iPhone"
FIX:
  ☐ MUST use Safari (not Chrome!)
  ☐ Trust developer profile in Settings
  ☐ Check device UDID was registered before build
```

---

## 📊 PROGRESS TRACKER

```
╔═══════════════════════════════════════════════════╗
║  PHASE 1: Apple Developer Portal          [0/3]  ║
╠═══════════════════════════════════════════════════╣
║  ☐ 1. Create App ID                              ║
║  ☐ 2. Register Device (UDID)                     ║
║  ☐ 3. Create API Key                             ║
╠═══════════════════════════════════════════════════╣
║  PHASE 2: Codemagic Setup                 [0/3]  ║
╠═══════════════════════════════════════════════════╣
║  ☐ 4. Create Account                             ║
║  ☐ 5. Add Application                            ║
║  ☐ 6. Configure Code Signing                     ║
╠═══════════════════════════════════════════════════╣
║  PHASE 3: Build & Deploy                  [0/2]  ║
╠═══════════════════════════════════════════════════╣
║  ☐ 7. Start Build                                ║
║  ☐ 8. Download IPA                               ║
╠═══════════════════════════════════════════════════╣
║  PHASE 4: Install on iPhone               [0/2]  ║
╠═══════════════════════════════════════════════════╣
║  ☐ 9. Upload to Diawi                            ║
║  ☐ 10. Install & Test                            ║
╚═══════════════════════════════════════════════════╝

OVERALL PROGRESS: [0/10] 0%
```

---

## 🎯 QUICK LINKS

```
Apple Developer:
→ https://developer.apple.com/account

App Store Connect API:
→ https://appstoreconnect.apple.com/access/api

Get iPhone UDID:
→ https://www.udid.io/

Codemagic:
→ https://codemagic.io/signup

Diawi (Install IPA):
→ https://www.diawi.com

Your Git Repo:
→ https://github.com/tung1506/esim-project
```

---

## ⏱️ TIMELINE ESTIMATE

```
Task                          Time      Cumulative
─────────────────────────────────────────────────
1. Create App ID              3 min     3 min
2. Register Device            5 min     8 min
3. Create API Key             7 min     15 min
4. Create Codemagic Account   2 min     17 min
5. Add Application            3 min     20 min
6. Configure Code Signing     5 min     25 min
7. Start Build                15 min    40 min
8. Download IPA               1 min     41 min
9. Upload to Diawi            2 min     43 min
10. Install & Test            2 min     45 min
─────────────────────────────────────────────────
TOTAL                         45 min
```

---

**📌 PRINT THIS PAGE AND CHECK OFF EACH STEP AS YOU GO!**

**🚀 YOU GOT THIS! LET'S BUILD THAT IPA!**
