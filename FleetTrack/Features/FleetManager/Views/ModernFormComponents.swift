//
//  ModernFormComponents.swift
//  FleetTrack
//
//  Created for modernizing input forms
//

import SwiftUI

struct ModernFormHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Logo/Icon
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundColor(.appEmerald)
                .padding(20)
                .background(Color.appEmerald.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
    }
}

struct ModernTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isRequired: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .none
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.gray)
                .frame(width: 24)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundColor(.gray.opacity(0.6))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                TextField("", text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(autocapitalization)
            }
            
            if isRequired && text.isEmpty {
                Text("*")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal)
        .frame(height: 60)
        .frame(maxWidth: .infinity)
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct ModernPicker<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let icon: String
    let title: String
    @Binding var selection: T
    let options: [T]
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }) {
                    Text(option.rawValue)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Text(selection.rawValue)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .frame(height: 60)
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

struct ModernDriverPicker: View {
    let icon: String
    @Binding var selection: UUID?
    let drivers: [FMDriver]
    let placeholder: String
    
    var body: some View {
        Menu {
            Button(action: {
                selection = nil
            }) {
                Text("Unassigned")
            }
            
            ForEach(drivers) { driver in
                Button(action: {
                    selection = driver.id
                }) {
                    Text(driver.displayName)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Text(selection == nil ? "Unassigned" : (drivers.first(where: { $0.id == selection })?.displayName ?? placeholder))
                    .font(.body)
                    .foregroundColor(selection == nil ? .gray : .white)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

struct ModernVehiclePicker: View {
    let icon: String
    @Binding var selection: UUID?
    let vehicles: [FMVehicle]
    let placeholder: String
    
    var body: some View {
        Menu {
            ForEach(vehicles) { vehicle in
                Button(action: {
                    selection = vehicle.id
                }) {
                    Text("\(vehicle.model) (\(vehicle.registrationNumber))")
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Text(selection == nil ? placeholder : (vehicles.first(where: { $0.id == selection })?.registrationNumber ?? placeholder))
                    .font(.body)
                    .foregroundColor(selection == nil ? .gray : .white)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .frame(height: 60)
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }
}

struct ModernDatePicker: View {
    let icon: String
    let title: String
    @Binding var selection: Date
    var components: DatePicker.Components = .date
    var fromDate: Date? = nil
    var throughDate: Date? = nil
    
    var body: some View {
        ZStack {
            // Visual background and labels (non-interactable so taps pass through)
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .frame(width: 24)
                
                Group {
                    if components.contains(.hourAndMinute) && components.contains(.date) {
                        Text(selection.formatted(.dateTime.day().month(.abbreviated).year().hour().minute()))
                    } else if components.contains(.hourAndMinute) {
                        Text(selection.formatted(.dateTime.hour().minute()))
                    } else {
                        Text(selection.formatted(.dateTime.day().month(.abbreviated).year()))
                    }
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(height: 60)
            .background(Color.appCardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
            .allowsHitTesting(false)
            
            // The actual interactable picker overlay (covers the whole area)
            Group {
                if let from = fromDate {
                    DatePicker("", selection: $selection, in: from..., displayedComponents: components)
                } else if let through = throughDate {
                    DatePicker("", selection: $selection, in: ...through, displayedComponents: components)
                } else {
                    DatePicker("", selection: $selection, displayedComponents: components)
                }
            }
            .labelsHidden()
            .datePickerStyle(.compact)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(5) // Sufficient but not extreme scaling
            .opacity(0.011)
            .contentShape(Rectangle()) // Confine gesture area
        }
        .frame(height: 60)
        .clipped() // Prevent invisible hit areas from bleeding out
    }
}
