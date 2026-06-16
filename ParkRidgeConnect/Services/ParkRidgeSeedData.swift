import Foundation

enum ParkRidgeSeedData {
    static let borough = KnowledgeSource(
        id: "borough",
        title: "Park Ridge Borough",
        url: URL(string: "https://parkridgeboro.com/")!,
        summary: "Official borough site for alerts, calendar, departments, payments, public notices, and resident resources."
    )

    static let recreation = KnowledgeSource(
        id: "recreation",
        title: "Park Ridge Recreation",
        url: URL(string: "https://parkridgeboro.com/departments/recreation")!,
        summary: "Official recreation and cultural programs, meetings, summer camp, concerts, and forms."
    )

    static let library = KnowledgeSource(
        id: "library",
        title: "Park Ridge Public Library",
        url: URL(string: "https://parkridgelibrarynj.org/")!,
        summary: "Library hours, events, museum passes, digital resources, kids, teens, and adult programs."
    )

    static let schools = KnowledgeSource(
        id: "schools",
        title: "Park Ridge School District",
        url: URL(string: "https://www.parkridgeschools.org/")!,
        summary: "District calendar, schools, registration, parent portal, athletics, closings, and Board of Ed."
    )

    static let transit = KnowledgeSource(
        id: "transit",
        title: "Park Ridge Public Transportation",
        url: URL(string: "https://parkridgeboro.com/resident/transportation")!,
        summary: "Pascack Valley train, Coach USA/Rockland buses, commuter parking, and Senior Ride."
    )

    static let weather = KnowledgeSource(
        id: "nws-weather",
        title: "National Weather Service",
        url: URL(string: "https://api.weather.gov/gridpoints/OKX/30,54/forecast/hourly")!,
        summary: "Official National Weather Service hourly forecast grid for the Park Ridge area."
    )

    static let alerts: [TownAlert] = [
        TownAlert(
            id: "water-restrictions-2026",
            title: "Mandatory water restrictions",
            severity: .advisory,
            summary: "The Water Department announced mandatory restrictions effective April 1 through September 1. Check the borough notice before watering or planning outdoor work.",
            effectiveText: "Apr 1 - Sep 1",
            source: borough
        ),
        TownAlert(
            id: "emergency-alert-signup",
            title: "Sign up for borough emergency alerts",
            severity: .info,
            summary: "Use the official Swiftreach alert signup linked from the borough site for local notices and urgent updates.",
            effectiveText: "Ongoing",
            source: borough
        )
    ]

    static let notices: [TownNotice] = [
        TownNotice(id: "roadway-bid", title: "Roadway improvements project", summary: "Recent borough notices include bid documents and capital ordinances for 2026 road, curb, drainage, and sidewalk work.", source: borough, tags: ["roads", "public notices", "construction"]),
        TownNotice(id: "lead-service-line", title: "Lead service line replacements", summary: "The borough posted notice-to-bidders materials related to lead service line replacements.", source: borough, tags: ["water", "utilities", "bids"]),
        TownNotice(id: "america-250", title: "America 250 home decorating contest", summary: "Recreation is promoting a patriotic community home decorating contest tied to America 250.", source: recreation, tags: ["recreation", "community"]),
        TownNotice(id: "library-digital", title: "Library digital access", summary: "The library offers 24/7 access to Libby, Kanopy, Hoopla, Consumer Reports, Heritage Quest, and Newsbank with a library card.", source: library, tags: ["library", "digital", "family"])
    ]

