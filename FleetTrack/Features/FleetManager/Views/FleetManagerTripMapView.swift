//
//  FleetManagerTripMapView.swift
//  FleetTrack
//
//  Created for Fleet Manager Trip Map Integration
//

import SwiftUI
import MapKit

struct FleetManagerTripMapView: View {
    let fmTrip: FMTrip
    let showRoute: Bool
    @StateObject private var viewModel: FleetManagerTripMapViewModel
    @State private var detailHeight: CGFloat = 350
    @State private var isDragging = false
    
    private let minHeight: CGFloat = 120
    private let maxHeight: CGFloat = 550
    
    init(trip: FMTrip, showRoute: Bool = true) {
        self.fmTrip = trip
        self.showRoute = showRoute
        _viewModel = StateObject(wrappedValue: FleetManagerTripMapViewModel(tripId: trip.id, vehicleId: trip.vehicleId))
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Full screen map
            if viewModel.isLoading {
                ProgressView("Loading trip...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            } else if let trip = viewModel.trip {
                UnifiedTripMap(
                    trip: trip,
                    provider: viewModel.locationProvider,
                    routePolyline: showRoute ? viewModel.routePolyline : nil
                )
                .edgesIgnoringSafeArea(.all)
                
                // Retractable bottom sheet
                VStack(spacing: 0) {
                    Spacer()
                    
                    RetractableDetailSheet(
                        trip: trip,
                        fmTrip: fmTrip,
                        viewModel: viewModel,
                        height: $detailHeight,
                        minHeight: minHeight,
                        maxHeight: maxHeight
                    )
                }
                .edgesIgnoringSafeArea(.bottom)
            } else {
                Text("Failed to load trip details")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.appBackground)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Tracking Shipment")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .onAppear {
            viewModel.loadTripData()
            viewModel.startTracking()
        }
        .onDisappear {
            viewModel.stopTracking()
        }
    }
}

// MARK: - Retractable Detail Sheet

struct RetractableDetailSheet: View {
    let trip: Trip
    let fmTrip: FMTrip
    @ObservedObject var viewModel: FleetManagerTripMapViewModel
    @Binding var height: CGFloat
    let minHeight: CGFloat
    let maxHeight: CGFloat
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Driver Info Section
                    driverInfoSection
                    
                    // Trip ID and Date
                    HStack {
                        Text("#\(trip.id.uuidString.prefix(8).uppercased())")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appEmeraldLight)
                        
                        Spacer()
                        
                        if let startTime = trip.startTime {
                            Text(startTime.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 13))
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                    
                    // Locations
                    locationsSection
                    
                    // Live Tracking Button (if ongoing)
                    if viewModel.isLive {
                        liveTrackingButton
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .frame(height: height + dragOffset)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = -value.translation.height
                }
                .onEnded { value in
                    let newHeight = height + dragOffset
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if newHeight < (minHeight + maxHeight) / 2 {
                            height = minHeight
                        } else {
                            height = maxHeight
                        }
                        dragOffset = 0
                    }
                }
        )
    }
    
    // MARK: - Driver Info Section
    
    private var driverInfoSection: some View {
        HStack(spacing: 12) {
            // Driver Avatar (placeholder)
            Circle()
                .fill(Color.appEmerald)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                )
                .overlay(
                    Circle()
                        .fill(Color.appEmeraldLight)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 18, y: 18)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.driverName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Delivery Partner")
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryText)
            }
            
            Spacer()
            
            // Call Button Only
            Button(action: {
                viewModel.callDriver()
            }) {
                Circle()
                    .fill(Color.appEmerald)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "phone.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
            .disabled(viewModel.driverPhone == nil)
        }
    }
    
    // MARK: - Locations Section
    
    private var locationsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Location Icons
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                    )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 2, height: 40)
                
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                    )
            }
            .padding(.top, 4)
            
            // Addresses
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pickup")
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                    Text(trip.startAddress ?? "Unknown")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deliver To")
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                    Text(trip.endAddress ?? "Unknown")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Package Illustration
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "CD9C6B"))
                .opacity(0.8)
        }
    }
    
    // MARK: - Live Tracking Button
    
    private var liveTrackingButton: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Live Tracking")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(Color.appBackground)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "F9D854"))
            )
        }
        .padding(.top, 8)
    }
}
