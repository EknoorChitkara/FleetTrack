//
//  FleetManagerComponents.swift
//  FleetTrack
//

import SwiftUI

struct TripRow: View {
    let trip: FMTrip
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon with background
            ZStack {
                Circle()
                    .fill(statusColor(trip.status).opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: statusIcon(trip.status))
                    .foregroundColor(statusColor(trip.status))
                    .font(.system(size: 20))
            }
            .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(trip.startAddress ?? "Start")
                        .font(.system(size: 14, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(trip.endAddress ?? "End")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(trip.purpose ?? "Shipment", systemImage: "shippingbox.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    if let startTime = trip.startTime {
                        Text("•")
                            .foregroundColor(.gray.opacity(0.5))
                        Text(startTime.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.formattedDistance)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appEmerald)
                
                Text(trip.status.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(trip.status).opacity(0.1))
                    .foregroundColor(statusColor(trip.status))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Trip from \(trip.startAddress ?? "Start") to \(trip.endAddress ?? "End"). Purpose: \(trip.purpose ?? "Trip"). Status: \(trip.status). Distance: \(trip.formattedDistance).")
        .accessibilityIdentifier("fleet_trip_row_\(trip.id.uuidString.prefix(8))")
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "ongoing", "in progress": return .orange
        case "scheduled": return .blue
        case "cancelled": return .red
        default: return .gray
        }
    }
    
    private func statusIcon(_ status: String) -> String {
        switch status.lowercased() {
        case "completed": return "checkmark.circle.fill"
        case "ongoing", "in progress": return "map.fill"
        case "scheduled": return "calendar"
        case "cancelled": return "xmark.circle.fill"
        default: return "questionmark.circle"
        }
    }
}

struct ActivityRow: View {
    let activity: FMActivity
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: activity.icon).foregroundColor(.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(activity.description)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .time)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(activity.title): \(activity.description). Time: \(activity.timestamp.formatted(date: .omitted, time: .shortened))")
        .accessibilityIdentifier("fleet_activity_row")
    }
}

struct VehicleCard: View {
    @EnvironmentObject var fleetVM: FleetViewModel
    let vehicle: FMVehicle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vehicle.registrationNumber)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(vehicle.model)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    fleetVM.deleteVehicle(byId: vehicle.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appEmerald)
                    .padding(10)
                    .background(Color.appEmerald.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(vehicle.vehicleType.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                        Text(vehicle.assignedDriverName ?? "Unassigned")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(vehicle.status.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(vehicle.status).opacity(0.2))
                        .foregroundColor(statusColor(vehicle.status))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Vehicle \(vehicle.registrationNumber), \(vehicle.model). Status: \(vehicle.status.rawValue). Assigned to: \(vehicle.assignedDriverName ?? "Unassigned").")
        .accessibilityAction(named: "Delete Vehicle") {
            fleetVM.deleteVehicle(byId: vehicle.id)
        }
        .accessibilityIdentifier("fleet_vehicle_card_\(vehicle.registrationNumber)")
    }
    
    private func statusColor(_ status: VehicleStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .red
        case .inMaintenance: return .yellow
        case .retired: return .gray
        }
    }
}

struct DriverCard: View {
    let driver: FMDriver
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.appEmerald)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(driver.displayName + (driver.isActive == false ? " –" : ""))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(driver.licenseNumber ?? "No License")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                let status = driver.status ?? .available
                Text(status.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status == .available ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .foregroundColor(status == .available ? .green : .gray)
                    .cornerRadius(6)
                
                if let phone = driver.phoneNumber {
                    Text(phone)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Driver \(driver.displayName). Status: \(driver.status?.rawValue ?? "Unknown"). Phone: \(driver.phoneNumber ?? "None").")
        .accessibilityAction(named: "Delete Driver") {
            onDelete?()
        }
        .accessibilityIdentifier("fleet_driver_card_\(driver.id.uuidString.prefix(8))")
    }
}
