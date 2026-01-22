//
//  RefuelView.swift
//  FleetTrack
//
//  Created for drivers to log refueling
//

import SwiftUI
import PhotosUI

struct RefuelView: View {
    @StateObject var viewModel: RefuelViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showReceiptImagePicker = false
    @State private var showGaugeImagePicker = false
    @State private var showReceiptSourcePicker = false
    @State private var showGaugeSourcePicker = false
    @State private var receiptSourceType: UIImagePickerController.SourceType = .camera
    @State private var gaugeSourceType: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Fuel Details")) {
                    TextField("Liters Added", text: $viewModel.litersAdded)
                        .keyboardType(.decimalPad)
                    
                    TextField("Total Cost (Optional)", text: $viewModel.totalCost)
                        .keyboardType(.decimalPad)
                    
                    TextField("Odometer Reading (Optional)", text: $viewModel.odometerReading)
                        .keyboardType(.decimalPad)
                        .onChange(of: viewModel.odometerReading) { newValue in
                            // Filter to only allow digits
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                viewModel.odometerReading = filtered
                            }
                        }
                }
                
                Section(header: Text("Proof")) {
                    // Receipt Photo
                    HStack {
                        Text("Receipt Photo")
                        Spacer()
                        if let image = viewModel.receiptImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .cornerRadius(4)
                        }
                        Button {
                            showReceiptSourcePicker = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                        }
                        .confirmationDialog("Choose Photo Source", isPresented: $showReceiptSourcePicker) {
                            Button("Take Photo") {
                                receiptSourceType = .camera
                                showReceiptImagePicker = true
                            }
                            Button("Choose from Library") {
                                receiptSourceType = .photoLibrary
                                showReceiptImagePicker = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                    
                    // Gauge Photo
                    HStack {
                        Text("Fuel Gauge Photo")
                        Spacer()
                        if let image = viewModel.gaugeImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                                .cornerRadius(4)
                        }
                        Button {
                            showGaugeSourcePicker = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.blue)
                        }
                        .confirmationDialog("Choose Photo Source", isPresented: $showGaugeSourcePicker) {
                            Button("Take Photo") {
                                gaugeSourceType = .camera
                                showGaugeImagePicker = true
                            }
                            Button("Choose from Library") {
                                gaugeSourceType = .photoLibrary
                                showGaugeImagePicker = true
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                    }
                }
                
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        Task { await viewModel.submitRefill() }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Submit Log")
                                .bold()
                        }
                    }
                    .disabled(!viewModel.isValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Log Refueling")
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
            .onChange(of: viewModel.isSuccess) { success in
                if success { dismiss() }
            }
            .sheet(isPresented: $showReceiptImagePicker) {
                ImagePicker(image: $viewModel.receiptImage, sourceType: receiptSourceType)
            }
            .sheet(isPresented: $showGaugeImagePicker) {
                ImagePicker(image: $viewModel.gaugeImage, sourceType: gaugeSourceType)
            }
        }
    }
}
