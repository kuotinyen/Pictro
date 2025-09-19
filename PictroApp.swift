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

struct PermissionRequestView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.fill")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("歡迎使用 Pictro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("我們需要存取您的照片庫來幫助您整理照片")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("僅在本機進行篩選", systemImage: "lock.shield.fill")
                Label("不會上傳或分享您的照片", systemImage: "checkmark.shield.fill")
                Label("可隨時在設定中撤銷權限", systemImage: "gear")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.exclamationmark.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("需要照片權限")
                .font(.title)
                .fontWeight(.semibold)

            Text("請到「設定」>「隱私權與安全性」>「照片」中允許 Pictro 存取您的照片")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("開啟設定") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在載入照片...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let error: Error

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("發生錯誤")
                .font(.title2)
                .fontWeight(.semibold)

            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("重試") {
                // Trigger reload
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}