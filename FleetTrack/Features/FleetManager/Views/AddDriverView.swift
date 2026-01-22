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
                header
                
                ScrollView {
                    formContent
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)
            }
            .accessibilityLabel("Cancel")
            .accessibilityIdentifier("add_driver_cancel_button")
            
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
            .accessibilityLabel("Save Driver")
            .accessibilityHint(isFormValid ? "Double tap to save" : "Form incomplete")
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
    }
    
    private var formContent: some View {
        VStack(spacing: 24) {
            ModernFormHeader(
                title: "Driver Details",
                subtitle: "Enter personal and license information",
                iconName: "person.badge.plus.fill"
            )
            
            VStack(spacing: 16) {
                ModernTextField(icon: "person.fill", placeholder: "Full Name", text: $formData.fullName, isRequired: true)
                    .onChange(of: formData.fullName) { newValue in
                        var text = newValue
                        // Remove all leading numbers
                        while let first = text.first, first.isNumber {
                            text = String(text.dropFirst())
                        }
                        // Limit to 50 characters
                        if text.count > 50 {
                            text = String(text.prefix(50))
                        }
                        // Update state if changed
                        if text != newValue {
                            formData.fullName = text
                        }
                    }
                
                licenseSection
                
                phoneSection
                
                emailSection
                
                ModernTextField(icon: "house.fill", placeholder: "Address", text: $formData.address, isRequired: true)
            }
            .padding(.horizontal)
            
            Spacer(minLength: 40)
        }
    }
    
    private var licenseSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernTextField(icon: "creditcard.fill", placeholder: "License No. (XX-0000000000000)", text: $formData.licenseNumber, isRequired: true)
                .onChange(of: formData.licenseNumber) { newValue in
                    let raw = newValue.replacingOccurrences(of: "-", with: "")
                        .filter { $0.isLetter || $0.isNumber }
                        .uppercased()
                    
                    let trimmed = String(raw.prefix(15))
                    
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
            
            if !formData.licenseNumber.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "^[A-Z]{2}-\\d{13}$").evaluate(with: formData.licenseNumber) {
                Text("License must be 2 letters followed by hyphen and 13 digits")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading)
            }
        }
    }
    
    private var phoneSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                countryPicker
                
                phoneInput
                
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
    }
    
    private var countryPicker: some View {
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
        .accessibilityIdentifier("add_driver_country_picker")
    }
    
    private var phoneInput: some View {
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
    }
    
    private var emailSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ModernTextField(icon: "envelope.fill", placeholder: "Email", text: $formData.email, isRequired: true, keyboardType: .emailAddress)
            
            if !formData.email.isEmpty && !NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: formData.email) {
                Text("Invalid email format")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading)
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
