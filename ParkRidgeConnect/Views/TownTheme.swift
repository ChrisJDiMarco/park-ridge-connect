import SwiftUI

/// Park Ridge Connect design system.
/// Soft, elevated, iOS-native: continuous rounded corners, layered shadows,
/// capsule controls, and a calm civic palette.
enum PRTheme {
    // MARK: - Palette
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.14)
    static let muted = Color(red: 0.42, green: 0.46, blue: 0.49)
    static let canvas = Color(red: 0.953, green: 0.961, blue: 0.949)
    static let paper = Color.white
    static let teal = Color(red: 0.0, green: 0.46, blue: 0.46)
    static let tealDeep = Color(red: 0.0, green: 0.33, blue: 0.36)
    static let leaf = Color(red: 0.16, green: 0.52, blue: 0.30)
    static let cranberry = Color(red: 0.68, green: 0.15, blue: 0.26)
    static let gold = Color(red: 0.84, green: 0.55, blue: 0.10)
    static let sky = Color(red: 0.10, green: 0.48, blue: 0.78)
    static let line = Color.black.opacity(0.05)

    // MARK: - Metrics
    static let cardRadius: CGFloat = 22
    static let innerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 16

    // MARK: - Gradients
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [teal, tealDeep], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var skyWash: LinearGradient {
        LinearGradient(colors: [sky.opacity(0.16), sky.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
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

// MARK: - Backdrop

/// Shared aerial-photo wallpaper behind every page. The canvas-tinted scrim
/// keeps text readable while letting the town stay visible. Rendered once as
/// a static layer — no per-frame cost while scrolling.
struct TownBackdrop: View {
    var body: some View {
        ZStack {
            PRTheme.canvas
            Image("TownBackdrop")
                .resizable()
                .scaledToFill()
            LinearGradient(
                colors: [
                    PRTheme.canvas.opacity(0.78),
                    PRTheme.canvas.opacity(0.64),
                    PRTheme.canvas.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Cards

/// Primary elevated surface: generous continuous corners + soft layered shadow.
struct ResidentCard: ViewModifier {
    var padding: CGFloat = PRTheme.cardPadding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                // Shadows live on the shape, not the content, so the GPU only
                // renders the shadow for a rounded rect instead of rasterizing
                // the entire card subtree offscreen.
                RoundedRectangle(cornerRadius: PRTheme.cardRadius, style: .continuous)
                    .fill(PRTheme.paper)
                    .shadow(color: Color.black.opacity(0.05), radius: 14, y: 6)
                    .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: PRTheme.cardRadius, style: .continuous)
                    .strokeBorder(PRTheme.line, lineWidth: 1)
            }
    }
}

/// Quiet inset surface used for rows nested inside a card.
struct InnerTile: ViewModifier {
    var padding: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: PRTheme.innerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: PRTheme.innerRadius, style: .continuous))
    }
}

extension View {
    func residentCard(padding: CGFloat = PRTheme.cardPadding) -> some View {
        modifier(ResidentCard(padding: padding))
    }

    func innerTile(padding: CGFloat = 12) -> some View {
        modifier(InnerTile(padding: padding))
    }
}

// MARK: - Button Styles

/// Filled capsule button with a gentle press scale.
struct PRProminentButtonStyle: ButtonStyle {
    var tint: Color = PRTheme.teal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(tint)
                    .shadow(color: tint.opacity(0.30), radius: 8, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Soft tinted capsule button — the workhorse secondary action.
struct PRSoftButtonStyle: ButtonStyle {
    var tint: Color = PRTheme.teal

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(tint.opacity(0.12), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Small circular icon button on a tinted disc.
struct PRIconButtonStyle: ButtonStyle {
    var tint: Color = PRTheme.teal
    var size: CGFloat = 36

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.12), in: Circle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

/// Plain pressable style for tappable rows and tiles.
struct PRPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Section Header

/// Card section header: tinted icon chip + title + optional trailing accessory.
struct SectionHeader<Trailing: View>: View {
    let title: String
    let symbol: String
    var tint: Color
    @ViewBuilder var trailing: Trailing

    init(_ title: String, symbol: String, tint: Color = PRTheme.teal, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint.opacity(0.14))
                Image(systemName: symbol)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 30, height: 30)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(PRTheme.ink)

            Spacer(minLength: 8)
            trailing
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String, symbol: String, tint: Color = PRTheme.teal) {
        self.init(title, symbol: symbol, tint: tint) { EmptyView() }
    }
}

/// Small tinted capsule used for counts and statuses.
struct CountBadge: View {
    let text: String
    var tint: Color = PRTheme.teal

    var body: some View {
        Text(text)
            .font(.caption.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

func phoneURL(_ phone: String?) -> URL? {
    guard let phone else { return nil }
    let normalized = phone.filter { $0.isNumber || $0 == "x" || $0 == "X" }
    return URL(string: "tel://\(normalized)")
}
