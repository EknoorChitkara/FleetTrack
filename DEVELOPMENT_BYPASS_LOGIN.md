# Development Bypass Login - Quick Guide

## Purpose
This configuration allows you to skip the login screen and go directly to the dashboard during development/testing.

## Current Status
✅ **ENABLED** - App will open directly to the Maintenance Dashboard

## How to Use

### To Keep Bypass Login (Current State)
No action needed. The app will open directly to the dashboard.

### To Restore Normal Login Flow

**Option 1: Quick Toggle (Recommended)**
Open `DevelopmentConfig.swift` and change:
```swift
static let bypassLogin = true  // Change this to false
```

**Option 2: Complete Removal**
1. Delete or rename `DevelopmentConfig.swift`
2. Remove the `init()` method from `FleetTrackApp.swift` (lines 30-38)

## Switching Dashboards

To test different user roles, edit `DevelopmentConfig.swift`:

```swift
// For Fleet Manager Dashboard:
static let defaultRole: UserRole = .fleetManager

// For Driver Dashboard:
static let defaultRole: UserRole = .driver

// For Maintenance Dashboard (current):
static let defaultRole: UserRole = .maintenancePersonnel
```

## Files Modified

1. **NEW**: `FleetTrack/DevelopmentConfig.swift` - Configuration flags
2. **MODIFIED**: `FleetTrack/FleetTrackApp.swift` - Added init() to check bypass flag

## Revert Commands

```bash
# Option 1: Just disable the flag (keeps file for future use)
# Edit DevelopmentConfig.swift and set bypassLogin = false

# Option 2: Remove development config completely
rm FleetTrack/DevelopmentConfig.swift
# Then remove the init() method from FleetTrackApp.swift
```
