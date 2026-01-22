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
                AppTheme.backgroundPrimary.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Personal Information").foregroundColor(AppTheme.textSecondary)) {
                        TextField("Name", text: $name)
                            .foregroundColor(AppTheme.textPrimary)
                            .accessibilityLabel("Full Name")
                            .accessibilityIdentifier("edit_profile_name_field")
                        TextField("Phone Number", text: $phoneNumber)
                            .foregroundColor(AppTheme.textPrimary)
                            .keyboardType(.phonePad)
                            .accessibilityLabel("Phone Number")
                            .accessibilityIdentifier("edit_profile_phone_field")
                        TextField("Address", text: $address)
                            .foregroundColor(AppTheme.textPrimary)
                            .accessibilityLabel("Home Address")
                            .accessibilityIdentifier("edit_profile_address_field")
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
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
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Experience: \(driver.yearsOfExperience ?? 0) years")
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                }
                .scrollContentBackground(.hidden)
                
                if isLoading {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView()
                        .tint(AppTheme.accentPrimary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                    .accessibilityIdentifier("edit_profile_cancel_button")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .foregroundColor(AppTheme.accentPrimary)
                    .disabled(name.isEmpty || isLoading)
                    .accessibilityIdentifier("edit_profile_save_button")
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
        
        print("📝 Saving profile for driver: \(driver.id)")
        
        do {
            // 1. Update in "users" table
            struct UserUpdate: Encodable {
                let name: String
                let phone_number: String
            }
            
            let userUpdates = UserUpdate(name: name, phone_number: phoneNumber)
            
            let updatedUser: User = try await supabase.database
                .from("users")
                .update(userUpdates)
                .eq("id", value: user.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ User updated successfully")
            
            // 2. Update in "drivers" table
            struct DriverUpdate: Encodable {
                let full_name: String
                let phone_number: String?
                let address: String?
                let updated_at: String
            }
            
            let dateFormatter = ISO8601DateFormatter()
            let driverUpdates = DriverUpdate(
                full_name: name,
                phone_number: phoneNumber.isEmpty ? nil : phoneNumber,
                address: address.isEmpty ? nil : address,
                updated_at: dateFormatter.string(from: Date())
            )
            
            let updatedDriver: Driver = try await supabase.database
                .from("drivers")
                .update(driverUpdates)
                .eq("id", value: driver.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Driver updated successfully")
            
            await MainActor.run {
                self.user = updatedUser
                self.driver = updatedDriver
                self.isLoading = false
                self.isPresented = false
            }
        } catch {
            print("❌ Error saving profile: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}
