import SwiftUI

struct HomeView: View {
    @Environment(TownStore.self) private var store
    @Binding var selectedTab: AppTab

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PRTheme.sectionSpacing) {
                    AppHeader(title: store.config.appTitle, subtitle: store.homeStatusText)
                    weatherCard
                    townPlanSection
                    quickActions
                    alertSection
                    eventSection
                    savedPlaces
                    topPlaces
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .background { TownBackdrop() }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if store.lastRefresh == nil {
                    await store.refresh()
                }
            }
            .refreshable {
                await store.refresh(forcePlaceDirectory: true)
            }
        }
    }

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Right Now Outside", symbol: "cloud.sun.fill", tint: PRTheme.sky) {
                Button {
                    Task { await store.refreshWeather() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(PRIconButtonStyle(tint: PRTheme.sky, size: 30))
                .disabled(store.isLoadingWeather)
                .accessibilityLabel("Refresh weather")
            }

            if let weather = store.weatherSnapshot {
                HStack(alignment: .center, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(PRTheme.skyWash)
                        Image(systemName: weather.systemImage)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(PRTheme.sky)
                    }
                    .frame(width: 76, height: 76)

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(weather.temperatureText)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundStyle(PRTheme.ink)
                            Text(weather.shortForecast)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(PRTheme.sky)
                                .lineLimit(1)
                        }

                        Text(weather.outdoorAdvice)
                            .font(.footnote)
                            .foregroundStyle(PRTheme.muted)
                            .lineSpacing(2)
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PRSoftButtonStyle())
            } else {
                HStack(spacing: 12) {
                    ProgressView()
                        .opacity(store.isLoadingWeather ? 1 : 0)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.weatherStatus)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PRTheme.ink)
                        Text("Pull to refresh or tap the weather refresh button for the National Weather Service forecast.")
                            .font(.footnote)
                            .foregroundStyle(PRTheme.muted)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    /// One card that merges the old "Smart Town Plan" and "Resident Lens"
    /// sections: pick a lens, get three weather-aware moves for it.
    private var townPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Your Town Plan", symbol: "wand.and.stars") {
                CountBadge(text: store.selectedLens.rawValue)
            }

            Text("Pick a lens — the plan adapts to it and today's weather.")
                .font(.footnote)
                .foregroundStyle(PRTheme.muted)

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
                .padding(.vertical, 2)
            }

            VStack(spacing: 8) {
                ForEach(store.smartPlanItems.prefix(3)) { item in
                    smartPlanRow(for: item)
                }
            }

            Button {
                store.queueAssistantPrompt(store.assistantPromptForSmartPlan())
                selectedTab = .ask
            } label: {
                Label("Brief me on this plan", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PRProminentButtonStyle())
            .accessibilityLabel("Ask AI to brief you on this town plan")
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
            .buttonStyle(PRPressableStyle())
        } else if let serviceID = item.serviceID,
                  let service = store.service(withID: serviceID),
                  let website = service.website {
            Link(destination: website) {
                TownPlanRow(item: item, showsExternalArrow: true)
            }
            .buttonStyle(PRPressableStyle())
        } else {
            Button {
                store.queueAssistantPrompt(store.assistantPromptForSmartPlan())
                selectedTab = .ask
            } label: {
                TownPlanRow(item: item, showsExternalArrow: false)
            }
            .buttonStyle(PRPressableStyle())
        }
    }

    private var alertSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Borough Alerts", symbol: "bell.badge.fill", tint: PRTheme.gold)

            ForEach(store.alerts.prefix(3)) { alert in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: alert.severity == .urgent ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(alert.severity.color)
                        .padding(.top, 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alert.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PRTheme.ink)
                        Text(alert.summary)
                            .font(.footnote)
                            .foregroundStyle(PRTheme.muted)
                            .lineSpacing(2)
                        SourceBadge(title: alert.source.title)
                    }
                    Spacer()
                }
                .padding(12)
                .background(alert.severity.color.opacity(0.08), in: RoundedRectangle(cornerRadius: PRTheme.innerRadius, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Coming Up", symbol: "calendar")

            ForEach(store.featuredEvents) { event in
                HStack(spacing: 12) {
                    VStack(spacing: 1) {
                        Text(event.dateText.components(separatedBy: " ").first ?? event.dateText)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        Text(event.dateText.components(separatedBy: " ").dropFirst().joined(separator: " "))
                            .font(.caption.weight(.semibold))
                    }
                    .frame(width: 54, height: 54)
                    .foregroundStyle(event.category.color)
                    .background(event.category.color.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(event.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PRTheme.ink)
                        Text(event.timeText)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(PRTheme.muted)
                        Text(event.audience)
                            .font(.caption)
                            .foregroundStyle(PRTheme.muted)
                    }
                    Spacer()
                }
                .innerTile()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .residentCard()
    }

    private var quickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
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
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.14))
                    Image(systemName: symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                }
                .frame(width: 36, height: 36)

                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(PRTheme.ink)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(PRTheme.muted.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PRTheme.paper)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(PRTheme.line, lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(PRPressableStyle())
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private var savedPlaces: some View {
        if !store.favoritePlaces.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Saved Places", symbol: "bookmark.fill", tint: PRTheme.gold) {
                    CountBadge(text: "\(store.favoritePlaces.count)", tint: PRTheme.gold)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.favoritePlaces) { place in
                            NavigationLink {
                                PlaceDetailView(place: place)
                            } label: {
                                SavedPlaceTile(place: place)
                            }
                            .buttonStyle(PRPressableStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var topPlaces: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Useful Right Now", symbol: "star.fill", tint: PRTheme.gold)
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
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(item.category.color.opacity(0.12))
                Image(systemName: item.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.category.color)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.slot)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.category.color)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Label(item.actionLabel, systemImage: showsExternalArrow ? "arrow.up.right" : "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(PRTheme.muted.opacity(0.7))
                }

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PRTheme.ink)
                    .lineLimit(2)

                Text(item.summary)
                    .font(.footnote)
                    .foregroundStyle(PRTheme.muted)
                    .lineLimit(2)

                SourceBadge(title: item.source.title)
            }
        }
        .innerTile()
    }
}

private struct WeatherMetric: View {
    let symbol: String
    let text: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(PRTheme.sky)
            .padding(.horizontal, 10)
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
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .white : PRTheme.teal)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background {
                    Capsule()
                        .fill(isSelected ? PRTheme.teal : PRTheme.teal.opacity(0.10))
                        .shadow(color: isSelected ? PRTheme.teal.opacity(0.30) : .clear, radius: 6, y: 3)
                }
        }
        .buttonStyle(PRPressableStyle())
        .accessibilityLabel("\(lens.rawValue) resident lens")
    }
}

private struct SavedPlaceTile: View {
    let place: LocalPlace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlaceThumbnail(
                url: place.imageURL,
                tint: place.category.color,
                height: 82,
                symbol: place.category.symbol,
                title: place.name,
                radius: 12
            )
            Text(place.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PRTheme.ink)
                .lineLimit(2)
                .frame(minHeight: 36, alignment: .topLeading)
            Label(place.category.rawValue, systemImage: place.category.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(place.category.color)
        }
        .frame(width: 160)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(PRTheme.paper)
                .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(PRTheme.line, lineWidth: 1)
        }
    }
}
