# FleetTrack Data Models Documentation

## Overview

This document provides a comprehensive overview of all data models created for the FleetTrack fleet management system. The system supports three user roles: **Fleet Manager**, **Driver**, and **Maintenance Personnel**.

---

## Core Models

### 1. User Model
**File:** `User.swift`

Represents all users in the system with role-based access control.

**Properties:**
- `id: UUID` - Unique identifier
- `name: String` - User's full name
- `email: String` - Email address
- `phoneNumber: String` - Contact number
- `role: UserRole` - User's role (Fleet Manager, Driver, or Maintenance Personnel)
- `profileImageURL: String?` - Optional profile picture
- `isActive: Bool` - Account status
- `createdAt: Date` - Account creation timestamp
- `updatedAt: Date` - Last update timestamp

**Enums:**
- `UserRole`: `.fleetManager`, `.driver`, `.maintenancePersonnel`

**Features:**
- Computed `initials` property for avatar display

---

### 2. Vehicle Model
**File:** `Vehicle.swift`

Comprehensive vehicle tracking with live status and location data (based on your UI screenshots).

**Properties:**
- `id: UUID` - Unique identifier
- `registrationNumber: String` - License plate (e.g., "DL-01-AB-1234")
- `model: String` - Vehicle model (e.g., "Ace")
- `manufacturer: String` - Manufacturer name (e.g., "Tata")
- `vehicleType: VehicleType` - Type classification
- `status: VehicleStatus` - Current operational status

**Live Tracking:**
- `currentSpeed: Double` - Real-time speed in km/h
- `fuelLevel: Double` - Fuel percentage (0-100)
- `totalMileage: Double` - Odometer reading in km
- `averageFuelEfficiency: Double` - km/l
- `currentLocation: Location?` - GPS coordinates and address
- `lastUpdated: Date` - Last tracking update

**Assignment & Maintenance:**
- `assignedDriverId: UUID?` - Currently assigned driver
- `nextServiceDue: Date?` - Upcoming service date
- `lastServiceDate: Date?` - Most recent service

**Additional Details:**
- `yearOfManufacture: Int?`
- `vinNumber: String?`
- `color: String?`
- `capacity: String?` - Load or passenger capacity

**Enums:**
- `VehicleStatus`: `.active`, `.inMaintenance`, `.inactive`, `.outOfService`
- `VehicleType`: `.lightCommercial`, `.heavyCommercial`, `.passenger`, `.specialized`

**Nested Type:**
- `Location`: Contains `latitude`, `longitude`, `address`, `lastUpdated`

---

### 3. Trip Model
**File:** `Trip.swift`

Manages trip creation by fleet managers and execution by drivers.

**Properties:**
- `id: UUID` - Unique identifier
- `vehicleId: UUID` - Assigned vehicle
- `driverId: UUID` - Assigned driver
- `status: TripStatus` - Trip lifecycle status
- `startLocation: Location?` - Starting point
- `endLocation: Location?` - Destination
- `startTime: Date?` - Actual start time (set when driver starts)
- `endTime: Date?` - Actual end time
- `distance: Double?` - Total distance in km
- `purpose: String?` - Trip description
- `notes: String?` - Additional notes
- `createdBy: UUID` - Fleet Manager who created the trip

**Enums:**
- `TripStatus`: `.scheduled`, `.ongoing`, `.completed`, `.cancelled`

**Computed Properties:**
- `duration: TimeInterval?` - Trip duration
- `formattedDuration: String?` - Human-readable duration
- `formattedDistance: String?` - Formatted distance string

---

### 4. Part Model
**File:** `Part.swift`

Inventory management for vehicle parts with stock tracking.

**Properties:**
- `id: UUID` - Unique identifier
- `name: String` - Part name
- `partNumber: String` - SKU/Part number
- `category: PartCategory` - Part classification
- `description: String?` - Detailed description
- `quantityInStock: Int` - Current inventory count
- `minimumStockLevel: Int` - Reorder threshold
- `unitPrice: Double` - Price per unit
- `supplierName: String?` - Supplier information
- `supplierContact: String?` - Supplier phone/email
- `isActive: Bool` - Active status

