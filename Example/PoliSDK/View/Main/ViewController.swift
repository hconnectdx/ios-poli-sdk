//
//  ViewController.swift
//  HCBle
//
//  Created by x-oauth-basic on 02/20/2025.
//  Copyright (c) 2025 x-oauth-basic. All rights reserved.
//

import CoreBluetooth
import PoliSDK
import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet var tableView: UITableView!

    private var scannedPeripherals: [BleScanItem] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func onClickScan(_ sender: UIButton) {
        PoliBLE.shared.scan { peripheral, advertisementData, rssi in

//            guard let self = self else { return }

            if !self.scannedPeripherals.contains(where: { $0.peripheral?.identifier == peripheral.identifier }) && peripheral.name != nil {
//                print("peripheral: \(peripheral)")
//                print("advertisementData: \(advertisementData)")
//                print("rssi: \(rssi)")

                let newScanItem = BleScanItem(peripheral: peripheral, advertisementData: advertisementData, rssi: rssi)
                self.scannedPeripherals.append(newScanItem)
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }

    // MARK: - 데이타소스

    // Section : Grouped Tableview
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedPeripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "MyTableViewCell", for: indexPath) as! MyTableViewCell
        cell.deviceName.text = scannedPeripherals[indexPath.row].peripheral?.name ?? "Unknown Device"
        cell.selectionStyle = .none

        return cell
    }

    // MARK: - 일반이벤트

    // 셀의 높이값을 리턴
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPeripheral = scannedPeripherals[indexPath.row].peripheral

        guard let nextVC = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else { return }
        nextVC.peripheral = selectedPeripheral!
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
