//
//  ActionsView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct ActionsView: View {
    
    let nightscoutService: NightscoutService
    
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: OverrideView(nightscoutService: nightscoutService)) {
                    Text("Overrides")
                }
                NavigationLink(destination: CarbInputView(nightscoutService: nightscoutService)) {
                    Text("Carbs")
                }
                NavigationLink(destination: BolusInputView(nightscoutService: nightscoutService)) {
                    Text("Bolus")
                }
            }
        }
    }
}
