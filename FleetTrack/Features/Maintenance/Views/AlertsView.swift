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
                    Button(action: {
                        withAnimation {
                            viewModel.filter = filter
                        }
                    }) {
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        AppTheme.dividerPrimary,
                                        lineWidth: viewModel.filter == filter ? 0 : 1)
                            )
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
            if viewModel.isLoading && viewModel.alerts.isEmpty {
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

                    Text(
                        viewModel.filter == .all
                            ? "We'll notify you when there's an update"
                            : "No \(viewModel.filter.rawValue.lowercased()) alerts at this time"
                    )
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                    Button(action: { Task { await viewModel.loadAlerts() } }) {
                        Text("Refresh")
                            .foregroundColor(AppTheme.accentPrimary)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing.sm) {
                        ForEach(viewModel.filteredAlerts) { alert in
                            AlertRow(
                                alert: alert,
                                onMarkRead: {
                                    Task { await viewModel.markAsRead(alertId: alert.id) }
                                },
                                onDelete: {
                                    Task { await viewModel.deleteAlert(alertId: alert.id) }
                                })
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing.md)
                    .padding(.bottom, 100)  // Space for floating tab bar
                }
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
    let onMarkRead: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Icon/Status Indicator
                ZStack {
                    Circle()
                        .fill(alertColor.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: alertIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(alertColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(alert.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)

                        Spacer()

                        if !alert.isRead {
                            Circle()
                                .fill(AppTheme.accentPrimary)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(alert.message)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                Text(formatDate(alert.date))
                    .font(.caption2)
                    .foregroundColor(AppTheme.textTertiary)

                Spacer()

                HStack(spacing: 16) {
                    if !alert.isRead {
                        Button(action: onMarkRead) {
                            Text("Mark Read")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.accentPrimary)
                        }
                    }

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(AppTheme.statusError)
                    }
                }
            }
        }
        .padding(AppTheme.spacing.md)
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(AppTheme.cornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius.medium)
                .stroke(alert.isRead ? Color.clear : alertColor.opacity(0.2), lineWidth: 1)
        )
        .opacity(alert.isRead ? 0.7 : 1.0)
    }

    private var alertIcon: String {
        switch alert.type {
        case .emergency: return "exclamationmark.triangle.fill"
        case .inventory: return "shippingbox.fill"
        case .system: return "bell.fill"
        }
    }

    private var alertColor: Color {
        switch alert.type {
        case .emergency: return AppTheme.statusError
        case .inventory: return AppTheme.statusWarning
        case .system: return AppTheme.accentPrimary
        }
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
