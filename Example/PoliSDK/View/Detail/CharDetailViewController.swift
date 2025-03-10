//
//  CharDetailViewController.swift
//  HCBle_Example
//
//  Created by 곽민우 on 2/26/25.
//  Copyright © 2025 CocoaPods. All rights reserved.
//

import CoreBluetooth
import PoliSDK
import UIKit

class CharDetailViewController: UIViewController {
    @IBOutlet var lblChar: UILabel!
    var uuid: UUID!
    var service: CBService!
    var characteristic: CBCharacteristic!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        lblChar.text = characteristic.uuid.uuidString
        PoliBLE.shared.setService(uuid: uuid, service: service)
        PoliBLE.shared.setChar(uuid: uuid, characteristic: characteristic)

        PoliAPI.shared.initialize(
            baseUrl: "https://mapi.health-on.co.kr/poli",
            clientId: "659c95fd-900a-4a9a-8f61-1888334a3c7b",
            clientSecret: "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJpbmZyYSI6IkhlYWx0aE9uLUxpdmUiLCJjbGllbnQtaWQiOiI2NTljOTVmZC05MDBhLTRhOWEtOGY2MS0xODg4MzM0YTNjN2IifQ.GV8Fg5pY-08GlZI0UUFLIqtrmlwnU7kQ-soN6VFlj_usXBex7mv3-vjkAZxV5Yb2MMecifUqwOQpikyirX9aBw"
        )
    }

    @IBAction func onClickWrite(_ sender: UIButton) {
        print("123")
    }

    @IBAction func onClickRead(_ sender: UIButton) {
        PoliBLE.shared.readData(uuid: uuid)
    }

    @IBAction func onClickSubscribe(_ sender: UIButton) {
        PoliBLE.shared.enableNotifications(uuid: uuid)
    }

    @IBAction func onClickP1(_ sender: UIButton) {
        print("onClick P1")
        PoliAPI.shared.requestProtocol01 { response in
            print(response)
        }
    }

    @IBAction func onClickP2(_ sender: UIButton) {
        print("onClick P2")
    }

    @IBAction func onClickP3(_ sender: UIButton) {
        print("onClick P3")
    }

    @IBAction func onClickP4(_ sender: UIButton) {
        print("onClick P4")
        PoliAPI.shared.requestSleepStart { response in
            print("requestSleepStart Response :\(response)")
            print("retCd: \(response.retCd)")
            print("retMsg: \(response.retMsg)")
            print("data: \(response.data?.sessionId ?? "")")
        }
    }

    @IBAction func onClickP5(_ sender: UIButton) {
        print("onClick P5")
        PoliAPI.shared.requestSleepStop { response in
            print("retCd: \(response.retCd)")
            print("retMsg: \(response.retMsg)")
            print("data: \(response.data?.sleepQuality ?? 0)")
        }
    }

    @IBAction func onClickP6(_ sender: UIButton) {
        print("onClick P6")
        PoliAPI.shared.requestSleepProtocol06 { response in
            print("retCd: \(response.retCd)")
            print("retMsg: \(response.retMsg)")
            print("data: \(response.data?.sessionId ?? "")")
        }
    }

    @IBAction func onClickP7(_ sender: UIButton) {
        print("onClick P7")
    }

    @IBAction func onClickP8(_ sender: UIButton) {
        print("onClick P8")
    }

    @IBAction func onClickP9(_ sender: UIButton) {
        print("onClick P9")
        let data = [
            "oxygenVal": 50,
            "heartRateVal": 60
        ]
        PoliAPI.shared.requestSleepProtocol09(data: data) { response in
            print("retCd: \(response.retCd)")
            print("retMsg: \(response.retMsg)")
            print("data: \(response.data?.sessionId ?? "")")
        }
    }
}
