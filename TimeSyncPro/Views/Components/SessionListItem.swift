// SessionListItem.swift

import SwiftUI

struct SessionListItem: View {
    let session: WorkSession
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Date and Duration
            HStack {
                // Date with Icon
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                    
                    Text(formatDate(session.startTime))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Duration Badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                    Text(formatDuration(session.duration))
                        .font(.footnote.bold())
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // Time Range with Break Indicator
            HStack(alignment: .center, spacing: 12) {
                // Start Time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(session.startTime))
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Break Indicator if exists
                if !session.breaks.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 16))
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.orange.opacity(0.1))
                            )
                        
                        Text(formatBreakDuration(session.breaks))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // End Time
                VStack(alignment: .trailing, spacing: 4) {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(session.endTime ?? Date()))
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
    }
    
    // Formatting helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        return "\(hours)h \(minutes)m"
    }
    
    private func formatBreakDuration(_ breaks: [Break]) -> String {
        let totalBreakTime = breaks.reduce(0) { total, breakPeriod in
            let breakEndTime = breakPeriod.endTime ?? Date()
            return total + breakEndTime.timeIntervalSince(breakPeriod.startTime)
        }
        return "Break: \(Int(totalBreakTime / 60))m"
    }
} 
