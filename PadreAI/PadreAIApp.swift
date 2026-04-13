//
//  MiSanaApp.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI

@main
struct MiSanaApp: App {
    @StateObject private var modelService = ModelCoordinator()
    @StateObject private var healthKitService = HealthKitService()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .environmentObject(modelService)
                    .environmentObject(healthKitService)

                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

struct SplashScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            Image(colorScheme == .dark ? "MiSanaLogoDark" : "MiSanaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
        }
    }
}
