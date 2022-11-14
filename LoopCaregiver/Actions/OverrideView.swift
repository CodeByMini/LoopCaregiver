//
//  OverrideView.swift
//  LoopCaregiver
//
//  Created by Bill Gestrich on 11/13/22.
//

import SwiftUI
import NightscoutClient

struct OverrideView: View {
    
    let nightscoutService: NightscoutService
    @State var orginalOverride: NightscoutOverridePreset?
    @State var overidePresets: [NightscoutOverridePreset] = []
    @State var selectedOverride: NightscoutOverridePreset?
    var body: some View {
        HStack {
            Spacer()
            Picker("Overrides", selection: $selectedOverride) {
                Text("None").tag(nil as NightscoutOverridePreset?)
                ForEach(overidePresets, id: \.self) { overrideValue in
                    Text("\(overrideValue.name)").tag(overrideValue as NightscoutOverridePreset?)
                }
            }.pickerStyle(.wheel)
                .labelsHidden()
            Spacer()
                .onDisappear( perform: {
                    Task {
                        guard let selectedOverride = selectedOverride else {
                            return
                        }
                        
                        guard orginalOverride != selectedOverride else {
                            return
                        }
                        
                        do {
                            let _ = try await self.nightscoutService.startOverride(overrideName: selectedOverride.name, overrideDisplay: "A", durationInMinutes: 60)
                        } catch {
                            print(error)
                        }
                        
                        print("Done setting override")

                    }
                })
                .onAppear(perform: {
                    Task {
                        //TODO: Get the scheduleOverride from loopSettings and set that as the selected item
                        let profiles = try await nightscoutService.getProfiles()
                        if let activeProfile = profiles.first, let loopSettings = activeProfile.loopSettings {
    
                            overidePresets = loopSettings.overridePresets
                            
                            if let activeOverride = loopSettings.scheduleOverride {
                                self.orginalOverride = activeOverride
                                self.selectedOverride = activeOverride
                            }
                        }
                    }
                })
        }.navigationTitle("Overrides")
    }
}

extension NightscoutOverridePreset: Hashable {
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public static func == (lhs: NightscoutOverridePreset, rhs: NightscoutOverridePreset) -> Bool {
        lhs.name == rhs.name
    }
    
    
}
