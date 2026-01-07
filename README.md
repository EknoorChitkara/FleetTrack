# FleetTrack - Fleet Management System

**Platform:** iOS 15.0+  
**UI Framework:** SwiftUI  
**Architecture:** Modular MVVM + Service-Oriented Architecture  
**Language:** Swift 5.9+

---

## 📋 Project Overview

FleetTrack is a professional-grade Fleet Management System iOS application designed using a modular, layered architecture. The system comprises five core subsystems, each with clearly defined responsibilities following MVVM pattern and SwiftUI best practices.

---

## 🏗️ System Architecture

### Core Subsystems

1. **Authentication System** - Security gateway with 2FA, session management, and role-based access control
2. **Fleet Management System** - Admin-only dashboard for fleet oversight and assignments
3. **Driver Management System** - Driver-specific workflows and trip lifecycle management
4. **Vehicle Management System** - Shared core asset with complete lifecycle management
5. **Maintenance Management System** - Event-driven service scheduling and maintenance logging

### Layered Architecture

All subsystems follow a consistent four-layer architecture:

```
View Layer (SwiftUI Views)
    ↕
ViewModel Layer (@Published, ObservableObject)
    ↕
Service Layer (Business Logic, Mock APIs)
    ↕
Model Layer (Codable, Equatable Entities)
```

---

## 📁 Project Structure

```
FleetTrack/
├── App/
│   ├── FleetTrackApp.swift          # App entry point
│   ├── AppDelegate.swift            # App lifecycle
│   └── SceneDelegate.swift          # Scene management
│
├── Core/
│   ├── Models/                      # Shared domain models
│   ├── Services/                    # Shared service protocols
│   ├── Utilities/                   # Helper classes and extensions
│   ├── Networking/                  # API client (future)
│   └── Persistence/                 # Data storage utilities
│
├── Features/
│   ├── Authentication/
│   │   ├── Models/                  # User, Session, 2FA models
│   │   ├── Services/                # AuthService, SessionManager
│   │   ├── ViewModels/              # AuthViewModel, etc.
│   │   └── Views/                   # Login, 2FA, Setup views
│   │
│   ├── FleetManagement/
│   │   ├── Models/                  # Fleet, Assignment models
│   │   ├── Services/                # FleetService, AssignmentService
│   │   ├── ViewModels/              # AdminDashboardViewModel
│   │   └── Views/                   # Admin dashboard views
│   │
│   ├── DriverManagement/
│   │   ├── Models/                  # Driver, Trip models
│   │   ├── Services/                # DriverService, TripService
│   │   ├── ViewModels/              # DriverDashboardViewModel
│   │   └── Views/                   # Driver dashboard views
│   │
│   ├── VehicleManagement/
│   │   ├── Models/                  # Vehicle, VehicleStatus models
│   │   ├── Services/                # VehicleService
│   │   ├── ViewModels/              # VehicleListViewModel
│   │   └── Views/                   # Vehicle list/detail views
│   │
│   └── MaintenanceManagement/
│       ├── Models/                  # MaintenanceRecord models
│       ├── Services/                # MaintenanceService
│       ├── ViewModels/              # MaintenanceDashboardViewModel
│       └── Views/                   # Maintenance views
│
├── Resources/
│   ├── Assets.xcassets/             # Images, colors, icons
│   ├── Fonts/                       # Custom fonts
│   └── Localization/                # Localized strings
│
└── Tests/
    ├── UnitTests/                   # ViewModel and Service tests
    └── UITests/                     # SwiftUI view tests
```

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 14.0+**
- **iOS 15.0+** deployment target
- **Swift 5.9+**

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/FleetTrack.git
cd FleetTrack
```

2. Open the project in Xcode:
```bash
open FleetTrack.xcodeproj
```

3. Build and run:
- Select a simulator or device
- Press `Cmd + R` to build and run

---

## 👥 User Roles

The application supports three distinct user roles:

| Role | Access | Key Features |
|------|--------|--------------|
| **Admin** | Full fleet management | Fleet overview, vehicle assignments, reporting, driver management |
| **Driver** | Assigned vehicle only | View assigned vehicle, start/end trips, trip history |
| **Maintenance** | All vehicles (service context) | Schedule maintenance, log service records, update vehicle status |

---

## 🔐 Authentication Flow

```
Login Screen → 2FA Verification → Session Created → Role-Based Navigation
     ↓              ↓                    ↓                    ↓
Email/Password  6-Digit Code      Token Stored         Admin/Driver/
Validation      Validation        in Keychain          Maintenance Home
```

### Admin Setup Flow

1. System/Super-admin creates admin account
2. Setup email sent with one-time token
3. Admin sets password via setup link
4. Admin configures 2FA
5. Login with credentials + 2FA

---

## 📦 Core Components

### Models

All models conform to `Codable` and `Identifiable` for SwiftUI compatibility:

- **User Models**: `User`, `UserRole`, `Session`
- **Fleet Models**: `Fleet`, `Assignment`, `FleetReport`
- **Driver Models**: `Driver`, `Trip`, `TripLog`
- **Vehicle Models**: `Vehicle`, `VehicleStatus`, `VehicleHistory`
- **Maintenance Models**: `MaintenanceRecord`, `ServiceSchedule`

### Services

All services are protocol-based for testability and dependency injection:

- **AuthService**: Login, logout, session validation
- **VehicleService**: CRUD operations for vehicles
- **TripService**: Trip lifecycle management
- **MaintenanceService**: Service scheduling and logging

### ViewModels

All ViewModels use `@MainActor` and `ObservableObject`:

- `@Published` properties for reactive UI updates
- Async/await for service calls
- Error handling and loading states
- Role-based permission checks

---

## 🧪 Testing

### Unit Tests

Run unit tests for ViewModels and Services:

```bash
# Run all tests
Cmd + U

