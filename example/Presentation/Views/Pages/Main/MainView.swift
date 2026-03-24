//
//  MainView.swift
//  example
//
//  Path: Presentation/Views/Pages/Main/MainView.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI

struct MainView: View {
    @State private var selectedTab: Int = 0
    private var networkMonitor = ServiceContainer.shared.networkMonitor

    var body: some View {
        VStack(spacing: 0) {
            NetworkUnavailableBanner(isVisible: !networkMonitor.isNetworkAvailable)

            TabView(selection: $selectedTab) {
                FirstTabView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("First")
                    }
                    .tag(0)

                SecondTabView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Second")
                    }
                    .tag(1)
            }
        }
    }
}

// MARK: - Network Unavailable Banner
private struct NetworkUnavailableBanner: View {
    let isVisible: Bool

    var body: some View {
        if isVisible {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.caption)
                Text(Localized.Common.networkUnavailable)
                    .font(.caption)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.red.opacity(0.85))
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: isVisible)
        }
    }
}

// MARK: - First Tab
struct FirstTabView: View {
    private var authManager = ServiceContainer.shared.authManager

    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {
            Text("First Tab")
                .font(.largeTitle)
                .fontWeight(.bold)

            ExampleButton(title: Localized.Common.logout) {
                logout()
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .exampleLoadingOverlay(isLoading: isLoading)
    }

    private func logout() {
        Task {
            isLoading = true
            defer { isLoading = false }

            await authManager.logOut()
        }
    }
}

// MARK: - Second Tab
struct SecondTabView: View {
    var body: some View {
        VStack {
            Text("Second Tab")
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MainView()
}
