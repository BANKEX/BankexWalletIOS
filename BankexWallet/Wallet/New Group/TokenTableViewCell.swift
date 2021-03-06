//
//  TokenTableViewCell.swift
//  BankexWallet
//
//  Created by Vladislav on 12.09.2018.
//  Copyright © 2018 Alexander Vlasov. All rights reserved.
//

import UIKit
import web3swift

class TokenTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tokenImageView:UIImageView!
    @IBOutlet weak var balanceToken:UILabel!
    @IBOutlet weak var symbolToken:UILabel!
    @IBOutlet weak var nameToken:UILabel!
    @IBOutlet weak var addressToken:UILabel!
    @IBOutlet weak var tokenAddedImage:UIImageView!
    @IBOutlet weak var fillView:UIView!
    @IBOutlet weak var arrowRight:UIImageView!
    @IBOutlet weak var leftContraint:NSLayoutConstraint!
    @IBOutlet weak var rightContraint:NSLayoutConstraint!
    
    static let identifier:String = String(describing: TokenTableViewCell.self)
    let keysService = SingleKeyServiceImplementation()
    var isSearchable = false
    let service = CustomTokenUtilsServiceImplementation()
    var isBKXToken:Bool {
        return token.symbol == "BKX"
    }

    
    var token:ERC20TokenModel! {
        didSet {
            configure()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        leftContraint.constant = UIDevice.isIpad ? 52 : 15
        rightContraint.constant = UIDevice.isIpad ? 52 : 15
        fillView.setupDefaultShadow()
        fillView.layer.cornerRadius = 8.0
        selectionStyle = .none
        backgroundColor = UIColor.bgMainColor
        tokenAddedImage.isHidden = true
    }

    func configure() {
        if isSearchable {
            tokenAddedImage.isHidden = token.isAdded ? false : true
            arrowRight.isHidden = true
            symbolToken.isHidden = true
            balanceToken.isHidden = true
            addressToken.isHidden = false
        }else {
            arrowRight.isHidden = false
            symbolToken.isHidden = false
            balanceToken.isHidden = false
            addressToken.isHidden = true
        }
        isBKXToken ? tokenImageView.setBKXImage() : tokenImageView.setTokenImage(tokenAddress: token.address)
        addressToken.text = token.address.formattedAddrToken()
        nameToken.text = token.name
        symbolToken.text = token.symbol.uppercased()
        
        service.getBalance(for: token.address, address: keysService.selectedAddress() ?? "") { (result) in

            switch result {
            case .Success(let response):
                // TODO: it shouldn't be here anyway and also, lets move to background thread
                let formattedAmount = Web3.Utils.formatToEthereumUnits(response,
                                                                        toUnits: .eth,
                                                                        decimals: 8)
                self.balanceToken.text = formattedAmount!
            case .Error( _):
                self.balanceToken.text = "..."
            }
        }
        if !self.isSearchable {
            let tokenShort = TokenShort(name: self.token.name, balance: balanceToken.text!)
            if !TokenShortService.arrayTokensShort.contains(tokenShort) {
                TokenShortService.arrayTokensShort.append(tokenShort)
            }
        }
    }
    
}
