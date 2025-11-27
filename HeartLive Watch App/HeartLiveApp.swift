//
//  HeartLiveApp.swift
//  HeartLive Watch App
//
//  Created by francisco eduardo aramburo reyes on 25/11/25.
//

import SwiftUI

@main
struct HeartLiveApp: App {
    @StateObject private var vm = HeartRateVM()
    var body: some Scene {
        WindowGroup {
            HeartRateView()
                .environmentObject(vm)
        }
    }
}
