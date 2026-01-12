//
//  EditProfileView.swift
//  FleetTrack
//

import SwiftUI
import Supabase
struct EditProfileView: View {
    @Binding var user: User
    @Binding var driver: Driver
    @Binding var isPresented: Bool
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var address: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(user: Binding<User>, driver: Binding<Driver>, isPresented: Binding<Bool>) {
        self._user = user
        self._driver = driver
        self._isPresented = isPresented
        self._name = State(initialValue: driver.wrappedValue.fullName.isEmpty ? user.wrappedValue.name : driver.wrappedValue.fullName)
        self._phoneNumber = State(initialValue: driver.wrappedValue.phoneNumber ?? user.wrappedValue.phoneNumber ?? "")
        self._address = State(initialValue: driver.wrappedValue.address ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Personal Information").foregroundColor(AppTheme.textSecondary)) {
                        TextField("Name", text: $name)
                            .foregroundColor(AppTheme.textPrimary)
                        TextField("Phone Number", text: $phoneNumber)
                            .foregroundColor(AppTheme.textPrimary)
                            .keyboardType(.phonePad)
                        TextField("Address", text: $address)
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .listRowBackground(AppTheme.cardBackground)
                    
                    Section(header: Text("Driver Details").foregroundColor(AppTheme.textSecondary)) {
                        HStack {
                            Text("License")
                            Spacer()
                            Text(driver.driverLicenseNumber ?? "Not Set")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        HStack {
                            Text("Experience")
                            Spacer()
                            Text("\(driver.yearsOfExperience ?? 0) years")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground)
                }
                .scrollContentBackground(.hidden)
                
                if isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .tint(AppTheme.primary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .foregroundColor(AppTheme.primary)
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
        }
    }
    
    private func saveProfile() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Update in "users" table
            let updatedUser = try await supabase.database
                .from("users")
                .update(["name": name, "phone_number": phoneNumber])
                .eq("id", value: user.id)
                .select()
                .single()
                .execute()
                .value as User
            
            // 2. Update in "drivers" table
            struct DriverUpdate: Encodable {
                let full_name: String
                let phone_number: String
                let address: String
            }
            
            let driverUpdates = DriverUpdate(
                full_name: name,
                phone_number: phoneNumber,
                address: address
            )
            
            let updatedDriver = try await DriverService.shared.updateDriverProfile(driverId: driver.id, updates: driverUpdates)
            
            await MainActor.run {
                self.user = updatedUser
                self.driver = updatedDriver
                self.isLoading = false
                self.isPresented = false
            }
        } catch {
            print("❌ Error saving profile: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to save profile. Please try again."
                self.isLoading = false
            }
        }
    }
}
