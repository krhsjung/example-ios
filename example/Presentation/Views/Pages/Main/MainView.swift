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

    var body: some View {
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

// MARK: - First Tab
struct FirstTabView: View {
    private var authManager = AuthManager.shared

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

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
        .exampleErrorAlert(isPresented: $showError, message: errorMessage)
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
