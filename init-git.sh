#!/bin/bash

# FleetTrack Git Initialization Script
# This script initializes the Git repository and prepares it for GitHub

echo "🚀 Initializing FleetTrack Git Repository..."
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Error: Git is not installed"
    echo "Please install Git from https://git-scm.com/"
    exit 1
fi

# Initialize git repository
echo "📦 Initializing Git repository..."
git init

# Add all files
echo "📝 Adding files to Git..."
git add .

# Create initial commit
echo "💾 Creating initial commit..."
git commit -m "Initial commit: FleetTrack iOS project structure and documentation

- Complete project directory structure with MVVM layers
- Comprehensive architecture documentation
- Implementation guide with code examples
- Quick reference guide for developers
- README with project overview
- All subsystems scaffolded (Authentication, Fleet, Driver, Vehicle, Maintenance)
- Ready for implementation"

echo ""
echo "✅ Git repository initialized successfully!"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Create a new repository on GitHub:"
echo "   - Go to https://github.com/new"
echo "   - Repository name: FleetTrack"
echo "   - Description: Professional Fleet Management System iOS Application"
echo "   - Do NOT initialize with README (we already have one)"
echo ""
echo "2. Link your local repository to GitHub:"
echo "   git remote add origin https://github.com/YOUR_USERNAME/FleetTrack.git"
echo ""
echo "3. Push to GitHub:"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
echo "📊 Repository Statistics:"
git log --oneline | wc -l | xargs echo "   Commits:"
git ls-files | wc -l | xargs echo "   Files tracked:"
du -sh .git | cut -f1 | xargs echo "   Repository size:"
echo ""
echo "🎉 Your FleetTrack project is ready for GitHub!"
