import SwiftUI

struct AppHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(PRTheme.brandGradient)
                    .shadow(color: PRTheme.teal.opacity(0.35), radius: 10, y: 5)
                Image(systemName: "house.and.flag.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(PRTheme.ink)
                Text(subtitle)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(PRTheme.muted)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct CategoryPill: View {
    let category: TownCategory?
    let isSelected: Bool
    let action: () -> Void

    private var title: String { category?.rawValue ?? "All" }
    private var symbol: String { category?.symbol ?? "square.grid.2x2" }
    private var color: Color { category?.color ?? PRTheme.ink }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.10))
                        .shadow(color: isSelected ? color.opacity(0.30) : .clear, radius: 6, y: 3)
                }
        }
        .buttonStyle(PRPressableStyle())
        .accessibilityLabel(title)
    }
}

struct SourceBadge: View {
    let title: String

    var body: some View {
        Label(title, systemImage: "checkmark.seal.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(PRTheme.teal)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(PRTheme.teal.opacity(0.10), in: Capsule())
    }
}

struct ActionLink: View {
    let title: String
    let systemImage: String
    let url: URL?
    var tint: Color = PRTheme.teal

    var body: some View {
        if let url {
            Link(destination: url) {
                Label(title, systemImage: systemImage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(tint.opacity(0.10), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(PRPressableStyle())
        }
    }
}

struct EmptyResidentState: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(PRTheme.teal.opacity(0.10))
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(PRTheme.teal)
            }
            .frame(width: 64, height: 64)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PRTheme.ink)
                    .multilineTextAlignment(.center)
                Text("Try a different word or category.")
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .residentCard()
    }
}

struct PlaceCard: View {
    @Environment(TownStore.self) private var store

    let place: LocalPlace

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURL = place.imageURL {
                ZStack(alignment: .topTrailing) {
                    PlaceThumbnail(
                        url: imageURL,
                        tint: place.category.color,
                        height: 140,
                        symbol: place.category.symbol,
                        title: place.name
                    )
                    favoriteButton
                        .padding(8)
                }
            }

            HStack(alignment: .top) {
                Label(place.category.rawValue, systemImage: place.category.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(place.category.color)
                Spacer()
                SourceBadge(title: place.source.title)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(place.name)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(PRTheme.ink)
                Text(place.subcategory)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(place.category.color)
                Text(place.summary)
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
                    .lineSpacing(2)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(place.highlights, id: \.self) { highlight in
                        Text(highlight)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PRTheme.ink.opacity(0.8))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(PRTheme.canvas, in: Capsule())
                    }
                }
            }

            HStack(spacing: 8) {
                NavigationLink {
                    PlaceDetailView(place: place)
                } label: {
                    Label("Info", systemImage: "info.circle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(PRTheme.teal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(PRTheme.teal.opacity(0.10), in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(PRPressableStyle())

                ActionLink(title: "Open", systemImage: "safari", url: place.website)
                ActionLink(title: "Map", systemImage: "map", url: place.mapURL)
                ActionLink(title: "Call", systemImage: "phone", url: phoneURL(place.phone))
            }
        }
        .residentCard()
    }

    private var favoriteButton: some View {
        Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                store.toggleFavorite(place)
            }
        } label: {
            Image(systemName: store.isFavorite(place) ? "bookmark.fill" : "bookmark")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(store.isFavorite(place) ? PRTheme.gold : PRTheme.teal)
                .frame(width: 36, height: 36)
                .background {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: Color.black.opacity(0.10), radius: 6, y: 2)
                }
        }
        .buttonStyle(PRPressableStyle())
        .accessibilityLabel(store.isFavorite(place) ? "Unsave \(place.name)" : "Save \(place.name)")
    }
}

struct PlaceDetailView: View {
    @Environment(TownStore.self) private var store