    static let events: [TownEvent] = [
        TownEvent(id: "bpw-2026-06-03", title: "Board of Public Works Meeting", dateText: "Jun 3, 2026", timeText: "8:00 PM", summary: "Public utilities and borough works meeting.", category: .government, audience: "Residents tracking utilities and borough work", source: borough, priority: 8),
        TownEvent(id: "mayor-work-2026-06-09", title: "Mayor & Council Work/Closed Session", dateText: "Jun 9, 2026", timeText: "7:00 PM", summary: "Council work session before the public meeting.", category: .government, audience: "Civic watchers", source: borough, priority: 7),
        TownEvent(id: "rec-committee-2026-06-09", title: "Recreation and Cultural Committee Meeting", dateText: "Jun 9, 2026", timeText: "7:30 PM", summary: "Recreation programming and cultural planning meeting.", category: .recreation, audience: "Parents, coaches, volunteers", source: recreation, priority: 7),
        TownEvent(id: "mayor-public-2026-06-09", title: "Mayor & Council Public Meeting", dateText: "Jun 9, 2026", timeText: "8:00 PM", summary: "Regular public meeting for borough business.", category: .government, audience: "All residents", source: borough, priority: 9),
        TownEvent(id: "planning-2026-06-10", title: "Planning Board Meeting", dateText: "Jun 10, 2026", timeText: "8:00 PM", summary: "Planning Board meeting for land use and development items.", category: .government, audience: "Neighbors near proposed work", source: borough, priority: 8),
        TownEvent(id: "town-picnic-2026", title: "Town Picnic", dateText: "Jun 13, 2026", timeText: "12:00 PM - 5:00 PM", summary: "A major Park Ridge Recreation community event.", category: .recreation, audience: "Families and residents", source: recreation, priority: 10),
        TownEvent(id: "summer-camp-2026", title: "Park Ridge Summer Camp", dateText: "Jun 29 - Jul 31, 2026", timeText: "Day program", summary: "Annual summer day camp run through Recreation.", category: .kids, audience: "Families with children", source: recreation, priority: 9),
        TownEvent(id: "concert-rhyme-reason", title: "Summer Concert - Rhyme or Reason", dateText: "Jul 30, 2026", timeText: "6:30 PM - 8:00 PM", summary: "Outdoor summer concert series event.", category: .recreation, audience: "All ages", source: recreation, priority: 7),
        TownEvent(id: "concert-kootz", title: "Summer Concert - The Kootz", dateText: "Aug 6, 2026", timeText: "6:30 PM - 8:00 PM", summary: "Outdoor summer concert series event.", category: .recreation, audience: "All ages", source: recreation, priority: 7)
    ]

