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

        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("Scanning for peripherals...")
        } else {
            print("Bluetooth is not powered on")
        }
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
        guard let peripheralModel = peripherals.first(where: { $0.peripheral?.identifier == uuid }) else {
            print("Peripheral not added yet. Please call connect first.")
            return
        }

        guard let peripheral = peripheralModel.peripheral, let characteristic = peripheralModel.selChar else {
            print("Peripheral or characteristic is not set. Please ensure they are initialized.")
            return
        }

        peripheral.readValue(for: characteristic)
    }

    /** TODO : 개별 디바이스에서 통신하도록 만들어야 함 */
    public func writeData(_ data: Data) {
        guard let peripheral = peripheral, let characteristic = selChar else {
            print("Peripheral or characteristic is not set. Please ensure they are initialized.")
            return
        }

        // Write the data to the characteristic
        // Use .withResponse if you need confirmation that the write was successful
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
