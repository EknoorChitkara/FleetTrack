//
//  DriverOnboardingView.swift
//  FleetTrack
//
//  Created for Driver Onboarding
//

import SwiftUI
import Supabase
import Foundation
import Combine

struct DriverOnboardingView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel: DriverOnboardingViewModel
    @State private var isAnimating = false
    
    @MainActor
    init(user: User) {
        self._viewModel = StateObject(wrappedValue: DriverOnboardingViewModel(user: user))
    }
    
    var body: some View {
        ZStack {
            // Background with animated gradient
            AnimatedBackground()
            
            VStack(spacing: 30) {
                // Header section
                VStack(spacing: 12) {
                    Image(systemName: "truck.box.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.appEmerald)
                        .shadow(color: Color.appEmerald.opacity(0.5), radius: 10)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear { isAnimating = true }
                    
                    Text("Welcome to FleetTrack")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Let's set up your professional profile")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 40)
                
                // Form section with Glassmorphism
                VStack(spacing: 24) {
                    onboardingForm
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.1))
                        .background(
                            Color.white.opacity(0.05)
                                .blur(radius: 10)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Action Button
                Button(action: {
                    Task {
                        let success = await viewModel.completeOnboarding()
                        if success {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.black)
                        } else {
                            Text("Complete Setup")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(viewModel.isFormValid ? Color.appEmerald : Color.gray.opacity(0.3))
                    .foregroundColor(viewModel.isFormValid ? .black : .white.opacity(0.5))
                    .cornerRadius(16)
                    .shadow(color: viewModel.isFormValid ? .appEmerald.opacity(0.4) : .clear, radius: 10, y: 5)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let msg = viewModel.errorMessage {
                Text(msg)
            }
        }
    }
    
    private var onboardingForm: some View {
        VStack(spacing: 20) {
            OnboardingField(title: "Full Name", icon: "person.fill", text: $viewModel.name, placeholder: "Your professional name")
            
            OnboardingField(title: "Phone Number", icon: "phone.fill", text: $viewModel.phone, placeholder: "+1 234 567 8900", keyboard: .phonePad)
            
            OnboardingField(title: "License Number", icon: "creditcard.fill", text: $viewModel.license, placeholder: "ABC-12345-XYZ")
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Years of Experience")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 15) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.appEmerald)
                    
                    Stepper(value: $viewModel.experience, in: 0...50) {
                        Text("\(viewModel.experience) Years")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }
}

struct OnboardingField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    var keyboard: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.appEmerald)
                    .frame(width: 24)
                
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .keyboardType(keyboard)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var start = UnitPoint(x: 0, y: -2)
    @State private var end = UnitPoint(x: 4, y: 0)
    
    let timer = Timer.publish(every: 1, on: .main, in: .default).autoconnect()
    let colors = [Color.appBackground, Color(hexCode: "#0a1a1a"), Color(hexCode: "#052c24"), Color.appBackground]
    
    var body: some View {
        LinearGradient(gradient: Gradient(colors: colors), startPoint: start, endPoint: end)
            .ignoresSafeArea()
            .onReceive(timer) { _ in
                withAnimation(.easeInOut(duration: 10).repeatForever()) {
                    self.start = UnitPoint(x: 4, y: 0)
                    self.end = UnitPoint(x: 0, y: 2)
                }
            }
    }
}

// MARK: - ViewModel
@MainActor
class DriverOnboardingViewModel: ObservableObject {
    @Published var name: String
    @Published var phone: String
    @Published var license: String
    @Published var experience: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let user: User
    private let driverService = DriverService.shared
    
    init(user: User) {
        self.user = user
        self.name = user.name
        self.phone = user.phoneNumber ?? ""
        self.license = ""
    }
    
    var isFormValid: Bool {
        !name.isEmpty && !phone.isEmpty && !license.isEmpty && experience >= 0
    }
    
    func completeOnboarding() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if driver record exists
            var existingDriver: Driver?
            do {
                existingDriver = try await driverService.getDriverProfile(userId: user.id)
            } catch {
                // If it doesn't exist, we'll create it later or handle below
                print("ℹ️ Driver record might not exist yet: \(error)")
            }
            
            if let driver = existingDriver {
                // Update existing
                struct DriverUpdate: Encodable {
                    let full_name: String
                    let phone_number: String
                    let driver_license_number: String
                    let years_of_experience: Int
                    let updated_at: String
                }
                
                let updates = DriverUpdate(
                    full_name: name,
                    phone_number: phone,
                    driver_license_number: license,
                    years_of_experience: experience,
                    updated_at: ISO8601DateFormatter().string(from: Date())
                )
                
                _ = try await driverService.updateDriverProfile(driverId: driver.id, updates: updates)
            } else {
                // Create new driver record in DB
                // This might require a 'createDriver' method in DriverService
                // Let's assume we can just use supabase.database.from("drivers").insert(...)
                
                struct NewDriver: Encodable {
                    let user_id: UUID
                    let full_name: String
                    let email: String
                    let phone_number: String
                    let driver_license_number: String
                    let years_of_experience: Int
                    let status: String
                }
                
                let newDriver = NewDriver(
                    user_id: user.id,
                    full_name: name,
                    email: user.email,
                    phone_number: phone,
                    driver_license_number: license,
                    years_of_experience: experience,
                    status: "Available"
                )
                
                try await supabase
                    .from("drivers")
                    .insert(newDriver)
                    .execute()
            }
            
            // Also update the User record for consistency
            _ = try await SupabaseAuthService.shared.updateUserProfile(
                id: user.id,
                name: name,
                email: user.email,
                phoneNumber: phone
            )
            
            // Sync session
            let updatedUser = User(
                id: user.id,
                name: name,
                email: user.email,
                phoneNumber: phone,
                role: user.role,
                profileImageURL: user.profileImageURL,
                isActive: user.isActive,
                createdAt: user.createdAt,
                updatedAt: Date()
            )
            SessionManager.shared.updateCurrentUserLocally(updatedUser)
            
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
}
