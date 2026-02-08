#!/bin/bash

# Script to setup Git repository for Codemagic iOS build
# Usage: ./setup_git_for_codemagic.sh

set -e  # Exit on error

echo "🚀 Setting up Git repository for Codemagic iOS build..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Git is not installed. Please install git first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Git is installed${NC}"

# Check if we're in the correct directory
if [ ! -d "esim_webview_host" ] || [ ! -d "flutter_esim" ]; then
    echo -e "${RED}❌ Error: esim_webview_host or flutter_esim directory not found${NC}"
    echo "Please run this script from /home/hungtv/stock/java/android directory"
    exit 1
fi

echo -e "${GREEN}✅ Project directories found${NC}"

# Initialize git if not already initialized
if [ ! -d ".git" ]; then
    echo ""
    echo "📦 Initializing Git repository..."
    git init
    echo -e "${GREEN}✅ Git initialized${NC}"
else
    echo -e "${YELLOW}⚠️  Git already initialized${NC}"
fi

# Create .gitignore if not exists
if [ ! -f ".gitignore" ]; then
    echo ""
    echo "📝 Creating .gitignore..."
    cat > .gitignore << 'EOF'
# Miscellaneous
*.class
*.lock
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/

# IntelliJ
*.iml
*.ipr
*.iws
.idea/

# VSCode
.vscode/

# Flutter/Dart/Pub related
**/doc/api/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/
flutter_*.png
linked_*.ds
unlinked.ds
unlinked_spec.ds

# Android related
**/android/**/gradle-wrapper.jar
**/android/.gradle
**/android/captures/
**/android/gradlew
**/android/gradlew.bat
**/android/local.properties
**/android/**/GeneratedPluginRegistrant.java
**/android/key.properties
*.jks

# iOS/XCode related
**/ios/**/*.mode1v3
**/ios/**/*.mode2v3
**/ios/**/*.moved-aside
**/ios/**/*.pbxuser
**/ios/**/*.perspectivev3
**/ios/**/*sync/
**/ios/**/.sconsign.dblite
**/ios/**/.tags*
**/ios/**/.vagrant/
**/ios/**/DerivedData/
**/ios/**/Icon?
**/ios/**/Pods/
**/ios/**/.symlinks/
**/ios/**/profile
**/ios/**/xcuserdata
**/ios/.generated/
**/ios/Flutter/.last_build_id
**/ios/Flutter/App.framework
**/ios/Flutter/Flutter.framework
**/ios/Flutter/Flutter.podspec
**/ios/Flutter/Generated.xcconfig
**/ios/Flutter/app.flx
**/ios/Flutter/app.zip
**/ios/Flutter/flutter_assets/
**/ios/Flutter/flutter_export_environment.sh
**/ios/ServiceDefinitions.json
**/ios/Runner/GeneratedPluginRegistrant.*

# Coverage
coverage/

# Symbols
app.*.symbols

# Exceptions to above rules.
!**/ios/**/default.mode1v3
!**/ios/**/default.mode2v3
!**/ios/**/default.pbxuser
!**/ios/**/default.perspectivev3
!/packages/flutter_tools/test/data/dart_dependencies_test/**/.packages
!/dev/ci/**/Gemfile.lock

# Codemagic
codemagic.env
EOF
    echo -e "${GREEN}✅ .gitignore created${NC}"
else
    echo -e "${YELLOW}⚠️  .gitignore already exists${NC}"
fi

# Add files to git
echo ""
echo "📦 Adding files to Git..."
git add .
echo -e "${GREEN}✅ Files staged${NC}"

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo -e "${YELLOW}⚠️  No changes to commit${NC}"
else
    echo ""
    echo "💾 Creating initial commit..."
    git commit -m "Initial commit: iOS eSIM WebView Host with Universal Link support

- Added esim_webview_host Flutter app
- Added flutter_esim SDK with iOS Universal Link implementation
- Added Codemagic CI/CD configuration
- Added comprehensive documentation"
    echo -e "${GREEN}✅ Initial commit created${NC}"
fi

# Check if remote already exists
if git remote | grep -q "^origin$"; then
    echo ""
    echo -e "${YELLOW}⚠️  Remote 'origin' already exists${NC}"
    echo "Current remote URL:"
    git remote get-url origin
    echo ""
    read -p "Do you want to change the remote URL? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        read -p "Enter new GitHub repository URL: " REPO_URL
        git remote set-url origin "$REPO_URL"
        echo -e "${GREEN}✅ Remote URL updated${NC}"
    fi
else
    echo ""
    echo "🔗 Setting up remote repository..."
    echo ""
    echo -e "${YELLOW}📝 Please create a repository on GitHub first:${NC}"
    echo "   1. Go to: https://github.com/new"
    echo "   2. Repository name: esim-webview-ios (or your choice)"
    echo "   3. Choose Public or Private"
    echo "   4. DO NOT initialize with README"
    echo "   5. Click 'Create repository'"
    echo ""
    read -p "Enter the GitHub repository URL (e.g., https://github.com/username/repo.git): " REPO_URL
    
    if [ -z "$REPO_URL" ]; then
        echo -e "${RED}❌ No URL provided. Skipping remote setup.${NC}"
    else
        git remote add origin "$REPO_URL"
        echo -e "${GREEN}✅ Remote added: $REPO_URL${NC}"
        
        # Set main branch
        git branch -M main
        echo -e "${GREEN}✅ Branch renamed to 'main'${NC}"
        
        # Ask if user wants to push
        echo ""
        read -p "Do you want to push to GitHub now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "🚀 Pushing to GitHub..."
            git push -u origin main
            echo -e "${GREEN}✅ Pushed to GitHub successfully!${NC}"
        else
            echo -e "${YELLOW}⚠️  Skipped push. You can push later with: git push -u origin main${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✅ Git setup complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "📋 Next steps:"
echo "   1. If not pushed yet: git push -u origin main"
echo "   2. Setup Codemagic: https://codemagic.io/signup"
echo "   3. Connect Apple Developer Portal (API Key)"
echo "   4. Start build!"
echo ""
echo "📚 For detailed instructions, see:"
echo "   - QUICK_START.md (5-minute setup)"
echo "   - CODEMAGIC_SETUP_GUIDE.md (full guide)"
echo ""
echo -e "${GREEN}Good luck! 🚀${NC}"
