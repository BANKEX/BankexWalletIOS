//
//  QRButton.swift
//  BankexWallet
//
//  Created by Vladislav on 17.09.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit

class QRButton:UIButton {
    override func awakeFromNib() {
        self.layer.borderColor = WalletColors.mainColor.cgColor
        self.layer.borderWidth = 2.0
        self.layer.cornerRadius = 8.0
    }
}
