//
//  MiSanaApp.swift
//  MiSana
//
//  Created by Abe Perez on 3/11/26.
//

import SwiftUI
import UIKit
import UserNotifications

@main
struct MiSanaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}

struct SplashScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Color.miSana.screenCream
                .ignoresSafeArea()

            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color.brand.opacity(0.55),
                        Color.brand.opacity(0.28),
                        Color.brand.opacity(0.0)
                      ]
                    : [
                        Color.brand.opacity(0.95),
                        Color.brand.opacity(0.55),
                        Color.brand.opacity(0.0)
                      ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image(colorScheme == .dark ? "MiSanaLogoDark" : "MiSanaLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
        }
    }
}
