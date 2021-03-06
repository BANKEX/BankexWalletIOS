//
//  HDWalletService.swift
//  BankexWallet
//
//  Created by Korovkina, Ekaterina on 3/11/2561 BE.
//  Copyright © 2561 Alexander Vlasov. All rights reserved.
//

import Foundation
import web3swift
import SugarRecord

struct HDKey {
    let name: String?
    let address: String
}

enum HDWalletCreationError: Error {
    case creationError
}


// TODO: Add separate methods for getting only hd/ non-hd keys list
protocol GlobalWalletsService {
    func keystoreManager() -> KeystoreManager
    func fullHDKeysList() -> [HDKey]?
    func fullListOfSingleEthereumAddresses() -> [HDKey]?
    func fullListOfWallets() -> [HDKey]?
    func selectedAddress() -> String?
    func selectedKey() -> HDKey?
    func updateSelected(address: String)
    func delete(address: String)
    func selectedWallet() -> KeyWalletModel?
    func selectedWalletFromDB() -> KeyWalletModel?
    func keystoreManager(forAddress address: String) -> KeystoreManager
    func walletFromDB(forAddress address: String) -> KeyWalletModel?
}

extension GlobalWalletsService {
    func keystoreManager() -> KeystoreManager {
        guard let selectedAddress = selectedWallet(), let data = selectedAddress.data else {
            // TODO: Delete all !
            return KeystoreManager.defaultManager!
        }
        if selectedAddress.isHD {
            return KeystoreManager([BIP32Keystore(data)!])
        } else {
            return KeystoreManager([EthereumKeystoreV3(data)!])
        }
    }
    
    func keystoreManager(forAddress address: String) -> KeystoreManager {
        guard let wallet = walletFromDB(forAddress: address), let data = wallet.data else {
            return KeystoreManager.defaultManager!
        }
        if wallet.isHD {
            return KeystoreManager([BIP32Keystore(data)!])
        } else {
            return KeystoreManager([EthereumKeystoreV3(data)!])
        }
    }
    
    func walletFromDB(forAddress address: String) -> KeyWalletModel? {
        let key = try! DBStorage.db.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "address == %@", address))).first
        return KeyWalletModel.from(wallet: key)
    }

    func selectedWalletFromDB() -> KeyWalletModel? {
        let key = try! DBStorage.db.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "isSelected == %@", NSNumber(value: true)))).first
        return KeyWalletModel.from(wallet: key)
    }
    
    func selectedKey() -> HDKey? {
        guard let selectedWallet = selectedWallet(), !selectedWallet.address.isEmpty else {
            return nil
        }
        return HDKey(name: selectedWallet.name, address: selectedWallet.address)
    }
    


    func selectedAddress() -> String? {
        let key = try! DBStorage.db.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "isSelected == %@", NSNumber(value: true)))).first
        return key?.address
    }
    
    func fullListOfWallets() -> [HDKey]? {
        guard let allKeys = try? DBStorage.db.fetch(FetchRequest<KeyWallet>()) else {
            return nil
        }
        return allKeys.map({ (wallet) -> HDKey in
            return HDKey(name: wallet.name, address: wallet.address ?? "")
        })
    }
    
    func fullHDKeysList() -> [HDKey]? {
        guard let allKeys = try? DBStorage.db.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "isHD == %@", NSNumber(value: true)))) else {
            return nil
        }
        return allKeys.map({ (wallet) -> HDKey in
            return HDKey(name: wallet.name, address: wallet.address ?? "")
        })
    }
    
    
    func fullListOfSingleEthereumAddresses() -> [HDKey]? {
        guard let allKeys = try? DBStorage.db.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "isHD == %@", NSNumber(value: false)))) else {
            return nil
        }
        return allKeys.map({ (wallet) -> HDKey in
            return HDKey(name: wallet.name, address: wallet.address ?? "")
        })
    }
    
    func updateSelected(address: String) {
        do {
            try DBStorage.db.operation { (context, save) in
                let currentSelected = try context.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "isSelected == %@", NSNumber(value: true)))).first
                guard currentSelected?.address != address else {
                    return
                }
                
                let newSelected = try context.fetch(FetchRequest<KeyWallet>().filtered(with: "address", equalTo: address)).first
                currentSelected?.isSelected = false
                newSelected?.isSelected = true
                save()
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: DataChangeNotifications.didChangeWallet.notificationName(), object: self, userInfo: ["wallet": address])

                }
            }
        } catch {
            
        }
    }
    
    func delete(address: String) {
        do {
            try DBStorage.db.operation({ (context, save) in
                do {
                    guard let keyToDelete = try context.fetch(FetchRequest<KeyWallet>().filtered(with: "address", equalTo: address)).first else {
                        return
                    }
                    try context.remove(keyToDelete)
                    save()
                }

            })
        }
        catch {
            
        }
    }
    
    func clearAllWallets() {
        do {
            try DBStorage.db.operation{ (context, save) in
                
                let keysToDelete = try context.fetch(FetchRequest<KeyWallet>())
                try context.remove(keysToDelete)
                save()
            }
        }
        catch {
            
        }
    }
    
}

/*
    Service for work with HD key wallets
 */
protocol HDWalletService: GlobalWalletsService {
    
    func generateMnemonics(bitsOfEntropy: Int) -> String
    func generateMnemonics() -> String
    
    func createNewHDWallet(with name: String?,
                           mnemonics: String,
                           mnemonicsPassword: String,
                           walletPassword: String,
                           completion: @escaping (String?, Error?) -> Void)
    
