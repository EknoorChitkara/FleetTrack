 ---

## 13. Scalability Considerations

### Modular Architecture Benefits

1. **Independent Development**: Each subsystem can be developed and tested independently
2. **Team Scalability**: Different teams can own different subsystems
3. **Code Reusability**: Shared models and services reduce duplication
4. **Maintainability**: Clear boundaries make debugging and updates easier

### Future Backend Integration

The current architecture uses mock services, but is designed for easy backend integration:

```swift
// Current: Mock service
class MockVehicleService: VehicleServiceProtocol {
    func getAllVehicles() async throws -> [Vehicle] {
        return mockVehicles
    }
}

// Future: REST API service
class RESTVehicleService: VehicleServiceProtocol {
    private let apiClient: APIClient
    
    func getAllVehicles() async throws -> [Vehicle] {
        let endpoint = "/api/vehicles"
        return try await apiClient.get(endpoint)
    }
}

// No changes needed in ViewModels - dependency injection handles the swap
```

---

## 14. Conclusion

This architecture provides a robust, scalable foundation for a professional Fleet Management System iOS application. Key strengths include:

✅ **Clear Separation of Concerns**: MVVM pattern with distinct layers  
✅ **Modular Design**: Five independent subsystems with defined boundaries  
✅ **Role-Based Security**: Authentication system as a security gateway  
✅ **Shared Core Assets**: Vehicle Management as a central data hub  
✅ **SwiftUI Best Practices**: Modern declarative UI with reactive state management  
✅ **Testability**: Protocol-based services enable comprehensive unit testing  
✅ **Scalability**: Designed for future backend integration and feature expansion  

This architecture is suitable for:
- Academic presentations and viva examinations
- Technical documentation and architecture reviews
- Production implementation with real backend services
- Team collaboration and parallel development

---

## Appendix A: Complete Model Reference

### Authentication System Models

```swift
struct User: Identifiable, Codable {
    let id: UUID
    var email: String
    var role: UserRole
    var firstName: String
    var lastName: String
    var isActive: Bool
    var createdAt: Date
}

enum UserRole: String, Codable {
    case admin
    case driver
    case maintenance
}

struct Session: Codable {
    let id: UUID
    let userId: UUID
    var token: String
    var expiresAt: Date
    var isActive: Bool
}

struct TwoFactorCode: Codable {
    var code: String
    let userId: UUID
    var expiresAt: Date
    var isUsed: Bool
}

struct SetupToken: Codable {
    var token: String
    var email: String
    var expiresAt: Date
    var isUsed: Bool
}

struct PasswordResetToken: Codable {
    var token: String
    let userId: UUID
    var expiresAt: Date
    var isUsed: Bool
}
```

### Fleet Management Models

```swift
struct Fleet: Identifiable, Codable {
    let id: UUID
    var name: String
    var vehicleIds: [UUID]
    var totalVehicles: Int
    var activeVehicles: Int
    var createdAt: Date
}

struct Assignment: Identifiable, Codable {
    let id: UUID
    var driverId: UUID
    var vehicleId: UUID
    var startDate: Date
    var endDate: Date?
    var status: AssignmentStatus
}

enum AssignmentStatus: String, Codable {
    case active
    case completed
    case cancelled
}

struct FleetReport: Identifiable, Codable {
    let id: UUID
    var reportType: ReportType
    var dateRange: DateInterval
    var metrics: [String: Double]
    var generatedAt: Date
}

enum ReportType: String, Codable {
    case utilization
    case maintenance
    case trips
    case costs
}
```

### Driver Management Models

```swift
struct Driver: Identifiable, Codable {
    let id: UUID
    var userId: UUID
    var licenseNumber: String
    var licenseExpiry: Date
    var assignedVehicleId: UUID?
    var status: DriverStatus
}

enum DriverStatus: String, Codable {
    case available
    case onTrip
    case offDuty
    case suspended
}

struct Trip: Identifiable, Codable {
    let id: UUID
    var driverId: UUID
    var vehicleId: UUID
    var startTime: Date
    var endTime: Date?
    var startOdometer: Double
    var endOdometer: Double?
    var status: TripStatus
}

enum TripStatus: String, Codable {
    case planned
    case inProgress
    case completed
    case cancelled
}

struct TripLog: Identifiable, Codable {
    let id: UUID
    var tripId: UUID
    var timestamp: Date
    var eventType: TripEventType
    var notes: String?
}

enum TripEventType: String, Codable {
    case started
    case paused
    case resumed
    case completed
    case incident
}
```

### Vehicle Management Models

```swift
struct Vehicle: Identifiable, Codable {
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
}

enum VehicleStatus: String, Codable {
    case available
    case assigned
    case inService
    case retired
}

struct VehicleHistory: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var eventType: VehicleEventType
    var timestamp: Date
    var performedBy: UUID
    var details: String?
}

enum VehicleEventType: String, Codable {
    case registered
    case assigned
    case unassigned
    case serviceScheduled
    case serviceCompleted
    case retired
}

struct VehicleSpecifications: Codable {
    var fuelType: FuelType
    var capacity: Int
    var engineSize: Double
    var transmission: TransmissionType
}

enum FuelType: String, Codable {
    case petrol
    case diesel
    case electric
    case hybrid
}

enum TransmissionType: String, Codable {
    case manual
    case automatic
}
```

### Maintenance Management Models

