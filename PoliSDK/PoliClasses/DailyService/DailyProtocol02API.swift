class DailyProtocol02API: ProtocolHandlerUtil {
    public static let shared = DailyProtocol02API()
    public var preByte: UInt8 = 0x00
    override private init() {}
    
    // Get current byte array size for validation
    func getCurrentByteArraySize() -> Int {
        return getDaily02ByteArraySize()
    }
    
    // Reset data without returning it
    func resetData() {
        clearDaily02ByteArray()
    }
    
    // Save current Protocol02 data to a bin file
    func saveToFile(fileName: String? = nil) -> String {
        let actualFileName = fileName ?? "protocol02_\(DateUtil.getCurrentDateTime()).bin"
        let filePath = saveDaily02DataToFile(fileName: actualFileName)
        return filePath
    }
    
    func request(completion: @escaping (DailyProtocol02Response) -> Void, saveToFile: Bool = false) {
        // 파일로 저장 (옵션)
        if saveToFile {
            let filePath = self.saveToFile()
            print("Protocol02 데이터가 파일로 저장되었습니다: \(filePath)")
        }
        
        let requestBody: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "userAge": PoliAPI.shared.userAge
        ]
        
        // API 요청 수행
        PoliAPI.shared.postMultipart(
            path: "/day/protocol2",
            parameters: requestBody,
            fileData: DailyProtocol02API.shared.flushDaily02(),
            fileName: "ios_protocol02"
        ) { result in
            do {
                let response = try DailyProtocol02Response.convertToDailyResponse(from: result)
                completion(response)
            } catch {
                print("[Error] Failed to parse DailyProtocol02Response\(error)")
                let response = DailyProtocol02Response(
                    retCd: "-1",
                    retMsg: error.localizedDescription,
                    resDate: DateUtil.getCurrentDateTime()
                )
                
                completion(response)
            }
        }
    }
}
