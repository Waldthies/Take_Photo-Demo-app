//
//  CameraManager.swift
//  Take_Photo
//
//  Created by Thies Josten on 16.11.26.
//


import AVFoundation
import UIKit

class CameraManager: NSObject, ObservableObject {
    
    
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    
    @Published var isSessionRunning: Bool = false
    
    override init() {
            super.init()
        }

        // Asks for permission to use camera of the device. -> Make sure you set a camera usage description in your xcodeproj file
        func checkPermissions() async -> Bool {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            switch status {
                case .authorized:
                    return true
                case .notDetermined:
                    return await AVCaptureDevice.requestAccess(for: .video)
                default:
                    return false
            }
        }
    
        func configureSession() async -> Bool {
            guard await checkPermissions() else { return false }
            do {
                try setupCaptureDevice()
                return true
            } catch {
                print("Failed to setup camera session: \(error)")
                return false
            }
        }
        
        //Main function setting up all the stream we will use for input and output
        private func setupCaptureDevice() throws {
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            
            session.sessionPreset = .photo

            // We use a static back camera, you would want this to be changeable in any real camera app -> see presentation
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                throw CameraError.deviceUnavailable
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }
        }

        func startSession() {
            guard !session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
                Task { @MainActor in
                    self?.isSessionRunning = true
                }
            }
        }

        func stopSession() {
            guard session.isRunning else { return }
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.stopRunning()
                Task { @MainActor in
                    self?.isSessionRunning = false
                }
            }
        }
        
        func capturePhoto() async throws -> UIImage {
            return try await withCheckedThrowingContinuation { continuation in
                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                output.capturePhoto(with: settings, delegate: self)
            }
        }
    
    }

    extension CameraManager: AVCapturePhotoCaptureDelegate {
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let error = error {
                photoContinuation?.resume(throwing: error)
                photoContinuation = nil
                return
            }

            guard let imageData = photo.fileDataRepresentation(),
                  let image = UIImage(data: imageData) else {
                photoContinuation?.resume(throwing: CameraError.imageConversionFailed)
                photoContinuation = nil
                return
            }

            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }

    enum CameraError: Error {
        case deviceUnavailable
        case imageConversionFailed
    }

