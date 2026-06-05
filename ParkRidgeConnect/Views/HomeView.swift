import SwiftUI

struct HomeView: View {
    @Environment(TownStore.self) private var store
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    AppHeader(subtitle: store.refreshStatus)
                    refreshStrip
                    weatherCard
                    smartPlanCard
                    residentLensSection
                    alertSection
                    eventSection
                    quickActions
                    savedPlaces
                    topPlaces
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 96)
            }
            .background(PRTheme.canvas.ignoresSafeArea())
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if store.lastRefresh == nil {
                    await store.refresh()
                }
            }
            .refreshable {
                await store.refresh()
            }
        }
    }

    private var refreshStrip: some View {
        HStack {
            Label(store.lastRefresh.map { "Updated \($0.formatted(date: .omitted, time: .shortened))" } ?? "Official links + seeded local cache", systemImage: store.isRefreshing ? "arrow.triangle.2.circlepath" : "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PRTheme.teal)
            Spacer()
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Refresh borough data")
        }
        .residentCard()
    }

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Right Now Outside", systemImage: "cloud.sun.fill")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await store.refreshWeather() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .disabled(store.isLoadingWeather)
                .accessibilityLabel("Refresh weather")
            }

            if let weather = store.weatherSnapshot {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(PRTheme.sky.opacity(0.18))
                        Image(systemName: weather.systemImage)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(PRTheme.sky)
                    }
                    .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(weather.temperatureText)
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(PRTheme.ink)
                            Text(weather.shortForecast)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(PRTheme.sky)
                                .lineLimit(1)
                        }

                        Text(weather.outdoorAdvice)
                            .font(.caption)
                            .foregroundStyle(PRTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 8) {
                    WeatherMetric(symbol: "drop.fill", text: weather.precipitationText)
                    WeatherMetric(symbol: "wind", text: weather.windText)
                    SourceBadge(title: weather.source.title)
                }

                Button {
                    store.queueAssistantPrompt(store.assistantPromptForWeather())
                    selectedTab = .ask
                } label: {
                    Label("Ask AI what to do with this weather", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(PRTheme.teal)
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                        .opacity(store.isLoadingWeather ? 1 : 0)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.weatherStatus)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PRTheme.ink)
                        Text("Pull to refresh or tap the weather refresh button for the National Weather Service forecast.")
                            .font(.caption)
                            .foregroundStyle(PRTheme.muted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    private var smartPlanCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Smart Town Plan", systemImage: "wand.and.stars")
                        .font(.headline)
                    Text("Three useful moves for the \(store.selectedLens.rawValue) lens.")
                        .font(.caption)
                        .foregroundStyle(PRTheme.muted)
                }
                Spacer()
                Button {
                    store.queueAssistantPrompt(store.assistantPromptForSmartPlan())
                    selectedTab = .ask
                } label: {
                    Image(systemName: "sparkles")
                        .font(.headline.weight(.bold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Ask AI to explain the Smart Town Plan")
            }

            VStack(spacing: 8) {
                ForEach(store.smartPlanItems.prefix(3)) { item in
                    smartPlanRow(for: item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    @ViewBuilder
    private func smartPlanRow(for item: TownPlanItem) -> some View {
        if let placeID = item.placeID, let place = store.place(withID: placeID) {
            NavigationLink {
                PlaceDetailView(place: place)
            } label: {
                TownPlanRow(item: item, showsExternalArrow: false)
            }
            .buttonStyle(.plain)
        } else if let serviceID = item.serviceID,
                  let service = store.service(withID: serviceID),
                  let website = service.website {
            Link(destination: website) {
                TownPlanRow(item: item, showsExternalArrow: true)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                store.queueAssistantPrompt(store.assistantPromptForSmartPlan())
                selectedTab = .ask
            } label: {
                TownPlanRow(item: item, showsExternalArrow: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var residentLensSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Resident Lens", systemImage: "slider.horizontal.3")
                    .font(.headline)
                Spacer()
                Text(store.selectedLens.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PRTheme.teal)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(PRTheme.teal.opacity(0.10), in: Capsule())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ResidentLens.allCases) { lens in
                        ResidentLensPill(
                            lens: lens,
                            isSelected: lens == store.selectedLens
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                store.selectLens(lens)
                            }
                        }
                    }
                }
            }

            Button {
                store.queueAssistantPrompt(store.assistantPromptForSelectedLens())
                selectedTab = .ask
            } label: {
                Label("Brief me for \(store.selectedLens.rawValue)", systemImage: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(PRTheme.teal)

            VStack(spacing: 8) {
                ForEach(store.residentBriefItems.prefix(3)) { item in
                    residentBriefRow(for: item)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    @ViewBuilder
    private func residentBriefRow(for item: ResidentBriefItem) -> some View {
        if let placeID = item.placeID, let place = store.place(withID: placeID) {
            NavigationLink {
                PlaceDetailView(place: place)
            } label: {
                ResidentBriefRow(item: item, showsExternalArrow: false)
            }
            .buttonStyle(.plain)
        } else if let serviceID = item.serviceID,
                  let service = store.service(withID: serviceID),
                  let website = service.website {
            Link(destination: website) {
                ResidentBriefRow(item: item, showsExternalArrow: true)
            }
            .buttonStyle(.plain)
        } else {
            Button {
                store.queueAssistantPrompt(store.assistantPrompt(for: item))
                selectedTab = .ask
            } label: {
                ResidentBriefRow(item: item, showsExternalArrow: false)
            }
            .buttonStyle(.plain)
        }
    }

    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Borough Alerts")
                .font(.headline)
            ForEach(store.alerts.prefix(3)) { alert in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: alert.severity == .urgent ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundStyle(alert.severity.color)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(alert.title)
                            .font(.subheadline.weight(.bold))
                        Text(alert.summary)
                            .font(.caption)
                            .foregroundStyle(PRTheme.muted)
                        SourceBadge(title: alert.source.title)
                    }
                    Spacer()
                }
                .padding(10)
                .background(alert.severity.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Coming Up")
                .font(.headline)
            ForEach(store.featuredEvents) { event in
                HStack(spacing: 10) {
                    VStack {
                        Text(event.dateText.components(separatedBy: " ").first ?? event.dateText)
                            .font(.title3.weight(.bold))
                        Text(event.dateText.components(separatedBy: " ").dropFirst().joined(separator: " "))
                            .font(.caption)
                    }
                    .frame(width: 58)
                    .foregroundStyle(event.category.color)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title)
                            .font(.subheadline.weight(.bold))
                        Text(event.timeText)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(PRTheme.muted)
                        Text(event.audience)
                            .font(.caption)
                            .foregroundStyle(PRTheme.muted)
                    }
                    Spacer()
                }
                .padding(10)
                .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            quickAction("Ask AI", "sparkles", PRTheme.teal) {
                selectedTab = .ask
            }
            quickAction("Eat", "fork.knife", PRTheme.cranberry) {
                store.requestedExploreCategory = .food
                store.requestedExploreSearchText = ""
                selectedTab = .explore
            }
            quickAction("Kids", "figure.and.child.holdinghands", PRTheme.sky) {
                store.requestedExploreCategory = nil
                store.requestedExploreSearchText = "kids"
                selectedTab = .explore
            }
            quickAction("Services", "building.columns", PRTheme.leaf) {
                selectedTab = .services
            }
        }
    }

    private func quickAction(_ title: String, _ symbol: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                Text(title)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .opacity(0.7)
            }
            .font(.headline)
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var savedPlaces: some View {
        if !store.favoritePlaces.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Saved Places", systemImage: "bookmark.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(store.favoritePlaces.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PRTheme.teal)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(PRTheme.teal.opacity(0.10), in: Capsule())
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.favoritePlaces) { place in
                            NavigationLink {
                                PlaceDetailView(place: place)
                            } label: {
                                SavedPlaceTile(place: place)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var topPlaces: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Useful Right Now")
                .font(.headline)
            ForEach(store.topPlaces.prefix(4)) { place in
                PlaceCard(place: place)
            }
        }
    }
}

private struct TownPlanRow: View {
    let item: TownPlanItem
    let showsExternalArrow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(item.category.color.opacity(0.14))
                Image(systemName: item.symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.category.color)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(item.slot)
                        .font(.caption.weight(.black))
                        .foregroundStyle(item.category.color)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Label(item.actionLabel, systemImage: showsExternalArrow ? "arrow.up.right" : "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PRTheme.muted)
                }

                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PRTheme.ink)
                    .lineLimit(2)

                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(PRTheme.muted)
                    .lineLimit(2)

                SourceBadge(title: item.source.title)
            }
        }
        .padding(10)
        .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct WeatherMetric: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.bold))
            .foregroundStyle(PRTheme.sky)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(PRTheme.sky.opacity(0.10), in: Capsule())
    }
}