**Enums:**
- `PartCategory`: `.engine`, `.transmission`, `.brakes`, `.suspension`, `.electrical`, `.bodyWork`, `.tires`, `.fluids`, `.filters`, `.other`

**Computed Properties:**
- `isLowStock: Bool` - Checks if stock is at or below minimum
- `stockStatus: String` - "Out of Stock", "Low Stock", or "In Stock"
- `formattedPrice: String` - Currency-formatted price

---

### 5. MaintenanceRecord Model
**File:** `MaintenanceRecord.swift`

Tracks all maintenance activities, repairs, and service history.

**Properties:**
- `id: UUID` - Unique identifier
- `vehicleId: UUID` - Vehicle being serviced
- `type: MaintenanceType` - Service classification
- `status: MaintenanceStatus` - Current status
- `title: String` - Service title
- `description: String?` - Detailed description
- `scheduledDate: Date` - Planned service date
- `startedDate: Date?` - Actual start
- `completedDate: Date?` - Actual completion
- `performedBy: UUID?` - Maintenance personnel ID
- `laborCost: Double` - Labor charges
- `partsUsed: [PartUsage]` - Array of parts with quantities
- `mileageAtService: Double?` - Vehicle mileage during service
- `workNotes: String?` - Technical notes
- `recommendations: String?` - Future recommendations

**Enums:**
- `MaintenanceType`: `.scheduledService`, `.repair`, `.inspection`, `.emergency`
- `MaintenanceStatus`: `.scheduled`, `.inProgress`, `.completed`, `.cancelled`

**Nested Type:**
- `PartUsage`: Contains `partId`, `quantity`, `unitPrice`, computed `totalCost`

**Computed Properties:**
- `totalCost: Double` - Labor + parts total
- `formattedTotalCost: String` - Currency-formatted total

---

### 6. ServiceSchedule Model
**File:** `ServiceSchedule.swift`

Automated service scheduling based on mileage and/or time intervals.

**Properties:**
- `id: UUID` - Unique identifier
- `vehicleId: UUID` - Vehicle to service
- `serviceType: String` - Type of service (e.g., "Oil Change")
- `intervalType: ServiceInterval` - Mileage, time, or both
- `mileageInterval: Double?` - Km between services
- `timeInterval: Int?` - Days between services
- `nextServiceDate: Date?` - Next scheduled date
- `nextServiceMileage: Double?` - Next scheduled mileage
- `lastServiceDate: Date?` - Last completed date
- `lastServiceMileage: Double?` - Last completed mileage
- `lastMaintenanceRecordId: UUID?` - Reference to last service
- `isActive: Bool` - Schedule status
- `notes: String?` - Additional notes

**Enums:**
- `ServiceInterval`: `.mileageBased`, `.timeBased`, `.both`
- `ScheduleStatus`: `.upcoming`, `.due`, `.overdue`, `.completed` (computed)

**Computed Properties:**
- `status: ScheduleStatus` - Auto-calculated based on dates
- `daysUntilDue: Int?` - Days remaining
- `kmUntilDue: Double?` - Kilometers remaining

---

### 7. IssueReport Model
**File:** `IssueReport.swift`

Driver-reported issues with priority tracking and resolution workflow.

**Properties:**
- `id: UUID` - Unique identifier
- `vehicleId: UUID` - Vehicle with issue
- `reportedBy: UUID` - Driver ID
- `assignedTo: UUID?` - Maintenance personnel ID
- `title: String` - Issue summary
- `description: String` - Detailed description
- `category: IssueCategory` - Issue classification
- `priority: IssuePriority` - Urgency level
- `status: IssueStatus` - Resolution status
- `reportedAt: Date` - Report timestamp
- `acknowledgedAt: Date?` - When acknowledged
- `resolvedAt: Date?` - When resolved
- `closedAt: Date?` - When closed
- `vehicleMileageAtReport: Double?` - Mileage when reported
- `locationWhenReported: Location?` - GPS location
- `resolutionNotes: String?` - Solution description
- `relatedMaintenanceRecordId: UUID?` - Link to maintenance record
- `photoURLs: [String]` - Issue photos

