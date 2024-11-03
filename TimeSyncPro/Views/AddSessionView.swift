import SwiftUI

struct AddSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timerVM: TimerViewModel
    
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var includeBreak = false
    @State private var breakStartDate: Date
    @State private var breakEndDate: Date
    
    // Initialize break times properly
    init(timerVM: TimerViewModel) {
        self.timerVM = timerVM
        let now = Date()
        // Initialize break times to be in the middle of the session by default
        _breakStartDate = State(initialValue: now.addingTimeInterval(30 * 60)) // 30 mins from start
        _breakEndDate = State(initialValue: now.addingTimeInterval(45 * 60))   // 45 mins from start
    }
    
    // Computed property to check if save should be enabled
    private var isSaveEnabled: Bool {
        // Check if end time is different from start time
        return endDate > startDate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced Session Time Card
                    TimeCard(
                        title: "Work Session Duration",
                        icon: "briefcase.circle.fill",
                        color: .blue
                    ) {
                        VStack(spacing: 20) {
                            // Start Time Section
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Start Time", systemImage: "sunrise.fill")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                DatePicker("", selection: Binding(
                                    get: { startDate },
                                    set: { newDate in
                                        startDate = newDate
                                        // Ensure end date isn't before start date
                                        if endDate < newDate {
                                            endDate = newDate
                                        }
                                        // Update break times if needed
                                        if includeBreak {
                                            if breakStartDate < newDate {
                                                breakStartDate = newDate
                                            }
                                            if breakEndDate < breakStartDate {
                                                breakEndDate = breakStartDate
                                            }
                                        }
                                    }
                                ), displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.tertiarySystemGroupedBackground))
                                    )
                            }
                            
                            // Visual Separator
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 1)
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 4)
                            
                            // End Time Section
                            VStack(alignment: .leading, spacing: 8) {
                                Label("End Time", systemImage: "sunset.fill")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                DatePicker("", selection: Binding(
                                    get: { endDate },
                                    set: { newDate in
                                        endDate = max(startDate, newDate)
                                    }
                                ), in: startDate..., // Prevents selecting time before start
                                   displayedComponents: [.date, .hourAndMinute])
                                    .labelsHidden()
                                    .datePickerStyle(.compact)
                                    .frame(maxWidth: .infinity)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.tertiarySystemGroupedBackground))
                                    )
                            }
                        }
                    }
                    
                    // Enhanced Break Toggle with safe state handling
                    Card {
                        Toggle(isOn: Binding(
                            get: { includeBreak },
                            set: { newValue in
                                withAnimation {
                                    includeBreak = newValue
                                    if newValue {
                                        // When enabling break, set default times
                                        breakStartDate = max(startDate, min(breakStartDate, endDate))
                                        breakEndDate = max(breakStartDate, min(breakEndDate, endDate))
                                    }
                                }
                            }
                        )) {
                            HStack(spacing: 12) {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 24))
                                    .frame(width: 44, height: 44) // Following hit target guidelines
                                    .background(
                                        Circle()
                                            .fill(Color.orange.opacity(0.2))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Include Break")
                                        .font(.headline)
                                    Text("Add a break period to your session")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .tint(.orange)
                    }
                    
                    // Break Time Card with safe state handling
                    if includeBreak {
                        TimeCard(
                            title: "Break Duration",
                            icon: "pause.circle.fill",
                            color: .orange
                        ) {
                            VStack(spacing: 20) {
                                // Break Start with validation
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Break Start", systemImage: "cup.and.saucer")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    
                                    DatePicker("", selection: Binding(
                                        get: { breakStartDate },
                                        set: { newDate in
                                            breakStartDate = max(startDate, min(newDate, endDate))
                                            if breakEndDate < breakStartDate {
                                                breakEndDate = breakStartDate
                                            }
                                        }
                                    ), in: startDate...endDate,
                                       displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                                
                                // Break End with validation
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Break End", systemImage: "arrow.clockwise")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    
                                    DatePicker("", selection: Binding(
                                        get: { breakEndDate },
                                        set: { newDate in
                                            breakEndDate = max(breakStartDate, min(newDate, endDate))
                                        }
                                    ), in: breakStartDate...endDate,
                                       displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .datePickerStyle(.compact)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // Enhanced Save Button with disabled state
                    Button(action: {
                        let breakDuration = includeBreak ? breakEndDate.timeIntervalSince(breakStartDate) : nil
                        timerVM.addManualSession(
                            startTime: startDate,
                            endTime: endDate,
                            breakDuration: breakDuration
                        )
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Save Session")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            isSaveEnabled ? Color.accentColor : Color.gray,
                                            isSaveEnabled ? Color.accentColor.opacity(0.8) : Color.gray.opacity(0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .opacity(isSaveEnabled ? 1.0 : 0.6)
                        .shadow(color: (isSaveEnabled ? Color.accentColor : Color.gray).opacity(0.3), 
                                radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isSaveEnabled)
                    .padding(.top, 12)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Work Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct TimeCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 24))
                        .frame(width: 44, height: 44) // Hit target
                        .background(
                            Circle()
                                .fill(color.opacity(0.1))
                        )
                    
                    Text(title)
                        .font(.headline)
                }
                
                content
            }
        }
    }
}

struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}
