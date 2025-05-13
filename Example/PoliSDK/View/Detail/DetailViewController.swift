//
//  DetailViewController.swift
//  HCBle_Example
//
//  Created by 곽민우 on 2/21/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import CoreBluetooth
import PoliSDK
import UIKit

class DetailViewController: UIViewController {
    @IBOutlet var deviceName: UILabel!
    @IBOutlet var serviceTableView: UITableView!
    @IBOutlet var btnConnect: UIButton!

    var peripheral: CBPeripheral?
    private var services: [CBService] = []
    private var serviceChar: [(myService: CBService, myCharacteristic: CBCharacteristic)] = []
    private var expandedIndexPaths = Set<IndexPath>()

    override func viewDidLoad() {
        super.viewDidLoad()
        serviceTableView.delegate = self
        serviceTableView.dataSource = self
        deviceName.text = peripheral?.name
    }

    private func setConnectionState(isConnected: Bool) {
        if isConnected {
            print("Successfully connected to \(peripheral?.name ?? "Unknown Device")")
            // Set button to white background with blue text
            btnConnect.tintColor = .white
            btnConnect.setTitleColor(.systemBlue, for: .normal)
            btnConnect.setTitle("Disconnect", for: .normal)
        } else {
            print("Disconnected or failed to connect")
            // Set button to blue background with white text
            btnConnect.tintColor = .systemBlue
            btnConnect.setTitleColor(.white, for: .normal)
            btnConnect.setTitle("Connect", for: .normal)
        }

        btnConnect.layer.borderWidth = 1
        btnConnect.layer.borderColor = UIColor.tintColor.cgColor
        btnConnect.layer.cornerRadius = 8
    }

    @IBAction func onClickConnect(_ sender: UIButton) {
        if let peripheral = peripheral {
            if PoliBLE.shared.isConnected(uuid: peripheral.identifier) {
                PoliBLE.shared.disconnect(uuid: peripheral.identifier)
            } else {
                PoliBLE.shared.connect(
                    peripheral: peripheral,
                    onConnState: { isConnected, error in
                        if isConnected {
                            print("Successfully connected to \(peripheral.name ?? "Unknown Device")")

                        } else {
                            print("Failed to connect: \(error?.localizedDescription ?? "Unknown error")")

                            // Clear the table view data source
                            self.serviceChar.removeAll()
                            self.serviceTableView.reloadData()
                        }

                        // Set button to white background with blue text
                        self.setConnectionState(isConnected: isConnected)
                    },
                    onDiscoverCharacteristics: { service, characteristics in
                        for charac in characteristics {
                            self.serviceChar.append((service, charac))
                        }
                        self.serviceTableView.reloadData()
                    },
                    onSubscriptionState: { state in
                        print("Subscription state: \(state)")
                    },

                    onReceiveSubscribtionData: { type, data in
                        print("protocol type: \(type)")
                        print("onReceive Data: \(String(describing: data))")

                        switch type {
                            case .PROTOCOL_1:
                                print("Received Protocol 01 Data")
                                let response: DailyProtocol01Response = data as! DailyProtocol01Response
                                print("Data: \(String(describing: response.data))")
                                print("lux: \(String(describing: response.data?.ltmModel.lux))")
                                print("mets: \(String(describing: response.data?.ltmModel.mets))")
                                print("skinTemp: \(String(describing: response.data?.ltmModel.skinTemp))")

                            case .PROTOCOL_2:
                                print("Received Protocol 02 Data")
                                let response: DailyProtocol02Response = data as! DailyProtocol02Response
                                print("userSystolic: \(String(describing: response.data?.userSystolic))")
                                print("userDiastolic: \(String(describing: response.data?.userDiastolic))")
                                print("userStress: \(String(describing: response.data?.userStress))")
                                print("userHighGlucose: \(String(describing: response.data?.userHighGlucose))")
                            case .PROTOCOL_3:
                                print("Received Protocol 03 Data")
                                let response: DailyProtocol03Response = data as! DailyProtocol03Response
                                print("heartRate: \(String(describing: response.data?.hrSpO2.heartRate))")
                                print("spo2: \(String(describing: response.data?.hrSpO2.spo2))")

                            case .PROTOCOL_1_ERROR:
                                print("Received Protocol 01 Error Data")

                            case .PROTOCOL_2_ERROR_LACK_OF_DATA:
                                print("Received Protocol 02 Error Data")

                            case .PROTOCOL_2_ERROR:
                                print("Received Protocol 02 Error Data")

                            case .PROTOCOL_2_START:
                                print("Received Protocol 02 Start Data")

                            case .PROTOCOL_3_ERROR:
                                print("Received Protocol 03 Error Data")

                            case .PROTOCOL_4_SLEEP_START:
                                print("Received Protocol 04 Sleep Start Data")

                            case .PROTOCOL_4_SLEEP_START_ERROR:
                                print("Received Protocol 04 Sleep Start Error Data")

                            case .PROTOCOL_5_SLEEP_END:
                                print("Received Protocol 05 Sleep End Data")
                                let response: SleepStopResponse = data as! SleepStopResponse
                                print("sleepQuality: \(String(describing: response.data?.sleepQuality))")

                            case .PROTOCOL_5_SLEEP_END_ERROR:
                                print("Received Protocol 05 Sleep End Error Data")

                            case .PROTOCOL_6:
                                print("Received Protocol 06 Data")

                            case .PROTOCOL_6_ERROR:
                                print("Received Protocol 06 Error Data")

                            case .PROTOCOL_7:
                                print("Received Protocol 07 Data")

                            case .PROTOCOL_7_ERROR:
                                print("Received Protocol 07 Error Data")

                            case .PROTOCOL_8:
                                print("Received Protocol 08 Data")

                            case .PROTOCOL_8_ERROR:
                                print("Received Protocol 08 Error Data")

                            case .PROTOCOL_9:
                                print("Received Protocol 09 Data")

                            case .PROTOCOL_9_ERROR:
                                print("Received Protocol 09 Error Data")
                        }
                    }
                )
            }

        } else {
            print("Error")
        }
    }
}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serviceChar.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = serviceTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ServiceTableViewCell

        let service = serviceChar[indexPath.row].myService
        let characteristics = serviceChar[indexPath.row].myCharacteristic

        cell.labelServiceUUID.text = "Service: " + service.uuid.uuidString
        cell.labelCharUUID.text = " - Char: " + characteristics.uuid.uuidString

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRow = serviceChar[indexPath.row]

        guard let nextVC = storyboard?.instantiateViewController(withIdentifier: "CharDetailViewController") as? CharDetailViewController else { return }
        nextVC.uuid = peripheral?.identifier
        nextVC.service = selectedRow.myService
        nextVC.characteristic = selectedRow.myCharacteristic
        navigationController?.pushViewController(nextVC, animated: true)
    }
}

extension DetailViewController: UITableViewDelegate {}
