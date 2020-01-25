//
//  Snapshot+Training.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/22.
//

import Foundation
import CoreML

extension Snapshot {
    var featureValue: MLFeatureValue {
        guard let array = try? MLMultiArray(coefficients) else {
            fatalError("Failed to create feature value of snapshot.")
        }
        return MLFeatureValue(multiArray: array)
    }
}
