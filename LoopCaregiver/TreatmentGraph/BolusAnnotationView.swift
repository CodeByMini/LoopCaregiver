//
//  BolusAnnotationView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import Foundation
import SwiftUI

struct BolusAnnotationView: View {
    @State var graphItem: GraphItem
    
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
                    
                }.frame(width: CGFloat(bolusEntry.amount) * bolusToAnnotationScaleFactor(), height: CGFloat(bolusEntry.amount) * bolusToAnnotationScaleFactor())
                if bolusEntry.amount >= 1.0 {
                    Text("\(truncateFloat(bolusEntry.amount))")
                        .frame(width: 50.0, height: 20.0)
                        .font(.footnote)
                }
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
    
    func bolusToAnnotationScaleFactor() -> CGFloat {
        return 10.0
    }
    
    func truncateFloat(_ floatValue: Float) -> String {
        if floatValue - Float(Int(floatValue)) >= 0.1 { //TODO: Crash risk
            return String(format:"%.1f U", floatValue)
        } else {
            return String(format:"%.0f U", floatValue)
        }

    }
}
