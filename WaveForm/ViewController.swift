//
//  ViewController.swift
//  WaveForm
//
//  Created by David Kyslenko on 31.10.2022.
//

import UIKit
import SnapKit
import AVFoundation
import MobileCoreServices

class ViewController: UIViewController {
    private let playerUnderlyView = UIView()
    private let uploadAudioButton = UIButton()
    private let activityIndicator = UIActivityIndicatorView()

    private var waveView: ScrollableWaveformView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "1A1B1E")

        view.addSubview(playerUnderlyView)

        playerUnderlyView.layer.cornerRadius = 10
        playerUnderlyView.backgroundColor = .white
        playerUnderlyView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalToSuperview().offset(45)
            make.right.equalToSuperview().inset(45)
            
            let height = self.calculateHeightMultiplier(508)
            make.height.equalTo(height)
        }
        
        playerUnderlyView.addSubview(activityIndicator)
        activityIndicator.hidesWhenStopped = true
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        waveView = ScrollableWaveformView()
        
        view.addSubview(waveView)
        waveView.snp.makeConstraints { make in
            make.top.equalTo(playerUnderlyView.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
            make.height.equalTo(100)
        }
        
        view.addSubview(uploadAudioButton)
        uploadAudioButton.addTarget(self, action: #selector(didTapUploadAudioButton), for: .touchUpInside)
        uploadAudioButton.setTitle("Upload audio", for: .normal)
        uploadAudioButton.layer.cornerRadius  = 22
        uploadAudioButton.layer.borderColor = UIColor.white.cgColor
        uploadAudioButton.layer.borderWidth = 1
        uploadAudioButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(44)
            make.width.equalTo(150)
        }

        self.waveView.drawWaveformView(values: firstDemoPoints)
    }
    
    @objc func didTapUploadAudioButton() {
        print(#function)
        let pickerController = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
        pickerController.delegate = self
        pickerController.modalPresentationStyle = .fullScreen
        self.present(pickerController, animated: true, completion: nil)
    }
    
    
}

extension ViewController: UIDocumentPickerDelegate{
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]){
        activityIndicator.startAnimating()
        controller.dismiss(animated: true)
        
        if let firstUrl = urls.first {
            let exporter = AudioExporter()
            let asset = AVAsset(url: firstUrl)
            
            let _ = exporter.load(from: asset) { _ in
                DispatchQueue.main.async {
                    self.waveView.removeFromSuperview()
                    self.waveView = nil
                    
                    self.waveView = ScrollableWaveformView()
                    
                    self.view.addSubview(self.waveView)
                    self.waveView.snp.makeConstraints { make in
                        make.top.equalTo(self.playerUnderlyView.snp.bottom).offset(30)
                        make.left.right.equalToSuperview()
                        make.height.equalTo(100)
                    }
                    self.waveView.drawWaveformView(values: exporter.resultPoints)
                    self.activityIndicator.stopAnimating()
                }
            }

        }
    }
}
