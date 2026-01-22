//
//  AllActivitiesView.swift
//  FleetTrack
//

import SwiftUI

struct AllActivitiesView: View {
    @EnvironmentObject var fleetVM: FleetViewModel
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
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Back")
                    .accessibilityIdentifier("all_activities_back_button")
                    
                    Text("Activity History")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.leading, 8)
                    
                    Spacer()
                }
                .padding()
                
                if fleetVM.activities.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No activities recorded yet")
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(fleetVM.activities) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding()
                        .accessibilityIdentifier("all_activities_list")
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
