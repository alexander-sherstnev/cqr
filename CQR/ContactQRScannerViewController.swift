//
//  ContactQRScannerViewController.swift
//  CQR
//
//  Created by Alexander Sherstnev on 5/16/20.
//  Copyright © 2020 Alexander Sherstnev. All rights reserved.
//

import UIKit
import AVFoundation
import Contacts

class ContactQRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var _captureSession: AVCaptureSession!
    var _previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black
        
        _captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (_captureSession.canAddInput(videoInput)) {
            _captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()

        if (_captureSession.canAddOutput(metadataOutput)) {
            _captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        _previewLayer = AVCaptureVideoPreviewLayer(session: _captureSession)
        _previewLayer.frame = view.layer.bounds
        _previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(_previewLayer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (_captureSession?.isRunning == false) {
//            found(code: "{\"firstName\": \"Alexander\", \"lastName\": \"Sherstnev\", \"phone\": \"+375291163946\"}")
            _captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (_captureSession?.isRunning == true) {
            _captureSession.stopRunning()
        }
    }
    
    // MARK: - Methods
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported",
                                   message: "Your device does not support scanning a code from an item. Please use a device with a camera.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        
        _captureSession = nil
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        _captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }

        dismiss(animated: true)
    }
    
    func found(code: String) {
        let decoder = JSONDecoder()
        do {
            let data = Data(code.utf8)
            let contact = try decoder.decode(Contact.self, from: data)
            
            let alert = UIAlertController(title: "Contact Validation",
                                          message: "Please validate contact information.\nFirst Name: \(contact.firstName)\nLast Name: \(contact.lastName)\nPhone: \(contact.phone)",
                preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) {
                [unowned self] action in
                self.navigationController?.popViewController(animated: true)
            }
            
            let saveAction = UIAlertAction(title: "Add", style: .default) {
                [unowned self] action in
                
                let contactEntity = CNMutableContact()
                contactEntity.givenName = contact.firstName
                contactEntity.familyName = contact.lastName
                contactEntity.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberiPhone,
                                                             value: CNPhoneNumber(stringValue: contact.phone))]
                
                let store = CNContactStore()
                let saveRequest = CNSaveRequest()
                saveRequest.add(contactEntity, toContainerWithIdentifier: nil)

                do {
                    try store.execute(saveRequest)
                } catch {
                    print("Saving contact failed, error: \(error)")
                }
                
                self.navigationController?.popToRootViewController(animated: true)
            }
            
            alert.addAction(cancelAction)
            alert.addAction(saveAction)
            
            present(alert, animated: true)
        } catch let error as NSError {
            print("Could not deencode JSON. \(error), \(error.userInfo)")
            navigationController?.popViewController(animated: true)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
