//
//  ContactQRViewController.swift
//  CQR
//
//  Created by Alexander Sherstnev on 5/16/20.
//  Copyright © 2020 Alexander Sherstnev. All rights reserved.
//

import UIKit

class ContactQRViewController: UIViewController {
    
    @IBOutlet weak var _QRImage: UIImageView!
    var contact: Contact?

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            let jsonData = try JSONEncoder().encode(contact)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            
            guard let QRFilter = CIFilter(name: "CIQRCodeGenerator") else { return }
            QRFilter.setValue(jsonString.data(using: .ascii), forKey: "inputMessage")
            
            guard let QRImage = QRFilter.outputImage else { return }
            
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledQRImage = QRImage.transformed(by: transform)
            
            let context = CIContext()
            guard let cgImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent) else { return }
            _QRImage.image = UIImage(cgImage: cgImage)
        } catch let error as NSError {
            print("Could not encode JSON. \(error), \(error.userInfo)")
        }
    }
}
