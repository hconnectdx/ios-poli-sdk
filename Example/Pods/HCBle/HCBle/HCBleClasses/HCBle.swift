import CoreBluetooth

public class HCBle: NSObject {
    class PeripheralModel {
        var selService: CBService?
        var selChar: CBCharacteristic?
        var peripheral: CBPeripheral?

        init(selService: CBService? = nil, selChar: CBCharacteristic? = nil, peripheral: CBPeripheral? = nil) {
            self.selService = selService
            self.selChar = selChar
            self.peripheral = peripheral
        }
    }

    // Singleton instance
    public static let shared = HCBle()

    private var centralManager: CBCentralManager?
    private var scanCallback: ((CBPeripheral, [String: Any], NSNumber) -> Void)?
    private var connectCallback: ((CBPeripheral, Bool, Error?) -> Void)?
    private var discoverCallback: ((CBPeripheral, [String: Any], NSNumber) -> Void)?
    private var onConnState: ((Bool, Error?) -> Void)?
    private var onDiscoverServices: (([CBService]) -> Void)?
    private var onDiscoverCharacteristics: ((CBService, [CBCharacteristic]) -> Void)?
    private var onSubscriptionState: ((Bool) -> Void)?
    private var onReceiveSubscribtionData: ((Data) -> Void)?
    private var peripheral: CBPeripheral?
    private var peripherals: [PeripheralModel] = []
    private var selService: CBService?
    private var selChar: CBCharacteristic?

    // Private initializer to prevent additional instances
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    public func scan(callback: @escaping (CBPeripheral, [String: Any], NSNumber) -> Void) {
        scanCallback = callback
        guard let centralManager = centralManager else {
            print("Central Manager is not initialized")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // 항상 딜레이
            if centralManager.state == .poweredOn {
                centralManager.scanForPeripherals(withServices: nil)
                print("Started scanning after fixed delay")
            } else {
                print("Bluetooth is not powered on")
            }
        }
    }

    public func stopScan() {
        guard let centralManager = centralManager else {
            print("Central Manager is not initialized")
            return
        }
        centralManager.stopScan()
        print("Stopped scanning for peripherals")
    }

    public func connect(
        peripheral: CBPeripheral,
        onConnState: ((Bool, Error?) -> Void)? = nil,
        onBondState: (() -> Void)? = nil,
        onDiscoverServices: (([CBService]) -> Void)? = nil,
        onDiscoverCharacteristics: ((CBService, [CBCharacteristic]) -> Void)? = nil,
        onReadCharacteristic: (() -> Void)? = nil,
        onWriteCharacteristic: (() -> Void)? = nil,
        onSubscriptionState: ((Bool) -> Void)? = nil,
        onReceiveSubscribtionData: ((Data) -> Void)? = nil
    ) {
        self.onConnState = onConnState
        self.onDiscoverServices = onDiscoverServices
        self.onDiscoverCharacteristics = onDiscoverCharacteristics
        self.onSubscriptionState = onSubscriptionState
        self.onReceiveSubscribtionData = onReceiveSubscribtionData

        guard let centralManager = centralManager else {
            print("Central Manager is not initialized")
            return
        }

        if centralManager.state == .poweredOn {
            print("Attempting to connect to \(peripheral.name ?? "Unknown Device")")
            centralManager.connect(peripheral, options: nil)
        } else {
            print("Bluetooth is not powered on")
        }
    }

    public func readData(uuid: UUID) {
        // 1. peripherals 배열에서 해당 UUID의 peripheralModel을 찾기
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        // 2. peripheral과 characteristic이 유효한지 확인
        guard let peripheral = peripheralModel.peripheral, let characteristic = peripheralModel.selChar else {
            print("Peripheral or characteristic is not set. Please ensure they are initialized.")
            return
        }

        // 3. characteristic으로부터 데이터 읽기
        peripheral.readValue(for: characteristic)
    }

    public func writeData(uuid: UUID, data: Data) {
        // 1. peripherals 배열에서 해당 UUID의 peripheralModel을 찾기
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        // 2. peripheral과 characteristic이 유효한지 확인
        guard let peripheral = peripheralModel.peripheral, let characteristic = peripheralModel.selChar else {
            print("Peripheral or characteristic is not set. Please ensure they are initialized.")
            return
        }

        // 3. 데이터를 characteristic에 write (응답을 받는 방식으로)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    public func enableNotifications(uuid: UUID) {
        print(peripherals)
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        guard let peripheral = peripheralModel.peripheral, let characteristic = peripheralModel.selChar else {
            print("Peripheral or characteristic is not set. Please ensure they are initialized.")
            return
        }

        // Enable notifications for the characteristic
        peripheral.setNotifyValue(true, for: characteristic)
    }

    public func setService(uuid: UUID, service: CBService) {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        // Assuming selService is a property that should be set
        peripheralModel.selService = service
        print("Service set for peripheral with UUID: \(uuid)")
    }

    public func setChar(uuid: UUID, characteristic: CBCharacteristic) {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        peripheralModel.selChar = characteristic
    }

