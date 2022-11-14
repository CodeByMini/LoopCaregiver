//
//  CarbInputView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct CarbInputView: View {
    
    let nightscoutService: NightscoutService
    @State var carbInput: String = ""
    @State var duration: String = ""
    @State var otp: String = ""
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    var body: some View {
        VStack {
            Form {
                TextField(
                    "Carbs grams",
                    text: $carbInput
                )
                TextField(
                    "Duration",
                    text: $duration
                )
                TextField(
                    "OTP",
                    text: $otp
                )
            }
            Button("Submit") {
                Task {
                    if let carbAmountInGrams = Int(carbInput), let durationInHours = Float(duration), let otpCode = Int(otp) {
                        let _ = try await nightscoutService.deliverCarbs(amountInGrams: carbAmountInGrams, amountInHours: durationInHours, otp: otpCode)
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }

    }
}

