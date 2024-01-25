//
//  Misc.swift
//  VoiceCloneSteps
//
//  Created by javi www on 1/18/24.
//

import SwiftUI

func scaledValue(_ power: Double) -> Double {
    let minDb = -60.0;
    if (power < minDb) { return 0.0 }
    if (power > 1.0) { return 1.0 }

    // compute normalized value
    return (abs(minDb) - abs(power)) / abs(minDb);
}
