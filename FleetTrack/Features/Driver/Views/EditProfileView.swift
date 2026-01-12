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
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(user: Binding<User>, driver: Binding<Driver>, isPresented: Binding<Bool>) {
        self._user = user
        self._driver = driver
        self._isPresented = isPresented
        self._name = State(initialValue: user.wrappedValue.name)
        self._phoneNumber = State(initialValue: user.wrappedValue.phoneNumber ?? "")
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundPrimary.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Personal Information").foregroundColor(AppTheme.textSecondary)) {
                        TextField("Name", text: $name)
                            .foregroundColor(AppTheme.textPrimary)
                        TextField("Phone Number", text: $phoneNumber)
                            .foregroundColor(AppTheme.textPrimary)
                            .keyboardType(.phonePad)
                    }
                    .listRowBackground(AppTheme.backgroundSecondary)
                    
                    Section(header: Text("Driver Details").foregroundColor(AppTheme.textSecondary)) {
                        HStack {
                            Text("License")
                            Spacer()
                            Text(driver.driverLicenseNumber)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        HStack {
                            Text("Experience")
                            Spacer()
                            Text("\(driver.yearsOfExperience) years")
                                .foregroundColor(AppTheme.textSecondary)
                        }
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
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                        }
                    }
                    .foregroundColor(AppTheme.accentPrimary)
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
            // Update in Supabase
            let updatedUser = try await supabase
                .from("users")
                .update(["name": name, "phone_number": phoneNumber])
                .eq("id", value: user.id)
                .select()
                .single()
                .execute()
                .value as User
            
            await MainActor.run {
                self.user = updatedUser
                self.isLoading = false
                self.isPresented = false
            }
        } catch {
            print(" Error saving profile: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to save profile. Please try again."
                self.isLoading = false
            }
        }
    }
}
