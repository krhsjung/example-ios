//
//  UIApplication+Keyboard.swift
//  example
//
//  Path: Presentation/Views/Extensions/UIApplication+Keyboard.swift
//

import UIKit

extension UIApplication {
    /// 현재 포커스된 입력 필드의 키보드를 내림
    ///
    /// UIKit의 resignFirstResponder를 사용하여 SwiftUI의 FocusState 변경보다
    /// 부드러운 키보드 해제 애니메이션을 제공
    static func dismissKeyboard() {
        shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
