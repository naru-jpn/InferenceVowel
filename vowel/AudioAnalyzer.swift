//
//  AudioAnalyzer.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/19.
//

import Accelerate
import Foundation

protocol AudioAnalyzerDelegate: class {
    func audioAnalyzerDidStartAnalyze(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int)
    func audioAnalyzerDidNormalize(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int)
    func audioAnalyzerDidApplyWindowFunction(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int)
    func audioAnalyzerDidAnalyzeFrequencySpectrum(_ analyzer: AudioAnalyzer, amplitudes: UnsafeMutablePointer<Float>, length: Int)
    func audioAnalyzerDidApplyMelFilterBank(_ analyzer: AudioAnalyzer, melFilteredAmplitudes: UnsafeMutablePointer<Float>, length: Int)
    func audioAnalyzerDidAnalyzeMelFrequencyLogSpectrum(_ analyzer: AudioAnalyzer, melFilteredLogAmplitudes: UnsafeMutablePointer<Float>, length: Int)
    func audioAnalyzerDidAnalyzeDCTCoefficients(_ analyzer: AudioAnalyzer, dctCoefficients: UnsafeMutablePointer<Float>, length: Int)
}

// ref: http://practicalcryptography.com/miscellaneous/machine-learning/guide-mel-frequency-cepstral-coefficients-mfccs/#computing-the-mel-filterbank
final class AudioAnalyzer {
    let fftSize: Int
    let fftSizeHalf: Int
    let fftSizeLog2: Int
    private(set) var sampleRate: Float64 = 0

    /// Processed Sample Buffer
    private let sampleBuffer: UnsafeMutablePointer<Float>
    /// Window Function (hamm)
    private let window: UnsafeMutablePointer<Float>
    /// SplitComplex used fft calculation
    private let splitComplex: UnsafeMutablePointer<DSPSplitComplex>
    /// Setup for FFT
    private let fftSetup: FFTSetup
    /// Amplitude of FFT Result
    private let fftAmplitude: UnsafeMutablePointer<Float>
    /// Mel Filter Bank
    private let melFilterBank: MelFilterBank
    /// Mel Filtered Amplitude
    private let melFilteredFFTAmplitude: UnsafeMutablePointer<Float>
    /// Mel Filtered Log10 Amplitude
    private let melFilteredFFTLogAmplitude: UnsafeMutablePointer<Float>
    /// DCT Setup
    private let dctSetup: vDSP_DFT_Setup
    /// DCT Coefficient
    private let dctCoefficient: UnsafeMutablePointer<Float>

    private(set) var isAnalyzing: Bool = false

    weak var delegate: AudioAnalyzerDelegate?

    init(numSamples: Int, melFilterBank: MelFilterBank) {
        self.fftSize = numSamples
        fftSizeHalf = numSamples / 2
        fftSizeLog2 = Int(log2(Float(numSamples)))
        sampleBuffer = unsafeBitCast(malloc(MemoryLayout<Float>.stride * numSamples), to: UnsafeMutablePointer<Float>.self)
        window = unsafeBitCast(malloc(MemoryLayout<Float>.stride * numSamples), to: UnsafeMutablePointer<Float>.self)
        vDSP_hamm_window(window, vDSP_Length(numSamples), 0)
        splitComplex = unsafeBitCast(malloc(MemoryLayout<DSPSplitComplex>.size), to: UnsafeMutablePointer<DSPSplitComplex>.self)
        splitComplex.pointee.realp = unsafeBitCast(malloc(MemoryLayout<Float>.stride * fftSizeHalf), to: UnsafeMutablePointer<Float>.self)
        splitComplex.pointee.imagp = unsafeBitCast(malloc(MemoryLayout<Float>.stride * fftSizeHalf), to: UnsafeMutablePointer<Float>.self)
        guard let fftSetup = vDSP_create_fftsetup(vDSP_Length(log2(Float(fftSize))), FFTRadix(kFFTRadix2)) else {
            fatalError("Failed to create FFTSetup with FFT size: \(numSamples)")
        }
        self.fftSetup = fftSetup
        fftAmplitude = unsafeBitCast(malloc(MemoryLayout<Float>.stride * fftSizeHalf), to: UnsafeMutablePointer<Float>.self)
        self.melFilterBank = melFilterBank
        melFilteredFFTAmplitude = unsafeBitCast(malloc(MemoryLayout<Float>.stride * melFilterBank.numFilters), to: UnsafeMutablePointer<Float>.self)
        melFilteredFFTLogAmplitude = unsafeBitCast(malloc(MemoryLayout<Float>.stride * melFilterBank.numFilters), to: UnsafeMutablePointer<Float>.self)
        guard let dctSetup = vDSP_DCT_CreateSetup(nil, vDSP_Length(melFilterBank.numFilters), vDSP_DCT_Type.II) else {
            fatalError("Failed to create DCT Setup. DSP length (same value is used with `melFilterBank.numFilters`) must be formed `f * 2**n, (f=1,3,5 or 15, n>=4)`.")
        }
        self.dctSetup = dctSetup
        dctCoefficient = unsafeBitCast(malloc(MemoryLayout<Float>.stride * melFilterBank.numFilters), to: UnsafeMutablePointer<Float>.self)
    }

