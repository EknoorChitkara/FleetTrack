//
//  AlertsView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct AlertsView: View {
    @StateObject private var viewModel = AlertsViewModel()

    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection

                // Filters
                filterSection

                // Content
                contentSection
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Alerts")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)

            Text("System alerts and notifications")
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.vertical, AppTheme.spacing.md)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing.sm) {
                ForEach(AlertsViewModel.AlertFilter.allCases, id: \.self) { filter in
                    Button(action: { viewModel.filter = filter }) {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.filter == filter
                                    ? AppTheme.accentPrimary : AppTheme.backgroundSecondary
                            )
                            .foregroundColor(
                                viewModel.filter == filter ? .black : AppTheme.textPrimary
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacing.md)
            .padding(.bottom, AppTheme.spacing.md)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(AppTheme.accentPrimary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if viewModel.filteredAlerts.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppTheme.iconDisabled)

                    Text("No alerts found")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Text("We'll notify you when there's an update")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)

                    Button(action: { Task { await viewModel.loadAlerts() } }) {
                        Text("Refresh")
                            .foregroundColor(AppTheme.accentPrimary)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(viewModel.filteredAlerts) { alert in
                        AlertRow(alert: alert)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.deleteAlert(alertId: alert.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                if !alert.isRead {
                                    Button {
                                        Task { await viewModel.markAsRead(alertId: alert.id) }
                                    } label: {
                                        Label("Mark Read", systemImage: "envelope.open")
                                    }
                                    .tint(AppTheme.accentPrimary)
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.loadAlerts()
                }
            }
        }
    }
}

// MARK: - Alert Row Component

struct AlertRow: View {
    let alert: MaintenanceAlert

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            VStack {
                ZStack {
                    Circle()
                        .fill(
                            alert.type == .emergency
                                ? AppTheme.statusErrorBackground : AppTheme.statusActiveBackground
                        )
                        .frame(width: 44, height: 44)

                    Image(
                        systemName: alert.type == .emergency
                            ? "exclamationmark.triangle.fill" : "bell.fill"
                    )
                    .foregroundColor(
                        alert.type == .emergency ? AppTheme.statusError : AppTheme.accentPrimary)
                }

                if !alert.isRead {
                    Circle()
                        .fill(AppTheme.accentPrimary)
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(alert.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Text(formatDate(alert.date))
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }

                Text(alert.message)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
        .padding(.horizontal, AppTheme.spacing.md)
        .padding(.vertical, 6)
        .opacity(alert.isRead ? 0.7 : 1.0)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    AlertsView()
}
