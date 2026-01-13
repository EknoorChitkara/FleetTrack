# Fix Xcode Build Errors - .gitkeep Files

## Problem
The build errors you're seeing are because `.gitkeep` files are being included in the Xcode build target. These files should only be in Git, not compiled.

## Solution

### Option 1: Remove .gitkeep from Build Phases (Recommended)

1. Open Xcode
2. Select your **FleetTrack** project in the navigator
3. Select the **FleetTrack** target
4. Go to **Build Phases** tab
5. Expand **"Compile Sources"**
6. Look for any `.gitkeep` files
7. Select them and click the **"-"** button to remove them
8. Expand **"Copy Bundle Resources"**
9. Remove any `.gitkeep` files from here too
10. Clean build folder: **Product → Clean Build Folder** (⇧⌘K)
11. Build again: **Product → Build** (⌘B)

### Option 2: Delete .gitkeep Files (Alternative)

Since we now have actual files in most directories, we can delete the `.gitkeep` files:

```bash
cd /Users/eknoor/Documents/FleetTrack
find FleetTrack -name ".gitkeep" -type f -delete
git add .
git commit -m "chore: remove .gitkeep files (no longer needed)"
```

### Option 3: Quick Fix via Terminal

Run this command to remove .gitkeep from Xcode project references:

```bash
cd /Users/eknoor/Documents/FleetTrack

# Remove .gitkeep files that have actual content now
rm FleetTrack/Core/Utilities/.gitkeep
rm FleetTrack/Features/Authentication/Views/.gitkeep

# Keep .gitkeep in empty directories
# (The build error is likely from directories that now have files)
```

## After Fixing

1. Clean build folder: **⇧⌘K**
2. Build: **⌘B**
3. Run: **⌘R**

You should see in the console:
```
✅ Firebase initialized
[Firebase/Core][I-COR000003] The default Firebase app has been configured.
```

## If Still Getting Errors

The error might also be from:
- Duplicate file references in Xcode project
- Files added to multiple targets

**To fix:**
1. In Xcode, select the problematic file
2. Open **File Inspector** (right panel)
3. Under **Target Membership**, ensure only **FleetTrack** is checked
4. Uncheck any other targets

## Need Help?

Let me know which option you'd like to try, or if you need me to create a script to automate the fix!
