//
//  TimeSyncProApp.swift
//  TimeSyncPro
//
//  Created by Nico Müller on 03.11.24.
//

import SwiftUI
import SwiftData

@main
struct TimeSyncProApp: App {
    let container: ModelContainer
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {
        do {
            // Configure SwiftData container with our models
            let schema = Schema([
                WorkSession.self,
                Break.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema)
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .preferredColorScheme(isDarkMode ? .dark : nil)
        }
    }
}

// Main content view
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // Create TimerViewModel with modelContext
        let timerVM = TimerViewModel(modelContext: modelContext)
        
        DashboardView(timerVM: timerVM)
            .preferredColorScheme(.light)
            .background(Color(.systemBackground))
    }
}
