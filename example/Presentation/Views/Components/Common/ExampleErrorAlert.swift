//
//  ExampleErrorAlert.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleErrorAlert.swift
//  Created by 정희석 on 1/7/26.
//

import SwiftUI

// MARK: - View Modifier
struct ExampleErrorAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("", isPresented: $isPresented) {
                if let onRetry = onRetry {
                    Button(Localized.Common.retry) {
                        onDismiss()
                        onRetry()
                    }
                }
                Button(Localized.Common.confirm, role: .cancel) {
                    onDismiss()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    func exampleErrorAlert(
        isPresented: Binding<Bool>,
        message: String,
        onRetry: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        modifier(ExampleErrorAlertModifier(
            isPresented: isPresented,
            message: message,
            onRetry: onRetry,
            onDismiss: onDismiss
        ))
    }
}
