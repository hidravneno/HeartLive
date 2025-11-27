
//
//  MockHeartRateStream.swift
//  HeartLive Watch App
//
//  Created by francisco eduardo aramburo reyes on 25/11/25.
//

import Foundation
import HealthKit
import Combine

// A drop-in replacement for HeartRateStream that fakes BPM updates.
// Use in Simulator or when Demo Mode is enabled.
final class MockHeartRateStream: NSObject, ObservableObject {
    @Published var bpm: Int!
    @Published var state: HKWorkoutSessionState = .notStarted
    
    private var timer: AnyCancellable?
    private var base: Int = 76     // baseline BPM
    private var drift: Int = 0
    
    func start() {
        guard state != .running else { return }
        state = .running
        
        // Emit a new BPM every ~2.5 seconds with gentle random variation.
        timer = Timer
            .publish(every: 2.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // Slowly drift around the baseline to feel "alive"
                self.drift = max(-8, min(8, self.drift + Int.random(in: -2...2)))
                let noise = Int.random(in: -3...3)
                let val = max(55, min(150, self.base + self.drift + noise))
                self.bpm = val
            }
    }
    
    func pause() {
        state = .paused
        timer?.cancel()
    }
    
    func resume() {
        start()
    }
        
        func end() {
            state = .ended
            timer?.cancel()
            timer = nil
        }
    }