**Enums:**
- `IssuePriority`: `.low`, `.medium`, `.high`, `.critical`
- `IssueStatus`: `.reported`, `.acknowledged`, `.inProgress`, `.resolved`, `.closed`
- `IssueCategory`: `.mechanical`, `.electrical`, `.bodyDamage`, `.safety`, `.performance`, `.other`

**Computed Properties:**
- `isOpen: Bool` - Whether issue needs attention
- `timeToResolve: TimeInterval?` - Resolution duration

---

### 8. Assignment Model
**File:** `Assignment.swift`

Tracks vehicle-to-driver assignments with temporal management.

**Properties:**
- `id: UUID` - Unique identifier
- `vehicleId: UUID` - Assigned vehicle
- `driverId: UUID` - Assigned driver
- `status: AssignmentStatus` - Assignment type
- `assignedDate: Date` - Assignment start
- `endDate: Date?` - Assignment end (for temporary)
- `assignedBy: UUID` - Fleet Manager ID
- `notes: String?` - Assignment notes
- `isCurrentAssignment: Bool` - Current/historical flag

**Enums:**
- `AssignmentStatus`: `.active`, `.inactive`, `.temporary`

**Computed Properties:**
- `duration: TimeInterval?` - Assignment duration
- `isTemporary: Bool` - Whether assignment has end date

---

## Mock Data

All models include comprehensive mock data for testing:
- `User.mockFleetManager`, `User.mockDriver`, `User.mockMaintenancePersonnel`
- `Vehicle.mockVehicle1/2/3` (including the Tata Ace from your screenshots)
- `Trip.mockOngoingTrip`, `Trip.mockCompletedTrip`, `Trip.mockScheduledTrip`
- `Part.mockPart1/2/3/4`
- `MaintenanceRecord.mockRecord1/2/3`
- `ServiceSchedule.mockSchedule1/2/3`
- `IssueReport.mockIssue1/2/3`
- `Assignment.mockAssignment1/2`

---

## Design Features

### ✅ Comprehensive Type Safety
All models use Swift enums for type-safe status and category management.

### ✅ Protocol Conformance
All models conform to:
- `Identifiable` - For SwiftUI list rendering
- `Codable` - For JSON serialization
- `Hashable` - For collection operations

### ✅ Computed Properties
Smart computed properties for formatted display (durations, distances, costs, etc.).

### ✅ Relationship Management
UUIDs are used for relationships between models, supporting future database integration.

### ✅ Real-world Alignment
Vehicle model matches your UI screenshots with live tracking data (speed, fuel, location, efficiency).

---

## User Role Capabilities

### Fleet Manager
- Create and assign trips
- View all vehicles, trips, and maintenance data
- Manage vehicle-driver assignments
- Access reports and analytics

### Driver
- View assigned vehicle (one vehicle at a time, but reassignable)
- Start/end trips created by fleet manager
- Report issues
- View trip history

### Maintenance Personnel
- View and update parts inventory
- Log maintenance work
- View service schedules
- Update vehicle status
- Resolve driver-reported issues

---

## Next Steps for Implementation

1. **Services Layer**: Create service protocols and implementations for data operations
2. **ViewModels**: Build ObservableObject ViewModels for each feature
3. **Views**: Create SwiftUI views matching your design screenshots
4. **Persistence**: Implement local storage (UserDefaults/Core Data) or backend integration
5. **Real-time Tracking**: Integrate location services and vehicle telemetry APIs

---

**Created:** January 8, 2026  
**Models Location:** `/FleetTrack/Core/Models/`  
**Total Models:** 8 core entities with full CRUD support ready
