//
//  ReportIssueView.swift
//  FleetTrack
//
//  Created for Driver
//

import SwiftUI

struct ReportIssueView: View {
    @StateObject private var viewModel: ReportIssueViewModel
    @Environment(\.presentationMode) var presentationMode
    
    // Initializer
    init(driverId: UUID, vehicleId: UUID?) {
        _viewModel = StateObject(wrappedValue: ReportIssueViewModel(driverId: driverId, vehicleId: vehicleId))
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
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Report Issue")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Emergency or maintenance alert")
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
                    .padding(.leading, 8)
                    
                    Spacer()
                    
                    // User icon placeholder
                    Button(action: {}) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.2)) // Dimmed as in design
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Issue Type Grid
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Issue Type")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(IssueType.allCases, id: \.self) { type in
                                    IssueTypeCard(type: type, isSelected: viewModel.selectedIssueType == type) {
                                        viewModel.selectedIssueType = type
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                        
                        // Severity Level
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Severity Level")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 0) {
                                ForEach(IssueSeverity.allCases, id: \.self) { severity in
                                    Button(action: {
                                        viewModel.selectedSeverity = severity
                                    }) {
                                        HStack {
                                            Circle()
                                                .fill(severity == viewModel.selectedSeverity ? severityColor(severity) : Color.white.opacity(0.2))
                                                .frame(width: 12, height: 12)
                                            
                                            Text(severity.rawValue)
                                                .foregroundColor(.white)
                                                .padding(.leading, 8)
                                            
                                            Spacer()
                                            
                                            if severity == viewModel.selectedSeverity {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                    }
                                    
                                    if severity != .critical {
                                        Divider().background(Color.white.opacity(0.1))
                                    }
                                }
                            }
                            .cornerRadius(12)
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                        
                        // Description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $viewModel.description)
                                .frame(height: 120)
                                .padding(12)
                                .scrollContentBackground(.hidden)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    Group {
                                        if viewModel.description.isEmpty {
                                            Text("Describe the issue in detail...")
                                                .foregroundColor(.gray)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 20)
                                                .allowsHitTesting(false)
                                        }
                                    },
                                    alignment: .topLeading
                                )
                            
                            // Photo Button
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "camera")
                                    Text("Add photo (optional)")
                                }
                                .foregroundColor(.appSecondaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [5]))
                                )
                            }
                        }
                        .padding()
                        .background(Color.appCardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                        )
                    }
                    .padding()
                }
                
                // Send Alert Button
                Button(action: {
                    Task {
                        await viewModel.submitReport()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Send Alert")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appEmerald)
                .cornerRadius(12)
                .padding()
                .disabled(viewModel.isLoading)
                .alert("Issue Reported", isPresented: $viewModel.isSuccess) {
                    Button("OK") {
                        presentationMode.wrappedValue.dismiss()
                    }
                } message: {
                    Text("Your issue has been reported successfully.")
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    func severityColor(_ severity: IssueSeverity) -> Color {
        switch severity {
        case .normal: return .gray
        case .warning: return .orange
        case .critical: return .red
        }
    }
}

struct IssueTypeCard: View {
    let type: IssueType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: type.iconName) // Using SF Symbols
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(type.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appEmerald : Color.clear, lineWidth: 1)
            )
        }
    }
}
