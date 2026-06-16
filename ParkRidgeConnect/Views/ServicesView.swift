import SwiftUI

struct ServicesView: View {
    @Environment(TownStore.self) private var store
    @Binding var selectedTab: AppTab
    @State private var searchText = ""
    @State private var selectedCategory: TownCategory?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: PRTheme.sectionSpacing) {
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
                .padding(.top, 12)
                .padding(.bottom, 96)
            }
            .background { TownBackdrop() }
            .navigationTitle("Services")
            .searchable(text: $searchText, prompt: "Water, permits, recycling, schools")
        }
    }

    private func civicWorkflowSection(_ workflows: [CivicWorkflow]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Civic Action Center", symbol: "checklist.checked") {
                CountBadge(text: "\(workflows.count)")
            }
            .padding(.horizontal, 2)

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
            HStack(spacing: 8) {
                CategoryPill(category: nil, isSelected: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                        selectedCategory = nil
                    }
                }
                ForEach([TownCategory.government, .services, .utilities, .emergency, .transit, .schools, .recreation, .library]) { category in
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

    private var officialContact: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(PRTheme.brandGradient)
                Image(systemName: "building.2.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(store.config.townHall.name)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(PRTheme.ink)
                Text(store.config.townHall.addressLine)
                    .font(.footnote)
                    .foregroundStyle(PRTheme.muted)
                Text(store.config.townHall.hoursLine)
                    .font(.caption)
                    .foregroundStyle(PRTheme.muted)
            }

            Spacer()

            if let url = phoneURL(store.config.townHall.phone) {
                Link(destination: url) {
                    Image(systemName: "phone.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PRTheme.teal)
                        .frame(width: 40, height: 40)
                        .background(PRTheme.teal.opacity(0.12), in: Circle())
                }
                .buttonStyle(PRPressableStyle())
                .accessibilityLabel("Call \(store.config.townHall.name)")
            }
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
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(workflow.category.color.opacity(0.12))
                    Image(systemName: workflow.symbol)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(workflow.category.color)
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 4) {
                    Text(workflow.kicker.uppercased())
                        .font(.caption2.weight(.bold))
                        .kerning(0.6)
                        .foregroundStyle(workflow.category.color)
                    Text(workflow.title)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(PRTheme.ink)
                    Text(workflow.summary)
                        .font(.subheadline)
                        .foregroundStyle(PRTheme.muted)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                ForEach(workflow.steps.prefix(3)) { step in
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(PRTheme.teal)
                            .padding(.top, 1)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.title)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(PRTheme.ink)
                                .lineLimit(1)
                            Text(step.detail)
                                .font(.footnote)
                                .foregroundStyle(PRTheme.muted)
                                .lineLimit(2)
                        }
                    }
                }
            }
            .innerTile()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(workflow.sourceTitles, id: \.self) { title in
                        SourceBadge(title: title)
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: askAction) {
                    Label("Ask AI", systemImage: "sparkles")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(PRTheme.teal, in: Capsule())
                }
                .buttonStyle(PRPressableStyle())
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
