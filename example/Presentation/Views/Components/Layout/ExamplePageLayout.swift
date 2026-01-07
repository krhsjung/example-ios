//
//  AuthPageLayout.swift
//  example
//
//  Path: Presentation/Views/Components/Layout/ExamplePageLayout.swift
//  Created by 정희석 on 12/29/25.
//

import SwiftUI

/// 인증 화면을 위한 기본 레이아웃 템플릿
/// Header, Container, Footer 구조를 제공
struct ExamplePageLayout<Header: View, Container: View, Footer: View>: View {
    let header: Header
    let container: Container
    let footer: Footer

    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder container: () -> Container,
        @ViewBuilder footer: () -> Footer
    ) {
        self.header = header()
        self.container = container()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            header
                .frame(maxWidth: .infinity)

            container
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
    }
}

#Preview {
    ExamplePageLayout(
        header: {
            Text("Header")
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.blue.opacity(0.2))
        },
        container: {
            Text("Container")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.green.opacity(0.2))
        },
        footer: {
            Text("Footer")
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(Color.red.opacity(0.2))
        }
    )
}
