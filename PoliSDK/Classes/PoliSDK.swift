import CoreBluetooth
import Foundation
import HCBle

public class PoliBLE {
    // MARK: - Singleton
    
    public static let shared = PoliBLE()
    
    private var onConnState: ((Bool, Error?) -> Void)?
    private var onDiscoverServices: (([CBService]) -> Void)?
    private var onDiscoverCharacteristics: ((CBService, [CBCharacteristic]) -> Void)?
    private var onSubscriptionState: ((Bool) -> Void)?
    private var onReceiveSubscribtionData: ((ProtocolType, BaseResponse?) -> Void)?
    private var onReadCharacteristic: (() -> Void)?
    private var onWriteCharacteristic: (() -> Void)?
    
    /// 블루투스 스캔 시작
    /// - Parameter completion: 스캔 결과를 전달하는 콜백
    public func scan(completion: @escaping (CBPeripheral, [String: Any], NSNumber) -> Void) {
        HCBle.shared.scan(callback: completion)
    }
    
    /// 블루투스 스캔 중지
    public func stopScan() {
        // TODO:
    }
    
    /// 특정 기기에 연결
    /// - Parameters:
    ///   - peripheral: 연결할 기기
    ///   - completion: 연결 결과를 전달하는 콜백
    public func connect(
        peripheral: CBPeripheral,
        onConnState: ((Bool, Error?) -> Void)? = nil,
        onDiscoverServices: (([CBService]) -> Void)? = nil,
        onDiscoverCharacteristics: ((CBService, [CBCharacteristic]) -> Void)? = nil,
        onReadCharacteristic: (() -> Void)? = nil,
        onWriteCharacteristic: (() -> Void)? = nil,
        onSubscriptionState: ((Bool) -> Void)? = nil,
        onReceiveSubscribtionData: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        self.onConnState = onConnState
        self.onDiscoverServices = onDiscoverServices
        self.onDiscoverCharacteristics = onDiscoverCharacteristics
        
        self.onReadCharacteristic = onReadCharacteristic
        self.onWriteCharacteristic = onWriteCharacteristic
        
        self.onSubscriptionState = onSubscriptionState
        self.onReceiveSubscribtionData = onReceiveSubscribtionData
        
        HCBle.shared.connect(
            peripheral: peripheral,
            onConnState: onConnState,
            onDiscoverServices: onDiscoverServices,
            onDiscoverCharacteristics: onDiscoverCharacteristics,
            onReadCharacteristic: onReadCharacteristic,
            onWriteCharacteristic: onWriteCharacteristic,
            onSubscriptionState: onSubscriptionState,
            onReceiveSubscribtionData: { data in
                self.handleReceivedData(data: data, onReceiveSubscribtionData: onReceiveSubscribtionData)
            }
        )
    }
    
    /// 연결된 기기 해제
    /// - Parameter peripheral: 해제할 기기
    public func disconnect(from uuid: UUID) {
        HCBle.shared.disconnect(uuid: uuid)
    }
    
    /// 모든 연결 해제
    public func disconnectAll() {
        // TODO:
    }
    
    public func readData(uuid: UUID) {
        HCBle.shared.readData(uuid: uuid)
    }
    
    /** TODO : 개별 디바이스에서 통신하도록 만들어야 함 */
    public func writeData(_ data: Data) {
        // TODO:
    }
    
    public func enableNotifications(uuid: UUID) {
        HCBle.shared.enableNotifications(uuid: uuid)
    }
    
    public func setService(uuid: UUID, service: CBService) {
        HCBle.shared.setService(uuid: uuid, service: service)
    }
    
    public func setChar(uuid: UUID, characteristic: CBCharacteristic) {
        HCBle.shared.setChar(uuid: uuid, characteristic: characteristic)
    }
    
    public func disconnect(uuid: UUID) {
        HCBle.shared.disconnect(uuid: uuid)
    }
    
    public func isConnected(uuid: UUID) -> Bool {
        return HCBle.shared.isConnected(uuid: uuid)
    }
    
    public func getPeripheral(uuid: UUID) -> CBPeripheral? {
        return HCBle.shared.getPeripheral(uuid: uuid)
    }
    
