import SwiftUI

enum PRTheme {
    static let ink = Color(red: 0.08, green: 0.11, blue: 0.12)
    static let muted = Color(red: 0.37, green: 0.42, blue: 0.43)
    static let canvas = Color(red: 0.96, green: 0.97, blue: 0.95)
    static let paper = Color.white
    static let teal = Color(red: 0.0, green: 0.45, blue: 0.45)
    static let leaf = Color(red: 0.16, green: 0.50, blue: 0.28)
    static let cranberry = Color(red: 0.64, green: 0.12, blue: 0.22)
    static let gold = Color(red: 0.88, green: 0.58, blue: 0.15)
    static let sky = Color(red: 0.10, green: 0.50, blue: 0.78)
    static let line = Color.black.opacity(0.08)
}

extension TownCategory {
    var color: Color {
        switch self {
        case .food: return PRTheme.cranberry
        case .kids: return PRTheme.sky
        case .recreation: return PRTheme.leaf
        case .adults: return PRTheme.gold
        case .government: return PRTheme.teal
        case .services: return PRTheme.muted
        case .schools: return Color.indigo
        case .library: return Color.pink
        case .transit: return Color.cyan
        case .emergency: return Color.red
        case .utilities: return Color.orange
        }
    }
}

extension NoticeSeverity {
    var color: Color {
        switch self {
        case .info: return PRTheme.sky
        case .advisory: return PRTheme.gold
        case .urgent: return Color.red
        }
    }
}

struct ResidentCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(PRTheme.paper, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(PRTheme.line, lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 3)
    }
}

extension View {
    func residentCard() -> some View {
        modifier(ResidentCard())
    }
}

func phoneURL(_ phone: String?) -> URL? {
    guard let phone else { return nil }
    let normalized = phone.filter { $0.isNumber || $0 == "x" || $0 == "X" }
    return URL(string: "tel://\(normalized)")
}