    func generateChildNode(with name: String,
                           key: HDKey,
                           password: String,
                           completion: @escaping (String?, Error?) -> Void)
    func updateWalletName(walletAddress: String, newName: String, completion: @escaping (Error?) -> Void)
}

extension HDWalletService {
    
    func generateMnemonics() -> String {
        return generateMnemonics(bitsOfEntropy: 128)
    }
}

/*
 Need to remember, that under the hood might be multiple wallets with multiple keys in each
 */
class HDWalletServiceImplementation: HDWalletService {
    
    private var selectedLocalWallet: KeyWalletModel?
    
    func selectedWallet() -> KeyWalletModel? {
        return  selectedLocalWallet
    }
    
    init() {
        selectedLocalWallet = selectedWalletFromDB()
        NotificationCenter.default.addObserver(forName: DataChangeNotifications.didChangeWallet.notificationName(), object: nil, queue: nil) { (_) in
            self.selectedLocalWallet = self.selectedWalletFromDB()
        }
    }
    
    func generateMnemonics(bitsOfEntropy: Int) -> String {
        guard let mnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: bitsOfEntropy),
            let unwrapped = mnemonics else {
            return ""
        }
        return unwrapped
    }
    
    // After this method should be created new wallet with only one root address
    func createNewHDWallet(with name: String?,
                           mnemonics: String,
                           mnemonicsPassword: String,
                           walletPassword: String,
                           completion: @escaping (String?, Error?) -> Void) {
        // TODO: smth strange is here with throwing
        do {
            DispatchQueue.global(qos: .userInitiated).async {
                if let keystore = try? BIP32Keystore(mnemonics: mnemonics,
                                                        password: walletPassword,
                                                        mnemonicsPassword: mnemonicsPassword,
                                                        language: .english),
                    let wallet = keystore {
                    self.saveWalletInfo(name: name, wallet: wallet, completion: completion)
                }
            }
        }
        catch (let error) {
            completion(nil, error)
        }
    }
    
    func updateWalletName(name:String, address:String,completion:@escaping (Error?)->Void) {
        do {
            try db.operation({ (context, save) in
                if let data = try? context.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "address == %@", address))).first {
                    data?.name = name
                    save()
                    completion(nil)
                }else {
                    completion(NSError())
                }
            })
        }catch let error {
            completion(error)
        }
    }
    
    func updateSelectedWallet() {
        selectedLocalWallet = selectedWalletFromDB()
    }
    

    func generateChildNode(with name: String,
                           key: HDKey,
                           password: String,
                           completion: @escaping (String?, Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.db.operation({ (context, save) in
                    guard let foundKey = try context.fetch(FetchRequest<KeyWallet>().filtered(with: "address", equalTo: key.address)).first, let data = foundKey.data else {
                        DispatchQueue.main.async {
                            completion(nil, nil)
                        }
                        return
                    }
                    
                    let wallet = BIP32Keystore(data)
                    try wallet?.createNewChildAccount(password: password)
                    guard let allAddresses = wallet?.addresses?.compactMap({ (ethAddress) -> String? in
                        return ethAddress.address
                    }) else {
                        DispatchQueue.main.async {
                            completion(nil, nil)
                        }
                        return
                    }
                    let allStored = try context.fetch(FetchRequest<KeyWallet>()).compactMap({ (key) -> String? in
                        return key.address
                    })
                    let addressINeed = Set(allAddresses).subtracting(Set(allStored))
                    guard addressINeed.count == 1 else {
                        DispatchQueue.main.async {
                            completion(nil, nil)
                        }
                        return
                    }
                    //TODO: Fix me
                    let newChild: KeyWallet = try context.new()
                    newChild.name = name
                    newChild.isHD = true
                    newChild.isSelected = false
                    newChild.parentKey = foundKey
                    newChild.address = addressINeed.first
//                    updateSelected(address: address)
//                    newChild.data =
//                    save()
//                    DispatchQueue.main.async {
//                        completion(nil, nil)
//                    }
//                    return
                })
            }
            catch (let error) {
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
            
        }
    }
    
    func updateWalletName(walletAddress: String, newName: String, completion: @escaping (Error?) -> Void) {
        do {
            try DBStorage.db.operation { (context, save) in
                let currentSelected = try context.fetch(FetchRequest<KeyWallet>().filtered(with: NSPredicate(format: "address == %@", walletAddress))).first
                currentSelected?.name = newName
                save()
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } catch {
            DispatchQueue.main.async {
                completion(error)
            }
        }
            
    }
    
    
    // MARK: Private Part
    let db = DBStorage.db
    
    // TODO: Write me please
    //    private func saveChildWallet()
    
    // This is saving of parent HD wallet
    private func saveWalletInfo(name: String?,
                                wallet: BIP32Keystore,
                                completion: @escaping (String?, Error?) -> Void) {
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.db.operation { (context, save) in
                    guard let keydata = try? JSONEncoder().encode(wallet.keystoreParams) else {
                        throw HDWalletCreationError.creationError
                    }
                    let newWallet: KeyWallet = try context.new()
                    newWallet.name = name
                    newWallet.address = wallet.addresses?.first?.address
                    newWallet.isHD = true
                    newWallet.isSelected = false
                    newWallet.data = keydata
                    try context.insert(newWallet)
                    save()
                    self.updateSelected(address: wallet.addresses?.first?.address ?? "")
                    DispatchQueue.main.async {
                        completion(wallet.addresses?.first?.address, nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, HDWalletCreationError.creationError)
                }
            }
        }
    }
}
