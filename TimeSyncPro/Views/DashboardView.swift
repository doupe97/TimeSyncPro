import SwiftUI
import SwiftData

struct DashboardView: View {
    @ObservedObject var timerVM: TimerViewModel
    @State private var showingAddSession = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Timer Card at top
                    TimerCard(timerVM: timerVM)
                        .padding(.horizontal, 16)
                    
                    // Stats Overview
                    StatsOverview(timerVM: timerVM)
                    
                    // Quick Actions Row with Navigation
                    HStack(spacing: 16) {
                        ActionButton(
                            title: "Add Session",
                            icon: "plus.circle.fill",
                            color: .blue
                        ) {
                            showingAddSession = true
                        }
                        
                        // Statistics button with navigation
                        NavigationLink(destination: StatisticsView(timerVM: timerVM)) {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.title2)
                                Text("Statistics")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 80) // Following hit target guidelines
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Recent Sessions List
                    RecentSessionsList(timerVM: timerVM)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 16)
            }
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showingAddSession) {
                AddSessionView(timerVM: timerVM)
            }
        }
    }
}

// Enhanced Timer Card
struct TimerCard: View {
    @ObservedObject var timerVM: TimerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            // Compact Timer Display
            VStack(spacing: 16) {
                // Top Bar with Status and Progress
                HStack(alignment: .center) {
                    StatusPillDashboard(
                        text: timerVM.isOnBreak ? "On Break" : (timerVM.isRunning ? "Working" : "Not Started"),
                        color: timerVM.isOnBreak ? .orange : (timerVM.isRunning ? .green : .secondary)
                    )
                    
                    Spacer()
                    
                    // Progress Indicator moved to top right
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 3)
                            .frame(width: 28, height: 28)
                        
                        Circle()
                            .trim(from: 0, to: min(timerVM.elapsedTime / (8 * 3600), 1))
                            .stroke(
                                Color.accentColor,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .frame(width: 28, height: 28)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: timerVM.elapsedTime)
                    }
                }
                
                // Timer Display
                HStack {
                    Text(formatTime(timerVM.elapsedTime))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .frame(height: 44) // Minimum touch target height
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
            // Control Buttons
            HStack(spacing: 12) {
                if !timerVM.isRunning {
                    PrimaryButton(
                        title: "Start",
                        icon: "play.fill",
                        color: .green
                    ) {
                        timerVM.startWork()
                    }
                } else {
                    Group {
                        PrimaryButton(
                            title: "End",
                            icon: "stop.fill",
                            color: .red
                        ) {
                            timerVM.stopAndSaveSession()
                        }
                        
                        if !timerVM.isOnBreak {
                            PrimaryButton(
                                title: "Break",
                                icon: "cup.and.saucer.fill",
                                color: .orange
                            ) {
                                timerVM.startBreak()
                            }
                        } else {
                            PrimaryButton(
                                title: "Resume",
                                icon: "arrow.clockwise",
                                color: .green
                            ) {
                                timerVM.endBreak()
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGroupedBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
    }
}

// Enhanced Quick Actions Row
struct QuickActionsRow: View {
    @ObservedObject var timerVM: TimerViewModel
    @Binding var showingAddSession: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ActionButton(
                title: "Add Session",
                icon: "plus.circle.fill",
                color: .blue
            ) {
                showingAddSession = true
            }
            
            ActionButton(
                title: "Statistics",
                icon: "chart.bar.fill",
                color: .purple
            ) {
                // Add statistics action
            }
        }
    }
}

// Enhanced Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color.gradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

// Action Button Component
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// Recent Sessions List
struct RecentSessionsList: View {
    @ObservedObject var timerVM: TimerViewModel
    @State private var showingAllSessions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Recent Sessions")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button {
                    showingAllSessions = true
                } label: {
                    Text("See all")
                        .font(.subheadline.bold())
                }
            }
            
            // Sessions List
            if timerVM.sessions.isEmpty {
                EmptySessionsView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(timerVM.sessions.prefix(5)) { session in
                        SessionCard(session: session)
                            .transition(.opacity)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingAllSessions) {
            AllSessionsView(timerVM: timerVM)
        }
    }
}

// Empty State View
struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("No Sessions Yet")
                .font(.headline)
            
            Text("Start working or add a session manually")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// Session Card Component
struct SessionCard: View {
    let session: WorkSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Date and Time
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(session.startTime))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(session.duration))
                        .font(.headline)
                }
                
                Spacer()
                
                // Status Icon
                if !session.breaks.isEmpty {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                }
            }
            
            // Break information if exists
            if !session.breaks.isEmpty && session.breakDuration > 0 {
                HStack {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.orange.opacity(0.8))
                        .font(.system(size: 12))
                    Text("Break: \(formatDuration(session.breakDuration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Refined Status Pill
struct StatusPillDashboard: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .strokeBorder(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(color)
    }
}