    public func setTargetService(uuid: UUID, serviceUUID: String) {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        guard let peripheral = peripheralModel.peripheral else {
            print("Peripheral is not set.")
            return
        }

        // Check if services have been discovered
        guard let services = peripheral.services else {
            print("Services not discovered yet. Please discover services first.")
            return
        }

        // Find the service with matching UUID
        let targetService = services.first { service in
            service.uuid.uuidString.uppercased() == serviceUUID.uppercased()
        }

        if let foundService = targetService {
            peripheralModel.selService = foundService
            print("✅ Target service set for peripheral UUID: \(uuid)")
            print("🎯 Service UUID: \(foundService.uuid.uuidString)")
        } else {
            print("❌ Service with UUID '\(serviceUUID)' not found in discovered services")
            print("📋 Available services:")
            for service in services {
                print("   - \(service.uuid.uuidString)")
            }
        }
    }

    public func setTargetChar(uuid: UUID, characteristicUUID: String) {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        guard let peripheral = peripheralModel.peripheral else {
            print("Peripheral is not set.")
            return
        }

        // Check if service has been set
        guard let selectedService = peripheralModel.selService else {
            print("Selected service is not set. Please set target service first using setTargetService.")
            return
        }

        // Check if characteristics have been discovered for the selected service
        guard let characteristics = selectedService.characteristics else {
            print("Characteristics not discovered yet for the selected service. Please discover characteristics first.")
            return
        }

        // Find the characteristic with matching UUID
        let targetCharacteristic = characteristics.first { characteristic in
            characteristic.uuid.uuidString.uppercased() == characteristicUUID.uppercased()
        }

        if let foundCharacteristic = targetCharacteristic {
            peripheralModel.selChar = foundCharacteristic
            print("✅ Target characteristic set for peripheral UUID: \(uuid)")
            print("🎯 Characteristic UUID: \(foundCharacteristic.uuid.uuidString)")
            print("🔧 Properties: \(foundCharacteristic.properties)")
        } else {
            print("❌ Characteristic with UUID '\(characteristicUUID)' not found in selected service")
            print("📋 Available characteristics in service \(selectedService.uuid.uuidString):")
            for characteristic in characteristics {
                print("   - \(characteristic.uuid.uuidString) (Properties: \(characteristic.properties))")
            }
        }
    }

    public func disconnect(uuid: UUID) {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        // Cancel the connection to the peripheral
        guard let peripheral = peripheralModel.peripheral else { return }
        centralManager?.cancelPeripheralConnection(peripheral)
    }

    public func isConnected(uuid: UUID) -> Bool {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return false
        }

        // Check the connection state of the peripheral
        return peripheralModel.peripheral?.state == .connected
    }

    public func getPeripheral(uuid: UUID) -> CBPeripheral? {
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return nil
        }
        return peripheralModel.peripheral
    }
}

extension HCBle: CBPeripheralDelegate {
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        for service in services {
            print("Service UUID: \(service.uuid.uuidString)")
            service.peripheral?.discoverCharacteristics(nil, for: service)
        }

        onDiscoverServices?(services)
    }

    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            print("Characteristic UUID: \(characteristic.uuid.uuidString)")
        }

        onDiscoverCharacteristics?(service, characteristics)
    }

    /* MARK: - Discover Services */
    private func discoverServices(peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("Error reading characteristic value: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("Characteristic value is nil")
            return
        }

        // Convert the data to an array of bytes
        let byteArray = [UInt8](data)

        // Print each byte in hexadecimal format
        let byteString = byteArray.map { String(format: "%02x", $0) }.joined(separator: " ")
        print("Received size: \(data)")
        print("Received bytes: \(byteString)")
        print("")

        onReceiveSubscribtionData?(data)
    }

    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("Error writing characteristic value: \(error.localizedDescription)")
        } else {
            print("Successfully wrote value to characteristic: \(characteristic.uuid)")
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: (any Error)?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            onSubscriptionState?(false)
            return
        }

        if characteristic.isNotifying {
            print("Notifications enabled for characteristic: \(characteristic.uuid)")
            onSubscriptionState?(true)
        } else {
            print("Notifications disabled for characteristic: \(characteristic.uuid)")
            onSubscriptionState?(false)
        }
    }
}

extension HCBle: CBCentralManagerDelegate {
    // CBCentralManagerDelegate methods
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
            case .poweredOn:
                print("Bluetooth is powered on")
            case .poweredOff:
                print("Bluetooth is powered off")
            case .resetting:
                print("Bluetooth is resetting")
            case .unauthorized:
                print("Bluetooth is unauthorized")
            case .unsupported:
                print("Bluetooth is unsupported")
            case .unknown:
                print("Bluetooth state is unknown")
            @unknown default:
                print("A new state is available that is not handled")
        }

        if centralManager?.state == .poweredOn {
            centralManager?.scanForPeripherals(withServices: nil)

            print("Scanning for peripherals...")
        } else {
            print("Bluetooth is not powered on")
        }
    }

    /* MARK: - Scan Callback */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        scanCallback?(peripheral, advertisementData, RSSI)
    }

    /* MARK: - Connect State Callback */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        onConnState?(true, nil)
        self.peripheral = peripheral

        let peripheralModel = PeripheralModel(peripheral: peripheral)
        peripherals.append(peripheralModel)
        discoverServices(peripheral: peripheral)
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device")")
        onConnState?(false, error)
    }

    public func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        print("connectionEventDidOccur")
    }

    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("didDisconnectPeripheral")
        onConnState?(false, error)

        attemptReconnect(to: peripheral)
    }

    func attemptReconnect(to peripheral: CBPeripheral) {
        // Implement your reconnection logic here
        // For example, you might want to delay the reconnection attempt
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.centralManager?.connect(peripheral, options: nil)
        }
    }
}
