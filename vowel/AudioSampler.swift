//
//  AudioSampler.swift
//  audio
//
//  Created by Naruki Chigira on 2020/01/19.
//

import Accelerate
import AVFoundation
import Foundation

protocol AudioSamplerDelegate: class {
    func audioSamplerDidSample(_ sampleBuffer: UnsafeMutablePointer<Float>, sampleRate: Float64)
}

final class AudioSampler: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate {
    static let shared = AudioSampler()
    static let numSamples: Int = 1024

    private let serialQueue = DispatchQueue.main
    private let captureSession = AVCaptureSession()
    private let sampleBufferPointer: UnsafeMutablePointer<Float>

    weak var delegate: AudioSamplerDelegate?

    override init() {
        let sampleBufferRawPointer = malloc(MemoryLayout<Float>.stride * AudioSampler.numSamples)
        sampleBufferPointer = unsafeBitCast(sampleBufferRawPointer, to: UnsafeMutablePointer<Float>.self)
        super.init()
        configure()
    }

    private func configure() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setActive(false)
            try audioSession.setCategory(.record)
            try audioSession.setMode(.videoRecording)
            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(1024.0 / 44100.0)
            try audioSession.setActive(true)
        } catch {
            fatalError("Failed to configure audio session with error: \(error)")
        }

        do {
            guard let captureDevice = AVCaptureDevice.default(for: .audio) else {
                fatalError("Failed to get audio capture device.")
            }
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)

            let captureAudioDataOutput = AVCaptureAudioDataOutput()
            captureAudioDataOutput.setSampleBufferDelegate(self, queue: serialQueue)

            captureSession.beginConfiguration()
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            if captureSession.canAddOutput(captureAudioDataOutput) {
                captureSession.addOutput(captureAudioDataOutput)
            }
            captureSession.automaticallyConfiguresApplicationAudioSession = false
            captureSession.commitConfiguration()
        } catch {
            fatalError("Failed to configure audio devices with error: \(error)")
        }
    }

    func startCapture() {
        captureSession.startRunning()
    }

    func stopCapture() {
        captureSession.stopRunning()
    }

    // MARK: AVCaptureAudioDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            debugPrint("Failed to get CMSampleBufferGetFormatDescription.")
            return
        }
        guard let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee else {
            debugPrint("Failed to get CMAudioFormatDescriptionGetStreamBasicDescription.")
            return
        }
        // validate media data
        guard audioStreamBasicDescription.mFormatID == kAudioFormatLinearPCM else {
            debugPrint("Failed to get LinearPCM formated audio stream.")
            return
        }
        let channelsPerFrame = audioStreamBasicDescription.mChannelsPerFrame
        let bitsPerChannel = audioStreamBasicDescription.mBitsPerChannel
        guard channelsPerFrame == 1 && bitsPerChannel == 8 * MemoryLayout<Int16>.size else {
            debugPrint("Got unexpected ChannelsPerFrame or BitsPerChannel: ChannelsPerFrame(\(channelsPerFrame)), BitsPerChannel(\(bitsPerChannel))")
            return
        }

        let sampleRate = audioStreamBasicDescription.mSampleRate
        let numSamples = CMSampleBufferGetNumSamples(sampleBuffer)
        guard numSamples == type(of: self).numSamples else {
            debugPrint("Got unexpented size \(numSamples) samples.")
            return
        }

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            debugPrint("Failed to get CMBlockBuffer of media data.")
            return
        }
        var _dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: nil, dataPointerOut: &_dataPointer)
        guard let dataPointer = _dataPointer else {
            debugPrint("Failed to get DataPointer.")
            return
        }

        vDSP_vflt16(UnsafeRawPointer(dataPointer).bindMemory(to: Int16.self, capacity: numSamples), 1, sampleBufferPointer, 1, vDSP_Length(numSamples))

        delegate?.audioSamplerDidSample(sampleBufferPointer, sampleRate: sampleRate)
    }
}