    let place: LocalPlace
    @State private var aiResponse: TownAIResponse?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: PRTheme.sectionSpacing) {
                PlaceThumbnail(
                    url: place.imageURL,
                    tint: place.category.color,
                    height: 220,
                    symbol: place.category.symbol,
                    title: place.name,
                    radius: PRTheme.cardRadius
                )
                .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Label(place.category.rawValue, systemImage: place.category.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(place.category.color)
                        Spacer()
                        SourceBadge(title: place.source.title)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(place.name)
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(PRTheme.ink)
                        Text(place.subcategory)
                            .font(.headline)
                            .foregroundStyle(place.category.color)
                        Text(place.summary)
                            .font(.body)
                            .foregroundStyle(PRTheme.muted)
                            .lineSpacing(3)
                    }

                    if let address = place.address {
                        Label(address, systemImage: "mappin.and.ellipse")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PRTheme.ink)
                    }

                    chipSection(title: "Why Locals Use It", values: place.highlights)

                    if !place.tags.isEmpty {
                        chipSection(title: "Good For", values: place.tags.map { $0.capitalized })
                    }
                }
                .residentCard()

                actionPanel
                aiPanel
            }
            .padding(16)
        }
        .background { TownBackdrop() }
        .navigationTitle(place.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        store.toggleFavorite(place)
                    }
                } label: {
                    Image(systemName: store.isFavorite(place) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(store.isFavorite(place) ? "Unsave \(place.name)" : "Save \(place.name)")
            }
        }
    }

    private var actionPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Plan It", symbol: "calendar.badge.checkmark")

            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        store.toggleFavorite(place)
                    }
                } label: {
                    Label(store.isFavorite(place) ? "Saved" : "Save", systemImage: store.isFavorite(place) ? "bookmark.fill" : "bookmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(store.isFavorite(place) ? PRTheme.gold : PRTheme.teal, in: Capsule())
                }
                .buttonStyle(PRPressableStyle())

                ActionLink(title: "Map", systemImage: "map", url: place.mapURL)
                ActionLink(title: "Call", systemImage: "phone", url: phoneURL(place.phone))
                ActionLink(title: "Web", systemImage: "safari", url: place.website)
            }
        }
        .residentCard()
    }

    private var aiPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Ask AI", symbol: "sparkles") {
                Button("Make a Plan") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        aiResponse = store.placePlan(for: place)
                    }
                }
                .buttonStyle(PRSoftButtonStyle())
            }

            if let aiResponse {
                Text(aiResponse.text)
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.ink)
                    .lineSpacing(3)
                    .textSelection(.enabled)

                if !aiResponse.sourceTitles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(aiResponse.sourceTitles, id: \.self) { sourceTitle in
                                SourceBadge(title: sourceTitle)
                            }
                        }
                    }
                }
            } else {
                Text("Get a quick local recommendation using this place, nearby town resources, and the current \(store.config.townName) guide.")
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
                    .lineSpacing(3)
            }
        }
        .residentCard()
    }

    private func chipSection(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PRTheme.ink)
            FlowChips(values: values)
        }
    }
}

struct PlaceThumbnail: View {
    let url: URL?
    let tint: Color
    let height: CGFloat
    let symbol: String
    let title: String?
    let radius: CGFloat

    init(
        url: URL?,
        tint: Color,
        height: CGFloat,
        symbol: String = "mappin.and.ellipse.circle.fill",
        title: String? = nil,
        radius: CGFloat = 16
    ) {
        self.url = url
        self.tint = tint
        self.height = height
        self.symbol = symbol
        self.title = title
        self.radius = radius
    }

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.18))) { phase in
                    switch phase {
                    case .empty:
                        placeholder
                            .redacted(reason: .placeholder)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05))
        }
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            LinearGradient(
                colors: [tint.opacity(0.22), tint.opacity(0.08), PRTheme.canvas],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 7) {
                Image(systemName: symbol)
                    .font(.system(size: min(height * 0.28, 48), weight: .bold))
                    .foregroundStyle(tint)

                if height >= 110 {
                    VStack(spacing: 2) {
                        Text(title ?? "Local spot")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PRTheme.ink)
                            .lineLimit(1)
                        Text("Local guide")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(PRTheme.muted)
                    }
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct FlowChips: View {
    let values: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PRTheme.ink.opacity(0.8))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }
}

struct ServiceCard: View {
    let service: CivicService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(service.category.color.opacity(0.12))
                    Image(systemName: service.category.symbol)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(service.category.color)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 3) {
                    Text(service.name)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(PRTheme.ink)
                    Text(service.department)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(service.category.color)
                }

                Spacer(minLength: 0)
            }

            Text(service.summary)
                .font(.subheadline)
                .foregroundStyle(PRTheme.muted)
                .lineSpacing(2)

            HStack {
                SourceBadge(title: service.source.title)
                Spacer()
            }

            HStack(spacing: 8) {
                ActionLink(title: service.actionLabel, systemImage: "safari", url: service.website)
                ActionLink(title: "Call", systemImage: "phone", url: phoneURL(service.phone))
            }
        }
        .residentCard()
    }
}
