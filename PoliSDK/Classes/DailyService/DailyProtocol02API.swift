class DailyProtocol02API: ProtocolHandlerUtil {
    public static let shared = DailyProtocol02API()
    public var preByte: UInt8 = 0x00
    override private init() {}
    
    func request(completion: @escaping (DailyProtocol02Response) -> Void) {
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
            fileName: "ios_protocol02")
        { result in
            do {
                let response = try DailyProtocol02Response.convertToDailyResponse(from: result)
                completion(response)
            } catch {
                print("[Error] Failed to parse DailyProtocol02Response\(error)")
            }
        }
    }
}
