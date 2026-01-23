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
    @Binding var odometerUnscaledImage: UIImage?
    @Binding var fuelGaugeUnscaledImage: UIImage?
    
    // We can also accept an optional 'routes' array to let user select a route
    var availableRoutes: [String]? = nil // Passed as simple strings or simple structs for now
    @Binding var selectedRouteIndex: Int? // Add binding for route selection
    
    let onCommit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var odometerItem: PhotosPickerItem?
    @State private var fuelGaugeItem: PhotosPickerItem?
    @State private var showOdometerImagePicker = false
    @State private var showFuelGaugeImagePicker = false
    @State private var showOdometerSourcePicker = false
    @State private var showFuelGaugeSourcePicker = false
    @State private var odometerSourceType: UIImagePickerController.SourceType = .camera
    @State private var fuelGaugeSourceType: UIImagePickerController.SourceType = .camera
    
    init(
        title: String,
        subtitle: String,
        buttonTitle: String,
        buttonColor: Color,
        odometer: Binding<String>,
        fuelLevel: Binding<Double>,
        odometerUnscaledImage: Binding<UIImage?>,
        fuelGaugeUnscaledImage: Binding<UIImage?>,
        availableRoutes: [String]? = nil,
        selectedRouteIndex: Binding<Int?>,
        onCommit: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.buttonColor = buttonColor
        self._odometer = odometer
        self._fuelLevel = fuelLevel
        self._odometerUnscaledImage = odometerUnscaledImage
        self._fuelGaugeUnscaledImage = fuelGaugeUnscaledImage
        self.availableRoutes = availableRoutes
        self._selectedRouteIndex = selectedRouteIndex
        self.onCommit = onCommit
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Odometer Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "speedometer")
                                    .font(.headline)
                                    .foregroundColor(.appEmerald)
                                Text("ODOMETER")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .kerning(1.2)
                            }
                            
                            TextField("Enter current mileage (km)", text: $odometer)
                                .font(.system(size: 20, weight: .medium))
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color(white: 0.15))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .accessibilityIdentifier("trip_log_odometer_field")
                                .onChange(of: odometer) { newValue in
                                    let filtered = newValue.filter { $0.isNumber }
                                    if filtered != newValue {
                                        odometer = filtered
                                    }
                                }
                            
                            // Odometer Photo Area
                            Button {
                                showOdometerSourcePicker = true
                            } label: {
                                Group {
                                    if let img = odometerUnscaledImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 160)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(12)
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "camera.viewfinder")
                                                .font(.system(size: 32))
                                            Text("Capture Odometer Photo")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.appEmerald)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.appEmerald.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                                                .background(Color.appEmerald.opacity(0.05))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(white: 0.08))
                        .cornerRadius(24)
                        .padding(.horizontal)
                        .confirmationDialog("Choose Photo Source", isPresented: $showOdometerSourcePicker) {
                            Button("Take Photo") {
                                odometerSourceType = .camera
                                showOdometerImagePicker = true
                            }
                            Button("Choose from Library") {
                                odometerSourceType = .photoLibrary
                                showOdometerImagePicker = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        
                        // Route Selection (If available)
                        if let routes = availableRoutes, !routes.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "map")
                                        .font(.headline)
                                        .foregroundColor(.appEmerald)
                                    Text("SELECT ROUTE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.gray)
                                        .kerning(1.2)
                                }
                                
                                Picker("Route", selection: $selectedRouteIndex) {
                                    ForEach(routes.indices, id: \.self) { index in
                                        Text(routes[index]).tag(Optional(index))
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .colorMultiply(.appEmerald)
                            }
                            .padding(20)
                            .background(Color(white: 0.08))
                            .cornerRadius(24)
                            .padding(.horizontal)
                        }

                        // Fuel Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "fuelpump.fill")
                                    .font(.headline)
                                    .foregroundColor(.appEmerald)
                                Text("FUEL STATUS")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .kerning(1.2)
                                Spacer()
                                Text("\(Int(fuelLevel))%")
                                    .font(.headline)
                                    .foregroundColor(.appEmerald)
                            }
                            
                            Slider(value: $fuelLevel, in: 0...100, step: 1)
                                .accentColor(.appEmerald)
                            
                            // Fuel Photo Area
                            Button {
                                showFuelGaugeSourcePicker = true
                            } label: {
                                Group {
                                    if let img = fuelGaugeUnscaledImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 160)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                            .cornerRadius(12)
                                    } else {
                                        VStack(spacing: 12) {
                                            Image(systemName: "fuelpump.circle")
                                                .font(.system(size: 32))
                                            Text("Capture Gauge Photo")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.appEmerald)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 120)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.appEmerald.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [6]))
                                                .background(Color.appEmerald.opacity(0.05))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(white: 0.08))
                        .cornerRadius(24)
                        .padding(.horizontal)
                        .confirmationDialog("Choose Photo Source", isPresented: $showFuelGaugeSourcePicker) {
                            Button("Take Photo") {
                                fuelGaugeSourceType = .camera
                                showFuelGaugeImagePicker = true
                            }
                            Button("Choose from Library") {
                                fuelGaugeSourceType = .photoLibrary
                                showFuelGaugeImagePicker = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        
                        Spacer(minLength: 120) // Extra space for sticky button
                    }
                }
                
                // Sticky Footer Button
                VStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Divider().background(Color.gray.opacity(0.3))
                        Button(action: {
                            onCommit()
                            dismiss()
                        }) {
                            Text(buttonTitle)
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(buttonColor)
                                .cornerRadius(16)
                                .shadow(color: buttonColor.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        .disabled(odometer.isEmpty || odometerUnscaledImage == nil || fuelGaugeUnscaledImage == nil)
                        .opacity((odometer.isEmpty || odometerUnscaledImage == nil || fuelGaugeUnscaledImage == nil) ? 0.6 : 1.0)
                        .accessibilityIdentifier("trip_log_submit_button")
                    }
                    .background(Color.black.blur(radius: 20).opacity(0.9))
                }
            }
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
        .sheet(isPresented: $showOdometerImagePicker) {
            ImagePicker(image: $odometerUnscaledImage, sourceType: odometerSourceType)
        }
        .sheet(isPresented: $showFuelGaugeImagePicker) {
            ImagePicker(image: $fuelGaugeUnscaledImage, sourceType: fuelGaugeSourceType)
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
        odometerUnscaledImage: .constant(nil),
        fuelGaugeUnscaledImage: .constant(nil),
        selectedRouteIndex: .constant(nil),
        onCommit: {}
    )
    .preferredColorScheme(.dark)
}
