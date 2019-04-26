//
//  ViewController.swift
//  AmazonS3MultipleUploadSample
//
//  Created by Jose Manuel Solis Bulos on 4/26/19.
//  Copyright © 2019 manuelbulos. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    lazy var progressViewContainer: ProgressViewContainer = {
        let frame: CGRect = .init(x: 24, y: 24, width: view.frame.width - 48, height: 100)
        let progressViewContainer: ProgressViewContainer = ProgressViewContainer(frame: frame)
        return progressViewContainer
    }()

    lazy var beginUploadButton: UIButton = {
        let frame: CGRect = .init(x: 24, y: progressViewContainer.frame.maxY + 24, width: view.frame.width - 48, height: 100)
        let beginUploadButton: UIButton = .init(frame: frame)
        beginUploadButton.addTarget(self, action: #selector(beginUploadButtonTapped), for: .touchUpInside)
        return beginUploadButton
    }()

    lazy var sampleImage: UIImage = UIImage(named: "sample") ?? UIImage()

    lazy var images: [UIImage] = [sampleImage, sampleImage, sampleImage]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        resumeUpload()
    }

    func setupViews() {
        AmazonS3Manager.shared.delegate = self
        view.addSubview(progressViewContainer)
        view.didAddSubview(beginUploadButton)
    }

    func resumeUpload() {
        AmazonS3Manager.shared.resumeAnyUnfinishedUploads()
    }

    @objc func beginUploadButtonTapped() {
        let onlineFilePaths = AmazonS3Manager.shared.updateLocalFolderAndResumeUpload(images: images)
        print(onlineFilePaths)
    }

}

extension ViewController: AmazonS3ManagerDelegate {
    func progressChanged(_ progress: Float) {
        DispatchQueue.main.async {
            self.progressViewContainer.isHidden = false
            self.progressViewContainer.progressView.progress = progress
            if self.progressViewContainer.label.text?.isEmpty ?? true {
                self.progressViewContainer.label.text = "Upload in progress"
            }
        }
    }

    func statusChanged(_ status: AmazonS3Manager.Status) {
        switch status {
        case .started:
            self.progressViewContainer.isHidden = false
            self.progressViewContainer.label.text = "Upload started"
        case .failed(let error):
            self.progressViewContainer.isHidden = true
            self.progressViewContainer.label.text = "Error: \(error)"
        case .finished(let imagesLeft):
            self.progressViewContainer.isHidden = false
            self.progressViewContainer.label.text = "Pending images: \(imagesLeft)"
        }
    }

    func finishedUploadingImages() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.progressViewContainer.isHidden = true
        }
    }
}
