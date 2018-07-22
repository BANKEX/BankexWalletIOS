//
//  WalletCell.swift
//  BankexWallet
//
//  Created by Vladislav on 22.07.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit

class WalletCell: UITableViewCell {
    
    @IBOutlet weak var nameWalletLabel:UILabel!
    @IBOutlet weak var addressWalletLabel:UILabel!
    
    
    static var identifier:String {
        return String(describing: self)
    }
    
    

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    func configure(wallet:HDKey) {
        nameWalletLabel.text = wallet.name
        addressWalletLabel.text = wallet.address
    }

}
