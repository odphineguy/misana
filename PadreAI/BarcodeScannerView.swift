//
//  BarcodeScannerView.swift
//  MiSana
//
//  Created by Abe Perez on 3/19/26.
//

import SwiftUI
import AVFoundation
import UIKit

struct BarcodeScannerView: UIViewControllerRepresentable {
    var selectedLanguage: AppLanguage = .spanish
    let onBarcodeFound: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerViewController {
        let vc = BarcodeScannerViewController()
        vc.selectedLanguage = selectedLanguage
        vc.onBarcodeFound = onBarcodeFound
        vc.onCancel = onCancel
        return vc
    }

    func updateUIViewController(_ uiViewController: BarcodeScannerViewController, context: Context) {}
}

class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var selectedLanguage: AppLanguage = .spanish
    var onBarcodeFound: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var hasFoundBarcode = false
    private var isShowingDeniedState = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraAuthorization()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isShowingDeniedState && !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - Authorization

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
            setupOverlay()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                        self?.setupOverlay()
                        DispatchQueue.global(qos: .userInitiated).async {
                            self?.captureSession.startRunning()
                        }
                    } else {
                        self?.showPermissionDeniedState()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedState()
        @unknown default:
            showPermissionDeniedState()
        }
    }

    private func showPermissionDeniedState() {
        isShowingDeniedState = true
        view.backgroundColor = UIColor.systemBackground
        let isSpanish = selectedLanguage == .spanish

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let icon = UIImageView(image: UIImage(systemName: "camera.metering.unknown"))
        icon.tintColor = .systemOrange
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalToConstant: 64).isActive = true

        let title = UILabel()
        title.text = isSpanish ? "Acceso a la cámara denegado" : "Camera access denied"
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textColor = .label
        title.textAlignment = .center
        title.numberOfLines = 0

        let message = UILabel()
        message.text = isSpanish ?
            "Para escanear códigos de barras de medicinas, MiSana necesita acceso a la cámara. Puedes activarlo en Ajustes." :
            "To scan medication barcodes, MiSana needs camera access. You can enable it in Settings."
        message.font = .systemFont(ofSize: 15)
        message.textColor = .secondaryLabel
        message.textAlignment = .center
        message.numberOfLines = 0

        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle(isSpanish ? "Abrir Ajustes" : "Open Settings", for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        settingsButton.backgroundColor = UIColor(named: "BrandColor") ?? .systemBlue
        settingsButton.setTitleColor(.white, for: .normal)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)
        settingsButton.layer.cornerRadius = 12
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(isSpanish ? "Cancelar" : "Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(message)
        stack.setCustomSpacing(24, after: message)
        stack.addArrangedSubview(settingsButton)
        stack.addArrangedSubview(cancelButton)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    @objc private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showPermissionDeniedState()
            return
        }

        if captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            metadataOutput.metadataObjectTypes = [
                .ean13,
                .upce
            ]
        }

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.addSublayer(preview)
        previewLayer = preview
    }

    private func setupOverlay() {
        let isSpanish = selectedLanguage == .spanish

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(isSpanish ? "Cancelar" : "Cancel", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancelButton)

        let label = UILabel()
        label.text = isSpanish ?
            "Apunta al código de barras del frasco" :
            "Point at the barcode on the bottle"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let frameView = UIView()
        frameView.layer.borderColor = UIColor.white.cgColor
        frameView.layer.borderWidth = 2
        frameView.layer.cornerRadius = 12
        frameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(frameView)

        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            frameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            frameView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            frameView.heightAnchor.constraint(equalToConstant: 120),

            label.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 24),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc private func cancelTapped() {
        onCancel?()
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasFoundBarcode,
              let metadata = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = metadata.stringValue else { return }

        hasFoundBarcode = true
        captureSession.stopRunning()

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        onBarcodeFound?(value)
    }
}
