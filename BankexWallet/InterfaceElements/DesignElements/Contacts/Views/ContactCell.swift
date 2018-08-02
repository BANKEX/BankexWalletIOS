//
//  ContactCellTableViewCell.swift
//  BankexWallet
//
//  Created by Vladislav on 26.07.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit

class ContactCell: UITableViewCell {
    
    @IBOutlet weak var nameContactLabel:UILabel!
    
    
    static var identifier:String {
        return String(describing: self)
    }
    
    
    var contact:FavoriteModel! {
        didSet {
            nameContactLabel.attributedText = prepare()
        }
    }
    
    func prepare() -> NSMutableAttributedString {
        var string:NSMutableAttributedString = NSMutableAttributedString(string: contact.firstName)
        string.append(NSMutableAttributedString(string: " "))
        let attr = [NSAttributedStringKey.font:UIFont.boldSystemFont(ofSize: 17.0)]
        let secondItem = NSMutableAttributedString(string: contact.lastname, attributes: attr)
        string.append(secondItem)
        return string
    }

}
