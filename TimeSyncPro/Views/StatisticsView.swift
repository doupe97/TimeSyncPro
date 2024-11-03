// StatisticsView.swift

import SwiftUI
import Charts

struct StatisticsView: View {
    @ObservedObject var timerVM: TimerViewModel
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var timeOffset = 0 // Add this to track time period offset
    
    // Add gesture state
    @GestureState private var dragOffset: CGFloat = 0
    
    enum TimeFrame {
        case week, month
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Single Time Frame Selector at top
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        Text("Week").tag(TimeFrame.week)
                        Text("Month").tag(TimeFrame.month)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    // Pie Chart Card
                    VStack(alignment: .center, spacing: 24) {
                        // Centered Pie Chart Section
                        VStack(spacing: 16) {
                            // Period Text
                            Text(getPeriodText())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            // Pie Chart
                            ZStack {
                                // Background ring
                                Circle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 32)
                                    .frame(width: 260, height: 260)
                                
                                // Work time slice with gradient
                                Circle()
                                    .trim(from: 0, to: calculateWorkFraction())
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 32, lineCap: .round)
                                    )
                                    .frame(width: 260, height: 260)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: calculateWorkFraction())
                                
                                // Break time slice with gradient
                                Circle()
                                    .trim(from: calculateWorkFraction(), to: 1)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.orange, Color.orange.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        style: StrokeStyle(lineWidth: 32, lineCap: .round)
                                    )
                                    .frame(width: 260, height: 260)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut, value: calculateWorkFraction())
                                
                                // Center stats with shadow
                                VStack(spacing: 8) {
                                    Text("Total Time")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(formatDuration(calculateSummary().workTime + calculateSummary().breakTime))
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .padding(20)
                                .background(
                                    Circle()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                                )
                            }
                            .padding(.vertical, 20)
                            
                            // Legend with improved styling
                            HStack(spacing: 32) {
                                // Work time legend
                                VStack(alignment: .center, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                        Text("Work")
                                            .font(.subheadline)
                                    }
                                    Text(formatDuration(calculateSummary().workTime))
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.blue)
                                }
                                
                                // Break time legend
                                VStack(alignment: .center, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(Color.orange)
                                            .frame(width: 8, height: 8)
                                        Text("Break")
                                            .font(.subheadline)
                                    }
                                    Text(formatDuration(calculateSummary().breakTime))
                                        .font(.system(.headline, design: .rounded))
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(
                                    color: Color.black.opacity(0.05),
                                    radius: 10,
                                    x: 0,
                                    y: 4
                                )
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    // Statistics Summary
                    StatsSummaryGrid(data: calculateSummary())
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Statistics")
        }
    }
    
    // Helper function to get period text
    private func getPeriodText() -> String {
        let calendar = Calendar.current
        let currentDate = Date()
        let periodLength = selectedTimeFrame == .week ? 7 : 30
        
        if let startDate = calendar.date(byAdding: .day, value: -(periodLength * (timeOffset + 1)), to: currentDate),
           let endDate = calendar.date(byAdding: .day, value: -periodLength * timeOffset, to: currentDate) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d"
            return "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
        }
        return ""
    }
    
    // Add these methods to calculate data
    private func calculateSummary() -> SummaryData {
        let calendar = Calendar.current
        let timeframe = selectedTimeFrame == .week ? 7 : 30
        let endDate = calendar.date(byAdding: .day, value: -timeframe * timeOffset, to: Date()) ?? Date()
        let startDate = calendar.date(byAdding: .day, value: -timeframe, to: endDate) ?? endDate
        
        // Filter sessions within timeframe
        let filteredSessions = timerVM.sessions.filter { session in
            session.startTime >= startDate && session.startTime < endDate
        }
        
        // Calculate total work time
        let totalWorkTime = filteredSessions.reduce(TimeInterval(0)) { total, session in
            let sessionDuration = (session.endTime ?? Date()).timeIntervalSince(session.startTime)
            let breakDuration = session.breaks.reduce(TimeInterval(0)) { total, breakPeriod in
                let breakEndTime = breakPeriod.endTime ?? Date()
                return total + breakEndTime.timeIntervalSince(breakPeriod.startTime)
            }
            return total + (sessionDuration - breakDuration)
        }
        
        // Calculate total break time
        let totalBreakTime = filteredSessions.reduce(TimeInterval(0)) { total, session in
            session.breaks.reduce(TimeInterval(0)) { breakTotal, breakPeriod in
                let breakEndTime = breakPeriod.endTime ?? Date()
                return breakTotal + breakEndTime.timeIntervalSince(breakPeriod.startTime)
            }
        }
        
        // Calculate average session duration (excluding breaks)
        let avgSessionDuration = filteredSessions.isEmpty ? TimeInterval(0) : totalWorkTime / Double(filteredSessions.count)
        
        // Calculate productivity (work time / total time ratio)
        let totalTime = totalWorkTime + totalBreakTime
        let productivity = totalTime > 0 ? (totalWorkTime / totalTime) * 100 : 0
        
        return SummaryData(
            workTime: totalWorkTime,
            breakTime: totalBreakTime,
            totalWork: formatDuration(totalWorkTime),
            totalBreaks: formatDuration(totalBreakTime),
            avgSession: formatDuration(avgSessionDuration),
            productivity: String(format: "%.0f%%", productivity)
        )
    }
    
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
    
    // Add this helper function
    private func calculateWorkFraction() -> Double {
        let summary = calculateSummary()
        let total = summary.workTime + summary.breakTime
        return total > 0 ? Double(summary.workTime) / Double(total) : 0
    }
}

// Supporting Views
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatsSummaryGrid: View {
    let data: SummaryData
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Total Work", value: data.totalWork, icon: "clock.fill", color: .blue)
            StatCard(title: "Total Breaks", value: data.totalBreaks, icon: "cup.and.saucer.fill", color: .orange)
            StatCard(title: "Avg. Session", value: data.avgSession, icon: "chart.bar.fill", color: .purple)
            StatCard(title: "Productivity", value: data.productivity, icon: "chart.line.uptrend.xyaxis", color: .green)
        }
        .padding(.horizontal, 20)
    }
}

// Data Models
struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let workHours: Double
    let breakHours: Double
}
