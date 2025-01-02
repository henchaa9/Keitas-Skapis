
import SwiftUI
import SwiftData

// MARK: - Kalendāra skats
struct CalendarView: View {
    // MARK: - Datu vaicājumi un vides mainīgie
    @Environment(\.modelContext) private var modelContext // Accesses the data model context for data operations
    @Environment(\.dismiss) var dismiss // Provides a method to dismiss the current view
    @Query private var days: [Day]
    
    // MARK: - Stāvokļu mainīgie
    @State private var displayedMonth: Date = Date()
    @State private var selectedDay: Day?
    @State private var showDaySheet = false
    @State private var isTapLocked = false

    private let calendar = Calendar.current // Kalendāra instance datuma noteikšanai

    // Galvenais skats ar galveni un kalendāru
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("Kalendārs")
                        .font(.title)
                        .bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.black), lineWidth: 1)
                )
                .padding(.horizontal, 10)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                
                VStack {
                    // Mēnešu navigācija
                    monthHeader
                        .bold()
                        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                    
                    // Režģis, kas attēlo katru mēneša dienu
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 7), spacing: 10) {
                        ForEach(daysInDisplayedMonth(), id: \.self) { day in
                            dayCell(for: day)
                                .bold()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                }
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.black), lineWidth: 1)
                )
                .padding(.horizontal, 10)

                
                Spacer()
            }
            .background(
                Image("background_dmitriy_steinke")
                    .resizable()
                    .edgesIgnoringSafeArea(.all)
                    .opacity(0.3)
            )
            ToolBar()
                .background(Color(.systemGray5))
                .padding(.top, -10)
                .sheet(isPresented: $showDaySheet, onDismiss: { selectedDay = nil }) {
                    if let day = selectedDay {
                        DaySheetView(day: day) // Parāda dienas lapu, uzspiežot uz dienas
                    } else {
                        Text("Diena nav ielādēta, mēģiniet vēlreiz...") // Noklusējuma teksts, ja diena nav ielādēta
                    }
                }
                .navigationBarBackButtonHidden(true)
        }
    }

    // MARK: - Mēnešu pārslēgšana
    /// Kalendāra galvene ar mēnesi
    private var monthHeader: some View {
        HStack {
            Button("<") {
                displayedMonth = previousMonth(from: displayedMonth) // Poga iepriešējam mēnesim
            }
            Spacer()
            Text(monthTitle(for: displayedMonth)) // Pašreizējais mēnesis
                .font(.headline)
            Spacer()
            Button(">") {
                displayedMonth = nextMonth(from: displayedMonth) // Poga nākamajam mēnesim
            }
        }
        .padding()
    }

    // MARK: - Dienas šūna
    /// Izveido pogu katrai kalendāra dienai, lai atvērtu dienas lapu
    /// - Parameter date: Diena, kuru attēlot šūnā
    /// - Returns: Dienas skats
    private func dayCell(for date: Date) -> some View {
        let existingDiena = days.first { calendar.isDate($0.date, inSameDayAs: date) } // Pārbauda, vai diena eksistē

        return Button {
            // 1) Pārbauda, vai ir veikts pieskāriens un bloķē to, lai diena var ielādēties
            guard !isTapLocked else { return }
            isTapLocked = true

            // 2) Izveido jaunu dienu vai izmanto jau eksistējošu dienu
            if let found = existingDiena {
                selectedDay = found
            } else {
                let tmpDay = Day(date: date, notes: "")
                selectedDay = tmpDay
            }
            showDaySheet = true

            // 3) Atļauj veikt pieskārienu pēc kāda laika. Šis tiek darīts, lai ļautu dienām pilnvērtīgi ielādēties
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isTapLocked = false
            }
        } label: {
            Text("\(calendar.component(.day, from: date))") // Display day number
                .padding(8)
                .background(existingDiena != nil ? Color.yellow.opacity(0.3) : Color.clear)
                .clipShape(Circle())
        }
        .disabled(isTapLocked) // Bloķē pogu
    }


    // MARK: - Palīgfunkcijas
    /// Ģenerē sarakstu ar datumiem katrai dienai
    /// - Returns: Saraksts ar `Date` objektiem katrai dienai
    private func daysInDisplayedMonth() -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        return range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    /// Formatē datumu simbolu virknē ar mēnesi un gadu
    /// - Parameter date: Datums, kuru formatēt
    /// - Returns: Simbolu virkne formātā "Mēnesis Gads"
    private func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
    
    /// Izrēķina iepriekšējo mēnesi no datuma
    /// - Parameter date: Pašreiz rādītais mēnesis
    /// - Returns: `Date` objekts attēlojot iepriekšējo mēnesi
    private func previousMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    /// Izrēķina nākamo mēnesi no datuma
    /// - Parameter date: Pašreiz rādītais mēnesis
    /// - Returns: `Date` objekts attēlojot nākamo mēnesi
    private func nextMonth(from date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// Pārbauda, vai datums ir pašreiz attēlotajā mēnesī
    /// - Parameter date: Datums, kuru pārbaudīt
    /// - Returns: `true`, ja datums ir mēnesī, pretēji `false`
    private func isCurrentMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: displayedMonth, toGranularity: .month)
    }
}



