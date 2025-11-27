//
//  HeartRateStream.swift
//  HeartLive
//
//  Created by francisco eduardo aramburo reyes on 25/11/25.
//
import HealthKit
import Combine

final class HeartRateStream: NSObject,
                             ObservableObject,
                             HKLiveWorkoutBuilderDelegate,
                             HKWorkoutSessionDelegate {   // <- add this
    @Published var bpm: Int?
    @Published var state: HKWorkoutSessionState = .notStarted

    private let store: HKHealthStore
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    init(store: HKHealthStore) { self.store = store }

    func start() throws {
        let config = HKWorkoutConfiguration()
        config.activityType = .other
        config.locationType = .unknown
        session = try HKWorkoutSession(healthStore: store, configuration: config)
        guard let session else { return }

        // Delegates
        session.delegate = self
        builder = session.associatedWorkoutBuilder()
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: store,
            workoutConfiguration: config
        )

        // Start
        session.startActivity(with: Date())
        builder?.beginCollection(withStart: Date()) { _, _ in }
        state = .running
    }
    func pause()  { session?.pause();  state = .paused }

    func resume() { session?.resume(); state = .running }

    func end() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { _, _ in
            self.builder?.finishWorkout { _, _ in }
        }
        state = .ended
    }

    // MARK: HKLiveWorkoutBuilderDelegate
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                       didCollectDataOf types: Set<HKSampleType>) {
        guard types.contains(HKObjectType.quantityType(forIdentifier: .heartRate)!) else { return }
        if let stats = workoutBuilder.statistics(for: .quantityType(forIdentifier: .heartRate)!),
           let q = stats.mostRecentQuantity() {
            let unit = HKUnit.count().unitDivided(by: .minute())
            let val = q.doubleValue(for: unit)
            DispatchQueue.main.async { self.bpm = Int(round(val)) }
        }
    }

    // MARK: HKWorkoutSessionDelegate (required)
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async { self.state = toState }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        // You can surface this to UI if you want
        DispatchQueue.main.async { self.state = .ended }
        // print("Workout session failed: \(error)")
    }

    // (Often optional, but safe to include)
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didGenerate event: HKWorkoutEvent) {
        // Handle pause/resume events if you want
    }
}
