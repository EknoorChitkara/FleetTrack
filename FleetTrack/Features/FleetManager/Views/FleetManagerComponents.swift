//
//  FleetManagerComponents.swift
//  FleetTrack
//

import SwiftUI

struct TripRow: View {
    let trip: FMTrip
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: "map.fill").foregroundColor(.purple))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(trip.startAddress ?? "Start") → \(trip.endAddress ?? "End")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(trip.purpose ?? "Trip")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(trip.formattedDistance)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.appEmerald)
                if let startTime = trip.startTime {
                    Text(startTime, style: .date)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
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
    }
    
    private func statusColor(_ status: VehicleStatus) -> Color {
        switch status {
        case .active: return .green
        case .inactive: return .gray
        case .inMaintenance: return .orange
        case .retired: return .red
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
                Text(driver.displayName)
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
    }
}
