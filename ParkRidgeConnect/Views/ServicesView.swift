import SwiftUI

struct ServicesView: View {
    @Environment(TownStore.self) private var store
    @Binding var selectedTab: AppTab
    @State private var searchText = ""
    @State private var selectedCategory: TownCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    serviceCategories

                    let workflows = store.filteredCivicWorkflows(searchText: searchText, category: selectedCategory)
                    if !workflows.isEmpty {
                        civicWorkflowSection(workflows)
                    }

                    officialContact

                    let results = store.filteredServices(searchText: searchText, category: selectedCategory)
                    if results.isEmpty && workflows.isEmpty {
                        EmptyResidentState(title: "No service matches that search", systemImage: "doc.text.magnifyingglass")
                    } else {
                        ForEach(results) { service in
                            ServiceCard(service: service)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 96)
            }
            .background(PRTheme.canvas.ignoresSafeArea())
            .navigationTitle("Services")
            .searchable(text: $searchText, prompt: "Water, permits, recycling, schools")
        }
    }

    private func civicWorkflowSection(_ workflows: [CivicWorkflow]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Civic Action Center", systemImage: "checklist.checked")
                    .font(.headline)
                Spacer()
                Text("\(workflows.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(PRTheme.teal)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(PRTheme.teal.opacity(0.10), in: Capsule())
            }

            ForEach(workflows.prefix(4)) { workflow in
                CivicWorkflowCard(
                    workflow: workflow,
                    primaryService: primaryService(for: workflow)
                ) {
                    store.queueAssistantPrompt(store.assistantPrompt(for: workflow))
                    selectedTab = .ask
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var serviceCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                CategoryPill(category: nil, isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach([TownCategory.government, .services, .utilities, .emergency, .transit, .schools, .recreation, .library]) { category in
                    CategoryPill(category: category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var officialContact: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "building.2.fill")
                .foregroundStyle(PRTheme.teal)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text("Borough Hall")
                    .font(.headline)
                Text("53 Park Avenue, Park Ridge, NJ 07656")
                    .font(.subheadline)
                    .foregroundStyle(PRTheme.muted)
                Text("Mon-Fri, 8:00 AM - 4:30 PM")
                    .font(.caption)
                    .foregroundStyle(PRTheme.muted)
            }
            Spacer()
            ActionLink(title: "Call", systemImage: "phone", url: phoneURL("201-573-1800"))
        }
        .residentCard()
    }

    private func primaryService(for workflow: CivicWorkflow) -> CivicService? {
        workflow.steps.compactMap { step in
            guard let serviceID = step.serviceID else { return nil }
            return store.service(withID: serviceID)
        }.first
    }
}

private struct CivicWorkflowCard: View {
    let workflow: CivicWorkflow
    let primaryService: CivicService?
    let askAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(workflow.category.color.opacity(0.14))
                    Image(systemName: workflow.symbol)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(workflow.category.color)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(workflow.kicker)
                        .font(.caption.weight(.black))
                        .foregroundStyle(workflow.category.color)
                    Text(workflow.title)
                        .font(.headline)
                        .foregroundStyle(PRTheme.ink)
                    Text(workflow.summary)
                        .font(.subheadline)
                        .foregroundStyle(PRTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(workflow.steps.prefix(3)) { step in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PRTheme.teal)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(PRTheme.ink)
                                .lineLimit(1)
                            Text(step.detail)
                                .font(.caption)
                                .foregroundStyle(PRTheme.muted)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .padding(10)
            .background(PRTheme.canvas, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(workflow.sourceTitles, id: \.self) { title in
                        SourceBadge(title: title)
                    }
                }
            }

            HStack {
                Button(action: askAction) {
                    Label("Ask AI", systemImage: "sparkles")
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(PRTheme.teal)
                .accessibilityLabel("Ask AI about \(workflow.title)")

                ActionLink(
                    title: primaryService?.actionLabel ?? "Open",
                    systemImage: "safari",
                    url: primaryService?.website
                )
            }
        }
        .residentCard()
    }
}
