//
//  PaperButtonStyle.swift
//  trippin
//
//  Created by Rick Liu on 2026-04-03.
//

import SwiftUI

enum PaperButtonVariant {
    case primary
    case secondary
    case ghost
    case danger
}

struct PaperButtonStyle: ButtonStyle {
    let variant: PaperButtonVariant
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.paperBody(16, weight: .medium))
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(minHeight: 44)
            .foregroundStyle(foregroundColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(borderColor, lineWidth: variant == .secondary ? 1 : 0)
            )
            .opacity(opacity(isPressed: configuration.isPressed))
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: .white
        case .secondary: .paperPrimary
        case .ghost: .paperPrimary
        case .danger: .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: .paperPrimary
        case .secondary: .clear
        case .ghost: .clear
        case .danger: .paperDanger
        }
    }

    private var borderColor: Color {
        switch variant {
        case .secondary: .paperPrimary
        default: .clear
        }
    }

    private func opacity(isPressed: Bool) -> Double {
        if !isEnabled { return 0.4 }
        if isPressed { return 0.7 }
        return 1.0
    }
}

extension ButtonStyle where Self == PaperButtonStyle {
    static var paperPrimary: PaperButtonStyle { .init(variant: .primary) }
    static var paperSecondary: PaperButtonStyle { .init(variant: .secondary) }
    static var paperGhost: PaperButtonStyle { .init(variant: .ghost) }
    static var paperDanger: PaperButtonStyle { .init(variant: .danger) }
}
