//
//  AddMaintenanceStaffView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct AddMaintenanceStaffView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = MaintenanceStaffCreationData()
    @State private var showSuccessAlert = false
    
    // Phone State
    struct Country: Hashable {
        let name: String
        let flag: String
        let code: String
        let limit: Int
        let placeholder: String
    }
    
    let countries: [Country] = [
        Country(name: "India", flag: "🇮🇳", code: "+91", limit: 10, placeholder: "XXXXXXXXXX"),
        Country(name: "United States", flag: "🇺🇸", code: "+1", limit: 10, placeholder: "XXX XXX XXXX"),
        Country(name: "United Kingdom", flag: "🇬🇧", code: "+44", limit: 10, placeholder: "XXXX XXXXXX"),
        Country(name: "UAE", flag: "🇦🇪", code: "+971", limit: 9, placeholder: "X XXX XXXX"),
        Country(name: "Canada", flag: "🇨🇦", code: "+1", limit: 10, placeholder: "XXX XXX XXXX"),
        Country(name: "Australia", flag: "🇦🇺", code: "+61", limit: 9, placeholder: "XXX XXX XXX"),
        Country(name: "Germany", flag: "🇩🇪", code: "+49", limit: 11, placeholder: "XXXX XXXXXXX"),
        Country(name: "France", flag: "🇫🇷", code: "+33", limit: 9, placeholder: "X XX XX XX XX"),
        Country(name: "Japan", flag: "🇯🇵", code: "+81", limit: 10, placeholder: "XX XXXX XXXX"),
        Country(name: "China", flag: "🇨🇳", code: "+86", limit: 11, placeholder: "XXX XXXX XXXX"),
        Country(name: "Brazil", flag: "🇧🇷", code: "+55", limit: 11, placeholder: "XX X XXXX XXXX"),
        Country(name: "Russia", flag: "🇷🇺", code: "+7", limit: 10, placeholder: "XXX XXX XX XX"),
        Country(name: "Italy", flag: "🇮🇹", code: "+39", limit: 10, placeholder: "XXX XXXXXXX"),
        Country(name: "South Korea", flag: "🇰🇷", code: "+82", limit: 10, placeholder: "XX XXXX XXXX"),
        Country(name: "Spain", flag: "🇪🇸", code: "+34", limit: 9, placeholder: "XXX XXX XXX"),
        Country(name: "Mexico", flag: "🇲🇽", code: "+52", limit: 10, placeholder: "XX XX XXXX XXXX"),
        Country(name: "Singapore", flag: "🇸🇬", code: "+65", limit: 8, placeholder: "XXXX XXXX"),
        Country(name: "South Africa", flag: "🇿🇦", code: "+27", limit: 9, placeholder: "XX XXX XXXX"),
        Country(name: "Saudi Arabia", flag: "🇸🇦", code: "+966", limit: 9, placeholder: "X XXX XXXX"),
        Country(name: "New Zealand", flag: "🇳🇿", code: "+64", limit: 9, placeholder: "XX XXX XXXX"),
        Country(name: "Netherlands", flag: "🇳🇱", code: "+31", limit: 9, placeholder: "X XX XX XX XX")
    ]
    
    @State private var selectedCountry: Country = Country(name: "India", flag: "🇮🇳", code: "+91", limit: 10, placeholder: "XXXXXXXXXX")
    @State private var localPhoneNumber = ""
    
    private func updatePhoneNumber() {
        formData.phoneNumber = "\(selectedCountry.code) \(localPhoneNumber)"
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel("Cancel")
                    .accessibilityIdentifier("add_maintenance_cancel_button")
                    Spacer()
                    Text("Add Maintenance")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        fleetVM.addMaintenanceStaff(formData)
                        showSuccessAlert = true
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                    .accessibilityLabel("Save")
                    .accessibilityHint(isFormValid ? "Double tap to save maintenance staff" : "Form incomplete")
                    .accessibilityIdentifier("add_maintenance_save_button")
                    .alert(isPresented: $showSuccessAlert) {
                        Alert(
                            title: Text("Success"),
                            message: Text("Maintenance staff added successfully"),
                            dismissButton: .default(Text("OK")) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        ModernFormHeader(
                            title: "Staff Details",
                            subtitle: "Register new maintenance personnel",
                            iconName: "wrench.and.screwdriver.fill"
                        )
                        
                        VStack(spacing: 16) {
                            ModernTextField(icon: "person.fill", placeholder: "Full Name", text: $formData.fullName, isRequired: true)
                                .onChange(of: formData.fullName) { newValue in
                                    if newValue.count > 50 {
                                        formData.fullName = String(newValue.prefix(50))
                                    }
                                }
                            
                            ModernTextField(icon: "star.fill", placeholder: "Specialization (e.g., Mechanic)", text: $formData.specialization, isRequired: true)
                            
                            // Phone Number with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    
                                    Menu {
                                        ForEach(countries, id: \.self) { country in
                                            Button {
                                                selectedCountry = country
                                                if localPhoneNumber.count > country.limit {
                                                    localPhoneNumber = String(localPhoneNumber.prefix(country.limit))
                                                }
                                                updatePhoneNumber()
                                            } label: {
                                                Text("\(country.flag) \(country.name) \(country.code)")
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(selectedCountry.code)
                                                .foregroundColor(.white)
                                                .fixedSize()
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .accessibilityLabel("Country Code: \(selectedCountry.name) \(selectedCountry.code)")
                                    .accessibilityHint("Double tap to change country")
                                    .accessibilityIdentifier("add_maintenance_country_picker")
                                    
                                    ZStack(alignment: .leading) {
                                        if localPhoneNumber.isEmpty {
                                            Text(selectedCountry.placeholder)
                                                .foregroundColor(.gray.opacity(0.6))
                                                .minimumScaleFactor(0.5)
                                        }
                                        TextField("", text: $localPhoneNumber)
                                            .keyboardType(.numberPad)
                                            .foregroundColor(.white)
                                            .onChange(of: localPhoneNumber) { newValue in
                                                let filtered = newValue.filter { $0.isNumber }
                                                if filtered.count > selectedCountry.limit {
                                                    localPhoneNumber = String(filtered.prefix(selectedCountry.limit))
                                                } else {
                                                    localPhoneNumber = filtered
                                                }
                                                updatePhoneNumber()
                                            }
                                    }
                                    
                                    if formData.phoneNumber.isEmpty {
                                         Text("*")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal)
                                .frame(height: 60)
                                .background(Color.appCardBackground)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Phone number. Country code \(selectedCountry.code). Current number \(localPhoneNumber). \(formData.phoneNumber.isEmpty ? "Required" : "")")
                                .accessibilityHint("Double tap to edit phone number")
                                .accessibilityIdentifier("add_maintenance_phone_field")
                                
                                if !localPhoneNumber.isEmpty && localPhoneNumber.count != selectedCountry.limit {
                                     Text("Phone must be in format \(selectedCountry.code) \(String(repeating: "X", count: selectedCountry.limit))")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                ModernTextField(icon: "envelope.fill", placeholder: "Email", text: $formData.email, isRequired: true, keyboardType: .emailAddress)
                                
                                if !formData.email.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                                    Text("Invalid email format")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            ModernTextField(icon: "briefcase.fill", placeholder: "Experience (Yrs)", text: $formData.yearsOfExperience, keyboardType: .numberPad)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        guard !formData.fullName.isEmpty else { return false }
        guard !formData.specialization.isEmpty else { return false }
        guard !localPhoneNumber.isEmpty && localPhoneNumber.count == selectedCountry.limit else { return false }
        
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: formData.email) else { return false }
        
        return true
    }
}
