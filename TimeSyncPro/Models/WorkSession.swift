import Foundation
import SwiftData

@Model
class WorkSession {
    var startTime: Date
    var endTime: Date?
    var breaks: [Break] = []
    
    init(startTime: Date = Date(), endTime: Date? = nil) {
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
    
    var breakDuration: TimeInterval {
        breaks.reduce(0) { total, breakItem in
            total + breakItem.duration
        }
    }
}

enum SessionType: String, Codable {
    case work
    case flex
    case vacation
}

@Model
class Break {
    var startTime: Date
    var endTime: Date?
    
    init(startTime: Date = Date(), endTime: Date? = nil) {
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var duration: TimeInterval {
        if let endTime = endTime {
            return endTime.timeIntervalSince(startTime)
        }
        return Date().timeIntervalSince(startTime)
    }
} 