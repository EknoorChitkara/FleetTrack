//
//  BarcodeScannerView.swift
//  FleetTrack
//
//  Created for Maintenance Module - QR/Barcode Scanner
//

import SwiftUI
import AVFoundation

struct ScannedPartData: Equatable {
    var partName: String?
    var partNumber: String?
    var quantity: Int?
    var supplierName: String?
    var unitPrice: Double?
    var description: String?
}

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var scannedData: ScannedPartData?
    
    @State private var scannedCode: String = ""
    @State private var showingResult = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                CameraPreview(scannedCode: $scannedCode, onCodeScanned: handleScannedCode)
                    .ignoresSafeArea()
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanner Frame
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.accentPrimary, lineWidth: 3)
                        .frame(width: 250, height: 250)
                    
                    Spacer()
                    
                    // Instructions
                    VStack(spacing: 12) {
                        Text("Scan QR Code or Barcode")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Position the code within the frame")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scan Part")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        let parsedData = parseScannedCode(code)
        scannedData = parsedData
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Dismiss after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func parseScannedCode(_ code: String) -> ScannedPartData {
        var data = ScannedPartData()
        
        // Try parsing as JSON first
        if let jsonData = code.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            data.partName = json["name"] as? String ?? json["partName"] as? String ?? json["part_name"] as? String
            data.partNumber = json["number"] as? String ?? json["partNumber"] as? String ?? json["part_number"] as? String ?? json["sku"] as? String
            data.quantity = json["quantity"] as? Int ?? json["qty"] as? Int
            data.supplierName = json["supplier"] as? String ?? json["supplierName"] as? String ?? json["supplier_name"] as? String
            data.unitPrice = json["price"] as? Double ?? json["unitPrice"] as? Double ?? json["unit_price"] as? Double
            data.description = json["description"] as? String ?? json["desc"] as? String
            return data
        }
        
        // Try parsing as key-value pairs (e.g., "name:Brake Pads,number:BP-001,qty:10")
        if code.contains(":") && code.contains(",") {
            let pairs = code.components(separatedBy: ",")
            for pair in pairs {
                let components = pair.components(separatedBy: ":")
                guard components.count == 2 else { continue }
                
                let key = components[0].trimmingCharacters(in: .whitespaces).lowercased()
                let value = components[1].trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "name", "partname", "part_name":
                    data.partName = value
                case "number", "partnumber", "part_number", "sku":
                    data.partNumber = value
                case "quantity", "qty":
                    data.quantity = Int(value)
                case "supplier", "suppliername", "supplier_name":
                    data.supplierName = value
                case "price", "unitprice", "unit_price":
                    data.unitPrice = Double(value)
                case "description", "desc":
                    data.description = value
                default:
                    break
                }
            }
            return data
        }
        
        // Fallback: treat as simple part number
        data.partNumber = code
        return data
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    @Binding var scannedCode: String
    let onCodeScanned: (String) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        let captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return view
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .qr,
                .ean8,
                .ean13,
                .code128,
                .code39,
                .upce
            ]
        } else {
            return view
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        context.coordinator.captureSession = captureSession
        
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            previewLayer.frame = uiView.layer.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedCode: $scannedCode, onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        @Binding var scannedCode: String
        let onCodeScanned: (String) -> Void
        var previewLayer: AVCaptureVideoPreviewLayer?
        var captureSession: AVCaptureSession?
        private var hasScanned = false
        
        init(scannedCode: Binding<String>, onCodeScanned: @escaping (String) -> Void) {
            self._scannedCode = scannedCode
            self.onCodeScanned = onCodeScanned
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasScanned else { return }
            
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                hasScanned = true
                scannedCode = stringValue
                onCodeScanned(stringValue)
                
                // Stop session
                captureSession?.stopRunning()
            }
        }
    }
}
