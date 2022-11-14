//
//  TreatmentGraph.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import Charts
import NightscoutClient

struct TreatmentGraph: View {
    @State var graphItems: [GraphItem] = []
    @State var bolusEntryGraphItems: [GraphItem] = []
    @State var carbEntryGraphItems: [GraphItem] = []
    let nightscoutClient: NightscoutService
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    let nowDate: () -> Date
    
    var body: some View {
        Chart() {
            ForEach(graphItems){
                PointMark(
                    x: .value("Time", $0.displayTime),
                    y: .value("Reading", $0.value)
                )
                .foregroundStyle(by: .value("Reading", $0.colorType))
            }
            ForEach(bolusEntryGraphItems) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", graphItem.colorType))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem,
                                               viewStyle: TreatmentAnnotationView.bolusViewStyle())
                }
            }
            ForEach(carbEntryGraphItems) { graphItem in
                PointMark(
                    x: .value("Time", graphItem.displayTime),
                    y: .value("Reading", graphItem.value)
                )
                .foregroundStyle(by: .value("Reading", graphItem.colorType))
                .annotation(position: .overlay, alignment: .center, spacing: 0) {
                    return TreatmentAnnotationView(graphItem: graphItem,
                                               viewStyle: TreatmentAnnotationView.carbViewStyle())
                }
            }
        }
        //Make sure the domain values line up with what is in foregroundStyle above.
        .chartForegroundStyleScale(domain: ColorType.membersAsRange(), range: ColorType.allCases.map({$0.color}), type: .none)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle()) //For taps
                    .onTapGesture { tapPosition in
                        guard let (date, value) = proxy.value(at: tapPosition, as: (Date, Int).self) else {
                            print("Could not convert")
                            return
                        }
                        print("Location: \(date), \(value)")
                    }
            }
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

    @MainActor
    func updateData() async throws {
        let egvs = try await fetchEGVs()
        graphItems = egvs.map({$0.graphItem()})
        let bolusEntries = try await fetchBolusEntries()
        bolusEntryGraphItems = bolusEntries.map({$0.graphItem(egvValues: egvs)})
        
        let carbEntries = try await fetchCarbEntries()
        carbEntryGraphItems = carbEntries.map({$0.graphItem(egvValues: egvs)})
    }
    
    func fetchEGVs() async throws -> [NightscoutEGV] {
        return try await nightscoutClient.getEGVs(startDate: graphStartDate(), endDate:graphEndDate())
            .sorted(by: {$0.displayTime < $1.displayTime})
    }
    
    func fetchBolusEntries() async throws -> [BolusEntry] {
        return try await nightscoutClient.getBolusTreatments(startDate: graphStartDate(), endDate: graphEndDate())
    }
    
    func fetchCarbEntries() async throws -> [CarbEntry] {
        return try await nightscoutClient.getCarbTreatments(startDate: graphStartDate(), endDate: graphEndDate())
    }
    
    func graphStartDate() -> Date {
        return nowDate().addingTimeInterval(-60*60 * graphHourRange())
    }
    
    func graphEndDate() -> Date {
        return graphStartDate().addingTimeInterval(60*60 * graphHourRange())
    }
    
    func graphHourRange() -> Double {
        return 6.0
    }
}

enum GraphItemType {
    case egv
    case bolus(BolusEntry)
    case carb(CarbEntry)
}

struct GraphItem: Identifiable {
    
    var id = UUID()
    var type: GraphItemType
    var value: Int
    var displayTime: Date
    
    var colorType: ColorType {
        return ColorType(egvValue: value)
    }
}

enum ColorType: Int, Plottable, CaseIterable, Comparable {

    var primitivePlottable: Int {
        return self.rawValue
    }
    
    typealias PrimitivePlottable = Int

    case gray
    case green
    case yellow
    case red
    
    init?(primitivePlottable: Int){
        self.init(rawValue: primitivePlottable)
    }
    
    init(egvValue: Int) {
        switch egvValue {
        case 0..<180:
            self = ColorType.green
        case 180...249:
            self = ColorType.yellow
        case 250...:
            self = ColorType.red
        default:
            assertionFailure("Uexpected range")
            self = ColorType.gray
        }
    }

    var color: Color {
        switch self {
        case .gray:
            return Color.gray
        case .green:
            return Color.green
        case .yellow:
            return Color.yellow
        case .red:
            return Color.red
        }
    }
    
    static func membersAsRange() -> ClosedRange<ColorType> {
        return ColorType.allCases.first!...ColorType.allCases.last!
    }
    
    //Comparable
    static func < (lhs: ColorType, rhs: ColorType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

}



extension NightscoutEGV: Identifiable {
    public var id: Date {
        return displayTime
    }
    
    func graphItem() -> GraphItem {
        return GraphItem(type: .egv, value: value, displayTime: displayTime)
    }
}

extension CarbEntry {
    
    func graphItem(egvValues: [NightscoutEGV]) -> GraphItem {
        let relativeEgvValue = interpolateEGVValue(egvs: egvValues, atDate: date) ?? 390
        return GraphItem(type: .carb(self), value: relativeEgvValue, displayTime: date)
    }
    
    func interpolateEGVValue(egvs: [NightscoutEGV], atDate date: Date ) -> Int? {
        
        guard egvs.count >= 2 else {
            return egvs.first?.value
        }
        
        let priorEGVs = egvs.filter({$0.displayTime < date})
        guard let greatestPriorEGV = priorEGVs.last else {
            //All after, use first
            return egvs.first?.value
        }
        
        let laterEGVs = egvs.filter({$0.displayTime > date})
        guard let leastFollowingEGV = laterEGVs.first else {
            //All prior, use last
            return egvs.last?.value
        }
        
        return interpolateRange(range: (first: greatestPriorEGV.value, second: leastFollowingEGV.value), referenceRange: (first: greatestPriorEGV.displayTime, second: leastFollowingEGV.displayTime), refereceValue: date)
    }
}

extension BolusEntry {
    
    func graphItem(egvValues: [NightscoutEGV]) -> GraphItem {
        let relativeEgvValue = interpolateEGVValue(egvs: egvValues, atDate: date) ?? 390
        return GraphItem(type: .bolus(self), value: relativeEgvValue, displayTime: date)
    }
}

func interpolateEGVValue(egvs: [NightscoutEGV], atDate date: Date ) -> Int? {
    
    guard egvs.count >= 2 else {
        return egvs.first?.value
    }
    
    let priorEGVs = egvs.filter({$0.displayTime < date})
    guard let greatestPriorEGV = priorEGVs.last else {
        //All after, use first
        return egvs.first?.value
    }
    
    let laterEGVs = egvs.filter({$0.displayTime > date})
    guard let leastFollowingEGV = laterEGVs.first else {
        //All prior, use last
        return egvs.last?.value
    }
    
    return interpolateRange(range: (first: greatestPriorEGV.value, second: leastFollowingEGV.value), referenceRange: (first: greatestPriorEGV.displayTime, second: leastFollowingEGV.displayTime), refereceValue: date)
}

func interpolateRange(range: (first: Int, second: Int), referenceRange: (first: Date, second: Date), refereceValue: Date) -> Int {
    let referenceRangeDistance = referenceRange.second.timeIntervalSince1970 - referenceRange.first.timeIntervalSince1970
    let lowerRangeToValueDifference = refereceValue.timeIntervalSince1970 - referenceRange.first.timeIntervalSince1970
    let scaleFactor = lowerRangeToValueDifference / referenceRangeDistance
    
    let rangeDifference = range.first - range.second
    return range.first + (rangeDifference * Int(scaleFactor))
    
}
