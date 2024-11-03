import Foundation
import SwiftData
import Combine

@MainActor
class TimerViewModel: ObservableObject {
    private var timer: Timer?
    let modelContext: ModelContext
    
    @Published var currentSession: WorkSession?
    @Published var currentBreak: Break?
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var isOnBreak = false
    @Published var sessions: [WorkSession] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSessions()
    }
    
    private func loadSessions() {
        do {
            let descriptor = FetchDescriptor<WorkSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            sessions = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
    
    func stopAndSaveSession() {
        guard isRunning else { return }
        
        if let currentSession = currentSession {
            currentSession.endTime = Date()
            
            // If there was a break, ensure it's properly ended
            if let currentBreak = currentBreak {
                currentBreak.endTime = Date()
                currentSession.breaks.append(currentBreak)
            }
            
            // Add to sessions array at the beginning
            sessions.insert(currentSession, at: 0)
            
            // Save to SwiftData
            try? modelContext.save()
        }
        
        // Reset timer state
        isRunning = false
        isOnBreak = false
        elapsedTime = 0
        currentSession = nil
        currentBreak = nil
        stopTimer()
    }
    
    func addManualSession(startTime: Date, endTime: Date, breakDuration: TimeInterval?) {
        let session = WorkSession(startTime: startTime, endTime: endTime)
        
        if let breakDuration = breakDuration, breakDuration > 0 {
            // Calculate break start time (halfway through the session)
            let breakStartTime = startTime.addingTimeInterval(session.duration / 2)
            let breakEndTime = breakStartTime.addingTimeInterval(breakDuration)
            
            let breakPeriod = Break(startTime: breakStartTime, endTime: breakEndTime)
            session.breaks.append(breakPeriod)
        }
        
        // Insert at the beginning of the array
        sessions.insert(session, at: 0)
        
        // Save to SwiftData
        modelContext.insert(session)
        try? modelContext.save()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateElapsedTime() {
        if let startTime = currentSession?.startTime {
            if isOnBreak {
                // Don't update elapsed time during breaks
                return
            }
            elapsedTime = Date().timeIntervalSince(startTime)
        }
    }
    
    func startWork() {
        let session = WorkSession()
        currentSession = session
        modelContext.insert(session)
        isRunning = true
        startTimer()
    }
    
    func startBreak() {
        let breakPeriod = Break()
        currentBreak = breakPeriod
        isOnBreak = true
    }
    
    func endBreak() {
        if let currentBreak = currentBreak {
            currentBreak.endTime = Date()
            currentSession?.breaks.append(currentBreak)
            self.currentBreak = nil
        }
        isOnBreak = false
    }
    
    var todaysTotalWorkTime: TimeInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return sessions
            .filter { calendar.isDate($0.startTime, inSameDayAs: today) }
            .reduce(0) { total, session in
                // Safely unwrap endTime, use current date if session is ongoing
                let endTime = session.endTime ?? Date()
                
                // Calculate total session duration
                let sessionDuration = endTime.timeIntervalSince(session.startTime)
                
                // Subtract break durations
                let breakDuration = session.breaks.reduce(0) { total, breakPeriod in
                    // Safely unwrap break endTime
                    let breakEndTime = breakPeriod.endTime ?? Date()
                    return total + breakEndTime.timeIntervalSince(breakPeriod.startTime)
                }
                
                return total + (sessionDuration - breakDuration)
            }
    }
    
    var monthlyTotalWorkTime: TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now
        
        return sessions
            .filter { calendar.isDate($0.startTime, inSameDayAs: startOfMonth) || $0.startTime > startOfMonth }
            .reduce(0) { total, session in
                let endTime = session.endTime ?? Date()
                let sessionDuration = endTime.timeIntervalSince(session.startTime)
                
                let breakDuration = session.breaks.reduce(0) { total, breakPeriod in
                    let breakEndTime = breakPeriod.endTime ?? Date()
                    return total + breakEndTime.timeIntervalSince(breakPeriod.startTime)
                }
                
                return total + (sessionDuration - breakDuration)
            }
    }
} 
