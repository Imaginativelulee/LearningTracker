import SwiftUI

struct DayCircle: View {
    let number: Int
    let status: DayStatus?
    let isToday: Bool

    var body: some View {
        Text("\(number)")
            .font(.subheadline)
            .foregroundStyle(textColor)
            .frame(width: 36, height: 36)
            .background(backgroundColor, in: .circle)
    }

    private var isHighlightedToday: Bool { isToday && status == nil }

    private var textColor: Color {
        if isHighlightedToday { return .white }
        switch status {
        case .learned: return Color("AppOrange")
        case .freezed: return Color("AppCyan")
        case nil: return .primary
        }
    }

    private var backgroundColor: Color {
        if isHighlightedToday { return Color("AppOrange") }
        switch status {
        case .learned: return Color("AppOrange").opacity(0.2)
        case .freezed: return Color("AppCyan").opacity(0.2)
        case nil: return .clear
        }
    }
}
