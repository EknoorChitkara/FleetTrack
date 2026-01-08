//
//  ContentView.swift
//  FleetTrack
//
//  Created by Eknoor on 07/01/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("Hello, world!")
                .font(.title)
            
            Text("✅ You are logged in!")
                .foregroundColor(.green)
            
            // Logout button for testing
            Button("Logout") {
                Task {
                    await authViewModel.logout()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
