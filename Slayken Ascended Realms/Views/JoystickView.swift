//
//  JoystickView.swift
//  test
//

import SwiftUI
import UIKit

struct JoystickView: View {
    @Binding var vector: SIMD2<Float>

    private let size: CGFloat = 130
    private let knobSize: CGFloat = 54

    var body: some View {
        let radius = (size - knobSize) / 2

        ZStack {
            Circle()
                .fill(.black.opacity(0.28))
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1.5))

            knobView
                .frame(width: knobSize, height: knobSize)
                .offset(
                    x: CGFloat(vector.x) * radius,
                    y: CGFloat(-vector.y) * radius
                )
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let center = CGPoint(x: size / 2, y: size / 2)
                    let dx = value.location.x - center.x
                    let dy = value.location.y - center.y
                    let normalized = normalizedVector(dx: dx, dy: dy, maxRadius: radius)
                    vector = SIMD2(Float(normalized.x), Float(-normalized.y))
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.12)) {
                        vector = .zero
                    }
                }
        )
    }

    @ViewBuilder
    private var knobView: some View {
        if let image = UIImage(named: "joystick") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else {
            Circle()
                .fill(.white.opacity(0.92))
                .overlay(Circle().stroke(.black.opacity(0.12), lineWidth: 1))
        }
    }

    private func normalizedVector(dx: CGFloat, dy: CGFloat, maxRadius: CGFloat) -> CGPoint {
        let distance = sqrt((dx * dx) + (dy * dy))
        guard distance > 0 else { return .zero }

        let clampedDistance = min(distance, maxRadius)
        return CGPoint(
            x: dx / distance * clampedDistance / maxRadius,
            y: dy / distance * clampedDistance / maxRadius
        )
    }
}
