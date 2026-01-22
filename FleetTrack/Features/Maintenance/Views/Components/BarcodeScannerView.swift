//
//  BarcodeScannerView.swift
//  FleetTrack
//
//  QR/Barcode Scanner for Inventory Parts
//

import SwiftUI
import AVFoundation

// MARK: - Scanned Part Data Model

struct ScannedPartData: Equatable {
    var partName: String?
    var partNumber: String?
    var quantity: String?
    var supplierName: String?
    var unitPrice: String?
    var description: String?
    
    // Parse from JSON or structured string
    static func parse(from code: String) -> ScannedPartData {
        var data = ScannedPartData()
        
        // Try parsing as JSON first
        if let jsonData = code.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            // Map common JSON keys to our fields
            data.partName = json["name"] as? String ?? json["partName"] as? String ?? json["part_name"] as? String
            data.partNumber = json["number"] as? String ?? json["partNumber"] as? String ?? json["part_number"] as? String ?? json["sku"] as? String
            data.quantity = json["quantity"] as? String ?? json["qty"] as? String
            data.supplierName = json["supplier"] as? String ?? json["supplierName"] as? String ?? json["supplier_name"] as? String
            data.unitPrice = json["price"] as? String ?? json["unitPrice"] as? String ?? json["unit_price"] as? String
            data.description = json["description"] as? String ?? json["desc"] as? String
            
            print("✅ Parsed JSON QR code: \(json)")
        }
        // Try parsing as key-value pairs (e.g., "name:Spark Plug;number:SP123;qty:10")
        else if code.contains(":") {
            let pairs = code.components(separatedBy: ";")
            for pair in pairs {
                let keyValue = pair.components(separatedBy: ":")
                guard keyValue.count == 2 else { continue }
                
                let key = keyValue[0].trimmingCharacters(in: .whitespaces).lowercased()
                let value = keyValue[1].trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "name", "partname", "part_name":
                    data.partName = value
                case "number", "partnumber", "part_number", "sku":
                    data.partNumber = value
                case "quantity", "qty":
                    data.quantity = value
                case "supplier", "suppliername", "supplier_name":
                    data.supplierName = value
                case "price", "unitprice", "unit_price":
                    data.unitPrice = value
                case "description", "desc":
                    data.description = value
                default:
                    break
                }
            }
            print("✅ Parsed key-value QR code")
        }
        // Fallback: treat as simple part number
        else {
            data.partNumber = code
            print("✅ Parsed as simple part number: \(code)")
        }
        
        return data
    }
}

// MARK: - Barcode Scanner View

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var scannedData: ScannedPartData?
    
    @State private var isScanning = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            // Camera preview
            BarcodeScannerViewController(
                scannedData: $scannedData,
                isScanning: $isScanning,
                errorMessage: $errorMessage
            )
            .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Scanning frame
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 280, height: 280)
                    .overlay(
                        VStack {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Scan QR Code or Barcode")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                    )
                
                Spacer()
                
                // Instructions
                VStack(spacing: 8) {
                    Text("Position the code within the frame")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: scannedData) { newValue in
            if newValue != nil {
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                // Dismiss after successful scan
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - UIKit Scanner Controller

struct BarcodeScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedData: ScannedPartData?
    @Binding var isScanning: Bool
    @Binding var errorMessage: String?
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {
        if isScanning {
            uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(scannedData: $scannedData, errorMessage: $errorMessage)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        @Binding var scannedData: ScannedPartData?
        @Binding var errorMessage: String?
        
        init(scannedData: Binding<ScannedPartData?>, errorMessage: Binding<String?>) {
            _scannedData = scannedData
            _errorMessage = errorMessage
        }
        
        func didScan(code: String) {
            scannedData = ScannedPartData.parse(from: code)
        }
        
        func didFail(error: String) {
            errorMessage = error
        }
    }
}

// MARK: - Scanner View Controller

protocol ScannerViewControllerDelegate: AnyObject {
    func didScan(code: String)
    func didFail(error: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didFail(error: "Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didFail(error: "Camera access error")
            return
        }
        
        if captureSession?.canAddInput(videoInput) == true {
            captureSession?.addInput(videoInput)
        } else {
            delegate?.didFail(error: "Could not add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession?.canAddOutput(metadataOutput) == true {
            captureSession?.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .qr,
                .ean8,
                .ean13,
                .code128,
                .code39,
                .upce
            ]
        } else {
            delegate?.didFail(error: "Could not add metadata output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer!)
    }
    
    func startScanning() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            stopScanning()
            delegate?.didScan(code: stringValue)
        }
    }
}
