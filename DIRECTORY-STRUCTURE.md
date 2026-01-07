# FleetTrack Directory Structure

```
FleetTrack/
│
├── .gitignore                                  # Git ignore configuration
├── README.md                                   # Project overview and guide
├── PROJECT-SETUP-SUMMARY.md                    # Setup summary and next steps
│
├── Documentation/
│   ├── architecture.md                         # Complete system architecture
│   ├── implementation-guide.md                 # Step-by-step implementation
│   └── quick-reference.md                      # Developer quick reference
│
└── FleetTrack/
    │
    ├── App/
    │   └── .gitkeep                            # App entry point files
    │
    ├── Core/
    │   ├── Models/
    │   │   └── .gitkeep                        # Shared domain models
    │   ├── Services/
    │   │   └── .gitkeep                        # Shared service protocols
    │   ├── Utilities/
    │   │   └── .gitkeep                        # Helper classes and extensions
    │   ├── Networking/
    │   │   └── .gitkeep                        # API client (future)
    │   └── Persistence/
    │       └── .gitkeep                        # Data storage utilities
    │
    ├── Features/
    │   │
    │   ├── Authentication/                     # Authentication System
    │   │   ├── Models/
    │   │   │   └── .gitkeep                    # User, Session, 2FA, SetupToken
    │   │   ├── Services/
    │   │   │   └── .gitkeep                    # AuthService, SessionManager, EmailService
    │   │   ├── ViewModels/
    │   │   │   └── .gitkeep                    # AuthViewModel, TwoFactorViewModel
    │   │   └── Views/
    │   │       └── .gitkeep                    # LoginView, TwoFactorView, SetupView
    │   │
    │   ├── FleetManagement/                    # Fleet Management System (Admin)
    │   │   ├── Models/
    │   │   │   └── .gitkeep                    # Fleet, Assignment, FleetReport
    │   │   ├── Services/
    │   │   │   └── .gitkeep                    # FleetService, AssignmentService, ReportService
    │   │   ├── ViewModels/
    │   │   │   └── .gitkeep                    # AdminDashboardViewModel, FleetOverviewViewModel
    │   │   └── Views/
    │   │       └── .gitkeep                    # AdminDashboardView, FleetOverviewView
    │   │
    │   ├── DriverManagement/                   # Driver Management System
    │   │   ├── Models/
    │   │   │   └── .gitkeep                    # Driver, Trip, TripLog, DriverStatus
    │   │   ├── Services/
    │   │   │   └── .gitkeep                    # DriverService, TripService
    │   │   ├── ViewModels/
    │   │   │   └── .gitkeep                    # DriverDashboardViewModel, TripViewModel
    │   │   └── Views/
    │   │       └── .gitkeep                    # DriverDashboardView, TripView
    │   │
    │   ├── VehicleManagement/                  # Vehicle Management System (Shared Core)
    │   │   ├── Models/
    │   │   │   └── .gitkeep                    # Vehicle, VehicleStatus, VehicleHistory
    │   │   ├── Services/
    │   │   │   └── .gitkeep                    # VehicleService, VehicleAssignmentService
    │   │   ├── ViewModels/
    │   │   │   └── .gitkeep                    # VehicleListViewModel, VehicleDetailViewModel
    │   │   └── Views/
    │   │       └── .gitkeep                    # VehicleListView, VehicleDetailView
    │   │
    │   └── MaintenanceManagement/              # Maintenance Management System
    │       ├── Models/
    │       │   └── .gitkeep                    # MaintenanceRecord, ServiceSchedule
    │       ├── Services/
    │       │   └── .gitkeep                    # MaintenanceService, ServiceScheduleService
    │       ├── ViewModels/
    │       │   └── .gitkeep                    # MaintenanceDashboardViewModel
    │       └── Views/
    │           └── .gitkeep                    # MaintenanceDashboardView
    │
    ├── Resources/
    │   ├── Assets.xcassets/
    │   │   └── .gitkeep                        # Images, colors, icons
    │   ├── Fonts/
    │   │   └── .gitkeep                        # Custom fonts
    │   └── Localization/
    │       └── .gitkeep                        # Localized strings
    │
    └── Tests/
        ├── UnitTests/
        │   └── .gitkeep                        # ViewModel and Service tests
        └── UITests/
            └── .gitkeep                        # SwiftUI view tests
```

---

## Directory Counts

- **Total Directories:** 31
- **Feature Subsystems:** 5
- **Layers per Subsystem:** 4 (Models, Services, ViewModels, Views)
- **Core Directories:** 5
- **Resource Directories:** 3
- **Test Directories:** 2
- **Documentation Files:** 4

---

## File Organization Pattern

Each feature subsystem follows the same structure:

```
FeatureName/
├── Models/          # Data structures (Codable, Identifiable)
├── Services/        # Business logic (Protocol-based, async/await)
├── ViewModels/      # State management (@Published, ObservableObject)
└── Views/           # UI components (SwiftUI)
```

---

## Key Directories Explained

### App/
- `FleetTrackApp.swift` - App entry point
- `AppDelegate.swift` - App lifecycle
- `SceneDelegate.swift` - Scene management

### Core/
Shared utilities used across all features:
- **Models/** - Common domain models
- **Services/** - Shared service protocols
- **Utilities/** - Extensions, helpers, constants
- **Networking/** - API client (future backend integration)
- **Persistence/** - UserDefaults, Keychain wrappers

### Features/
Five independent subsystems, each with MVVM layers:

1. **Authentication/** - Security gateway
2. **FleetManagement/** - Admin dashboard
3. **DriverManagement/** - Driver workflows
4. **VehicleManagement/** - Shared vehicle core
5. **MaintenanceManagement/** - Service management

### Resources/
- **Assets.xcassets/** - Images, colors, app icons
- **Fonts/** - Custom typography
- **Localization/** - Multi-language support

### Tests/
- **UnitTests/** - ViewModel and Service tests
- **UITests/** - SwiftUI view tests

---

## .gitkeep Files

All 31 directories contain `.gitkeep` files to ensure they are tracked by Git even when empty. These placeholder files will be removed as you add actual implementation files.

---

**Last Updated:** January 7, 2026  
**Status:** Complete and ready for implementation
