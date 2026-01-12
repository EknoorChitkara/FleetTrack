//
//  MaintenanceDashboardViewModel.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import Foundation
import Combine

class MaintenanceDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Old properties - commented out for now, will be implemented later
    // @Published var stats: MaintenanceDashboardStats
    // @Published var todaysSchedule: [WorkOrder]
    // @Published var priorityTasks: [WorkOrder]
    // @Published var alerts: [MaintenanceAlert]
    @Published var isLoading: Bool = false
    
    // New properties for updated dashboard design
    @Published var currentUser: User
    @Published var pendingTasksCount: Int = 0
    @Published var inProgressTasksCount: Int = 0
    @Published var maintenanceSummary: MaintenanceSummary
    @Published var highPriorityMaintenanceTasks: [MaintenanceTask] = []
    @Published var completedTasks: [MaintenanceTask] = []
    
    // MARK: - Initialization
    
    init(user: User) {
        // Initialize new dashboard properties
        // Using the existing User model from Authentication
        self.currentUser = user
        self.maintenanceSummary = MaintenanceSummary(
            completedTasksThisMonth: 45,
            averageCompletionTimeHours: 2.5
        )
        
        // Load mock data for preview/development
        loadData()
    }
    
    // MARK: - Data Loading
    
    func loadData() {
        self.isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.generateMockData()
            self.isLoading = false
        }
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockData() {
        // Old mock data commented out - uses types that don't exist yet
        /*
        // Mock Stats
        self.stats = MaintenanceDashboardStats(
            totalActiveWorkOrders: 12,
            upcomingScheduledMaintenance: 5,
            overdueMaintenance: 2,
            currentMonthCost: 15430.00,
            previousMonthCost: 12800.00,
            healthyVehiclesCount: 42,
            vehiclesInMaintenanceCount: 3,
            totalVehicles: 45,
            completedRequestsThisMonth: 18,
            averageCompletionTimeHours: 4.5
        )
        
        // Mock Today's Schedule (Work Orders scheduled for today)
        self.todaysSchedule = [...]
        
        // Mock Priority Tasks
        self.priorityTasks = [...]
        
        // Mock Alerts
        self.alerts = [...]
        */
        
        // Generate new dashboard data
        generateDashboardData()
    }
    
    private func generateDashboardData() {
        // Task counts
        self.pendingTasksCount = 5
        self.inProgressTasksCount = 3
        
        // High priority maintenance tasks
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let jan22 = calendar.date(from: DateComponents(year: 2026, month: 1, day: 22))!
        
        self.highPriorityMaintenanceTasks = [
            MaintenanceTask(
                vehicleRegistrationNumber: "TRK-001",
                priority: .high,
                component: .oil,
                status: "Pending",
                dueDate: today
            ),
            MaintenanceTask(
                vehicleRegistrationNumber: "VAN-002",
                priority: .high,
                component: .tires,
                status: "Pending",
                dueDate: tomorrow
            ),
            MaintenanceTask(
                vehicleRegistrationNumber: "TRK-005",
                priority: .high,
                component: .brakes,
                status: "Pending",
                dueDate: jan22
            )
        ]
        
        // Generate completed tasks (most recent 3)
        self.completedTasks = [
            MaintenanceTask(
                vehicleRegistrationNumber: "TRK-001",
                priority: .medium,
                component: .oilChange,
                dueDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            ),
            MaintenanceTask(
                vehicleRegistrationNumber: "VAN-003",
                priority: .low,
                component: .tireReplacement,
                dueDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
            ),
            MaintenanceTask(
                vehicleRegistrationNumber: "TRK-005",
                priority: .medium,
                component: .brakeInspection,
                dueDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
            )
        ]
    }
}
