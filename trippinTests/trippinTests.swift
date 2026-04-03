//
//  trippinTests.swift
//  trippinTests
//
//  Created by Rick Liu on 2026-04-03.
//

import Testing
import SwiftUI
@testable import trippin

@Suite("Spacing Tests")
struct SpacingTests {
    @Test("spacing values match design scale")
    func spacingScale() {
        #expect(Spacing.xxxs == 2)
        #expect(Spacing.xxs == 4)
        #expect(Spacing.xs == 8)
        #expect(Spacing.sm == 12)
        #expect(Spacing.md == 16)
        #expect(Spacing.lg == 24)
        #expect(Spacing.xl == 32)
        #expect(Spacing.xxl == 40)
    }

    @Test("spacing values increase monotonically")
    func spacingOrder() {
        let values = [
            Spacing.xxxs, Spacing.xxs, Spacing.xs, Spacing.sm,
            Spacing.md, Spacing.lg, Spacing.xl, Spacing.xxl
        ]
        for i in 1..<values.count {
            #expect(values[i] > values[i - 1])
        }
    }
}

@Suite("Corner Radius Tests")
struct CornerRadiusTests {
    @Test("corner radius values match design scale")
    func radiusScale() {
        #expect(CornerRadius.none == 0)
        #expect(CornerRadius.sm == 4)
        #expect(CornerRadius.md == 8)
        #expect(CornerRadius.lg == 12)
    }
}

@Suite("Elevation Tests")
struct ElevationTests {
    @Test("elevation shadow values are subtle")
    func subtleShadow() {
        #expect(Elevation.borderOpacity == 0.1)
        #expect(Elevation.shadowRadius == 4)
        #expect(Elevation.shadowY == 2)
    }
}

@Suite("Color Token Tests")
struct ColorTokenTests {
    @Test("all paper color tokens resolve")
    func colorTokensResolve() {
        let colors: [Color] = [
            .paperPrimary,
            .paperSecondary,
            .paperSuccess,
            .paperWarning,
            .paperDanger,
            .paperSurface,
            .paperText,
            .paperTextSecondary,
            .paperBorder
        ]
        #expect(colors.count == 9)
    }
}

@Suite("Font Tests")
struct FontTests {
    @Test("paperBody returns valid font with defaults")
    func bodyDefaults() {
        let font = Font.paperBody()
        #expect(font == .system(size: 16, weight: .regular, design: .default))
    }

    @Test("paperBody accepts custom size and weight")
    func bodyCustom() {
        let font = Font.paperBody(18, weight: .semibold)
        #expect(font == .system(size: 18, weight: .semibold, design: .default))
    }

    @Test("paperDisplay uses rounded design")
    func displayRounded() {
        let font = Font.paperDisplay()
        #expect(font == .system(size: 32, weight: .semibold, design: .rounded))
    }

    @Test("paperMono uses monospaced design")
    func monoDesign() {
        let font = Font.paperMono()
        #expect(font == .system(size: 14, weight: .regular, design: .monospaced))
    }

    @Test("type scale covers all design sizes")
    func typeScale() {
        let _ = Font.paperMono(14)
        let _ = Font.paperBody(16)
        let _ = Font.paperBody(18, weight: .semibold)
        let _ = Font.paperDisplay(24)
        let _ = Font.paperDisplay(32)
        let _ = Font.paperDisplay(40, weight: .bold)
    }
}

@Suite("Animation Tests")
struct AnimationTests {
    @Test("paper animations exist")
    func animationsExist() {
        let _ = Animation.paperSpring
        let _ = Animation.paperEase
    }
}

@Suite("Button Style Tests")
struct ButtonStyleTests {
    @Test("all button variants can be created")
    func buttonVariants() {
        let _ = PaperButtonStyle(variant: .primary)
        let _ = PaperButtonStyle(variant: .secondary)
        let _ = PaperButtonStyle(variant: .ghost)
        let _ = PaperButtonStyle(variant: .danger)
    }

    @Test("static accessors return correct variants")
    func staticAccessors() {
        let primary: PaperButtonStyle = .paperPrimary
        let secondary: PaperButtonStyle = .paperSecondary
        let ghost: PaperButtonStyle = .paperGhost
        let danger: PaperButtonStyle = .paperDanger

        #expect(primary.variant == .primary)
        #expect(secondary.variant == .secondary)
        #expect(ghost.variant == .ghost)
        #expect(danger.variant == .danger)
    }
}
