//
//  MelFilterBank.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/19.
//

import Foundation

/// ref: http://practicalcryptography.com/miscellaneous/machine-learning/guide-mel-frequency-cepstral-coefficients-mfccs/#computing-the-mel-filterbank
final class MelFilterBank {
    let range: ClosedRange<Float>
    let filteredRange: ClosedRange<Float>
    let numSamples: Int
    let numFilters: Int
    let filterBank: UnsafeMutablePointer<Float>

    init(range: ClosedRange<Float>, filteredRange: ClosedRange<Float>, numSamples: Int, numFilters: Int) {
        self.range = range
        self.filteredRange = filteredRange
        self.numSamples = numSamples
        self.numFilters = numFilters
        filterBank = unsafeBitCast(malloc(MemoryLayout<Float>.stride * numSamples * numFilters), to: UnsafeMutablePointer<Float>.self)
        buildFilterBank()
    }

    deinit {
        free(filterBank)
    }

    private func buildFilterBank() {
        let melRangeF = freq2Mel(filteredRange.lowerBound)...freq2Mel(filteredRange.upperBound)
        let mels: [Float] = (0...(numFilters + 1)).map({ (i: Int) -> Float in melRangeF.lowerBound + Float(i) * (melRangeF.upperBound - melRangeF.lowerBound) / Float(numFilters + 1) })
        let freqs: [Float] = mels.map(mel2Freq)
        let dk: Float = (range.upperBound - range.lowerBound) / Float(numSamples)
        for m in (1...numFilters) {
            let head: Int = (m - 1) * numSamples
            for i in (0..<numSamples) {
                let k = range.lowerBound + dk * Float(i)
                switch k {
                case 0.0..<freqs[m - 1]:
                    filterBank[head + i] = 0.0
                case freqs[m - 1]..<freqs[m]:
                    filterBank[head + i] = (k - freqs[m - 1]) / (freqs[m] - freqs[m - 1])
                case freqs[m]..<freqs[m + 1]:
                    filterBank[head + i] = (freqs[m + 1] - k) / (freqs[m + 1] - freqs[m])
                case freqs[m + 1]...Float.greatestFiniteMagnitude:
                    filterBank[head + i] = 0.0
                default:
                    fatalError("Got unexpected frequency while creating mel filter bank.")
                }
            }
        }
    }

    private func freq2Mel(_ f: Float) -> Float {
        1125.0 * log(1.0 + f / 700.0)
    }

    private func mel2Freq(_ m: Float) -> Float {
        700.0 * (exp(m / 1125.0) - 1)
    }
}
