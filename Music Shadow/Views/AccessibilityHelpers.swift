// Music Shadow/Utils/AccessibilityHelpers.swift

import SwiftUI

extension View {
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }

    func minimumTouchTarget(_ size: CGFloat = 44) -> some View {
        self
            .frame(minWidth: size, minHeight: size)
            .contentShape(Rectangle())
    }
}
