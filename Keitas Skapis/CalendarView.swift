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
    @Query private var days: [Day]
    
    @State private var displayedMonth: Date = Date()
    
    // The chosen day to show in a sheet
    @State private var selectedDay: Day?
    @State private var showDaySheet = false
    
    @State private var isTapLocked = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Kalendārs").font(.title).bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer()
                }.padding().background(Color(.systemGray6)).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.black), lineWidth: 1)).padding(.horizontal, 10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                
                VStack {
                    monthHeader.bold().shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 10) {
                        ForEach(daysInDisplayedMonth(), id: \.self) { day in
                            dayCell(for: day).bold()
                        }
                    }
                    .padding(.horizontal).padding(.bottom, 5)
                }.background(Color.white).cornerRadius(10).shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.black), lineWidth: 1)).padding(.horizontal, 10)

                
                Spacer()
            }.background(Image("background_dmitriy_steinke").resizable().edgesIgnoringSafeArea(.all).opacity(0.3))
            ToolBar()
            .background(Color(.systemGray5)).padding(.top, -10)
            .sheet(isPresented: $showDaySheet, onDismiss: { selectedDay = nil }) {
                if let day = selectedDay {
                    DaySheetView(day: day)
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
        let existingDiena = days.first { calendar.isDate($0.date, inSameDayAs: date) }

        return Button {
            // 1) If we’re already locked, ignore quick taps
            guard !isTapLocked else { return }
            isTapLocked = true

            // 2) Actually do your dayCell logic
            if let found = existingDiena {
                // Use existing
                selectedDay = found
            } else {
                // Create ephemeral, in-memory
                let tmpDay = Day(date: date, notes: "")
                // DON’T insert or save yet
                selectedDay = tmpDay
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

