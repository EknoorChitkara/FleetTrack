//
//  GeofencingListView.swift
//  FleetTrack
//
//  Created for Fleet Manager
//

import SwiftUI
import CoreLocation

struct GeofencingListView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var manager = CircularGeofenceManager.shared
    
    @State private var showAddGeofence = false
    @State private var geofenceToEdit: CircularGeofence?
    @State private var showDeleteAlert = false
    @State private var geofenceToDelete: CircularGeofence?
    @State private var togglingGeofenceId: UUID?
    
    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Geofences")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        showAddGeofence = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.appEmerald)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Geofences List
                if manager.activeGeofences.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "map.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No geofences found")
                            .foregroundColor(.gray)
                        Text("Tap + to create your first geofence")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(manager.activeGeofences) { geofence in
                                GeofenceCard(
                                    geofence: geofence,
                                    isToggling: togglingGeofenceId == geofence.id,
                                    onEdit: {
                                        geofenceToEdit = geofence
                                    },
                                    onDelete: {
                                        geofenceToDelete = geofence
                                        showDeleteAlert = true
                                    },
                                    onToggleStatus: {
                                        toggleGeofenceStatus(geofence)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddGeofence) {
            AddEditGeofenceView(geofence: nil)
        }
        .sheet(item: $geofenceToEdit) { geofence in
            AddEditGeofenceView(geofence: geofence)
        }
        .alert("Delete Geofence", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let geofence = geofenceToDelete {
                    deleteGeofence(geofence)
                }
            }
        } message: {
            Text("Are you sure you want to delete this geofence? This action cannot be undone.")
        }
        .onAppear {
            Task {
                await manager.fetchAndMonitorGeofences()
            }
        }
    }
    
    private func toggleGeofenceStatus(_ geofence: CircularGeofence) {
        togglingGeofenceId = geofence.id
        
        Task {
            do {
                try await manager.toggleGeofenceStatus(geofence.id)
                await MainActor.run {
                    togglingGeofenceId = nil
                }
            } catch {
                print("❌ Failed to toggle geofence status: \(error)")
                await MainActor.run {
                    togglingGeofenceId = nil
                }
            }
        }
    }
    
    private func deleteGeofence(_ geofence: CircularGeofence) {
        Task {
            do {
                try await manager.deleteGeofence(geofence.id)
                print("✅ Deleted geofence: \(geofence.name)")
            } catch {
                print("❌ Failed to delete geofence: \(error)")
                // Ideally show error alert
            }
        }
    }
}

// MARK: - Geofence Card

struct GeofenceCard: View {
    let geofence: CircularGeofence
    let isToggling: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleStatus: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: "map.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(geofence.isActive ? .purple : .gray)
                .padding(12)
                .background((geofence.isActive ? Color.purple : Color.gray).opacity(0.1))
                .clipShape(Circle())
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(geofence.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(coordinateString)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "ruler.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text("\(Int(geofence.radiusMeters)) meters")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Status Indicator
            if isToggling {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            } else {
                VStack(spacing: 4) {
                    Circle()
                        .fill(geofence.isActive ? Color.appEmerald : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(geofence.isActive ? "Active" : "Paused")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(geofence.isActive ? .appEmerald : .gray)
                }
            }
        }
        .padding()
        .background(Color.appCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .opacity(geofence.isActive ? 1.0 : 0.6)
        .contextMenu {
            Button(action: onToggleStatus) {
                Label(geofence.isActive ? "Pause" : "Resume", systemImage: geofence.isActive ? "pause.circle" : "play.circle")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.blue)
            Button(action: onToggleStatus) {
                Label(geofence.isActive ? "Pause" : "Resume", systemImage: geofence.isActive ? "pause" : "play")
            }
            .tint(geofence.isActive ? .orange : .green)
        }
    }
    
    private var coordinateString: String {
        String(format: "%.4f, %.4f", geofence.latitude, geofence.longitude)
    }
}
