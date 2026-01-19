import SwiftUI

struct MaintenanceHistoryView: View {
    let vehicle: FMVehicle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Maintenance History")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty space to balance the header
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Summary Cards
                        HStack(spacing: 16) {
                            SummaryCard(
                                title: "Last Service",
                                value: vehicle.lastService?.formatted(date: .abbreviated, time: .omitted) ?? "N/A",
                                icon: "calendar.badge.clock",
                                color: .blue
                            )
                            
                            SummaryCard(
                                title: "Next Due",
                                value: vehicle.nextServiceDue?.formatted(date: .abbreviated, time: .omitted) ?? "TBD",
                                icon: "clock.badge.exclamationmark",
                                color: .orange
                            )
                        }
                        
                        // History List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Service Logs")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if let services = vehicle.maintenanceServices, !services.isEmpty {
                                VStack(spacing: 12) {
                                    MaintenanceLogRow(
                                        date: vehicle.lastService ?? Date(),
                                        services: services,
                                        description: vehicle.maintenanceDescription ?? "Routine maintenance"
                                    )
                                }
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "clipboard")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("No maintenance logs found")
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color.appCardBackground)
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

struct MaintenanceLogRow: View {
    let date: Date
    let services: [String]
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.day()))
                    .font(.headline)
                    .foregroundColor(.white)
                Text(date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Completed Service")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                Text(services.joined(separator: ", "))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appEmerald.opacity(0.1))
                    .foregroundColor(.appEmerald)
                    .cornerRadius(4)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
    }
}
