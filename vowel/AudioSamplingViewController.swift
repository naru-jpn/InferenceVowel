//
//  AudioSamplingViewController.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/19.
//

import UIKit

class AudioSamplingViewController: UIViewController, AudioSamplerDelegate, AudioAnalyzerDelegate {
    // 24_000 depends on device audio sampling rate...
    private let melFilterBank = MelFilterBank(range: 0...24_000, filteredRange: 300...8000, numSamples: 512, numFilters: 32)
    private lazy var audioAnalyzer: AudioAnalyzer = {
        AudioAnalyzer(numSamples: AudioSampler.numSamples, melFilterBank: melFilterBank)
    }()
    private var needsToSnapshotDCTCoefficients: Bool = false

    @IBOutlet private var inputWaveView: WaveView! {
        didSet {
            inputWaveView.numDrawnSamples = 1024
            inputWaveView.maxY = 5.0
        }
    }
    @IBOutlet private var frequencySpectrumView: WaveView! {
        didSet {
            frequencySpectrumView.numDrawnSamples = 128
            frequencySpectrumView.maxY = 0.3
            frequencySpectrumView.position = 0.8
        }
    }
    @IBOutlet private var melFilteredSamplesView: WaveView! {
        didSet {
            melFilteredSamplesView.numDrawnSamples = 32
            melFilteredSamplesView.maxY = 0.5
            melFilteredSamplesView.position = 0.8
        }
    }
    @IBOutlet private var dctCoefficientsView: WaveView! {
        didSet {
            dctCoefficientsView.numDrawnSamples = 16
            dctCoefficientsView.maxY = 15.0
        }
    }
    @IBOutlet private var shutterView: UIView!

    @IBAction private func didTapSnapshotItem(_ item: UIBarButtonItem) {
        needsToSnapshotDCTCoefficients = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        audioAnalyzer.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        AudioSampler.shared.delegate = self
        AudioSampler.shared.startCapture()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioSampler.shared.stopCapture()
    }

    private func snapshotDCTCoefficients(_ coefficients: UnsafeMutablePointer<Float>) {
        let coefficients = Array<Float>(UnsafeBufferPointer(start: coefficients, count: 16))
        let alertController = UIAlertController(title: "Snapshot was taken", message: "Please select vowel.", preferredStyle: .alert)
        for vowel in Vowel.allCases {
            alertController.addAction(
                UIAlertAction(
                    title: vowel.displayName,
                    style: .default,
                    handler: { _ in
                        let snapshot = Snapshot(vowel: vowel, coefficients: coefficients)
                        SnapshotStore.shared.append(snapshot: snapshot)
                    }
                )
            )
        }
        alertController.addAction(
            UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        )
        executeShutterAnimation()
        present(alertController, animated: true)
    }

    private func executeShutterAnimation() {
        shutterView.alpha = 1.0
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.shutterView.alpha = 0.0
            }
        )
    }

    // MARK: AudioSamplerDelegate

    func audioSamplerDidSample(_ sampleBuffer: UnsafeMutablePointer<Float>, sampleRate: Float64) {
        audioAnalyzer.analyze(sampleBuffer: sampleBuffer, sampleRate: sampleRate)
    }

    // MARK: AudioAnalyzerDelegate

    func audioAnalyzerDidStartAnalyze(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidNormalize(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int) {
        inputWaveView.set(buffer: samples)
    }

    func audioAnalyzerDidApplyWindowFunction(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidAnalyzeFrequencySpectrum(_ analyzer: AudioAnalyzer, amplitudes: UnsafeMutablePointer<Float>, length: Int) {
        frequencySpectrumView.set(buffer: amplitudes)
    }

    func audioAnalyzerDidApplyMelFilterBank(_ analyzer: AudioAnalyzer, melFilteredAmplitudes: UnsafeMutablePointer<Float>, length: Int) {
        melFilteredSamplesView.set(buffer: melFilteredAmplitudes)
    }

    func audioAnalyzerDidAnalyzeMelFrequencyLogSpectrum(_ analyzer: AudioAnalyzer, melFilteredLogAmplitudes: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidAnalyzeDCTCoefficients(_ analyzer: AudioAnalyzer, dctCoefficients: UnsafeMutablePointer<Float>, length: Int) {
        dctCoefficientsView.set(buffer: dctCoefficients)
        if needsToSnapshotDCTCoefficients {
            snapshotDCTCoefficients(dctCoefficients)
            needsToSnapshotDCTCoefficients = false
        }
    }
}