    /// 수신된 데이터 처리
    private func handleReceivedData(
        data: Data,
        onReceiveSubscribtionData: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        guard data.count >= 2 else { return }
        
        let protocolType = data[0]
        let dataOrder = data[1]
        
        print("protocolType: \(protocolType), dataOrder: \(dataOrder)")
        
        switch protocolType {
            case 0x01:
                DailyProtocol01API.shared.categorizeData(data: data)
                if dataOrder == 0xff {
                    DailyProtocol01API.shared.createLTMModel()
                    DailyProtocol01API.shared.request { response in
                        print("DailyProtocol01API response: \(response)")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_1, response)
                    }
                }
            case 0x02:
                
                if DailyProtocol02API.shared.preByte != 0xfe, dataOrder == 0x00 {
                    print("Protocol02 Start")
                    onReceiveSubscribtionData?(ProtocolType.PROTOCOL_2_START, nil)
                }
                DailyProtocol02API.shared.preByte = dataOrder
        
                let removedHeaderData = DailyProtocol02API.shared.removeFrontBytes(data: data, size: 2)
                DailyProtocol02API.shared.addDaily02Byte(data: removedHeaderData)
                
                if dataOrder == 0xff {
                    DailyProtocol02API.shared.request { response in
                        print("DailyProtocol02API response: \(response)")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_2, response)
                    }
                }
            case 0x03:
                do {
                    let hrSpO2Data = try DailyProtocol03API.shared.asciiToHRSpO2(data: data)
                    DailyProtocol03API.shared.request(data: hrSpO2Data) { response in
                        print("DailyProtocol03API response: \(response)")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_3, response)
                    }
                } catch {
                    print("[Error] Failed to parse HRSpO2 data: \(error)")
                    onReceiveSubscribtionData?(ProtocolType.PROTOCOL_3_ERROR, nil)
                }
                
            case 0x04:
                SleepSessionAPI.shared.requestSleepStart { response in
                    if response.retCd != "0" {
                        print("retcd \(response.retCd)시작 실패")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_4_SLEEP_START_ERROR, response)
                    } else {
                        print("retcd \(response.retCd)시작 성공")
                        
                        let sessionId = response.data?.sessionId
                        PoliAPI.shared.sessionId = sessionId ?? ""
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_4_SLEEP_START, response)
                    }
                }
                
            case 0x05:
                SleepSessionAPI.shared.requestSleepStop { response in
                    if response.retCd != "0" {
                        print("retcd \(response.retCd)중지 실패")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_5_SLEEP_END_ERROR, response)
                    } else {
                        print("retcd \(response.retCd)중지 성공")
                        print("sleepQuailty : \(response.data?.sleepQuality ?? 0)")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_5_SLEEP_END, response)
                    }
                }
            case 0x06:
                let removedHeaderData = SleepProtocol06API.shared.removeFrontBytes(data: data, size: 2)
                SleepProtocol06API.shared.addByte(data: removedHeaderData)
                if dataOrder == 0xff {
                    DispatchQueue.global(qos: .background).async {
                        SleepProtocol06API.shared.request { response in
                            print("response: \(response)")
                            onReceiveSubscribtionData?(ProtocolType.PROTOCOL_6, response)
                        }
                    }
                }
                
            case 0x07:
                let removedHeaderData = SleepProtocol07API.shared.removeFrontBytes(data: data, size: 2)
                SleepProtocol07API.shared.addByte(data: removedHeaderData)
                
                if dataOrder == 0xff {
                    DispatchQueue.global(qos: .background).async {
                        SleepProtocol07API.shared.request { response in
                            print("response: \(response)")
                            onReceiveSubscribtionData?(ProtocolType.PROTOCOL_7, response)
                        }
                    }
                } else {}
                
            case 0x08:
                let removedHeaderData = SleepProtocol06API.shared.removeFrontBytes(data: data, size: 2)
                SleepProtocol08API.shared.addByte(data: removedHeaderData)
                
                if dataOrder == 0xff {
                    DispatchQueue.global(qos: .background).async {
                        SleepProtocol08API.shared.request { response in
                            print("response: \(response)")
                            onReceiveSubscribtionData?(ProtocolType.PROTOCOL_8, response)
                        }
                    }
                } else {}
            case 0x09:
                DispatchQueue.global(qos: .background).async {
                    let removedHeaderData = SleepProtocol09API.shared.removeFrontBytes(data: data, size: 1)
                    do {
                        let hrSpO2 = try SleepProtocol09API.shared.asciiToHRSpO2(data: removedHeaderData)
                        print("hrSp02 = \(hrSpO2)")
                        SleepProtocol09API.shared.request(data: hrSpO2) { response in
                            print("response: \(response)")
                            onReceiveSubscribtionData?(ProtocolType.PROTOCOL_9, response)
                        }
                        
                    } catch {
                        print("[Error] Failed to parse HRSpO2 data: \(error)")
                        onReceiveSubscribtionData?(ProtocolType.PROTOCOL_9_ERROR, nil)
                    }
                }
                
            default:
                break
        }
    }
}
