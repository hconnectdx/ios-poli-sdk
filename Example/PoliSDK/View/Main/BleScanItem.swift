//
//  BleScanItem.swift
//  HCBle_Example
//
//  Created by 곽민우 on 2/20/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import CoreBluetooth
import Foundation

class BleScanItem {
    init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }

    var peripheral: CBPeripheral?
    var advertisementData: [String: Any]?
    var rssi: NSNumber?
}
