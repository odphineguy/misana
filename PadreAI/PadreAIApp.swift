//
//  PadreAIApp.swift
//  PadreAI
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

@main
struct PadreAIApp: App {
    @StateObject private var modelService = LocalModelService()
    @StateObject private var healthKitService = HealthKitService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(modelService)
                .environmentObject(healthKitService)
        }
    }
}
