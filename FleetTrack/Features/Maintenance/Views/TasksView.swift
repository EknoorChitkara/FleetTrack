//
//  TasksView.swift
//  FleetTrack
//
//  Created by Anmolpreet Singh on 09/01/26.
//

import SwiftUI

struct TasksView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack {
                Text("Tasks")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Task management view coming soon")
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    TasksView()
}
