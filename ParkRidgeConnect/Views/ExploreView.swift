import SwiftUI

struct ExploreView: View {
    @Environment(TownStore.self) private var store
    @State private var searchText = ""
    @State private var selectedCategory: TownCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    categoryRail

                    let results = store.filteredPlaces(searchText: searchText, category: selectedCategory)
                    if results.isEmpty {
                        EmptyResidentState(title: "No local places match that search", systemImage: "magnifyingglass")
                    } else {
                        ForEach(results) { place in
                            PlaceCard(place: place)
                        }
                    }
                }
                .padding(16)
            }
            .background(PRTheme.canvas.ignoresSafeArea())
            .navigationTitle("Explore")
            .searchable(text: $searchText, prompt: "Food, playground, pool, train, forms")
            .onAppear {
                applyRequestedFilter()
            }
        }
    }

    private var categoryRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                CategoryPill(category: nil, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(TownCategory.allCases) { category in
                    CategoryPill(category: category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 2)
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
