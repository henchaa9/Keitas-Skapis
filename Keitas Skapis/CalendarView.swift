//
//  CalendarView.swift
//  Keitas Skapis
//
//  Created by Henrijs Obolevics on 28/12/2024.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // All saved days
    @Query private var dienas: [Diena]
    
    @State private var displayedMonth: Date = Date()
    
    // The chosen day to show in a sheet
    @State private var selectedDiena: Diena?
    @State private var showDaySheet = false
    
    @State private var isTapLocked = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Kalendārs").font(.title).bold()
                    Spacer()
                }.padding()
                
                monthHeader
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 10) {
                    ForEach(daysInDisplayedMonth(), id: \.self) { day in
                        dayCell(for: day)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            ToolBar()
            .sheet(isPresented: $showDaySheet, onDismiss: { selectedDiena = nil }) {
                if let diena = selectedDiena {
                    DaySheetView(diena: diena)
                } else {
                    Text("Loading day...") // Fallback
                }
            }
            .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Month Navigation
    private var monthHeader: some View {
        HStack {
            Button("<") {
                displayedMonth = previousMonth(from: displayedMonth)
            }
            Spacer()
            Text(monthTitle(for: displayedMonth))
                .font(.headline)
            Spacer()
            Button(">") {
                displayedMonth = nextMonth(from: displayedMonth)
            }
        }
        .padding()
    }

    // MARK: - Day Cell
    private func dayCell(for date: Date) -> some View {
        let existingDiena = dienas.first { calendar.isDate($0.datums, inSameDayAs: date) }

        return Button {
            // 1) If we’re already locked, ignore quick taps
            guard !isTapLocked else { return }
            isTapLocked = true

            // 2) Actually do your dayCell logic
            if let found = existingDiena {
                // Use existing
                selectedDiena = found
            } else {
                // Create ephemeral, in-memory
                let tmpDay = Diena(datums: date, piezimes: "")
                // DON’T insert or save yet
                selectedDiena = tmpDay
            }
            showDaySheet = true

            
            // 3) Unlock after 0.2 seconds (tweak as needed)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapLocked = false
            }
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .padding(8)
                .background(existingDiena != nil ? Color.yellow.opacity(0.3) : Color.clear)
                .clipShape(Circle())
        }
        .disabled(isTapLocked) // optional if you want a visual disable
    }


    // MARK: - Helpers
    private func daysInDisplayedMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    private func previousMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    private func nextMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }
}

