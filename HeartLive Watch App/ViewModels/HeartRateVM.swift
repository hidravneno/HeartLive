//
//  HeartRateVM.swift
//  HeartLive
//
//  Created by francisco eduardo aramburo reyes on 25/11/25.
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HeartRateVM: ObservableObject {
    @Published var bpmText: String = "--"
    @Published var status: String = "Not started"
    @Published var authorized: Bool = false

    private let hk = HealthKitService()
    private var stream: HeartRateStream?
    private var cancellables: Set<AnyCancellable> = []

    func requestAuth() async {
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
        guard authorized else {
            status = "Not authorized"
            return
        }
        stream = HeartRateStream(store: hk.store)
        stream?.$bpm
            .receive(on: DispatchQueue.main)
            .sink { [weak self] v in
                self?.bpmText = v.map(String.init) ?? "--"
            }
            .store(in: &cancellables)
        stream?.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] st in
                self?.status = vmStatusText(st)
            }
            .store(in: &cancellables)
        try? stream?.start()
    }

    func pause() {
        stream?.pause()
    }
    
    func resume() {
        stream?.resume()
    }
    
    func end() {
        stream?.end()
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
