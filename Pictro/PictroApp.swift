//
//  PictroApp.swift
//  Pictro
//
//  Created by Ting-Yen, Kuo on 2025/9/15.
//

import SwiftUI

@main
struct PictroApp: App {
    @StateObject private var photoLibraryService = PhotoLibraryService()
    @StateObject private var persistenceService = PersistenceService()
    @StateObject private var hapticsService = HapticsService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(photoLibraryService)
                .environmentObject(persistenceService)
                .environmentObject(hapticsService)
                .onAppear {
                    photoLibraryService.requestPermission()
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var photoLibraryService: PhotoLibraryService

    var body: some View {
        Group {
            switch photoLibraryService.authorizationStatus {
            case .requestingPermission:
                PermissionRequestView()
            case .permissionDenied:
                PermissionDeniedView()
            case .loadingAssets:
                LoadingView()
            case .ready:
                MonthListView()
            case .error(let error):
                ErrorView(error: error)
            }
        }
    }
}

// Views are now defined in MonthListView.swift to avoid duplication
