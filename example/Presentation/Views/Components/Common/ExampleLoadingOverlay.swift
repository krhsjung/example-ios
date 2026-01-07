//
//  ExampleLoadingOverlay.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleLoadingOverlay.swift
//  Created by 정희석 on 1/7/26.
//

import SwiftUI

struct ExampleLoadingOverlay: View {
    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
    }
}

// MARK: - View Modifier
struct ExampleLoadingOverlayModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if isLoading {
                    ExampleLoadingOverlay()
                }
            }
    }
}

extension View {
    func exampleLoadingOverlay(isLoading: Bool) -> some View {
        modifier(ExampleLoadingOverlayModifier(isLoading: isLoading))
    }
}

#Preview {
    VStack {
        Text("Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .exampleLoadingOverlay(isLoading: true)
}
