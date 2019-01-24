//
//  MainViewController.swift
//  Pixelizator
//
//  Created by Greg on 1/10/19.
//  Copyright © 2019 GS. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import PKHUD

final class MainViewController: UIViewController {
    
    @IBOutlet private weak var pixelSizeSlider: UISlider!
    @IBOutlet private weak var backgroundImageView: UIImageView!
    @IBOutlet private weak var previewImageView: UIImageView!
    private var sourceImage: UIImage!
    private var lastPixelizationTimestamp: TimeInterval?

    override func viewDidLoad() {
        super.viewDidLoad()
        let randomNumber = Int.random(in: 1 ..< 6)
        setImage(image: UIImage(named: "Example\(randomNumber)")!, animated: false)
    }
    
    //MARK: - IBActions
    
    @IBAction func sliderAction(_ sender: UISlider) {
        pixelizeImage(pixelSize: CGFloat(pixelSizeSlider.value))
    }
    
    @IBAction func loadAction(_ sender: UIButton) {
        tryToLoadGallery()
    }
    
    @IBAction func saveAction(_ sender: UIButton) {
        UIImageWriteToSavedPhotosAlbum(previewImageView.image!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //MARK: - Action logic
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if error != nil {
            HUD.flash(.labeledError(title: "Error", subtitle: "Try again!"), delay: popupDelay)
        } else {
            HUD.flash(.label("Saved to the gallery!"), delay: popupDelay)
        }
    }
    
    private func tryToLoadGallery() {
        func handleStatus(status: PHAuthorizationStatus) {
            if status == .authorized{
                self.loadGallery()
            } else {
                self.showPermissionPrompt()
            }
        }
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                handleStatus(status: status)
            })
        } else {
            handleStatus(status: status)
        }
    }
    
    private func loadGallery() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = UIImagePickerController.SourceType.savedPhotosAlbum
        present(imagePickerController, animated: true, completion: nil)
    }
    
    private func showPermissionPrompt() {
        let alertController = UIAlertController(title: "Allow Camera Roll Access", message:
            "Photos access is necessary for this app to run.", preferredStyle: UIAlertController.Style.alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            if let url = URL(string:UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    private func setImage(image: UIImage, animated: Bool) {
        let scale: CGFloat = previewImageView.frame.width/image.size.width
        let screenScale = UIScreen.main.scale
        let adjustedImage = image.resize(scaleX: scale/screenScale, scaleY: scale/screenScale, interpolation: .default)
        
        backgroundImageView.image = adjustedImage
        sourceImage = adjustedImage
        showImage(image: image, animated: animated)
        pixelizeImage(pixelSize: CGFloat(pixelSizeSlider.value))
    }
    
    private func pixelizeImage(pixelSize: CGFloat) {
        if lastPixelizationTimestamp == nil || NSDate().timeIntervalSince1970 > lastPixelizationTimestamp! + pixelizationUpdateThreshold {
            DispatchQueue.global(qos: .background).async {
                let pixeletedImage = self.sourceImage.pixelize(pixelSize: pixelSize)
                DispatchQueue.main.async {
                    self.showImage(image: pixeletedImage, animated: true)
                    self.previewImageView.image = pixeletedImage
                }
            }
            lastPixelizationTimestamp = NSDate().timeIntervalSince1970
        }
    }
    
    private func showImage(image: UIImage, animated: Bool) {
        if animated {
            UIView.transition(with: self.previewImageView,
                              duration: imageTransitionAnimationTime,
                              options: .transitionCrossDissolve,
                              animations: { self.previewImageView.image = image },
                              completion: nil)
        } else {
            self.previewImageView.image = image
        }
    }
}

extension MainViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            pixelSizeSlider.value = 0
            setImage(image: image, animated: true)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
