// StatCard.swift

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced Header with refined icon treatment
            HStack(spacing: 10) {
                // Layered icon design
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.15),
                                    color.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .strokeBorder(
                            color.opacity(0.2),
                            lineWidth: 1
                        )
                    
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            // Smooth gradient divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            color.opacity(0.2),
                            color.opacity(0.05),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.vertical, 4)
            
            // Value with compact styling
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.03),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                color.opacity(0.1),
                                color.opacity(0.05),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(
            color: color.opacity(0.03),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// Usage in StatsOverview
struct StatsOverview: View {
    @ObservedObject var timerVM: TimerViewModel
    
    var body: some View {
        HStack(spacing: 12) { // Reduced spacing between cards
            // Today's Work Time StatCard
            StatCard(
                title: "Today",
                value: formatDuration(timerVM.todaysTotalWorkTime),
                icon: "clock.badge.checkmark.fill",
                color: .blue
            )
            
            // Monthly Work Time StatCard
            StatCard(
                title: "This Month",
                value: formatDuration(timerVM.monthlyTotalWorkTime),
                icon: "calendar.badge.clock",
                color: .purple
            )
        }
        .padding(.horizontal, 16) // Reduced horizontal padding
    }
    
    // Compact duration formatting
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours == 0 {
            return "\(minutes)m"
        } else if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
    }
}
