//
//  ContentView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/12/22.
//

import SwiftUI
import NightscoutClient
import Charts

struct ContentView: View {
    
    @State var currentEGV: NightscoutEGV?
//    @State var formattedEGV: String = "?"
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    //TODO: Move these to some kind of credential structure - maybe save to secure preferences.
    static let nightscoutURL = URL(string: "")!
    static let nightscoutSecret = ""
//    static let nowDate: () -> Date = {Date().addingTimeInterval(-60*60*16)}
    static let nowDate: () -> Date = {Date()}
    
    let nightscoutService = NightscoutService(baseURL: Self.nightscoutURL, secret: Self.nightscoutSecret, referenceDate: Self.nowDate())
    
    var body: some View {
        VStack {
            HStack {
//                Text(formattedEGVValue())
                Text(formatEGV(currentEGV))
//                Text(formattedEGV)
                    .font(.largeTitle)
                    .foregroundColor(egvValueColor())
                    .padding()
                Spacer()
            }
            Spacer()
            TreatmentGraph(nightscoutClient: nightscoutService, nowDate: Self.nowDate)
            Spacer()
            ActionsView(nightscoutService: nightscoutService)
        }
        .onAppear(perform: {
            Task {
                try await updateData()
            }
        })
        .onReceive(timer) { input in
            Task {
                try await updateData()
            }
        }
    }
    
    func egvValueColor() -> Color {
        if let currentEGV = currentEGV {
            return ColorType(egvValue: currentEGV.value).color
        } else {
            return .red
        }
    }
    
    func formattedEGVValue() -> String {
        if let currentEGV {
            return String(currentEGV.value)
        } else {
            return "?"
        }
    }
    
    
    func formatEGV(_ egv: NightscoutEGV?) -> String {
        if let egv {
            return String(egv.value)
        } else {
            return "?"
        }
    }
    
    @MainActor
    func updateData() async throws {
        if let egv = try await fetchLatestEGV() {
            currentEGV = egv
//            formattedEGV = formatEGV(currentEGV)
        }
    }
    
    func fetchLatestEGV() async throws -> NightscoutEGV? {
        let minutesLookback = -30.0
        let startDate = Self.nowDate().addingTimeInterval(60 * minutesLookback)
        return try await nightscoutService.getEGVs(startDate:  startDate, endDate:Self.nowDate())
            .sorted(by: {$0.displayTime < $1.displayTime})
            .last
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
