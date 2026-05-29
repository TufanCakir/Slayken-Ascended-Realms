//
//  PerformanceModeManager.swift
//  Slayken Ascended Realms
//
//  Created by Tufan Cakir on 29.05.26.
//

import Combine
import SwiftUI
import UIKit

@MainActor
final class PerformanceModeManager: ObservableObject {
    static let shared = PerformanceModeManager()

    @Published private(set) var isScreenCaptured = UIScreen.main.isCaptured
    @Published private(set) var isLowPowerModeEnabled =
        ProcessInfo.processInfo.isLowPowerModeEnabled

    private var cancellables = Set<AnyCancellable>()

    var isReducedEffectsEnabled: Bool {
        isScreenCaptured || isLowPowerModeEnabled
    }

    var sceneFramesPerSecond: Int {
        isReducedEffectsEnabled ? 30 : 60
    }

    private init() {
        NotificationCenter.default.publisher(
            for: UIScreen.capturedDidChangeNotification
        )
        .merge(
            with: NotificationCenter.default.publisher(
                for: .NSProcessInfoPowerStateDidChange
            )
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _ in
            self?.refreshState()
        }
        .store(in: &cancellables)
    }

    private func refreshState() {
        isScreenCaptured = UIScreen.main.isCaptured
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
}
