// AllSessionsView.swift

import SwiftUI

struct AllSessionsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timerVM: TimerViewModel
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                ForEach(timerVM.sessions) { session in
                    SessionListItem(session: session)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    timerVM.deleteSession(session)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete { indexSet in
                    withAnimation {
                        for index in indexSet {
                            timerVM.deleteSession(timerVM.sessions[index])
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("All Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
    }
}

// Status Pill Component
struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
    }
}

// Update TimerViewModel to include delete functionality
extension TimerViewModel {
    func deleteSession(_ session: WorkSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            modelContext.delete(sessions[index])
            sessions.remove(at: index)
        }
    }
}
