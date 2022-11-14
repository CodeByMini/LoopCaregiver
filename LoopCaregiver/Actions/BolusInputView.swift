//
//  BolusInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct BolusInputView: View {
    
    let nightscoutService: NightscoutService
    @State var bolusAmount: String = ""
    @State var duration: String = ""
    @State var otp: String = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            Form {
                TextField(
                    "Bolus units",
                    text: $bolusAmount
                )
                TextField(
                    "OTP",
                    text: $otp
                )
            }
            Button("Submit") {
                Task {
                    if let bolusAmountInUnits = Double(bolusAmount), let otpCode = Int(otp) {
                        let _ = try await nightscoutService.deliverBolus(amountInUnits: bolusAmountInUnits, otp: otpCode)
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }

    }
}