    deinit {
        free(sampleBuffer)
        free(window)
        free(splitComplex.pointee.realp)
        free(splitComplex.pointee.imagp)
        free(splitComplex)
        vDSP_destroy_fftsetup(fftSetup)
        free(fftAmplitude)
        free(melFilteredFFTAmplitude)
        free(melFilteredFFTLogAmplitude)
        vDSP_DFT_DestroySetup(dctSetup)
        free(dctCoefficient)
    }

    func analyze(sampleBuffer: UnsafeMutablePointer<Float>, sampleRate: Float64) {
        guard !isAnalyzing else {
            debugPrint("Already running, skip analyze...")
            return
        }
        self.sampleRate = sampleRate
        memcpy(self.sampleBuffer, sampleBuffer, MemoryLayout<Float>.stride * fftSize)
        analyze()
    }

    private func analyze() {
        isAnalyzing = true
        delegate?.audioAnalyzerDidStartAnalyze(self, samples: sampleBuffer, length: fftSize)
        normalize()
        applyWindowFunction()
        analyzePowerSpectrum()
        applyMelFilterBank()
        analyzeMelFrequencyLogSpectrum()
        analyzeDCTCoefficients()
        isAnalyzing = false
    }

    private func normalize() {
        var mean: Float = 0.0
        var standardDeviation: Float = 1.0
        vDSP_normalize(sampleBuffer, 1, sampleBuffer, 1, &mean, &standardDeviation, vDSP_Length(fftSize))

        delegate?.audioAnalyzerDidNormalize(self, samples: sampleBuffer, length: fftSize)
    }

    private func applyWindowFunction() {
        vDSP_vmul(sampleBuffer, 1, window, 1, sampleBuffer, 1, vDSP_Length(fftSize))
        delegate?.audioAnalyzerDidApplyWindowFunction(self, samples: sampleBuffer, length: fftSize)
    }

    private func analyzePowerSpectrum() {
        let sampleBufferC = UnsafeRawPointer(sampleBuffer).bindMemory(to: DSPComplex.self, capacity: fftSizeHalf)
        vDSP_ctoz(sampleBufferC, 2, splitComplex, 1, vDSP_Length(fftSizeHalf))
        vDSP_fft_zrip(fftSetup, splitComplex, 1, vDSP_Length(fftSizeLog2), FFTDirection(kFFTDirection_Forward))

        var scale = 1.0 / Float(fftSize * 2)
        vDSP_vsmul(splitComplex.pointee.realp, 1, &scale, splitComplex.pointee.realp, 1, vDSP_Length(fftSizeHalf))
        vDSP_vsmul(splitComplex.pointee.imagp, 1, &scale, splitComplex.pointee.imagp, 1, vDSP_Length(fftSizeHalf))

        vDSP_zvabs(splitComplex, 1, fftAmplitude, 1, vDSP_Length(fftSizeHalf))
        delegate?.audioAnalyzerDidAnalyzeFrequencySpectrum(self, amplitudes: fftAmplitude, length: fftSizeHalf)
    }

    private func applyMelFilterBank() {
        vDSP_mmul(melFilterBank.filterBank, 1, fftAmplitude, 1, melFilteredFFTAmplitude, 1, vDSP_Length(melFilterBank.numFilters), 1, vDSP_Length(fftSizeHalf))
        delegate?.audioAnalyzerDidApplyMelFilterBank(self, melFilteredAmplitudes: melFilteredFFTAmplitude, length: melFilterBank.numFilters)
    }

    private func analyzeMelFrequencyLogSpectrum() {
        var size = Int32(melFilterBank.numFilters)
        vvlog10f(melFilteredFFTLogAmplitude, melFilteredFFTAmplitude, &size)
        delegate?.audioAnalyzerDidAnalyzeMelFrequencyLogSpectrum(self, melFilteredLogAmplitudes: melFilteredFFTLogAmplitude, length: melFilterBank.numFilters)
    }

    private func analyzeDCTCoefficients() {
        vDSP_DCT_Execute(dctSetup, melFilteredFFTLogAmplitude, dctCoefficient)
        delegate?.audioAnalyzerDidAnalyzeDCTCoefficients(self, dctCoefficients: dctCoefficient, length: melFilterBank.numFilters)
    }
}
