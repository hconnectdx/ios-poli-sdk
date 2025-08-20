import CoreBluetooth
import Foundation
import HCBle

public class PoliBLE {
    // MARK: - Constants
    
    private static let TAG = "PoliBLE"
    
    // Protocol 02 관련 상수
    private static let PROTOCOL_LAST_PACKET: UInt8 = 0xFF
    private static let PROTOCOL_02_MAX_ORDER: UInt8 = 0xFE
    private static let PROTOCOL_02_RESET_ORDER: UInt8 = 0x00
    
    // MARK: - Singleton
    
    public static let shared = PoliBLE()
    
    private var onConnState: ((Bool, Error?) -> Void)?
    private var onDiscoverServices: (([CBService]) -> Void)?
    private var onDiscoverCharacteristics: ((CBService, [CBCharacteristic]) -> Void)?
    private var onSubscriptionState: ((Bool) -> Void)?
    private var onReceiveSubscriptionData: ((ProtocolType, BaseResponse?) -> Void)?
    private var onReadCharacteristic: (() -> Void)?
    private var onWriteCharacteristic: (() -> Void)?
    
    // MARK: - Protocol 02 State Variables
    
    /// Protocol 02 순서 추적 변수들 (Android 로직과 동일)
    private var p2ExpectedOrder: UInt8 = PROTOCOL_02_RESET_ORDER
    private var prevByte: UInt8 = PROTOCOL_02_RESET_ORDER
    private var p2IsFirstPacket: Bool = true
    
    private init() {
        print("[\(Self.TAG)] PoliBLE 초기화")
    }
    
    // MARK: - Scan Management
    
    /// 블루투스 스캔 시작
    /// - Parameter completion: 스캔 결과를 전달하는 콜백
    public func scan(completion: @escaping (CBPeripheral, [String: Any], NSNumber) -> Void) {
        print("[\(Self.TAG)] 블루투스 스캔 시작")
        HCBle.shared.scan(callback: completion)
    }
    
    /// 블루투스 스캔 중지
    public func stopScan() {
        print("[\(Self.TAG)] 블루투스 스캔 중지")
        HCBle.shared.stopScan()
    }
    
