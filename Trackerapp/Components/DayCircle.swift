import SwiftUI

struct DayCircle: View {
    let number: Int
    let status: DayStatus?
    let isToday: Bool
    var size: CGFloat = 36
    var font: Font = .subheadline

    var body: some View {
        Text("\(number)")
            .font(font)
            .foregroundStyle(textColor)
            .frame(width: size, height: size)
            .background(backgroundColor, in: .circle)
    }

    /// Today with no selection yet is shown as a solid orange circle.
    private var isHighlightedToday: Bool { isToday && status == nil }

    /// The status color, or nil when the day has no status.
    private var tint: Color? {
        switch status {
        case .learned: Color.brandOrange
        case .freezed: Color.brandCyan
        case nil: nil
        }
    }

    private var textColor: Color {
        if isHighlightedToday { return .white }
        return tint ?? .primary
    }

    private var backgroundColor: Color {
        if isHighlightedToday { return .brandOrange }
        return tint?.opacity(0.2) ?? .clear
    }
}
