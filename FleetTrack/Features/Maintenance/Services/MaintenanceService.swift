//
//  MaintenanceService.swift
//  FleetTrack
//
//  Created for Maintenance Module
//

import Foundation
import Supabase

class MaintenanceService {
    static let shared = MaintenanceService()
    
    // Access the global Supabase client
    private var client: SupabaseClient {
        SupabaseClientManager.shared.client
    }
    
    private init() {}
    
    // MARK: - Fetch Operations
    
    /// Fetch all maintenance tasks from Supabase
    func fetchMaintenanceTasks() async throws -> [MaintenanceTask] {
        let tasks: [MaintenanceTask] = try await client
            .from("maintenance_tasks")
            .select()
            .execute()
            .value
        
        print("✅ Fetched \(tasks.count) maintenance tasks from Supabase")
        return tasks
    }
    
    /// Fetch maintenance summary statistics
    func fetchMaintenanceSummary() async throws -> MaintenanceSummary {
        // Query the maintenance_summary view
        struct SummaryResponse: Codable {
            let completedTasksThisMonth: Int?
            let averageCompletionTimeHours: Double?
            
            enum CodingKeys: String, CodingKey {
                case completedTasksThisMonth = "completed_tasks_this_month"
                case averageCompletionTimeHours = "average_completion_time_hours"
            }
        }
        
        let response: [SummaryResponse] = try await client
            .from("maintenance_summary")
            .select()
            .execute()
            .value
        
        // Extract first row (view returns single row)
        let summaryData = response.first
        
        let summary = MaintenanceSummary(
            completedTasksThisMonth: summaryData?.completedTasksThisMonth ?? 0,
            averageCompletionTimeHours: summaryData?.averageCompletionTimeHours ?? 0.0
        )
        
        print("✅ Fetched maintenance summary: \(summary.completedTasksThisMonth) completed tasks")
        return summary
    }
    
    // MARK: - Create Operations
    
    /// Add a new maintenance task
    func addMaintenanceTask(_ data: MaintenanceTaskCreationData) async throws {
        let newTask = MaintenanceTask(
            id: UUID(),
            vehicleRegistrationNumber: data.vehicleRegistrationNumber,
            priority: data.priority,
            component: data.component,
            status: data.status,
            dueDate: data.dueDate,
            completedDate: nil,
            partsUsed: data.partsUsed
        )
        
        try await client
            .from("maintenance_tasks")
            .insert(newTask)
            .execute()
        
        print("✅ Maintenance task created: \(data.component.rawValue) for \(data.vehicleRegistrationNumber)")
    }
    
    // MARK: - Update Operations
    
    /// Update the status of a maintenance task
    func updateTaskStatus(taskId: UUID, status: String) async throws {
        struct StatusUpdate: Encodable {
            let status: String
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }
        
        let update = StatusUpdate(status: status)
        
        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task \(taskId) status updated to: \(status)")
    }
    
    /// Mark a task as completed
    func completeTask(taskId: UUID, completedDate: Date = Date()) async throws {
        struct CompletionUpdate: Encodable {
            let status: String = "Completed"
            let completedDate: Date
            let updatedAt: Date = Date()
            
            enum CodingKeys: String, CodingKey {
                case status
                case completedDate = "completed_date"
                case updatedAt = "updated_at"
            }
        }
        
        let update = CompletionUpdate(completedDate: completedDate)
        
        try await client
            .from("maintenance_tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task \(taskId) marked as completed")
    }
    
    // MARK: - Delete Operations
    
    /// Delete a maintenance task
    func deleteTask(taskId: UUID) async throws {
        try await client
            .from("maintenance_tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task \(taskId) deleted")
    }
}
