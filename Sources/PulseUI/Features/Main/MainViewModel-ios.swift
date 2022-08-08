// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import CoreData
import Pulse
import Combine

#if os(iOS) || os(tvOS) || os(watchOS)

final class MainViewModel: ObservableObject {
    let items: [MainViewModelItem]

    let console: ConsoleViewModel
    let network: NetworkViewModel

#if os(iOS)
    let pins: PinsViewModel
    let insights: NetworkInsightsViewModel
#endif

#if os(iOS) || os(tvOS)
    let settings: SettingsViewModel
#endif

    let store: LoggerStore
    let configuration: ConsoleConfiguration

    init(store: LoggerStore, configuration: ConsoleConfiguration = .default, onDismiss: (() -> Void)?) {
        self.configuration = configuration
        self.store = store

        self.console = ConsoleViewModel(store: store, configuration: configuration)
        self.console.onDismiss = onDismiss

        self.network = NetworkViewModel(store: store)
        self.network.onDismiss = onDismiss

#if os(iOS)
        self.pins = PinsViewModel(store: store)
        self.pins.onDismiss = onDismiss

        self.insights = NetworkInsightsViewModel(store: store)
#endif

#if os(iOS) || os(tvOS)
        self.settings = SettingsViewModel(store: store)
        self.settings.onDismiss = onDismiss
#endif

#if os(iOS)
        self.items = [.console, .network, .pins, !store.isArchive ? .insights : nil, .settings]
            .compactMap { $0 }
#elseif os(tvOS)
        self.items = [.console, .network, .settings]
#else
        self.items = [.console, .network, .pins]
#endif
    }

    func freeMemory() {
        store.viewContext.reset()
    }
}

struct MainViewModelItem: Hashable, Identifiable {
    let title: String
    let imageName: String
    var id: String { title }

#if os(iOS) || os(tvOS)
    static let console = MainViewModelItem(title: "Console", imageName: isPad ? "message" : "message.fill")
    static let network = MainViewModelItem(title: "Network", imageName: {
        if #available(iOS 14.0, *) {
            return "network"
        } else {
            return "icloud.and.arrow.down.fill"
        }
    }())
    static let pins = MainViewModelItem(title: "Pins", imageName: isPad ? "pin" : "pin.fill")
    static let insights = MainViewModelItem(title: "Insights", imageName: isPad ? "chart.pie" : "chart.pie.fill")
    static let settings = MainViewModelItem(title: "Settings", imageName: {
        if #available(iOS 14.0, *) {
            return "gearshape.fill"
        } else {
            return "ellipsis.circle.fill"
        }
    }())
#else
    static let console = MainViewModelItem(title: "Console", imageName: "message")
    static let network = MainViewModelItem(title: "Network", imageName: "icloud.and.arrow.down")
    static let pins = MainViewModelItem(title: "Pins", imageName: "pin")
    static let settings = MainViewModelItem(title: "Settings", imageName: "ellipsis.circle")
#endif
}

extension MainViewModel {
    @ViewBuilder
    func makeView(for item: MainViewModelItem) -> some View {
        switch item {
        case .console:
            ConsoleView(viewModel: console)
        case .network:
            NetworkView(viewModel: network)
#if !os(tvOS)
        case .pins:
            PinsView(viewModel: pins)
#endif
#if os(iOS)
        case .insights:
            NetworkInsightsView(viewModel: insights)
#endif
#if os(iOS) || os(tvOS)
        case .settings:
            SettingsView(viewModel: settings)
#endif
        default: fatalError()
        }
    }
}

private let isPad = UIDevice.current.userInterfaceIdiom == .pad

#endif
