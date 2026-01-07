# FleetTrack Implementation Guide

This guide provides step-by-step instructions for implementing the FleetTrack iOS application based on the defined architecture.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Implementation Order](#implementation-order)
4. [Phase 1: Authentication System](#phase-1-authentication-system)
5. [Phase 2: Vehicle Management System](#phase-2-vehicle-management-system)
6. [Phase 3: Driver Management System](#phase-3-driver-management-system)
7. [Phase 4: Fleet Management System](#phase-4-fleet-management-system)
8. [Phase 5: Maintenance Management System](#phase-5-maintenance-management-system)
9. [Testing Strategy](#testing-strategy)
10. [Common Patterns](#common-patterns)

---

## Prerequisites

- **Xcode 14.0+** installed
- **macOS 12.0+**
- Basic understanding of:
  - Swift programming language
  - SwiftUI framework
  - MVVM architecture pattern
  - Async/await concurrency
  - Protocol-oriented programming

---

## Project Setup

### Step 1: Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Configure:
   - Product Name: `FleetTrack`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 15.0**
5. Save to `/Users/eknoor/Documents/FleetTrack`

### Step 2: Organize File Structure

The directory structure has already been created. Now add these folders to your Xcode project:

1. Right-click on project root in Xcode
2. Add Files to "FleetTrack"
3. Select the `FleetTrack` folder
4. Ensure "Create groups" is selected
5. Add to target: FleetTrack

### Step 3: Configure Project Settings

**Info.plist additions:**
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchScreenBackground</string>
</dict>
```

**Build Settings:**
- Swift Language Version: Swift 5
- iOS Deployment Target: 15.0

---

## Implementation Order

Implement subsystems in this order to maintain dependencies:

```
1. Core Utilities & Models (Foundation)
   ↓
2. Authentication System (Security Gateway)
   ↓
3. Vehicle Management System (Shared Core)
   ↓
4. Driver Management System (Depends on Vehicle)
   ↓
5. Fleet Management System (Depends on Vehicle & Driver)
   ↓
6. Maintenance Management System (Depends on Vehicle)
```

---

## Phase 1: Authentication System

### 1.1 Create Core Models

**File:** `FleetTrack/Features/Authentication/Models/User.swift`

```swift
import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: UUID
    var email: String
    var role: UserRole
    var firstName: String
    var lastName: String
    var isActive: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        email: String,
        role: UserRole,
        firstName: String,
        lastName: String,
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.role = role
        self.firstName = firstName
        self.lastName = lastName
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

enum UserRole: String, Codable, CaseIterable {
    case admin
    case driver
    case maintenance
    
    var displayName: String {
        switch self {
        case .admin: return "Fleet Manager"
        case .driver: return "Driver"
        case .maintenance: return "Maintenance Manager"
        }
    }
}
```

**File:** `FleetTrack/Features/Authentication/Models/Session.swift`

```swift
import Foundation

struct Session: Codable {
    let id: UUID
    let userId: UUID
    var token: String
    var expiresAt: Date
    var isActive: Bool
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        token: String = UUID().uuidString,
        expiresAt: Date = Date().addingTimeInterval(86400), // 24 hours
        isActive: Bool = true
    ) {
        self.id = id
        self.userId = userId
        self.token = token
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}
```

**File:** `FleetTrack/Features/Authentication/Models/TwoFactorCode.swift`

```swift
import Foundation

struct TwoFactorCode: Codable {
    var code: String
    let userId: UUID
    var expiresAt: Date
    var isUsed: Bool
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    init(
        userId: UUID,
        code: String = String(format: "%06d", Int.random(in: 0...999999)),
        expiresAt: Date = Date().addingTimeInterval(300), // 5 minutes
        isUsed: Bool = false
    ) {
        self.code = code
        self.userId = userId
        self.expiresAt = expiresAt
        self.isUsed = isUsed
    }
}
```

### 1.2 Create Service Protocols

**File:** `FleetTrack/Features/Authentication/Services/AuthServiceProtocol.swift`

```swift
import Foundation

protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func validateSession() async throws -> Bool
    var currentUser: User? { get }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case sessionExpired
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .sessionExpired:
            return "Your session has expired. Please login again."
        case .unauthorized:
            return "You are not authorized to perform this action"
        }
    }
}
```

### 1.3 Implement Mock Service

**File:** `FleetTrack/Features/Authentication/Services/MockAuthService.swift`

```swift
import Foundation

@MainActor
class MockAuthService: AuthServiceProtocol, ObservableObject {
    @Published private(set) var currentUser: User?
    
    // Mock user database
    private var mockUsers: [User] = [
        User(email: "admin@fleettrack.com", role: .admin, firstName: "John", lastName: "Admin"),
        User(email: "driver@fleettrack.com", role: .driver, firstName: "Jane", lastName: "Driver"),
        User(email: "maintenance@fleettrack.com", role: .maintenance, firstName: "Mike", lastName: "Mechanic")
    ]
    
    // Mock password storage (in real app, use secure storage)
    private let mockPasswords: [String: String] = [
        "admin@fleettrack.com": "admin123",
        "driver@fleettrack.com": "driver123",
        "maintenance@fleettrack.com": "maint123"
    ]
    
    func login(email: String, password: String) async throws -> User {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Validate credentials
        guard let storedPassword = mockPasswords[email],
              storedPassword == password else {
            throw AuthError.invalidCredentials
        }
        
        // Find user
        guard let user = mockUsers.first(where: { $0.email == email }) else {
            throw AuthError.userNotFound
        }
        
        currentUser = user
        return user
    }
    
    func logout() async throws {
        currentUser = nil
    }
    
    func validateSession() async throws -> Bool {
        return currentUser != nil
    }
}
```

### 1.4 Create ViewModel

**File:** `FleetTrack/Features/Authentication/ViewModels/AuthViewModel.swift`

```swift
import Foundation
import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = MockAuthService()) {
        self.authService = authService
    }
    
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.login(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func logout() async {
        do {
            try await authService.logout()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### 1.5 Create Login View

**File:** `FleetTrack/Features/Authentication/Views/LoginView.swift`

```swift
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo/Header
                VStack(spacing: 8) {
                    Image(systemName: "car.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("FleetTrack")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Fleet Management System")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 40)
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.login(email: email, password: password)
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Demo Credentials
                VStack(spacing: 8) {
                    Text("Demo Credentials:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Admin: admin@fleettrack.com / admin123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Driver: driver@fleettrack.com / driver123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Welcome")
        }
    }
}

#Preview {
    LoginView()
}
```

### 1.6 Update App Entry Point

**File:** `FleetTrack/App/FleetTrackApp.swift`

```swift
import SwiftUI

@main
struct FleetTrackApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
```

**File:** `FleetTrack/App/ContentView.swift`

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if let user = authViewModel.currentUser {
                switch user.role {
                case .admin:
                    AdminTabView()
                case .driver:
                    DriverTabView()
                case .maintenance:
                    MaintenanceTabView()
                }
            }
        }
    }
}

// Placeholder tab views
struct AdminTabView: View {
    var body: some View {
        TabView {
            Text("Admin Dashboard")
                .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
        }
    }
}

struct DriverTabView: View {
    var body: some View {
        TabView {
            Text("Driver Dashboard")
                .tabItem { Label("Dashboard", systemImage: "car.fill") }
        }
    }
}

struct MaintenanceTabView: View {
    var body: some View {
        TabView {
            Text("Maintenance Dashboard")
                .tabItem { Label("Dashboard", systemImage: "wrench.fill") }
        }
    }
}
```

---

## Phase 2: Vehicle Management System

### 2.1 Create Vehicle Models

**File:** `FleetTrack/Features/VehicleManagement/Models/Vehicle.swift`

```swift
import Foundation

struct Vehicle: Identifiable, Codable, Equatable {
    let id: UUID
    var registrationNumber: String
    var make: String
    var model: String
    var year: Int
    var vin: String
    var status: VehicleStatus
    var currentOdometer: Double
    var assignedDriverId: UUID?
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        registrationNumber: String,
        make: String,
        model: String,
        year: Int,
        vin: String,
        status: VehicleStatus = .available,
        currentOdometer: Double = 0,
        assignedDriverId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.registrationNumber = registrationNumber
        self.make = make
        self.model = model
        self.year = year
        self.vin = vin
        self.status = status
        self.currentOdometer = currentOdometer
        self.assignedDriverId = assignedDriverId
        self.createdAt = createdAt
    }
    
    var displayName: String {
        "\(make) \(model) (\(registrationNumber))"
    }
}

enum VehicleStatus: String, Codable, CaseIterable {
    case available
    case assigned
    case inService
    case retired
    
    var displayName: String {
        switch self {
        case .available: return "Available"
        case .assigned: return "Assigned"
        case .inService: return "In Service"
        case .retired: return "Retired"
        }
    }
    
    var color: String {
        switch self {
        case .available: return "green"
        case .assigned: return "blue"
        case .inService: return "orange"
        case .retired: return "gray"
        }
    }
}
```

### 2.2 Create Vehicle Service

**File:** `FleetTrack/Features/VehicleManagement/Services/VehicleServiceProtocol.swift`

```swift
import Foundation

protocol VehicleServiceProtocol {
    func getAllVehicles() async throws -> [Vehicle]
    func getVehicleById(id: UUID) async throws -> Vehicle
    func createVehicle(vehicle: Vehicle) async throws -> Vehicle
    func updateVehicleStatus(id: UUID, status: VehicleStatus) async throws
    func updateOdometer(id: UUID, reading: Double) async throws
}

enum VehicleError: LocalizedError {
    case notFound
    case invalidData
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Vehicle not found"
        case .invalidData: return "Invalid vehicle data"
        case .unauthorized: return "Unauthorized to perform this action"
        }
    }
}
```

**File:** `FleetTrack/Features/VehicleManagement/Services/MockVehicleService.swift`

```swift
import Foundation

@MainActor
class MockVehicleService: VehicleServiceProtocol, ObservableObject {
    @Published private var vehicles: [Vehicle] = [
        Vehicle(registrationNumber: "VAN-001", make: "Ford", model: "Transit", year: 2022, vin: "1FTFW1ET5MFC12345", status: .available),
        Vehicle(registrationNumber: "TRUCK-012", make: "Chevrolet", model: "Silverado", year: 2021, vin: "1GCUYDED5MZ123456", status: .assigned),
        Vehicle(registrationNumber: "VAN-003", make: "Mercedes", model: "Sprinter", year: 2023, vin: "WD3PE8CC5N5123456", status: .inService)
    ]
    
    func getAllVehicles() async throws -> [Vehicle] {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return vehicles
    }
    
    func getVehicleById(id: UUID) async throws -> Vehicle {
        guard let vehicle = vehicles.first(where: { $0.id == id }) else {
            throw VehicleError.notFound
        }
        return vehicle
    }
    
    func createVehicle(vehicle: Vehicle) async throws -> Vehicle {
        vehicles.append(vehicle)
        return vehicle
    }
    
    func updateVehicleStatus(id: UUID, status: VehicleStatus) async throws {
        guard let index = vehicles.firstIndex(where: { $0.id == id }) else {
            throw VehicleError.notFound
        }
        vehicles[index].status = status
    }
    
    func updateOdometer(id: UUID, reading: Double) async throws {
        guard let index = vehicles.firstIndex(where: { $0.id == id }) else {
            throw VehicleError.notFound
        }
        vehicles[index].currentOdometer = reading
    }
}
```

---

## Common Patterns

### Pattern 1: MVVM Structure

Every feature follows this pattern:

```
Models/ (Data structures)
   ↓
Services/ (Business logic + protocols)
   ↓
ViewModels/ (State management + @Published)
   ↓
Views/ (SwiftUI UI)
```

### Pattern 2: Async/Await for Services

```swift
// Always use async/await for service calls
func loadData() async {
    isLoading = true
    do {
        data = try await service.fetchData()
    } catch {
        errorMessage = error.localizedDescription
    }
    isLoading = false
}
```

### Pattern 3: Error Handling

```swift
// Define custom errors
enum FeatureError: LocalizedError {
    case notFound
    case invalidData
    
    var errorDescription: String? {
        // User-friendly messages
    }
}

// Display in UI
if let errorMessage = viewModel.errorMessage {
    Text(errorMessage)
        .foregroundColor(.red)
}
```

### Pattern 4: Dependency Injection

```swift
// Protocol-based services
protocol ServiceProtocol {
    func fetchData() async throws -> Data
}

// ViewModel accepts protocol
class ViewModel: ObservableObject {
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol = MockService()) {
        self.service = service
    }
}
```

---

## Testing Strategy

### Unit Tests Example

**File:** `FleetTrack/Tests/UnitTests/AuthViewModelTests.swift`

```swift
import XCTest
@testable import FleetTrack

