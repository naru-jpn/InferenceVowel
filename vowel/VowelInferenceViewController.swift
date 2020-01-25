//
//  VowelInferenceViewController.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/22.
//

import CoreML
import UIKit

final class VowelInferenceViewController: UIViewController, AudioSamplerDelegate, AudioAnalyzerDelegate {
    // 24_000 depends on device audio sampling rate...
    private let melFilterBank = MelFilterBank(range: 0...24_000, filteredRange: 300...8000, numSamples: 512, numFilters: 32)
    private lazy var audioAnalyzer: AudioAnalyzer = {
        AudioAnalyzer(numSamples: AudioSampler.numSamples, melFilterBank: melFilterBank)
    }()
    private let updatedModelUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("updated.mlmodelc")

    @IBOutlet private var waveView: WaveView! {
        didSet {
            waveView.numDrawnSamples = 1024
            waveView.maxY = 5.0
        }
    }
    @IBOutlet private var labelA: UILabel!
    @IBOutlet private var labelI: UILabel!
    @IBOutlet private var labelU: UILabel!
    @IBOutlet private var labelE: UILabel!
    @IBOutlet private var labelO: UILabel!

    private let inferenceBatchSize: Int = 3
    private var timer: Timer?
    private let intervalInference: TimeInterval = 0.25
    private var snapshots: [Snapshot] = []
    private var needsInsertSnapshots: Bool = false
    private var isProcessingInference: Bool = false
    private let outputProbThreasholdValue: Double = 0.7
    private let outputProbThreasholdCount: Int = 3

    @IBAction private func didTapCloseItem(item: UIBarButtonItem) {
        navigationController?.dismiss(animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        audioAnalyzer.delegate = self
        timer = Timer.scheduledTimer(withTimeInterval: intervalInference, repeats: true, block: { [weak self] _ in
            self?.needsInsertSnapshots = true
        })
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

    private func inference() {
        guard let model: UpdatableKNN = try? UpdatableKNN(contentsOf: updatedModelUrl) else {
            return
        }
        defer {
            isProcessingInference = false
        }

        let inputs: [UpdatableKNNInput] = snapshots.compactMap({ $0.featureValue.multiArrayValue }).map({ UpdatableKNNInput(input: $0) })
        do {
            let outputs: [UpdatableKNNOutput] = try model.predictions(inputs: inputs)
            displayResult(with: outputs)
            snapshots = []
        } catch {
            print("Failed to inference snapshots.")
        }
    }

    private func displayResult(with outputs: [UpdatableKNNOutput]) {
        resetHighlight()
        let labelProbs: [(String, Double)] = outputs.map({ $0.labelProbs.sorted(by: { $0.1 > $1.1 })[0] })
        let fixedLabelProbs: [(String, Double)] = labelProbs.filter({ $0.1 > outputProbThreasholdValue })
        guard fixedLabelProbs.count >= outputProbThreasholdCount else {
            print(fixedLabelProbs.count)
            return
        }
        guard let label = mostLikelifoodLabel(with: fixedLabelProbs), let vowel = Vowel.vowel(with: label) else {
            print("no label")
            return
        }
        highlight(vowel: vowel)
    }

    private func mostLikelifoodLabel(with labelProbs: [(String, Double)]) -> String? {
        let counters: [(String, Int)] = Set<String>(labelProbs.map({ $0.0 })).map({ key in (key, labelProbs.filter({ $0.0 == key }).count)  })
        return counters.sorted(by: { $0.1 > $1.1 }).first?.0
    }

    private func label(for vowel: Vowel) -> UILabel? {
        switch vowel {
        case .a:
            return labelA
        case .i:
            return labelI
        case .u:
            return labelU
        case .e:
            return labelE
        case .o:
            return labelO
        case .unknown:
            return nil
        }
    }

    private func resetHighlight() {
        for vowel in Vowel.allCases {
            label(for: vowel)?.textColor = .lightGray
        }
    }

    private func highlight(vowel: Vowel) {
        label(for: vowel)?.textColor = .orange
    }

    // MARK: AudioSamplerDelegate

    func audioSamplerDidSample(_ sampleBuffer: UnsafeMutablePointer<Float>, sampleRate: Float64) {
        audioAnalyzer.analyze(sampleBuffer: sampleBuffer, sampleRate: sampleRate)
    }

    // MARK: AudioAnalyzerDelegate

    func audioAnalyzerDidStartAnalyze(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidNormalize(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int) {
        waveView.set(buffer: samples)
    }

    func audioAnalyzerDidApplyWindowFunction(_ analyzer: AudioAnalyzer, samples: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidAnalyzeFrequencySpectrum(_ analyzer: AudioAnalyzer, amplitudes: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidApplyMelFilterBank(_ analyzer: AudioAnalyzer, melFilteredAmplitudes: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidAnalyzeMelFrequencyLogSpectrum(_ analyzer: AudioAnalyzer, melFilteredLogAmplitudes: UnsafeMutablePointer<Float>, length: Int) {
    }

    func audioAnalyzerDidAnalyzeDCTCoefficients(_ analyzer: AudioAnalyzer, dctCoefficients: UnsafeMutablePointer<Float>, length: Int) {
        guard needsInsertSnapshots, isProcessingInference == false else {
            return
        }

        let coefficients = Array<Float>(UnsafeBufferPointer(start: dctCoefficients, count: 16))
        let snapshot = Snapshot(vowel: .unknown, coefficients: coefficients)
        snapshots.append(snapshot)

        if snapshots.count >= inferenceBatchSize {
            isProcessingInference = true
            needsInsertSnapshots = false
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.inference()
            }
        }
    }
}