# Run specific test suite
xcodebuild test -scheme FleetTrack -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Mock Services

All services have mock implementations for testing:

- `MockAuthService`
- `MockVehicleService`
- `MockDriverService`
- `MockMaintenanceService`

---

## 🔧 Development Guidelines

### MVVM Pattern

```swift
// Model
struct Vehicle: Identifiable, Codable {
    let id: UUID
    var registrationNumber: String
    var status: VehicleStatus
}

// Service
protocol VehicleServiceProtocol {
    func getAllVehicles() async throws -> [Vehicle]
}

// ViewModel
@MainActor
class VehicleListViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    private let service: VehicleServiceProtocol
    
    func loadVehicles() async {
        vehicles = try await service.getAllVehicles()
    }
}

// View
struct VehicleListView: View {
    @StateObject private var viewModel = VehicleListViewModel()
    
    var body: some View {
        List(viewModel.vehicles) { vehicle in
            VehicleRow(vehicle: vehicle)
        }
        .task { await viewModel.loadVehicles() }
    }
}
```

### Dependency Injection

Use `ServiceContainer` for centralized dependency management:

```swift
class ServiceContainer {
    static let shared = ServiceContainer()
    
    let authService: AuthServiceProtocol
    let vehicleService: VehicleServiceProtocol
    
    private init() {
        self.authService = MockAuthService()
        self.vehicleService = MockVehicleService()
    }
}
```

### Role-Based Access Control

Enforce permissions at the ViewModel layer:

```swift
func performAdminAction() async {
    guard authService.currentUser?.role == .admin else {
        errorMessage = "Unauthorized"
        return
    }
    // Proceed with action
}
```

---

## 📱 Navigation Structure

### Admin Navigation

```
TabView
├── Fleet Overview
├── Assignments
├── Reports
└── Settings
```

### Driver Navigation

```
TabView
├── Dashboard (Assigned Vehicle)
├── Active Trip
├── Trip History
└── Profile
```

### Maintenance Navigation

```
TabView
├── Maintenance Dashboard
├── Schedule Service
├── Service History
└── Vehicle List
```

---

## 🔄 Inter-System Relationships

### Authentication as Gateway

All subsystems depend on Authentication for:
- User identity verification
- Role-based access control
- Session validation

### Vehicle Management as Shared Core

Vehicle Management is accessed by:
- **Fleet Management**: Full CRUD, assignments
- **Driver Management**: Read assigned vehicle, update odometer
- **Maintenance Management**: Read all vehicles, update service status

---

## 📊 Data Flow

```
Authentication System (Session & Role Management)
            ↓
    ┌───────┼───────┐
    ↓       ↓       ↓
  Fleet   Driver  Maintenance
    └───────┼───────┘
            ↓
    Vehicle Management (Shared Core)
```

---

## 🛠️ Future Enhancements

### Phase 1: Current (Mock Services)
- ✅ Complete architecture implementation
- ✅ Mock services for all subsystems
- ✅ SwiftUI views and navigation
- ✅ Role-based access control

### Phase 2: Backend Integration
- [ ] REST API client implementation
- [ ] Real authentication service
- [ ] Database persistence
- [ ] Push notifications

### Phase 3: Advanced Features
- [ ] Real-time trip tracking with MapKit
- [ ] Offline mode with Core Data
- [ ] Analytics dashboard
- [ ] Document scanning for maintenance records

---

## 📝 Implementation Checklist

### Authentication System
- [ ] Create User, Session, 2FA models
- [ ] Implement AuthService with mock data
- [ ] Build LoginView with email/password validation
- [ ] Implement 2FA verification flow
- [ ] Create admin setup workflow
- [ ] Implement SessionManager with Keychain

### Fleet Management System
- [ ] Create Fleet, Assignment models
- [ ] Implement FleetService and AssignmentService
- [ ] Build AdminDashboardView
- [ ] Create assignment management UI
- [ ] Implement fleet reports

### Driver Management System
- [ ] Create Driver, Trip models
- [ ] Implement DriverService and TripService
- [ ] Build DriverDashboardView
- [ ] Create trip start/end workflow
- [ ] Implement trip history view

### Vehicle Management System
- [ ] Create Vehicle, VehicleStatus models
- [ ] Implement VehicleService
- [ ] Build VehicleListView and VehicleDetailView
- [ ] Create vehicle registration form
- [ ] Implement vehicle history tracking

### Maintenance Management System
- [ ] Create MaintenanceRecord, ServiceSchedule models
- [ ] Implement MaintenanceService
- [ ] Build MaintenanceDashboardView
- [ ] Create service scheduling UI
- [ ] Implement cost tracking

---

## 🤝 Contributing

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for code consistency
- Write descriptive commit messages
- Add unit tests for new features

### Branch Strategy

- `main` - Production-ready code
- `develop` - Development branch
- `feature/*` - Feature branches
- `bugfix/*` - Bug fix branches

### Pull Request Process

1. Create feature branch from `develop`
2. Implement feature with tests
3. Ensure all tests pass
4. Submit PR with description
5. Address review comments
6. Merge after approval

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📞 Support

For questions or assistance:

- **Documentation**: See `/Documentation/architecture.md`
- **Issues**: Open an issue on GitHub
- **Email**: support@fleettrack.com

---

## 🙏 Acknowledgments

- Architecture inspired by iOS industry best practices
- MVVM pattern following Apple's SwiftUI guidelines
- Service-oriented architecture for scalability and testability

---

**Last Updated:** January 7, 2026  
**Version:** 1.0.0  
**Status:** Architecture Complete - Ready for Implementation
