//
//  HeartRateView.swift
//  HeartLive
//
//  Created by francisco eduardo aramburo reyes on 25/11/25.
//

import SwiftUI

struct HeartRateView: View {
    @EnvironmentObject var vm: HeartRateVM

    var body: some View {
        VStack(spacing: 10) {
            Text("Heart")
                .font(.system(.caption, design: .rounded))
                .opacity(0.8)

            Text(vm.bpmText)
                .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)

            Text(vm.status)
                .font(.system(.footnote, design: .rounded))
                .opacity(0.7)

            if !vm.authorized {
                Button("Allow Health Access") {
                    Task {
                        await vm.requestAuth()
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                HStack {
                    Button("Start") { vm.start() }
                    Button("Pause") { vm.pause() }
                    Button("End") { vm.end() }
                }
                .buttonStyle(.bordered)
                .font(.system(.footnote, design: .rounded))
            }
        }
        .padding(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Heart rate")
        .accessibilityValue(vm.bpmText + " beats per minute")
        .accessibilityHint(vm.status)
    }
}

// MARK: - Preview
#Preview {
    HeartRateView()
        .environmentObject(HeartRateVM())
}
