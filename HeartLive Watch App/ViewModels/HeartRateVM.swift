//
//  HeartRateVM.swift
//  HeartLive
//
//  Created by francisco eduardo aramburo reyes on 25/11/25.
//

import Foundation
import HealthKit
import Combine

#if targetEnvironment(simulator)
private let DEMO_MODE_DEFAULT = true   // Simulator: default ON
#else
private let DEMO_MODE_DEFAULT = false  // Device: default OFF
#endif

@MainActor
final class HeartRateVM: ObservableObject {
    @Published var bpmText: String = "--"
    @Published var status: String = "Not started"
    @Published var authorized: Bool = false
    @Published var demoMode: Bool = DEMO_MODE_DEFAULT  // ← NUEVA LÍNEA

    private let hk = HealthKitService()
    private var streamAny: Any?   // ← CAMBIADO: ahora puede ser HeartRateStream O MockHeartRateStream
    private var cancellables: Set<AnyCancellable> = []

    func requestAuth() async {
        // Si demo mode está ON, no necesitamos HealthKit auth
        guard demoMode == false else {
            authorized = true
            status = "Authorized (Demo)"
            return
        }
        do {
            try await hk.requestAuthorization()
            authorized = true
            status = "Authorized"
        } catch {
            authorized = false
            status = "Not authorized"
        }
    }

    func start() {
        guard authorized else { status = "Not authorized"; return }
        
        if demoMode {
            // MODO DEMO: usa datos falsos
            let mock = MockHeartRateStream()
            streamAny = mock
            mock.$bpm
                .sink { [weak self] v in self?.bpmText = v.map(String.init) ?? "--" }
                .store(in: &cancellables)
            mock.$state
                .sink { [weak self] st in self?.status = vmStatusText(st) }
                .store(in: &cancellables)
            mock.start()
        } else {
            // MODO REAL: usa HealthKit
            let real = HeartRateStream(store: hk.store)
            streamAny = real
            real.$bpm
                .receive(on: DispatchQueue.main)
                .sink { [weak self] v in self?.bpmText = v.map(String.init) ?? "--" }
                .store(in: &cancellables)
            real.$state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] st in self?.status = vmStatusText(st) }
                .store(in: &cancellables)
            try? real.start()
        }
    }

    func pause() {
        if let mock = streamAny as? MockHeartRateStream { mock.pause() }
        if let real = streamAny as? HeartRateStream { real.pause() }
    }

    func resume() {
        if let mock = streamAny as? MockHeartRateStream { mock.resume() }
        if let real = streamAny as? HeartRateStream { real.resume() }
    }

    func end() {
        if let mock = streamAny as? MockHeartRateStream { mock.end() }
        if let real = streamAny as? HeartRateStream { real.end() }
    }
}

private func vmStatusText(_ st: HKWorkoutSessionState) -> String {
    switch st {
    case .running: return "Live"
    case .paused: return "Paused"
    case .ended: return "Ended"
    default: return "Not started"
    }
}
