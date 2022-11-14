//
//  TreatmentAnnotationView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import Foundation
import SwiftUI

struct TreatmentAnnotationView: View {
    @State var graphItem: GraphItem
    let viewStyle: TreatmentAnnotationViewStyle
    
    @ViewBuilder var body: some View {
        switch graphItem.type {
        case .bolus(let bolusEntry):
            VStack {
                ZStack {
                    Circle()
                        .stroke()
                        .foregroundColor(.blue)
                    Circle()
                        .trim(from: 0, to: 0.5)
                        .fill(.blue)
                    if bolusEntry.amount >= 1.0 {
                        Text("\(formatBolusValue(bolusEntry.amount))")
                            .frame(width: 50.0, height: 20.0)
                            .font(.footnote)
                            .offset(.init(width: 0.0, height: circleWidth()))
                    }
                }.frame(width: circleWidth(), height: circleWidth())
                    .opacity(0.75)
            }
        case .carb(let carbEntry):
            VStack {
                ZStack {
                    Circle()
                        .stroke()
                        .foregroundColor(.blue)
                    Circle()
                        .trim(from: 0.5, to: 1.0)
                        .fill(.yellow)
                    if carbEntry.amount >= 1 {
                        Text("\(formatCarbValue(carbEntry.amount))")
                            .frame(width: 50.0, height: 20.0)
                            .font(.footnote)
                            .offset(.init(width: 0.0, height: -circleWidth()))
                    }
                }.frame(width: circleWidth(), height: circleWidth())
                    .opacity(0.75)
            }
        default:
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .fill(.blue)
                    .frame(width: 50, height: 50)
            }
        }
    }
    
    func circleWidth() -> CGFloat {
        switch graphItem.type {
        case .bolus(let bolusEntry):
            return CGFloat(bolusEntry.amount) * viewStyle.valueToScaleFactor
        case .carb(let carbEntry):
            return CGFloat(carbEntry.amount) * viewStyle.valueToScaleFactor
        default:
            return 0.0
        }
    }
    
    func formatBolusValue(_ floatValue: Float) -> String {
        if floatValue - Float(Int(floatValue)) >= 0.1 { //TODO: Crash risk
            return String(format:"%.1f U", floatValue)
        } else {
            return String(format:"%.0f U", floatValue)
        }
    }
    
    func formatCarbValue(_ value: Int) -> String {
        return "\(value) G"
    }
    
    struct TreatmentAnnotationViewStyle {
        let valueToScaleFactor: CGFloat
//        let valueFormatter: ()
    }
    
    static func bolusViewStyle() -> TreatmentAnnotationViewStyle {
        return TreatmentAnnotationViewStyle(valueToScaleFactor: 5.0)
    }
    
    static func carbViewStyle() -> TreatmentAnnotationViewStyle {
        return TreatmentAnnotationViewStyle(valueToScaleFactor: 0.5)
    }
}

//protocol TreatmentAnnotation {
//
//}
