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
    let onDismiss: () -> Void

    func body(content: Content) -> some View {
        content
            .alert("", isPresented: $isPresented) {
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
        onDismiss: @escaping () -> Void = {}
    ) -> some View {
        modifier(ExampleErrorAlertModifier(
            isPresented: isPresented,
            message: message,
            onDismiss: onDismiss
        ))
    }
}