    // MARK: - Connection Management
    
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
        onReceiveSubscriptionData: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] 디바이스 연결 시작: \(peripheral.identifier)")
        
        self.onConnState = onConnState
        self.onDiscoverServices = onDiscoverServices
        self.onDiscoverCharacteristics = onDiscoverCharacteristics
        self.onReadCharacteristic = onReadCharacteristic
        self.onWriteCharacteristic = onWriteCharacteristic
        self.onSubscriptionState = onSubscriptionState
        self.onReceiveSubscriptionData = onReceiveSubscriptionData
        
        HCBle.shared.connect(
            peripheral: peripheral,
            onConnState: { [weak self] isConnected, error in
                self?.handleConnectionStateChange(isConnected: isConnected)
                onConnState?(isConnected, error)
            },
            onDiscoverServices: onDiscoverServices,
            onDiscoverCharacteristics: onDiscoverCharacteristics,
            onReadCharacteristic: onReadCharacteristic,
            onWriteCharacteristic: { [weak self] in
                self?.handleWriteCharacteristic()
                onWriteCharacteristic?()
            },
            onSubscriptionState: onSubscriptionState,
            onReceiveSubscribtionData: { [weak self] data in
                self?.processReceivedData(data: data, onReceive: onReceiveSubscriptionData)
            }
        )
    }
    
    /// 연결 상태 변경 처리
    private func handleConnectionStateChange(isConnected: Bool) {
        print("[\(Self.TAG)] 연결 상태 변경: \(isConnected)")
        // 연결 시 Protocol 02 상태 초기화
        resetProtocol02State()
    }
    
    /// 특성 쓰기 완료 처리
    private func handleWriteCharacteristic() {
        print("[\(Self.TAG)] 특성 쓰기 완료")
        // 재측정 시 상태 초기화
        resetProtocol02State()
        prevByte = 0x00
    }
    
    /// 연결된 기기 해제
    /// - Parameter uuid: 해제할 기기의 UUID
    public func disconnect(from uuid: UUID) {
        print("[\(Self.TAG)] 디바이스 연결 해제: \(uuid)")
        HCBle.shared.disconnect(uuid: uuid)
    }
    
    /// 모든 연결 해제
    public func disconnectAll() {
        print("[\(Self.TAG)] 모든 디바이스 연결 해제")
        // TODO: HCBle에 disconnectAll 구현 필요
    }
    
    // MARK: - GATT Operations
    
    public func readData(uuid: UUID) {
        HCBle.shared.readData(uuid: uuid)
    }
    
    public func writeData(uuid: UUID, _ data: Data) {
        print("[\(Self.TAG)] 특성 쓰기: \(uuid), 데이터: \(data.map { String(format: "0x%02X", $0) }.joined(separator: " "))")
        HCBle.shared.writeData(uuid: uuid, data: data)
    }
    
    public func enableNotifications(uuid: UUID) {
        print("[\(Self.TAG)] 특성 알림 설정: \(uuid)")
        HCBle.shared.enableNotifications(uuid: uuid)
    }
    
    public func setService(uuid: UUID, service: CBService) {
        HCBle.shared.setService(uuid: uuid, service: service)
    }
    
    public func setTargetService(uuid: UUID, serviceUUID: String) {
        print("[\(Self.TAG)] 서비스 UUID 설정: \(serviceUUID)")
        HCBle.shared.setTargetService(uuid: uuid, serviceUUID: serviceUUID)
    }
    
    public func setReadChar(uuid: UUID, characteristic: CBCharacteristic) {
        HCBle.shared.setReadChar(uuid: uuid, characteristic: characteristic)
    }
    
    public func setTargetReadChar(uuid: UUID, characteristicUUID: String) {
        print("[\(Self.TAG)] Read 특성 UUID 설정: \(characteristicUUID)")
        HCBle.shared.setTargetReadChar(uuid: uuid, characteristicUUID: characteristicUUID)
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
    
    // MARK: - Data Processing
    
    /// 수신된 데이터 처리
    private func processReceivedData(
        data: Data,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        guard !data.isEmpty else {
            print("[\(Self.TAG)] ⚠️ 빈 데이터 수신")
            return
        }
        
        let protocolType = data[0]
        let dataOrder = data.count > 1 ? data[1] : Self.PROTOCOL_02_RESET_ORDER
        
        print("[\(Self.TAG)] 프로토콜 처리: 0x\(String(format: "%02X", protocolType))")
        
        switch protocolType {
        case 0x01:
            handleProtocol01(data: data, onReceive: onReceive)
        case 0x02:
            handleProtocol02(data: data, dataOrder: dataOrder, onReceive: onReceive)
        case 0x03:
            handleProtocol03(data: data, onReceive: onReceive)
        case 0x04:
            handleProtocol04(onReceive: onReceive)
        case 0x05:
            handleProtocol05(onReceive: onReceive)
        case 0x06:
            handleProtocol06(data: data, dataOrder: dataOrder, onReceive: onReceive)
        case 0x07:
            handleProtocol07(data: data, dataOrder: dataOrder, onReceive: onReceive)
        case 0x08:
            handleProtocol08(data: data, dataOrder: dataOrder, onReceive: onReceive)
        case 0x09:
            handleProtocol09(data: data, onReceive: onReceive)
        default:
            logUnknownProtocol(data: data)
        }
    }
    
    // MARK: - Protocol Handlers
    
    /// Protocol 01 처리 (Daily 시작)
    private func handleProtocol01(
        data: Data,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 01 처리")
        DispatchQueue.global(qos: .background).async {
            DailyProtocol01API.shared.categorizeData(data: data)
            if data[1] == Self.PROTOCOL_LAST_PACKET {
                DailyProtocol01API.shared.createLTMModel()
                DailyProtocol01API.shared.request { response in
                    print("[\(Self.TAG)] DailyProtocol01API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_1, response)
                }
            }
        }
    }
    
    /// Protocol 02 처리
    private func handleProtocol02(
        data: Data,
        dataOrder: UInt8,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 02 처리 - 데이터 순서: 0x\(String(format: "%02X", dataOrder))")
        
        // 시작 조건 검증
        checkStartCondition(onReceive: onReceive)
        
        // 패킷 처리
        handleDataPacket(dataOrder: dataOrder, onReceive: onReceive)
        
        // 데이터 추가 및 완료 처리
        prevByte = dataOrder
        let isLastPacket = (dataOrder == Self.PROTOCOL_LAST_PACKET)
        let removedHeaderData = removeFrontBytes(data: data, size: 2)
        
        DailyProtocol02API.shared.addDaily02ByteNew(data: removedHeaderData, isLast: isLastPacket)
        
        if isLastPacket {
            print("[\(Self.TAG)] Protocol 02 완료 - 앱으로 전송")
            handleLastPacket(onReceive: onReceive)
        }
    }
    
    /// 시작 조건 검증
    private func checkStartCondition(onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil) {
        let isNewSequenceStart = DailyProtocol02API.shared.getCurrentByteArraySize() == 0
        
        if isNewSequenceStart {
            print("[\(Self.TAG)] 새 시퀀스 시작 감지")
            resetProtocol02State()
            onReceive?(ProtocolType.PROTOCOL_2_START, nil)
        }
    }
    
    /// 패킷 처리
    private func handleDataPacket(
        dataOrder: UInt8,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        if p2IsFirstPacket {
            handleFirstPacket(dataOrder: dataOrder)
        } else {
            validatePacketOrder(dataOrder: dataOrder, onReceive: onReceive)
        }
    }
    
    /// 첫 번째 패킷 처리
    private func handleFirstPacket(dataOrder: UInt8) {
        p2ExpectedOrder = calculateNextOrder(currentOrder: dataOrder)
        p2IsFirstPacket = false
        print("[\(Self.TAG)] 첫 패킷 감지: 0x\(String(format: "%02X", dataOrder)), 다음 예상: 0x\(String(format: "%02X", p2ExpectedOrder))")
    }
    
    /// 패킷 순서 검증
    private func validatePacketOrder(
        dataOrder: UInt8,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        if (dataOrder != p2ExpectedOrder) && dataOrder != Self.PROTOCOL_LAST_PACKET {
            print("[\(Self.TAG)] ⚠️ 패킷 순서 오류 - 예상: 0x\(String(format: "%02X", p2ExpectedOrder)), 실제: 0x\(String(format: "%02X", dataOrder))")
            resetProtocol02State()
            onReceive?(ProtocolType.PROTOCOL_2_ERROR_LACK_OF_DATA, nil)
            return
        }
        
        p2ExpectedOrder = calculateNextOrder(currentOrder: dataOrder)
        print("[\(Self.TAG)] 패킷 순서 정상 - 다음 예상: 0x\(String(format: "%02X", p2ExpectedOrder))")
    }
    
    /// 마지막 패킷 처리
    private func handleLastPacket(onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil) {
        print("[\(Self.TAG)] 프로세스 종료 패킷 수신 (0xFF)")
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let byteSize = DailyProtocol02API.shared.getCurrentByteArraySize()
            print("[\(Self.TAG)] Protocol02 ByteArray size: \(byteSize)")
            
            if byteSize <= 192_000 {
                let filePath = DailyProtocol02API.shared.saveToFile()
                print("[\(Self.TAG)] Protocol02 데이터가 파일로 저장되었습니다: \(filePath)")
                
                DailyProtocol02API.shared.request(completion: { response in
                    print("[\(Self.TAG)] DailyProtocol02API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_2, response)
                }, saveToFile: false)
            } else {
                print("[\(Self.TAG)] ❌ Protocol02 데이터 부족: \(byteSize) bytes")
                onReceive?(ProtocolType.PROTOCOL_2_ERROR_LACK_OF_DATA, nil)
            }
            
            self.resetProtocol02State()
        }
    }
    
    /// 다음 순서 계산
    private func calculateNextOrder(currentOrder: UInt8) -> UInt8 {
        if currentOrder == Self.PROTOCOL_02_MAX_ORDER {  // 0xFE인 경우
            return Self.PROTOCOL_02_RESET_ORDER          // 0x00 반환
        } else {
            return currentOrder &+ 1                     // 안전한 덧셈
        }
    }
    
    /// Protocol 02 상태 초기화
    private func resetProtocol02State() {
        DailyProtocol02API.shared.resetByteArray() // 구현 필요
        p2ExpectedOrder = Self.PROTOCOL_02_RESET_ORDER
        prevByte = Self.PROTOCOL_02_RESET_ORDER
        p2IsFirstPacket = true
        
        print("[\(Self.TAG)] Protocol 02 상태 초기화")
    }
    
    /// Protocol 03 처리
    private func handleProtocol03(
        data: Data,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 03 처리")
        DispatchQueue.global(qos: .background).async {
            do {
                let hrSpO2Data = try DailyProtocol03API.shared.asciiToHRSpO2(data: data)
                DailyProtocol03API.shared.request(data: hrSpO2Data) { response in
                    print("[\(Self.TAG)] DailyProtocol03API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_3, response)
                }
            } catch {
                print("[\(Self.TAG)] ❌ Protocol 03 처리 중 오류: \(error)")
                onReceive?(ProtocolType.PROTOCOL_3_ERROR, nil)
            }
        }
    }
    
    /// Protocol 04 처리
    private func handleProtocol04(onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil) {
        print("[\(Self.TAG)] Protocol 04 처리 - 수면 시작")
        DispatchQueue.global(qos: .background).async {
            SleepSessionAPI.shared.requestSleepStart { response in
                let type: ProtocolType
                if response.retCd == "0" {
                    print("[\(Self.TAG)] 수면 시작 성공")
                    let sessionId = response.data?.sessionId
                    PoliAPI.shared.sessionId = sessionId ?? ""
                    type = ProtocolType.PROTOCOL_4_SLEEP_START
                } else {
                    print("[\(Self.TAG)] 수면 시작 실패: \(response.retCd)")
                    type = ProtocolType.PROTOCOL_4_SLEEP_START_ERROR
                }
                onReceive?(type, response)
            }
        }
    }
    
    /// Protocol 05 처리
    private func handleProtocol05(onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil) {
        print("[\(Self.TAG)] Protocol 05 처리 - 수면 종료")
        DispatchQueue.global(qos: .background).async {
            SleepSessionAPI.shared.requestSleepStop { response in
                let type: ProtocolType
                if response.retCd == "0" {
                    print("[\(Self.TAG)] 수면 종료 성공 - 수면 품질: \(response.data?.sleepQuality ?? 0)")
                    type = ProtocolType.PROTOCOL_5_SLEEP_END
                } else {
                    print("[\(Self.TAG)] 수면 종료 실패: \(response.retCd) - \(response.retMsg)")
                    type = ProtocolType.PROTOCOL_5_SLEEP_END_ERROR
                }
                onReceive?(type, response)
            }
        }
    }
    
    /// Protocol 06 처리
    private func handleProtocol06(
        data: Data,
        dataOrder: UInt8,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 06 처리")
        let removedHeaderData = removeFrontBytes(data: data, size: 2)
        SleepProtocol06API.shared.addByte(data: removedHeaderData)
        
        if dataOrder == Self.PROTOCOL_LAST_PACKET {
            DispatchQueue.global(qos: .background).async {
                SleepProtocol06API.shared.request { response in
                    print("[\(Self.TAG)] SleepProtocol06API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_6, response)
                }
            }
        } else {
            onReceive?(ProtocolType.PROTOCOL_6, nil)
        }
    }
    
    /// Protocol 07 처리
    private func handleProtocol07(
        data: Data,
        dataOrder: UInt8,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 07 처리")
        let removedHeaderData = removeFrontBytes(data: data, size: 2)
        SleepProtocol07API.shared.addByte(data: removedHeaderData)
        
        if dataOrder == Self.PROTOCOL_LAST_PACKET {
            DispatchQueue.global(qos: .background).async {
                SleepProtocol07API.shared.request { response in
                    print("[\(Self.TAG)] SleepProtocol07API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_7, response)
                }
            }
        } else {
            onReceive?(ProtocolType.PROTOCOL_7, nil)
        }
    }
    
    /// Protocol 08 처리
    private func handleProtocol08(
        data: Data,
        dataOrder: UInt8,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 08 처리")
        let removedHeaderData = removeFrontBytes(data: data, size: 2)
        SleepProtocol08API.shared.addByte(data: removedHeaderData)
        
        if dataOrder == Self.PROTOCOL_LAST_PACKET {
            DispatchQueue.global(qos: .background).async {
                SleepProtocol08API.shared.request { response in
                    print("[\(Self.TAG)] SleepProtocol08API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_8, response)
                }
            }
        } else {
            onReceive?(ProtocolType.PROTOCOL_8, nil)
        }
    }
    
    /// Protocol 09 처리 (HR, SpO2)
    private func handleProtocol09(
        data: Data,
        onReceive: ((ProtocolType, BaseResponse?) -> Void)? = nil
    ) {
        print("[\(Self.TAG)] Protocol 09 처리 - HR, SpO2")
        DispatchQueue.global(qos: .background).async {
            let removedHeaderData = self.removeFrontBytes(data: data, size: 1)
            do {
                let hrSpO2 = try SleepProtocol09API.shared.asciiToHRSpO2(data: removedHeaderData)
                print("[\(Self.TAG)] hrSpO2 = \(hrSpO2)")
                SleepProtocol09API.shared.request(data: hrSpO2) { response in
                    print("[\(Self.TAG)] SleepProtocol09API response: \(response)")
                    onReceive?(ProtocolType.PROTOCOL_9, response)
                }
            } catch {
                print("[\(Self.TAG)] ❌ Protocol 09 처리 중 오류: \(error)")
                onReceive?(ProtocolType.PROTOCOL_9_ERROR, nil)
            }
        }
    }
    
    /// 알 수 없는 프로토콜 로깅
    private func logUnknownProtocol(data: Data) {
        let hexString = data.map { String(format: "0x%02X", $0) }.joined(separator: " ")
        print("[\(Self.TAG)] ❌ 알 수 없는 프로토콜: \(hexString)")
    }
    
    // MARK: - Utility Methods
    
    /// 바이트 배열 앞부분 제거
    private func removeFrontBytes(data: Data, size: Int) -> Data {
        guard data.count > size else { return Data() }
        return data.subdata(in: size..<data.count)
    }
    
    /// 수면 강제 종료 / stop 신호 강제 생성
      public func stopSleepForce() {
          print("[\(Self.TAG)] 수면 강제 종료")
          DispatchQueue.global(qos: .background).async { [weak self] in
              SleepSessionAPI.shared.requestSleepStop { [weak self] response in
                  let type: ProtocolType
                  if response.retCd == "0" {
                      print("[\(Self.TAG)] 강제 수면 종료 성공")
                      type = ProtocolType.PROTOCOL_5_SLEEP_END
                  } else {
                      print("[\(Self.TAG)] 강제 수면 종료 실패: \(response.retCd)")
                      type = ProtocolType.PROTOCOL_5_SLEEP_END_ERROR
                  }
                  self?.onReceiveSubscriptionData?(type, response)
              }
          }
      }
}
