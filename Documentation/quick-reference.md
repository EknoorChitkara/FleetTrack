# FleetTrack Quick Reference

Quick reference guide for developers working on the FleetTrack iOS application.

---

## 🚀 Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/FleetTrack.git
cd FleetTrack

# Open in Xcode
open FleetTrack.xcodeproj

# Build and run
Cmd + R
```

---

## 📁 Project Structure

```
FleetTrack/
├── App/                    # App entry point
├── Core/                   # Shared utilities
├── Features/               # Feature modules
│   ├── Authentication/     # Login, 2FA, session
│   ├── FleetManagement/    # Admin dashboard
│   ├── DriverManagement/   # Driver workflows
│   ├── VehicleManagement/  # Vehicle CRUD
│   └── MaintenanceManagement/  # Service management
├── Resources/              # Assets, fonts, localization
└── Tests/                  # Unit and UI tests
```

---

## 🔑 Demo Credentials

| Role | Email | Password |
|------|-------|----------|
| **Admin** | admin@fleettrack.com | admin123 |
| **Driver** | driver@fleettrack.com | driver123 |
| **Maintenance** | maintenance@fleettrack.com | maint123 |

---

## 🏗️ Architecture Layers

Every feature follows this structure:

```
View (SwiftUI)
    ↓
ViewModel (@Published, ObservableObject)
    ↓
Service (Protocol-based, async/await)
    ↓
Model (Codable, Identifiable)
```

---

## 📦 Core Models

### User & Authentication

```swift
struct User: Identifiable, Codable {
    let id: UUID
    var email: String
    var role: UserRole  // .admin, .driver, .maintenance
    var firstName: String
    var lastName: String
}

struct Session: Codable {
    let id: UUID
    let userId: UUID
    var token: String
    var expiresAt: Date
}
```

### Vehicle

```swift
struct Vehicle: Identifiable, Codable {
    let id: UUID
    var registrationNumber: String
    var make: String
    var model: String
    var status: VehicleStatus  // .available, .assigned, .inService, .retired
}
```

### Driver & Trip

```swift
struct Driver: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var licenseNumber: String
    var assignedVehicleId: UUID?
    var status: DriverStatus  // .available, .onTrip, .offDuty
}

struct Trip: Identifiable, Codable {
    let id: UUID
    var driverId: UUID
    var vehicleId: UUID
    var startTime: Date
    var endTime: Date?
    var status: TripStatus  // .planned, .inProgress, .completed
}
```

### Maintenance

```swift
struct MaintenanceRecord: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var serviceType: ServiceType  // .oilChange, .tireRotation, etc.
    var scheduledDate: Date
    var status: MaintenanceStatus  // .scheduled, .inProgress, .completed
}
```

---

## 🔧 Common Patterns

### Creating a ViewModel

```swift
@MainActor
class FeatureViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol = MockService()) {
        self.service = service
    }
    
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await service.fetchItems()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Creating a View

```swift
struct FeatureView: View {
    @StateObject private var viewModel = FeatureViewModel()
    
    var body: some View {
        List(viewModel.items) { item in
            ItemRow(item: item)
        }
        .task {
            await viewModel.loadItems()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

### Creating a Service

```swift
protocol FeatureServiceProtocol {
    func fetchItems() async throws -> [Item]
}

class MockFeatureService: FeatureServiceProtocol {
    func fetchItems() async throws -> [Item] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockItems
    }
}
```

---

## 🎨 UI Components

### Standard Button

```swift
Button("Action") {
    // Action
}
.frame(maxWidth: .infinity)
.padding()
.background(Color.blue)
.foregroundColor(.white)
.cornerRadius(10)
```

### Form Field

```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Label")
        .font(.caption)
        .foregroundColor(.secondary)
    
    TextField("Placeholder", text: $value)
        .textFieldStyle(.roundedBorder)
}
```

### Status Badge

```swift
Text(status.displayName)
    .font(.caption)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(Color(status.color).opacity(0.2))
    .foregroundColor(Color(status.color))
    .cornerRadius(4)
```

---

## 🔐 Role-Based Access

### Check Permission in ViewModel

```swift
func performAction() async {
    guard let user = authService.currentUser,
          user.role == .admin else {
        errorMessage = "Unauthorized"
        return
    }
    
    // Proceed with action
}
```

### Conditional UI

```swift
if authViewModel.currentUser?.role == .admin {
    Button("Admin Action") {
        // Admin-only action
    }
}
```

---

## 🧪 Testing

### Unit Test Template

```swift
@MainActor
class FeatureViewModelTests: XCTestCase {
    var sut: FeatureViewModel!
    var mockService: MockFeatureService!
    
    override func setUp() {
        super.setUp()
        mockService = MockFeatureService()
        sut = FeatureViewModel(service: mockService)
    }
    
    func testLoadItems_Success() async {
        // Given
        mockService.itemsToReturn = [Item.mock()]
        
        // When
        await sut.loadItems()
        
        // Then
        XCTAssertEqual(sut.items.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
}
```

### Run Tests

```bash
# Run all tests
Cmd + U

# Run specific test
xcodebuild test -scheme FleetTrack -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 📊 Navigation Structure

### Admin

```swift
TabView {
    FleetOverviewView()
        .tabItem { Label("Fleet", systemImage: "car.2.fill") }
    
    AssignmentManagementView()
        .tabItem { Label("Assignments", systemImage: "person.crop.circle.badge.checkmark") }
    
    ReportsView()
        .tabItem { Label("Reports", systemImage: "chart.bar.fill") }
}
```

### Driver

```swift
TabView {
    DriverDashboardView()
        .tabItem { Label("Dashboard", systemImage: "car.fill") }
    
    TripHistoryView()
        .tabItem { Label("Trips", systemImage: "list.bullet") }
}
```

---

## 🐛 Common Issues

### Issue: "Cannot find type in scope"
**Solution:** Ensure the file is added to the Xcode target

### Issue: "Published property accessed from background thread"
**Solution:** Add `@MainActor` to ViewModel class

### Issue: "Preview crashes"
**Solution:** Provide mock data in `#Preview` block

```swift
#Preview {
    FeatureView()
        .environmentObject(AuthViewModel())
}
```

---

## 📝 Git Workflow

```bash
# Create feature branch
git checkout -b feature/authentication-system

# Commit changes
git add .
git commit -m "feat: implement login functionality"

# Push to remote
git push origin feature/authentication-system

# Create pull request on GitHub
```

### Commit Message Format

```
feat: add new feature
fix: fix bug
docs: update documentation
refactor: refactor code
test: add tests
```

---

## 📚 Resources

- **Architecture:** `Documentation/architecture.md`
- **Implementation Guide:** `Documentation/implementation-guide.md`
- **Apple SwiftUI Docs:** https://developer.apple.com/documentation/swiftui
- **Swift Concurrency:** https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html

---

## 🆘 Getting Help

1. Check `README.md` for project overview
2. Review `Documentation/architecture.md` for system design
3. Consult `Documentation/implementation-guide.md` for step-by-step instructions
4. Open an issue on GitHub for bugs or questions

---

**Last Updated:** January 7, 2026  
**Version:** 1.0.0
