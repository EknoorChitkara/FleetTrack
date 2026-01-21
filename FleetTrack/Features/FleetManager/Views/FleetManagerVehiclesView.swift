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
    let filters = ["All", "Active", "Inactive", "Maintenance", "Retired"]
    
    var filteredVehicles: [FMVehicle] {
        fleetVM.vehicles.filter { vehicle in
            let cleanedSearch = searchText.replacingOccurrences(of: "-", with: "").lowercased()
            let cleanedReg = vehicle.registrationNumber.replacingOccurrences(of: "-", with: "").lowercased()
            
            let matchesSearch = searchText.isEmpty || cleanedReg.contains(cleanedSearch)
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
                    TextField("Search vehicles (e.g. MH-12)", text: Binding(
                        get: { searchText },
                        set: { newValue in
                            // Auto-hyphenation logic
                            // Remove existing hyphens to re-process
                            let clean = newValue.replacingOccurrences(of: "-", with: "").uppercased()
                            var formatted = ""
                            
                            // Example Pattern: MH12AB1234 -> MH-12-AB-1234
                            // Simple logic: Insert hyphen after 2nd and 4th characters if length permits
                            // This is a basic generic formatter that helps readability
                            for (index, char) in clean.enumerated() {
                                if index == 2 || index == 4 {
                                    formatted += "-"
                                }
                                formatted.append(char)
                            }
                            
                            // Handle deletion logic (prevent getting stuck) by allowing direct set if deleting
                            if newValue.count < searchText.count {
                                searchText = newValue.uppercased()
                            } else {
                                searchText = formatted
                            }
                        }
                    ))
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
                                NavigationLink(destination: VehicleDetailView(vehicle: vehicle).environmentObject(fleetVM)) {
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