private struct ResidentLensPill: View {
    let lens: ResidentLens
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(lens.rawValue, systemImage: lens.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(isSelected ? .white : PRTheme.teal)
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .background(isSelected ? PRTheme.teal : PRTheme.teal.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lens.rawValue) resident lens")
    }
}

private struct ResidentBriefRow: View {
    let item: ResidentBriefItem
    let showsExternalArrow: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(item.category.color.opacity(0.14))
                Image(systemName: item.category.symbol)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(item.category.color)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.kicker)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.category.color)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Label(item.actionLabel, systemImage: showsExternalArrow ? "arrow.up.right" : "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PRTheme.muted)
                }

                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PRTheme.ink)
                    .lineLimit(2)

                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(PRTheme.muted)
                    .lineLimit(3)

                SourceBadge(title: item.source.title)
            }
        }
        .padding(10)
        .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SavedPlaceTile: View {
    let place: LocalPlace

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            PlaceThumbnail(
                url: place.imageURL,
                tint: place.category.color,
                height: 78,
                symbol: place.category.symbol,
                title: place.name
            )
            Text(place.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PRTheme.ink)
                .lineLimit(2)
                .frame(minHeight: 36, alignment: .topLeading)
            Label(place.category.rawValue, systemImage: place.category.symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(place.category.color)
        }
        .frame(width: 158)
        .padding(10)
        .background(PRTheme.paper, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PRTheme.line, lineWidth: 1)
        }
    }
}
