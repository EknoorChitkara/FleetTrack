//
//  AddDriverView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct AddDriverView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var formData = DriverCreationData()
    @State private var showError = false
    @State private var showSuccessAlert = false
    
    // Mock Data
    let statuses = DriverStatus.allCases
    
    // Phone State
    struct Country: Hashable {
        let name: String
        let flag: String
        let code: String
        let limit: Int
    }
    
    let countries: [Country] = [
        Country(name: "India", flag: "🇮🇳", code: "+91", limit: 10),
        Country(name: "United States", flag: "🇺🇸", code: "+1", limit: 10),
        Country(name: "United Kingdom", flag: "🇬🇧", code: "+44", limit: 10),
        Country(name: "UAE", flag: "🇦🇪", code: "+971", limit: 9),
        Country(name: "Canada", flag: "🇨🇦", code: "+1", limit: 10),
        Country(name: "Australia", flag: "🇦🇺", code: "+61", limit: 9),
        Country(name: "Germany", flag: "🇩🇪", code: "+49", limit: 11),
        Country(name: "France", flag: "🇫🇷", code: "+33", limit: 9),
        Country(name: "Japan", flag: "🇯🇵", code: "+81", limit: 10),
        Country(name: "China", flag: "🇨🇳", code: "+86", limit: 11),
        Country(name: "Brazil", flag: "🇧🇷", code: "+55", limit: 11),
        Country(name: "Russia", flag: "🇷🇺", code: "+7", limit: 10),
        Country(name: "Italy", flag: "🇮🇹", code: "+39", limit: 10),
        Country(name: "South Korea", flag: "🇰🇷", code: "+82", limit: 10),
        Country(name: "Spain", flag: "🇪🇸", code: "+34", limit: 9),
        Country(name: "Mexico", flag: "🇲🇽", code: "+52", limit: 10),
        Country(name: "Singapore", flag: "🇸🇬", code: "+65", limit: 8),
        Country(name: "South Africa", flag: "🇿🇦", code: "+27", limit: 9),
        Country(name: "Saudi Arabia", flag: "🇸🇦", code: "+966", limit: 9),
        Country(name: "New Zealand", flag: "🇳🇿", code: "+64", limit: 9),
        Country(name: "Netherlands", flag: "🇳🇱", code: "+31", limit: 9)
    ]
    
    @State private var selectedCountry: Country = Country(name: "India", flag: "🇮🇳", code: "+91", limit: 10)
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
                    Spacer()
                    Text("Add Driver")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        fleetVM.addDriver(formData)
                        showSuccessAlert = true
                    }) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(!isFormValid ? .gray : .appEmerald)
                    }
                    .disabled(!isFormValid)
                    .alert(isPresented: $showSuccessAlert) {
                        Alert(
                            title: Text("Success"),
                            message: Text("Driver added successfully"),
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
                            title: "Driver Details",
                            subtitle: "Enter personal and license information",
                            iconName: "person.badge.plus.fill"
                        )
                        
                        VStack(spacing: 16) {
                            ModernTextField(icon: "person.fill", placeholder: "Full Name", text: $formData.fullName, isRequired: true)
                                .onChange(of: formData.fullName) { newValue in
                                    if newValue.count > 50 {
                                        formData.fullName = String(newValue.prefix(50))
                                    }
                                }
                            
                            // License Number with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                ModernTextField(icon: "creditcard.fill", placeholder: "License No. (XX0000000000000)", text: $formData.licenseNumber, isRequired: true)
                                    .onChange(of: formData.licenseNumber) { newValue in
                                        // Clean input: Uppercase, alphanumeric only, remove hyphens
                                        let raw = newValue.replacingOccurrences(of: "-", with: "")
                                            .filter { $0.isLetter || $0.isNumber }
                                            .uppercased()
                                        
                                        // Limit to 15 characters (2 letters + 13 digits)
                                        let trimmed = String(raw.prefix(15))
                                        
                                        // Apply formatting
                                        if trimmed.count > 2 {
                                            let prefix = trimmed.prefix(2)
                                            let suffix = trimmed.dropFirst(2)
                                            let formatted = "\(prefix)-\(suffix)"
                                            
                                            if formatted != newValue {
                                                formData.licenseNumber = formatted
                                            }
                                        } else {
                                            if trimmed != newValue {
                                                formData.licenseNumber = trimmed
                                            }
                                        }
                                    }
                                
                                // Updated regex for XX-13DIGITS format
                                if !formData.licenseNumber.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "^[A-Z]{2}-\\d{13}$").evaluate(with: formData.licenseNumber) {
                                    Text("License must be 2 letters followed by hyphen and 13 digits")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            // Phone Number with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                // Composite Phone Number Field
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.gray)
                                        .frame(width: 24)
                                    
                                    // Country Code Picker
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
                                            Text("\(selectedCountry.flag) \(selectedCountry.code)")
                                                .foregroundColor(.white)
                                                .fixedSize() // Prevent compression
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 8)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    // Phone Number Input
                                    ZStack(alignment: .leading) {
                                        if localPhoneNumber.isEmpty {
                                            Text("XXXXXXXXXX")
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
                                    
                                    if formData.phoneNumber.isEmpty { // Show required asterisk if empty
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
                                
                                if !localPhoneNumber.isEmpty && localPhoneNumber.count != selectedCountry.limit {
                                     Text("Phone must be in format \(selectedCountry.code) \(String(repeating: "X", count: selectedCountry.limit))")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            // Email with Validation
                            VStack(alignment: .leading, spacing: 4) {
                                ModernTextField(icon: "envelope.fill", placeholder: "Email", text: $formData.email, isRequired: true, keyboardType: .emailAddress)
                                
                                // Matches standard email regex used in bottom validation
                                if !formData.email.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                                    Text("Invalid email format")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading)
                                }
                            }
                            
                            ModernTextField(icon: "house.fill", placeholder: "Address", text: $formData.address, isRequired: true)
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
        
        // License: MH1420110062821 (2 letters + 13 digits) -> Converted to MH-1420110062821
        let licenseRegEx = "^[A-Z]{2}-\\d{13}$"
        let licensePred = NSPredicate(format:"SELF MATCHES %@", licenseRegEx)
        guard licensePred.evaluate(with: formData.licenseNumber) else { return false }
        
        // Phone: Validate length based on country limit
        guard !localPhoneNumber.isEmpty && localPhoneNumber.count == selectedCountry.limit else { return false }
        
        // Email
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        guard emailPred.evaluate(with: formData.email) else { return false }
        
        return true
    }
}