@MainActor
class AuthViewModelTests: XCTestCase {
    var sut: AuthViewModel!
    var mockService: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockService = MockAuthService()
        sut = AuthViewModel(authService: mockService)
    }
    
    func testLogin_Success() async {
        // When
        await sut.login(email: "admin@fleettrack.com", password: "admin123")
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.role, .admin)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLogin_InvalidCredentials() async {
        // When
        await sut.login(email: "wrong@email.com", password: "wrong")
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
    }
}
```

---

## Next Steps

1. **Complete Authentication System** (Phase 1)
   - Add 2FA functionality
   - Implement password recovery
   - Add admin setup workflow

2. **Implement Vehicle Management** (Phase 2)
   - Create vehicle list view
   - Add vehicle detail view
   - Implement vehicle registration

3. **Build Driver Management** (Phase 3)
   - Create driver dashboard
   - Implement trip management
   - Add trip history

4. **Develop Fleet Management** (Phase 4)
   - Build admin dashboard
   - Create assignment management
   - Add reporting features

5. **Add Maintenance Management** (Phase 5)
   - Create maintenance dashboard
   - Implement service scheduling
   - Add cost tracking

---

## Support

For questions or issues during implementation:

1. Refer to `Documentation/architecture.md` for system design
2. Check this guide for implementation patterns
3. Review mock services for data structure examples
4. Test each phase before moving to the next

---

**Last Updated:** January 7, 2026  
**Version:** 1.0.0
