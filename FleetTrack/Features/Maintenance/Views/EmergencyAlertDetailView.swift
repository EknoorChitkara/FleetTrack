//
//  EmergencyAlertDetailView.swift
//  FleetTrack
//
//  Emergency Alert Detail with Driver Contact
//

import SwiftUI

struct EmergencyAlertDetailView: View {
    let alert: MaintenanceAlert
    @Environment(\.dismiss) var dismiss
    @State private var driver: Driver?
    @State private var vehicle: Vehicle?
    @State private var isLoadingDriver = false
    @State private var showingCallConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing.lg) {
                        // Emergency Header
                        emergencyHeaderCard
                        
                        // Alert Details
                        alertDetailsCard
                        
                        // Vehicle Information (if available)
                        if vehicle != nil {
                            vehicleInfoCard
                        }
                        
                        // Driver Contact (if available)
                        if driver != nil {
                            driverContactCard
                        }
                        
                        // Action Buttons
                        if driver != nil {
                            actionButtonsSection
                        }
                    }
                    .padding(AppTheme.spacing.md)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Emergency Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadDetails()
            }
            .alert("Call Driver", isPresented: $showingCallConfirmation) {
                if let phone = driver?.phoneNumber, !phone.isEmpty {
                    Button("Call") {
                        if let url = URL(string: "tel://\(phone)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                if let driverName = driver?.fullName, let phone = driver?.phoneNumber {
                    Text("Call \(driverName) at \(phone)?")
                }
            }
        }
    }
    
    // MARK: - Emergency Header Card
    
    private var emergencyHeaderCard: some View {
        VStack(spacing: AppTheme.spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text(alert.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(formattedDate(alert.date))
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing.lg)
        .background(
            LinearGradient(
                colors: [Color.red.opacity(0.1), Color.orange.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.cornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius.medium)
                .stroke(Color.red.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Alert Details Card
    
    private var alertDetailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Alert Details")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(alert.message)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Vehicle Info Card
    
    private var vehicleInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Vehicle Information")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if let vehicle = vehicle {
                VStack(spacing: AppTheme.spacing.sm) {
                    InfoRow(icon: "car.fill", label: "Vehicle", value: "\(vehicle.manufacturer) \(vehicle.model)")
                    InfoRow(icon: "number", label: "Registration", value: vehicle.registrationNumber)
                }
            } else if isLoadingDriver {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if let registration = alert.vehicleRegistration {
                InfoRow(icon: "number", label: "Registration", value: registration)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Driver Contact Card
    
    private var driverContactCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing.md) {
            Text("Driver Contact")
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            if let driver = driver {
                VStack(spacing: AppTheme.spacing.sm) {
                    InfoRow(icon: "person.fill", label: "Name", value: driver.fullName)
                    InfoRow(icon: "envelope.fill", label: "Email", value: driver.email)
                    
                    if let phone = driver.phoneNumber, !phone.isEmpty {
                        InfoRow(icon: "phone.fill", label: "Phone", value: phone)
                    } else {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(AppTheme.iconDefault)
                            Text("Phone")
                                .foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text("Not available")
                                .foregroundColor(AppTheme.textTertiary)
                                .italic()
                        }
                    }
                }
            } else if isLoadingDriver {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: AppTheme.spacing.sm) {
            if let phone = driver?.phoneNumber, !phone.isEmpty {
                Button(action: {
                    showingCallConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call Driver")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.accentPrimary)
                    .foregroundColor(.black)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    .fontWeight(.semibold)
                }
            }
            
            if let email = driver?.email {
                Button(action: {
                    if let url = URL(string: "mailto:\(email)") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Email Driver")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.backgroundElevated)
                    .foregroundColor(AppTheme.textPrimary)
                    .cornerRadius(AppTheme.cornerRadius.small)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadDetails() async {
        isLoadingDriver = true
        
        // Load vehicle if available
        if let vehicleId = alert.vehicleId {
            do {
                vehicle = try await MaintenanceService.shared.fetchVehicle(byId: vehicleId)
                print("✅ Loaded vehicle: \(vehicle?.registrationNumber ?? "")")
            } catch {
                print("❌ Error loading vehicle: \(error)")
            }
        } else if let registration = alert.vehicleRegistration {
            do {
                vehicle = try await MaintenanceService.shared.fetchVehicle(byRegistration: registration)
                print("✅ Loaded vehicle by registration: \(registration)")
            } catch {
                print("❌ Error loading vehicle by registration: \(error)")
            }
        }
        
        // Load driver if available
        if let driverId = alert.driverId {
            do {
                driver = try await MaintenanceService.shared.fetchDriver(byId: driverId)
                print("✅ Loaded driver: \(driver?.fullName ?? "")")
            } catch {
                print("❌ Error loading driver: \(error)")
            }
        } else if let vehicle = vehicle, let driverId = vehicle.assignedDriverId {
            do {
                driver = try await MaintenanceService.shared.fetchDriver(byId: driverId)
                print("✅ Loaded driver from vehicle: \(driver?.fullName ?? "")")
            } catch {
                print("❌ Error loading driver from vehicle: \(error)")
            }
        }
        
        isLoadingDriver = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