```swift
struct MaintenanceRecord: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var serviceType: ServiceType
    var scheduledDate: Date
    var completedDate: Date?
    var status: MaintenanceStatus
    var cost: Double?
    var vendorName: String?
    var notes: String?
    var performedBy: UUID
}

enum ServiceType: String, Codable, CaseIterable {
    case oilChange
    case tireRotation
    case brakeService
    case inspection
    case repair
    case other
}

enum MaintenanceStatus: String, Codable {
    case scheduled
    case inProgress
    case completed
    case cancelled
}

struct ServiceSchedule: Identifiable, Codable {
    let id: UUID
    var vehicleId: UUID
    var serviceType: ServiceType
    var intervalType: IntervalType
    var intervalValue: Int
    var lastServiceDate: Date?
    var nextServiceDate: Date
}

enum IntervalType: String, Codable {
    case days
    case kilometers
    case months
}
```

---

## Appendix B: Service Protocol Reference

```swift
// Authentication Services
protocol AuthServiceProtocol {
    func login(email: String, password: String) async throws -> User
    func logout() async throws
    func validateSession() async throws -> Bool
}

protocol TwoFactorServiceProtocol {
    func sendCode(userId: UUID) async throws
    func verifyCode(userId: UUID, code: String) async throws -> Bool
}

protocol SessionManagerProtocol {
    func createSession(user: User) -> Session
    func getActiveSession() -> Session?
    func invalidateSession()
}

protocol EmailServiceProtocol {
    func sendSetupEmail(to: String, token: String) async throws
    func sendPasswordResetEmail(to: String, token: String) async throws
}

protocol AdminSetupServiceProtocol {
    func createAdminAccount(email: String) async throws -> SetupToken
    func validateSetupToken(token: String) async throws -> Bool
    func completeSetup(token: String, password: String) async throws
}

// Fleet Services
protocol FleetServiceProtocol {
    func getAllFleets() async throws -> [Fleet]
    func getFleetById(id: UUID) async throws -> Fleet
    func getFleetMetrics(id: UUID) async throws -> FleetMetrics
}

protocol AssignmentServiceProtocol {
    func createAssignment(driverId: UUID, vehicleId: UUID) async throws -> Assignment
    func getActiveAssignments() async throws -> [Assignment]
    func endAssignment(id: UUID) async throws
}

protocol ReportServiceProtocol {
    func generateReport(type: ReportType, dateRange: DateInterval) async throws -> FleetReport
    func getReportHistory() async throws -> [FleetReport]
}

// Driver Services
protocol DriverServiceProtocol {
    func getDriverProfile(userId: UUID) async throws -> Driver
    func updateDriverStatus(id: UUID, status: DriverStatus) async throws
    func getAssignedVehicle(driverId: UUID) async throws -> Vehicle?
}

protocol TripServiceProtocol {
    func startTrip(driverId: UUID, vehicleId: UUID, odometer: Double) async throws -> Trip
    func endTrip(id: UUID, odometer: Double) async throws
    func getTripHistory(driverId: UUID) async throws -> [Trip]
    func logTripEvent(tripId: UUID, event: TripEventType) async throws
}

// Vehicle Services
protocol VehicleServiceProtocol {
    func getAllVehicles() async throws -> [Vehicle]
    func getVehicleById(id: UUID) async throws -> Vehicle
    func createVehicle(vehicle: Vehicle) async throws -> Vehicle
    func updateVehicleStatus(id: UUID, status: VehicleStatus) async throws
    func updateOdometer(id: UUID, reading: Double) async throws
}

protocol VehicleAssignmentServiceProtocol {
    func assignVehicle(vehicleId: UUID, driverId: UUID) async throws
    func unassignVehicle(vehicleId: UUID) async throws
    func getVehicleAssignmentHistory(vehicleId: UUID) async throws -> [Assignment]
}

protocol VehicleHistoryServiceProtocol {
    func logEvent(vehicleId: UUID, event: VehicleEventType, performedBy: UUID) async throws
    func getVehicleHistory(vehicleId: UUID) async throws -> [VehicleHistory]
}

// Maintenance Services
protocol MaintenanceServiceProtocol {
    func scheduleService(vehicleId: UUID, type: ServiceType, date: Date) async throws -> MaintenanceRecord
    func logMaintenance(record: MaintenanceRecord) async throws
    func completeService(id: UUID, cost: Double, notes: String) async throws
    func getUpcomingServices() async throws -> [MaintenanceRecord]
    func getMaintenanceHistory(vehicleId: UUID) async throws -> [MaintenanceRecord]
}

protocol ServiceScheduleServiceProtocol {
    func createSchedule(vehicleId: UUID, type: ServiceType, interval: Int) async throws -> ServiceSchedule
    func getSchedulesForVehicle(vehicleId: UUID) async throws -> [ServiceSchedule]
    func calculateNextServiceDate(schedule: ServiceSchedule) -> Date
}

protocol CostTrackingServiceProtocol {
    func getTotalCost(vehicleId: UUID, dateRange: DateInterval) async throws -> Double
    func getCostBreakdown(vehicleId: UUID) async throws -> [ServiceType: Double]
}
```

---

**Document Version:** 1.0  
**Last Updated:** January 7, 2026  
**Author:** Senior iOS Architect  
**Target Audience:** Development Team, Stakeholders, Academic Review
