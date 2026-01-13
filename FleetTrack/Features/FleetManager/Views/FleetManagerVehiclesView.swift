//
//  FleetManagerVehiclesView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI

struct FleetManagerVehiclesView: View {
    @EnvironmentObject var fleetVM: FleetViewModel
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    @State private var showAddVehicle = false
    
    // Filters
    let filters = ["All", "Active", "Inactive", "In Maintenance", "Out of Service"]
    
    var filteredVehicles: [FMVehicle] {
        fleetVM.vehicles.filter { vehicle in
            let matchesSearch = searchText.isEmpty || vehicle.registrationNumber.lowercased().contains(searchText.lowercased())
            let matchesFilter = selectedFilter == "All" || vehicle.status.rawValue == selectedFilter
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Vehicles")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddVehicle = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.appEmerald)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20) // Reduced top padding
                .padding(.bottom, 16)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search vehicles...", text: $searchText)
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.appCardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(filters, id: \.self) { filter in
                            FilterPill(title: filter, count: fleetVM.vehicles.filter { filter == "All" || $0.status.rawValue == filter }.count, isSelected: selectedFilter == filter) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
                
                // Vehicles List
                if filteredVehicles.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "car.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No vehicles found")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredVehicles) { vehicle in
                                NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                                    VehicleCard(vehicle: vehicle)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddVehicle) {
            AddVehicleView().environmentObject(fleetVM)
        }
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
                    
                    Text("Just now")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
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
        case .outOfService: return .red
        }
    }
}

struct FilterPill: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .fontWeight(.medium)
                Text("(\(count))")
                    .fontWeight(.regular)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appEmerald : Color(white: 0.2))
            .foregroundColor(isSelected ? .black : .gray)
            .cornerRadius(20)
        }
    }
}
