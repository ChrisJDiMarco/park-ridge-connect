import SwiftUI

struct ExploreView: View {
    @Environment(TownStore.self) private var store
    @State private var searchText = ""
    @State private var selectedCategory: TownCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PRTheme.sectionSpacing) {
                    categoryRail

                    let results = store.filteredPlaces(searchText: searchText, category: selectedCategory)
                    if results.isEmpty {
                        EmptyResidentState(title: "No local places match that search", systemImage: "magnifyingglass")
                    } else {
                        resultsHeader(count: results.count)
                        ForEach(results) { place in
                            PlaceCard(place: place)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .background { TownBackdrop() }
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: "Food, playground, pool, train, forms")
            .onAppear {
                applyRequestedFilter()
            }
        }
    }

    private func resultsHeader(count: Int) -> some View {
        HStack {
            Text(selectedCategory?.rawValue ?? "All Places")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(PRTheme.ink)
            Spacer()
            CountBadge(text: "\(count)", tint: selectedCategory?.color ?? PRTheme.teal)
        }
        .padding(.horizontal, 2)
    }

    private var categoryRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryPill(category: nil, isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selectedCategory = nil
                    }
                }
                ForEach(TownCategory.allCases) { category in
                    CategoryPill(category: category, isSelected: selectedCategory == category) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
        }
    }

    private func applyRequestedFilter() {
        guard let requestedSearchText = store.requestedExploreSearchText else { return }
        selectedCategory = store.requestedExploreCategory
        searchText = requestedSearchText
        store.requestedExploreCategory = nil
        store.requestedExploreSearchText = nil
    }
}