    static let places: [LocalPlace] = [
        LocalPlace(id: "peppercorns", name: "Peppercorns Restaurant & Bar", category: .food, subcategory: "American comfort food", summary: "Neighborhood scratch kitchen for lunch, dinner, happy hour, families, and casual celebrations.", address: "176 Colony Avenue, Park Ridge, NJ 07656", phone: "201-391-2818", website: URL(string: "https://www.peppercorns176.com/"), imageURL: URL(string: "https://static.wixstatic.com/media/81266f_03f11a797d104a71a215c3a714221420~mv2.jpg"), highlights: ["Open seven days", "Black Angus burgers", "Bar and comfort classics"], tags: ["dinner", "lunch", "family", "bar"], source: KnowledgeSource(id: "peppercorns-source", title: "Peppercorns", url: URL(string: "https://www.peppercorns176.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "four-leaves", name: "Four Leaves", category: .adults, subcategory: "Gastropub and cocktails", summary: "Elevated pub food, craft cocktails, brunch, private events, and downtown night-out energy.", address: "146 Kinderkamack Road, Park Ridge, NJ 07656", phone: "201-690-6755", website: URL(string: "https://the4leaves.com/"), imageURL: URL(string: "https://www.boozyburbs.com/wp-content/uploads/2024/06/img_1565-1-600x705.jpg"), highlights: ["Craft cocktails", "Weekend brunch", "Private events"], tags: ["cocktails", "brunch", "date night", "adults"], source: KnowledgeSource(id: "four-leaves-source", title: "Four Leaves", url: URL(string: "https://the4leaves.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "park-steakhouse", name: "The Park Steakhouse", category: .adults, subcategory: "Modern American steakhouse", summary: "Park Ridge steakhouse with dry-aged steaks, seafood, wine, cocktails, and private rooms.", address: "151 Kinderkamack Road, Park Ridge, NJ 07656", phone: "201-930-1300", website: URL(string: "https://www.theparksteakhouse.com/index.html"), imageURL: URL(string: "https://www.theparksteakhouse.com/content/website/accounts/201/800-4af8601eb9d0cdd11d4b40ff98c83768.jpg"), highlights: ["Established 1992", "Private dining", "Tuesday-Sunday dinner"], tags: ["steak", "wine", "private events", "date night"], source: KnowledgeSource(id: "park-steakhouse-source", title: "The Park Steakhouse", url: URL(string: "https://www.theparksteakhouse.com/index.html")!, summary: "Restaurant website.")),
        LocalPlace(id: "pesto", name: "Pesto Italian Bistro", category: .food, subcategory: "BYOB Italian", summary: "Cozy Italian bistro with lunch, dinner, online ordering, catering, and private events.", address: "168F Kinderkamack Road, Park Ridge, NJ 07656", phone: "201-690-6101", website: URL(string: "https://pestoitalianbistro.com/"), imageURL: URL(string: "https://pestoitalianbistro.com/wp-content/uploads/2025/09/Outside-2-scaled.jpg"), highlights: ["BYOB", "Fresh pasta", "Private events"], tags: ["italian", "byob", "family", "takeout"], source: KnowledgeSource(id: "pesto-source", title: "Pesto Italian Bistro", url: URL(string: "https://pestoitalianbistro.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "ridge-diner", name: "The Ridge Diner", category: .food, subcategory: "Classic diner", summary: "Park Ridge landmark for breakfast, lunch, dinner, late-night bites, and comfort food.", address: "125 Kinderkamack Road, Park Ridge, NJ 07656", phone: "201-391-4242", website: URL(string: "https://ridgediner.com/"), imageURL: URL(string: "https://ridgediner.com/wp-content/uploads/2024/09/Coffee-600x600.png"), highlights: ["Serving since 1972", "Late hours", "Breakfast all day"], tags: ["breakfast", "late night", "kids", "comfort food"], source: KnowledgeSource(id: "ridge-diner-source", title: "The Ridge Diner", url: URL(string: "https://ridgediner.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "pr-social", name: "PR Social Bar + Kitchen", category: .adults, subcategory: "Hotel bar and kitchen", summary: "Breakfast, lunch, dinner, drinks, private events, and social dining at the Marriott property.", address: "300 Brae Boulevard, Park Ridge, NJ 07656", phone: "201-307-0800", website: URL(string: "https://www.prsocialbar.com/"), imageURL: URL(string: "https://images.squarespace-cdn.com/content/v1/699612cfee2a7d1b8e65726f/ae6c405a-3f69-439b-89f4-8d70fd89e833/mhrsls.1395925.jpeg?format=750w"), highlights: ["Breakfast to drinks", "Private events", "Cocktail menu"], tags: ["cocktails", "breakfast", "hotel", "events"], source: KnowledgeSource(id: "pr-social-source", title: "PR Social Bar + Kitchen", url: URL(string: "https://www.prsocialbar.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "marcs", name: "Marc's Deli & Pizzeria", category: .food, subcategory: "Deli and pizza", summary: "Local pizza, subs, wings, pasta, salads, and family deals close to downtown.", address: "14 Park Avenue, Park Ridge, NJ 07656", phone: "201-391-4333", website: URL(string: "https://www.marcsdelipizzeria.com/"), imageURL: URL(string: "https://slicelife.imgix.net/22528/photos/original/product-sicilian-pizza-12373776.jpeg?auto=compress&auto=format"), highlights: ["Pizza", "Heroes", "Family feast deals"], tags: ["pizza", "takeout", "kids", "quick"], source: KnowledgeSource(id: "marcs-source", title: "Marc's Deli & Pizzeria", url: URL(string: "https://www.marcsdelipizzeria.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "park-pizza", name: "Park Pizza", category: .food, subcategory: "Pizza and Italian", summary: "Downtown pizza, pasta, sandwiches, lunch specials, and fast takeout.", address: "85 Park Avenue, Park Ridge, NJ 07656", phone: nil, website: URL(string: "https://www.parkpizzaparkridge.com/"), imageURL: URL(string: "https://slicelife.imgix.net/11779/photos/original/ParkPizza_CheesePizza.jpg?auto=compress&auto=format"), highlights: ["Pizza", "Pasta", "Lunch specials"], tags: ["pizza", "takeout", "downtown"], source: KnowledgeSource(id: "park-pizza-source", title: "Park Pizza", url: URL(string: "https://www.parkpizzaparkridge.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "dragon-house", name: "Dragon House", category: .food, subcategory: "Chinese takeout", summary: "Chinese food for pickup and delivery within five miles.", address: "Park Ridge, NJ 07656", phone: "201-505-0333", website: URL(string: "https://dragonhousetogo.com/"), imageURL: URL(string: "https://dragonhousetogo.com/images/General-Tsos-Chicken.jpg"), highlights: ["Pickup", "Delivery within 5 miles", "Closed Tuesday"], tags: ["chinese", "delivery", "takeout"], source: KnowledgeSource(id: "dragon-house-source", title: "Dragon House", url: URL(string: "https://dragonhousetogo.com/")!, summary: "Restaurant website.")),
        LocalPlace(id: "library", name: "Park Ridge Public Library", category: .library, subcategory: "Library and community hub", summary: "Books, storytime, museum passes, digital collections, newspapers, kids, teens, adults, and community links.", address: "51 Park Avenue, Park Ridge, NJ 07656", phone: "201-391-5151", website: URL(string: "https://parkridgelibrarynj.org/"), imageURL: nil, highlights: ["Museum passes", "Storytime", "Libby, Kanopy, Hoopla"], tags: ["kids", "adults", "storytime", "museum passes"], source: library),
        LocalPlace(id: "mill-pond", name: "Mill Pond", category: .recreation, subcategory: "Walk and nature", summary: "A quiet local walking and nature spot tied to borough open-space improvements and downtown life.", address: "Mill Pond, Park Ridge, NJ 07656", phone: nil, website: URL(string: "https://parkridgeboro.com/"), imageURL: nil, highlights: ["Walking trail", "Bridge", "Low-key outdoor reset"], tags: ["walk", "nature", "quiet", "kids"], source: borough),
        LocalPlace(id: "memorial-park", name: "Memorial Park and Pavilion", category: .kids, subcategory: "Playground, fields, and pavilion", summary: "Core family recreation area for playground time, athletic fields, pavilion use, and community events.", address: "Park Ridge Memorial Park, Park Ridge, NJ 07656", phone: nil, website: URL(string: "https://parkridgeboro.com/departments/recreation"), imageURL: nil, highlights: ["Playground", "Pavilion", "Athletic fields"], tags: ["playground", "kids", "fields", "picnic"], source: recreation),
        LocalPlace(id: "municipal-pool", name: "Park Ridge Municipal Pool", category: .recreation, subcategory: "Seasonal swimming", summary: "Resident-focused municipal pool for summer swimming, swim team activity, and family afternoons.", address: "Park Ridge Municipal Pool, Park Ridge, NJ 07656", phone: nil, website: URL(string: "https://parkridgeboro.com/"), imageURL: nil, highlights: ["Seasonal", "Family summer anchor", "Rules and membership via borough"], tags: ["pool", "summer", "kids", "family"], source: borough)
    ]

    static let services: [CivicService] = [
        CivicService(id: "borough-hall", name: "Borough Hall", department: "Administration", summary: "Main office for general borough questions, commuter parking decals, senior ride scheduling, forms, and resident routing.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "Open Borough Site", category: .government, tags: ["borough hall", "forms", "parking", "general"], source: borough),
        CivicService(id: "alerts", name: "Emergency Alert Signup", department: "Residents", summary: "Register for official local alerts and emergency communications.", phone: nil, website: URL(string: "https://portalv4.swiftreach.com/"), actionLabel: "Sign Up", category: .emergency, tags: ["alerts", "emergency", "notifications"], source: borough),
        CivicService(id: "trash-recycling", name: "Trash & Recycling Calendar", department: "DPW/Roads/Recycling", summary: "Find collection schedules, DPW guidance, and recycling information.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "View Calendar", category: .services, tags: ["trash", "recycling", "dpw"], source: borough),
        CivicService(id: "payments", name: "Make Payments", department: "Finance & Tax", summary: "Pay or review borough-related payment information from the official site.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "Payment Info", category: .services, tags: ["tax", "payments", "finance"], source: borough),
        CivicService(id: "water-sewer", name: "Water & Sewer", department: "Utilities", summary: "Water restrictions, sewer information, service notices, and utility updates.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "Water Info", category: .utilities, tags: ["water", "sewer", "restrictions"], source: borough),
        CivicService(id: "electric", name: "Electric Department", department: "Utilities", summary: "Local electric utility information and public works coordination.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "Electric Info", category: .utilities, tags: ["electric", "power", "utility"], source: borough),
        CivicService(id: "recreation", name: "Recreation Programs", department: "Recreation & Cultural", summary: "Summer camp, concerts, Zumba, chess, junior golf, tennis, pickleball, adult sports, picnic, and seasonal events.", phone: "201-822-3121", website: URL(string: "https://parkridgeboro.com/departments/recreation"), actionLabel: "View Programs", category: .recreation, tags: ["camp", "concerts", "sports", "pickleball"], source: recreation),
        CivicService(id: "schools", name: "Park Ridge Schools", department: "Board of Education", summary: "District calendar, East Brook, West Ridge, Park Ridge High School, registration, closings, PowerSchool, and BOE meetings.", phone: nil, website: URL(string: "https://www.parkridgeschools.org/"), actionLabel: "Open Schools", category: .schools, tags: ["school", "calendar", "registration", "boe"], source: schools),
        CivicService(id: "senior-ride", name: "Senior Ride", department: "Transportation", summary: "No-cost senior transportation for Park Ridge residents 55+ within an 8-mile radius of Montvale. Call at least a week ahead.", phone: "201-573-1800 x500", website: URL(string: "https://parkridgeboro.com/resident/transportation"), actionLabel: "Ride Details", category: .transit, tags: ["senior", "ride", "transportation"], source: transit),
        CivicService(id: "commuter", name: "Commuter Parking and Transit", department: "Transportation", summary: "Pascack Valley train stop, Coach USA/Rockland buses, resident commuter lot, metered Broadway parking, and links to NJ Transit.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/resident/transportation"), actionLabel: "Transit Info", category: .transit, tags: ["train", "bus", "parking", "commute"], source: transit),
        CivicService(id: "police-fire-ambulance", name: "Police, Fire, and Tri-Boro Ambulance", department: "Emergency", summary: "Fast access to official police, fire, and Tri-Boro Ambulance resources. For emergencies, call 911.", phone: "911", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "Official Links", category: .emergency, tags: ["police", "fire", "ambulance", "911"], source: borough),
        CivicService(id: "forms", name: "Resident Forms and Permits", department: "Clerk, Construction, Zoning", summary: "Find resident forms, construction information, zoning, CCO, clerk services, and public meeting documents.", phone: "201-573-1800", website: URL(string: "https://parkridgeboro.com/"), actionLabel: "Find Forms", category: .government, tags: ["forms", "permits", "zoning", "construction"], source: borough)
    ]

    static let civicWorkflows: [CivicWorkflow] = [
        CivicWorkflow(
            id: "new-resident-setup",
            title: "New Resident Setup",
            kicker: "First-week essentials",
            summary: "A practical checklist for getting oriented with borough services, alerts, schools, library access, and collection basics.",
            category: .government,
            symbol: "house.badge.checkmark",
            priority: 100,
            tags: ["new", "resident", "newcomer", "moved", "setup", "borough", "forms", "schools", "library", "alerts"],
            steps: [
                CivicWorkflowStep(id: "new-resident-borough", title: "Start with Borough Hall", detail: "Use the official borough site and main office for resident routing, forms, local payments, and general questions.", serviceID: "borough-hall", source: borough),
                CivicWorkflowStep(id: "new-resident-alerts", title: "Sign up for emergency alerts", detail: "Register for Swiftreach so local notices and urgent updates can reach you quickly.", serviceID: "alerts", source: borough),
                CivicWorkflowStep(id: "new-resident-schools", title: "Check school registration and calendars", detail: "Open the district site for registration, school calendars, closings, parent portal, and Board of Ed information.", serviceID: "schools", source: schools),
                CivicWorkflowStep(id: "new-resident-library", title: "Get a library card", detail: "Use the library for museum passes, digital access, kids programs, teen and adult events, and local discovery.", serviceID: nil, source: library),
                CivicWorkflowStep(id: "new-resident-trash", title: "Find collection rules", detail: "Confirm trash, recycling, DPW, and seasonal collection details before the first pickup day.", serviceID: "trash-recycling", source: borough)
            ]
        ),
        CivicWorkflow(
            id: "family-week-setup",
            title: "Family Week Setup",
            kicker: "Kids, school, camp",
            summary: "A parent-focused workflow for school calendars, recreation programs, library programs, and alerts.",
            category: .kids,
            symbol: "figure.2.and.child.holdinghands",
            priority: 94,
            tags: ["parent", "family", "kids", "school", "camp", "library", "recreation", "alerts"],
            steps: [
                CivicWorkflowStep(id: "family-schools", title: "Check the school calendar", detail: "Confirm registration, closings, athletics, and district updates before planning the week.", serviceID: "schools", source: schools),
                CivicWorkflowStep(id: "family-recreation", title: "Scan recreation programs", detail: "Look for summer camp, sports, concerts, picnic details, and seasonal programs.", serviceID: "recreation", source: recreation),
                CivicWorkflowStep(id: "family-library", title: "Use library programs", detail: "Look for storytime, museum passes, digital resources, teen events, and quiet indoor options.", serviceID: nil, source: library),
                CivicWorkflowStep(id: "family-alerts", title: "Keep alerts turned on", detail: "Use the borough alert signup so schedule changes and local notices are not missed.", serviceID: "alerts", source: borough)
            ]
        ),
        CivicWorkflow(
            id: "water-yard-rules",
            title: "Water + Yard Rules",
            kicker: "Homeowner watchlist",
            summary: "A homeowner workflow for water restrictions, DPW rules, payments, and utility follow-up.",
            category: .utilities,
            symbol: "drop.degreesign",
            priority: 92,
            tags: ["homeowner", "water", "yard", "trash", "recycling", "dpw", "sewer", "payments", "restrictions"],
            steps: [
                CivicWorkflowStep(id: "water-restrictions", title: "Check water restrictions first", detail: "Mandatory restrictions are active April 1 through September 1; check the borough notice before watering or outdoor work.", serviceID: "water-sewer", source: borough),
                CivicWorkflowStep(id: "water-trash", title: "Confirm DPW and collection guidance", detail: "Use the trash and recycling calendar for collection schedules and DPW rules.", serviceID: "trash-recycling", source: borough),
                CivicWorkflowStep(id: "water-payments", title: "Review payment paths", detail: "Use official borough payment information for tax, finance, or utility-related follow-up.", serviceID: "payments", source: borough),
                CivicWorkflowStep(id: "water-electric", title: "Keep utility contacts handy", detail: "Save water, sewer, and electric service paths before weather or service issues appear.", serviceID: "electric", source: borough)
            ]
        ),
        CivicWorkflow(
            id: "commuter-parking-plan",
            title: "Commuter Parking Plan",
            kicker: "Train, bus, parking",
            summary: "A commuter workflow for transit choices, resident parking, senior ride, and official contact paths.",
            category: .transit,
            symbol: "tram.fill",
            priority: 90,
            tags: ["commuter", "commute", "train", "bus", "parking", "nyc", "senior", "ride", "transportation"],
            steps: [
                CivicWorkflowStep(id: "commuter-transit", title: "Check train, bus, and parking details", detail: "Use the borough transportation page for Pascack Valley train, Coach USA/Rockland buses, commuter lot, and metered Broadway parking details.", serviceID: "commuter", source: transit),
                CivicWorkflowStep(id: "commuter-borough", title: "Route decal questions to Borough Hall", detail: "Contact Borough Hall for commuter parking decals and resident routing.", serviceID: "borough-hall", source: borough),
                CivicWorkflowStep(id: "commuter-senior", title: "Plan senior transportation early", detail: "Senior Ride requires advance scheduling for eligible Park Ridge residents 55+.", serviceID: "senior-ride", source: transit)
            ]
        ),
        CivicWorkflow(
            id: "permits-renovation",
            title: "Permits + Renovation",
            kicker: "Before work starts",
            summary: "A workflow for forms, permits, zoning, construction questions, payments, and public meeting awareness.",
            category: .government,
            symbol: "doc.badge.gearshape",
            priority: 88,
            tags: ["permit", "permits", "forms", "renovation", "construction", "zoning", "planning", "homeowner", "clerk"],
            steps: [
                CivicWorkflowStep(id: "permits-forms", title: "Find the right form", detail: "Start with Resident Forms and Permits for construction, zoning, CCO, clerk services, and public meeting documents.", serviceID: "forms", source: borough),
                CivicWorkflowStep(id: "permits-call", title: "Confirm the department path", detail: "Call or open Borough Hall before assuming whether the next stop is clerk, construction, zoning, or another department.", serviceID: "borough-hall", source: borough),
                CivicWorkflowStep(id: "permits-payments", title: "Check payment information", detail: "Use official borough payment information for fee or tax-related follow-up.", serviceID: "payments", source: borough),
                CivicWorkflowStep(id: "permits-meetings", title: "Watch planning and council dates", detail: "Track Planning Board, Mayor and Council, and public notices when neighborhood work or land-use items matter.", serviceID: nil, source: borough)
            ]
        ),
        CivicWorkflow(
            id: "emergency-ready",
            title: "Emergency Ready",
            kicker: "Before it is urgent",
            summary: "A compact readiness workflow for alerts, emergency contacts, weather, utilities, and local notices.",
            category: .emergency,
            symbol: "cross.case.fill",
            priority: 96,
            tags: ["emergency", "alerts", "911", "police", "fire", "ambulance", "weather", "power", "electric", "urgent"],
            steps: [
                CivicWorkflowStep(id: "emergency-alerts", title: "Emergency Alert Signup", detail: "Register for borough emergency alerts before severe weather, road, or utility notices become urgent.", serviceID: "alerts", source: borough),
                CivicWorkflowStep(id: "emergency-contacts", title: "Save emergency contacts", detail: "Use official police, fire, and Tri-Boro Ambulance resources; call 911 for emergencies.", serviceID: "police-fire-ambulance", source: borough),
                CivicWorkflowStep(id: "emergency-weather", title: "Check the live forecast", detail: "Use the National Weather Service snapshot in Today before travel, outdoor events, or family plans.", serviceID: nil, source: weather),
                CivicWorkflowStep(id: "emergency-utilities", title: "Know utility paths", detail: "Keep electric, water, and sewer information reachable before outages or service problems.", serviceID: "electric", source: borough)
            ]
        )
    ]
}

// MARK: - Park Ridge TownPack

extension ParkRidgeSeedData {
    static let config = TownConfig(
        townName: "Park Ridge",
        appTitle: "Park Ridge Connect",
        state: "NJ",
        assistantWelcome: "Ask me anything about Park Ridge: what is happening this week, where to eat, what to do with kids, how to handle trash/recycling, water restrictions, permits, trains, schools, or local services.",
        assistantWelcomeSourceTitles: ["Park Ridge Borough", "Park Ridge Recreation", "Park Ridge Public Library"],
        assistantSuggestedPrompts: [
            "What is happening in town this week?",
            "Where should I take kids after school?",
            "Best dinner or drinks tonight?",
            "How do I handle trash, water, or permits?",
            "How do I commute to NYC?"
        ],
        townHall: TownHallInfo(
            name: "Borough Hall",
            addressLine: "53 Park Avenue, Park Ridge, NJ 07656",
            hoursLine: "Mon-Fri, 8:00 AM - 4:30 PM",
            phone: "201-573-1800"
        ),
        weather: WeatherConfig(
            latitude: 40.9912,
            longitude: -74.0326,
            fallbackHourlyForecastURL: URL(string: "https://api.weather.gov/gridpoints/OKX/30,54/forecast/hourly"),
            contactEmail: "chris.john.dimarco@gmail.com"
        ),
        refresh: RefreshConfig(
            homepageURL: URL(string: "https://parkridgeboro.com/")!,
            sourceTitle: "Park Ridge Borough",
            sourceSummary: "Official borough site for alerts, calendar, departments, payments, public notices, and resident resources.",
            newsSectionMarker: "News & Announcements",
            calendarSectionMarker: "Borough Calendar",
            alertKeywords: ["water restrictions", "budget public hearing", "livestream"]
        ),
        placeDirectory: .parkRidgeDefault,
        anchors: TownAnchors(
            indoorFallbackPlaceID: "library",
            outdoorParkPlaceID: "memorial-park",
            nightOutPlaceID: "four-leaves",
            dinnerPlaceID: "park-steakhouse",
            townHallServiceID: "borough-hall",
            alertsServiceID: "alerts",
            trashServiceID: "trash-recycling",
            commuterServiceID: "commuter",
            seniorRideServiceID: "senior-ride",
            schoolsServiceID: "schools",
            formsServiceID: "forms",
            waterSewerServiceID: "water-sewer"
        )
    )

    static var pack: TownPack {
        TownPack(
            config: config,
            alerts: alerts,
            notices: notices,
            events: events,
            places: places,
            services: services,
            civicWorkflows: civicWorkflows
        )
    }
}

// MARK: - Pack Loader

/// Loads the active town. If a TownPack.json is bundled (the output of
/// Tools/town-onboarding), it wins; otherwise the built-in Park Ridge
/// seed pack keeps the app fully functional.
enum TownPackLoader {
    static func load(bundle: Bundle = .main) -> TownPack {
        if let url = bundle.url(forResource: "TownPack", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                return try JSONDecoder().decode(TownPack.self, from: data)
            } catch {
                assertionFailure("TownPack.json is bundled but failed to decode: \(error)")
            }
        }
        return ParkRidgeSeedData.pack
    }
}
