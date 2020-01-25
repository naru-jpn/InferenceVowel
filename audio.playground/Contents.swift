import Accelerate
import Foundation

//: ## MelFilterBank

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
        debugPrint(filterBank)
    }

    private func freq2Mel(_ f: Float) -> Float {
        1125.0 * log(1.0 + f / 700.0)
    }

    private func mel2Freq(_ m: Float) -> Float {
        700.0 * (exp(m / 1125.0) - 1)
    }
}

let numFilters = 32

let melFilterBank = MelFilterBank(range: 0...24_000, filteredRange: 300...8000, numSamples: 512, numFilters: numFilters)
debugPrint(melFilterBank)

for m in (0..<numFilters) {
    for i in (0..<512) {
        switch m {
        case 0:
            _ = melFilterBank.filterBank[512 * m + i]
        case 1:
            _ = melFilterBank.filterBank[512 * m + i]
        case 2:
            _ = melFilterBank.filterBank[512 * m + i]
        case 9:
            _ = melFilterBank.filterBank[512 * m + i]
        case 10:
            _ = melFilterBank.filterBank[512 * m + i]
        case 11:
            _ = melFilterBank.filterBank[512 * m + i]
        case 17:
            _ = melFilterBank.filterBank[512 * m + i]
        case 18:
            _ = melFilterBank.filterBank[512 * m + i]
        case 19:
            _ = melFilterBank.filterBank[512 * m + i]
        default:
            break
        }
    }
}

let samples = unsafeBitCast(malloc(MemoryLayout<Float>.stride * 512), to: UnsafeMutablePointer<Float>.self)
for i in 0..<512 {
    samples[i] = 1.0
}

let mulResult = unsafeBitCast(malloc(MemoryLayout<Float>.stride * numFilters), to: UnsafeMutablePointer<Float>.self)

vDSP_mmul(melFilterBank.filterBank, 1, samples, 1, mulResult, 1, vDSP_Length(numFilters), 1, 512)

for i in 0..<numFilters {
    _ = mulResult[i]
}

//: ## DCT

guard let dctSetup = vDSP_DCT_CreateSetup(nil, vDSP_Length(numFilters), vDSP_DCT_Type.II) else {
    fatalError("Failed to create DCT Setup.")
}

let dctResult = unsafeBitCast(malloc(MemoryLayout<Float>.stride * numFilters), to: UnsafeMutablePointer<Float>.self)

vDSP_DCT_Execute(dctSetup, mulResult, dctResult)

for i in 0..<numFilters {
    _ = dctResult[i]
}
