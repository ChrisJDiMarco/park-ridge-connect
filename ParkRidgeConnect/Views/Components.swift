import SwiftUI

struct AppHeader: View {
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(PRTheme.teal)
                Image(systemName: "house.and.flag.fill")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Park Ridge Connect")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(PRTheme.ink)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
            }
            Spacer()
        }
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
                .font(.callout.weight(.semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct SourceBadge: View {
    let title: String

    var body: some View {
        Label(title, systemImage: "checkmark.seal.fill")
            .font(.caption.weight(.medium))
            .foregroundStyle(PRTheme.teal)
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(PRTheme.teal.opacity(0.10), in: Capsule())
    }
}

struct ActionLink: View {
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        if let url {
            Link(destination: url) {
                Label(title, systemImage: systemImage)
                    .font(.footnote.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

struct EmptyResidentState: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(PRTheme.muted)
            Text(title)
                .font(.headline)
                .foregroundStyle(PRTheme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .residentCard()
    }
}

struct PlaceCard: View {
    @Environment(TownStore.self) private var store

    let place: LocalPlace

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let imageURL = place.imageURL {
                ZStack(alignment: .topTrailing) {
                    PlaceThumbnail(
                        url: imageURL,
                        tint: place.category.color,
                        height: 124,
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
                    .font(.headline)
                    .foregroundStyle(PRTheme.ink)
                Text(place.subcategory)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(place.category.color)
                Text(place.summary)
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(place.highlights, id: \.self) { highlight in
                        Text(highlight)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(PRTheme.canvas, in: Capsule())
                    }
                }
            }

            HStack {
                NavigationLink {
                    PlaceDetailView(place: place)
                } label: {
                    Label("Info", systemImage: "info.circle")
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

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
                .font(.headline.weight(.bold))
                .foregroundStyle(store.isFavorite(place) ? PRTheme.gold : PRTheme.teal)
                .frame(width: 36, height: 36)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(store.isFavorite(place) ? "Unsave \(place.name)" : "Save \(place.name)")
    }
}

struct PlaceDetailView: View {
    @Environment(TownStore.self) private var store

    let place: LocalPlace
    @State private var aiResponse: TownAIResponse?

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 14) {
                PlaceThumbnail(
                    url: place.imageURL,
                    tint: place.category.color,
                    height: 220,
                    symbol: place.category.symbol,
                    title: place.name
                )

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
                            .font(.title2.weight(.bold))
                            .foregroundStyle(PRTheme.ink)
                        Text(place.subcategory)
                            .font(.headline)
                            .foregroundStyle(place.category.color)
                        Text(place.summary)
                            .font(.body)
                            .foregroundStyle(PRTheme.muted)
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
        .background(PRTheme.canvas.ignoresSafeArea())
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Plan It")
                .font(.headline)
            HStack {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        store.toggleFavorite(place)
                    }
                } label: {
                    Label(store.isFavorite(place) ? "Saved" : "Save", systemImage: store.isFavorite(place) ? "bookmark.fill" : "bookmark")
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(store.isFavorite(place) ? PRTheme.gold : PRTheme.teal)

                ActionLink(title: "Map", systemImage: "map", url: place.mapURL)
                ActionLink(title: "Call", systemImage: "phone", url: phoneURL(place.phone))
                ActionLink(title: "Web", systemImage: "safari", url: place.website)
            }
        }
        .residentCard()
    }

    private var aiPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Ask AI", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(PRTheme.teal)
                Spacer()
                Button("Make a Plan") {
                    aiResponse = store.placePlan(for: place)
                }
                .font(.footnote.weight(.bold))
                .buttonStyle(.bordered)
            }

            if let aiResponse {
                Text(aiResponse.text)
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.ink)
                    .textSelection(.enabled)

                if !aiResponse.sourceTitles.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(aiResponse.sourceTitles, id: \.self) { sourceTitle in
                                SourceBadge(title: sourceTitle)
                            }
                        }
                    }
                }
            } else {
                Text("Get a quick local recommendation using this place, nearby town resources, and the current Park Ridge guide.")
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
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

    init(url: URL?, tint: Color, height: CGFloat, symbol: String = "mappin.and.ellipse.circle.fill", title: String? = nil) {
        self.url = url
        self.tint = tint
        self.height = height
        self.symbol = symbol
        self.title = title
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
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.black.opacity(0.06))
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
                        Text(title ?? "Park Ridge")
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
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }
}

struct ServiceCard: View {
    let service: CivicService

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Label(service.category.rawValue, systemImage: service.category.symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(service.category.color)
                Spacer()
                SourceBadge(title: service.source.title)
            }

            Text(service.name)
                .font(.headline)
                .foregroundStyle(PRTheme.ink)
            Text(service.department)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(service.category.color)
            Text(service.summary)
                .font(.subheadline)
                .foregroundStyle(PRTheme.muted)

            HStack {
                ActionLink(title: service.actionLabel, systemImage: "safari", url: service.website)
                ActionLink(title: "Call", systemImage: "phone", url: phoneURL(service.phone))
            }
        }
        .residentCard()
    }
}
