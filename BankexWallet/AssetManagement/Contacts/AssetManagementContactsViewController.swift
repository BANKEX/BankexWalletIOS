//
//  AssetManagementContactsViewController.swift
//  BankexWallet
//
//  Created by Andrew Kozlov on 28/11/2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit
import MessageUI

class AssetManagementContactsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: BackButtonView.create(self, action: #selector(finish)))
    }
    
    @objc func finish() {
        performSegue(withIdentifier: "Home", sender: self)
    }
    
}

extension AssetManagementContactsViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}
