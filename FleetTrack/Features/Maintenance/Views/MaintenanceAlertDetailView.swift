//
//  AlertDetailView.swift
//  FleetTrack
//
//  Created for Maintenance Module - Alert Management
//

import SwiftUI
import Combine

struct MaintenanceAlertDetailView: View {
    let alert: MaintenanceAlert
    @StateObject private var viewModel = MaintenanceAlertDetailViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.spacing.lg) {
                    // Alert Header Card
                    alertHeaderCard
                    
                    // Driver Contact Card (who reported the alert)
                    if let driver = viewModel.driver {
                        driverContactCard(driver: driver)
                    } else if viewModel.isLoading {
                        loadingView
                    } else {
                        noDriverView
                    }
                    
                    // Task Information (if available)
                    if let task = viewModel.task {
                        taskInfoCard(task: task)
                    }
                }
                .padding(AppTheme.spacing.md)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Alert Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAlertDetails(alert: alert)
        }
    }
    
    // MARK: - Alert Header Card
    
    private var alertHeaderCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            HStack {
                Image(systemName: iconForAlertType(alert.type))
                    .font(.system(size: 24))
                    .foregroundColor(colorForAlertType(alert.type))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.type.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(colorForAlertType(alert.type))
                    
                    Text(alert.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(AppTheme.iconDefault)
                
                Text(alert.date.formatted(date: .long, time: .shortened))
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Task Info Card
    
    private func taskInfoCard(task: MaintenanceTask) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Related Task")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Divider()
            
            VStack(spacing: AppTheme.spacing.sm) {
                MaintenanceAlertInfoRow(icon: "wrench.fill", label: "Component", value: task.component.rawValue)
                MaintenanceAlertInfoRow(icon: "car.fill", label: "Vehicle", value: task.vehicleRegistrationNumber)
                MaintenanceAlertInfoRow(icon: "calendar", label: "Due Date", value: task.dueDate.formatted(date: .abbreviated, time: .shortened))
                
                HStack {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(AppTheme.iconDefault)
                    
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text(task.status)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor(for: task.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: task.status).opacity(0.15))
                        .cornerRadius(AppTheme.cornerRadius.small)
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Driver Contact Card
    
    private func driverContactCard(driver: Driver) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Reported By")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Divider()
            
            // Driver Info
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.accentPrimary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(driver.fullName)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let phone = driver.phoneNumber {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Text(driver.email)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
            }
            .padding(.bottom, AppTheme.spacing.sm)
            
            // Contact Actions
            HStack(spacing: AppTheme.spacing.sm) {
                // Call Button
                if let phone = driver.phoneNumber {
                    Button(action: {
                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                            Text("Call")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.statusActiveText)
                        .cornerRadius(AppTheme.cornerRadius.medium)
                    }
                }
                
                // Email Button
                Button(action: {
                    if let url = URL(string: "mailto:\(driver.email)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Email")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accentPrimary)
                    .cornerRadius(AppTheme.cornerRadius.medium)
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: AppTheme.spacing.md) {
            ProgressView()
                .tint(AppTheme.accentPrimary)
            Text("Loading driver details...")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing.lg)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - No Driver View
    
    private var noDriverView: some View {
        VStack(spacing: AppTheme.spacing.sm) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Driver Information Unavailable")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("No driver assigned to this alert")
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing.lg)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Helper Functions
    
    private func iconForAlertType(_ type: AlertType) -> String {
        switch type {
        case .emergency:
            return "exclamationmark.triangle.fill"
        case .system, .maintenance:
            return "exclamationmark.circle.fill"
        case .inventory:
            return "info.circle.fill"
        }
    }
    
    private func colorForAlertType(_ type: AlertType) -> Color {
        switch type {
        case .emergency:
            return AppTheme.statusError
        case .system, .maintenance:
            return AppTheme.statusWarning
        case .inventory:
            return AppTheme.accentPrimary
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Completed":
            return .green
            return Color(hexCode: "2D7D46")
        case "In Progress":
            return .blue
        case "Pending":
            return .orange
        case "Failed":
            return .red
        case "Cancelled":
            return .gray
        default:
            return .gray
        }
    }
}

// MARK: - ViewModel

@MainActor
class MaintenanceAlertDetailViewModel: ObservableObject {
    @Published var task: MaintenanceTask?
    @Published var driver: Driver?
    @Published var isLoading = false
    
    func loadAlertDetails(alert: MaintenanceAlert) async {
        print("🔍 [DEBUG] Starting loadAlertDetails for alert: \(alert.id)")
        print("🔍 [DEBUG] Alert title: \(alert.title)")
        print("🔍 [DEBUG] Alert type: \(alert.type.rawValue)")
        print("🔍 [DEBUG] Alert driverId: \(alert.driverId?.uuidString ?? "nil")")
        print("🔍 [DEBUG] Alert taskId: \(alert.taskId?.uuidString ?? "nil")")
        
        isLoading = true
        
        // 1. Try to fetch driver directly from alert
        if let driverId = alert.driverId {
            print("🔍 [DEBUG] Attempting to fetch driver directly with ID: \(driverId)")
            do {
                driver = try await MaintenanceService.shared.fetchDriverForAlert(driverId: driverId)
                if let driver = driver {
                    print("✅ [SUCCESS] Loaded driver from alert: \(driver.fullName)")
                    print("✅ [SUCCESS] Driver email: \(driver.email)")
                    print("✅ [SUCCESS] Driver phone: \(driver.phoneNumber ?? "nil")")
                } else {
                    print("⚠️ [WARNING] fetchDriverForAlert returned nil")
                }
            } catch {
                print("❌ [ERROR] Failed to load driver from alert: \(error)")
                print("❌ [ERROR] Error details: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ [INFO] No driverId in alert, will try fallback methods")
        }
        
        // 2. Load task if taskId is available
        if let taskId = alert.taskId {
            print("🔍 [DEBUG] Attempting to fetch task with ID: \(taskId)")
            do {
                // Fetch all tasks and find the matching one
                let allTasks = try await MaintenanceService.shared.fetchMaintenanceTasks()
                print("🔍 [DEBUG] Fetched \(allTasks.count) total tasks")
                
                task = allTasks.first { $0.id == taskId }
                
                if let task = task {
                    print("✅ [SUCCESS] Found task: \(task.component.rawValue)")
                    print("🔍 [DEBUG] Task assignedDriverId: \(task.assignedDriverId?.uuidString ?? "nil")")
                    print("🔍 [DEBUG] Task vehicleRegistrationNumber: \(task.vehicleRegistrationNumber)")
                } else {
                    print("⚠️ [WARNING] Task not found in fetched tasks")
                }
                
                // 3. Fallback: Try to get driver from task/vehicle if not found directly
                if driver == nil {
                    print("🔍 [DEBUG] Driver not found yet, trying fallback methods")
                    
                    if let driverId = task?.assignedDriverId {
                        print("🔍 [DEBUG] Attempting to fetch driver from task with ID: \(driverId)")
                        driver = try await MaintenanceService.shared.fetchDriver(byId: driverId)
                        if let driver = driver {
                            print("✅ [SUCCESS] Loaded driver from task: \(driver.fullName)")
                        } else {
                            print("⚠️ [WARNING] fetchDriver(byId:) returned nil")
                        }
                    } else if let vehicleReg = task?.vehicleRegistrationNumber {
                        print("🔍 [DEBUG] No driver on task, trying vehicle: \(vehicleReg)")
                        // Try to get driver from vehicle
                        if let vehicle = try await MaintenanceService.shared.fetchVehicle(byRegistration: vehicleReg) {
                            print("✅ [SUCCESS] Found vehicle: \(vehicle.manufacturer) \(vehicle.model)")
                            print("🔍 [DEBUG] Vehicle assignedDriverId: \(vehicle.assignedDriverId?.uuidString ?? "nil")")
                            
                            if let driverId = vehicle.assignedDriverId {
                                print("🔍 [DEBUG] Attempting to fetch driver from vehicle with ID: \(driverId)")
                                driver = try await MaintenanceService.shared.fetchDriver(byId: driverId)
                                if let driver = driver {
                                    print("✅ [SUCCESS] Loaded driver from vehicle: \(driver.fullName)")
                                } else {
                                    print("⚠️ [WARNING] fetchDriver(byId:) from vehicle returned nil")
                                }
                            } else {
                                print("ℹ️ [INFO] Vehicle has no assigned driver")
                            }
                        } else {
                            print("⚠️ [WARNING] Vehicle not found: \(vehicleReg)")
                        }
                    } else {
                        print("ℹ️ [INFO] Task has no assignedDriverId or vehicleRegistrationNumber")
                    }
                } else {
                    print("ℹ️ [INFO] Driver already loaded, skipping fallback")
                }
            } catch {
                print("❌ [ERROR] Error loading alert details: \(error)")
                print("❌ [ERROR] Error details: \(error.localizedDescription)")
            }
        } else {
            print("ℹ️ [INFO] No taskId in alert")
        }
        
        // Final status
        if driver != nil {
            print("✅ [FINAL] Driver loaded successfully: \(driver!.fullName)")
        } else {
            print("❌ [FINAL] No driver found after all attempts")
        }
        
        isLoading = false
        print("🔍 [DEBUG] Finished loadAlertDetails, isLoading = false")
    }
}

// MARK: - Info Row Component

private struct MaintenanceAlertInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(AppTheme.iconDefault)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}
