//
//  SettingsViewController.swift
//  BankexWallet
//
//  Created by Vladislav on 21.07.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit


class SettingsViewController: UITableViewController,NetworkDelegate,WalletsDelegate {
    func didTapped(with wallet: HDKey) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func didTapped(with network: CustomNetwork) {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    @IBOutlet weak var nameWalletLabel:UILabel!
    @IBOutlet weak var nameNetworkLabel:UILabel!
    
    
    
    let managerReferences = ManagerReferences()
    let walletService = SingleKeyServiceImplementation()
    let networkService = NetworksServiceImplementation()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.topItem?.title = "Settings"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = true
        }
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 11.0, *) {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }
    
    
    
    
    


    
    func updateUI() {
        guard let selectedWallet = walletService.selectedWallet() else { return  }
        nameWalletLabel.text = selectedWallet.name ?? selectedWallet.address
        nameNetworkLabel.text = networkService.preferredNetwork().networkName ?? networkService.preferredNetwork().fullNetworkUrl.absoluteString
    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "networkSegue" {
            let dest = segue.destination as! NetworksViewController
            dest.delegate = self
        }else if segue.identifier == "walletSegue" {
            let dest = segue.destination as! WalletsViewController
            dest.delegate = self
        }
    }
    
    
}
