//
//  TripLogSheet.swift
//  FleetTrack
//
//  Created for Driver to log fuel and mileage
//

import SwiftUI

struct TripLogSheet: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonColor: Color
    
    @Binding var odometer: String
    @Binding var fuelLevel: Double
    
    let onCommit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top)
                
                // Odometer Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Odometer Reading (km)", systemImage: "speedometer")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("Enter current mileage", text: $odometer)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Fuel Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Fuel Level", systemImage: "fuelpump.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(Int(fuelLevel))%")
                            .font(.headline)
                            .foregroundColor(.appEmerald)
                    }
                    
                    Slider(value: $fuelLevel, in: 0...100, step: 1)
                        .accentColor(.appEmerald)
                    
                    HStack {
                        Text("Empty").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Text("Half").font(.caption).foregroundColor(.gray)
                        Spacer()
                        Text("Full").font(.caption).foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    onCommit()
                    dismiss()
                }) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor)
                        .cornerRadius(12)
                        .shadow(color: buttonColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(odometer.isEmpty)
                .opacity(odometer.isEmpty ? 0.6 : 1.0)
            }
            .padding()
            .background(Color.appBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    TripLogSheet(
        title: "Start Trip",
        subtitle: "Please log the vehicle status before starting",
        buttonTitle: "Confirm & Start",
        buttonColor: .green,
        odometer: .constant("12450"),
        fuelLevel: .constant(75),
        onCommit: {}
    )
    .preferredColorScheme(.dark)
}
