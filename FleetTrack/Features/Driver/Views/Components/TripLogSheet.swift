//
//  TripLogSheet.swift
//  FleetTrack
//
//  Created for Driver to log fuel and mileage
//

import SwiftUI

import PhotosUI

struct TripLogSheet: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let buttonColor: Color
    
    @Binding var odometer: String
    @Binding var fuelLevel: Double
    
    // Photo Picker State
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: Image? = nil
    
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
                    
                    HStack {
                        TextField("00000", text: $odometer)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .padding()
                            .foregroundColor(.white)
                        
                        Text("km")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.trailing)
                    }
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.appEmerald.opacity(odometer.isEmpty ? 0.0 : 0.5), lineWidth: 1)
                    )
                }
                
                // Fuel & Photo Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Fuel & Proof", systemImage: "fuelpump.fill")
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
                        Text("Full").font(.caption).foregroundColor(.gray)
                    }
                    
                    // Photo Picker
                    HStack {
                        if let selectedImage = selectedImage {
                            selectedImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    Button(action: {
                                        self.selectedItem = nil
                                        self.selectedImage = nil
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white.clipShape(Circle()))
                                    }
                                    .offset(x: 4, y: -4),
                                    alignment: .topTrailing
                                )
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text(selectedImage == nil ? "Upload Fuel Photo *" : "Change Photo")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    selectedImage = Image(uiImage: uiImage)
                                }
                            }
                        }
                        
                        if selectedImage == nil {
                            Spacer()
                            Text("* Required")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.top, 8)
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
                        .background(isFormValid ? buttonColor : Color.gray)
                        .cornerRadius(12)
                        .shadow(color: isFormValid ? buttonColor.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                }
                .disabled(!isFormValid)
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
    
    private var isFormValid: Bool {
        return !odometer.isEmpty && selectedImage != nil
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
