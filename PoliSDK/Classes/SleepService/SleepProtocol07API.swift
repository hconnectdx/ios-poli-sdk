class SleepProtocol07API: ProtocolHandlerUtil {
    public static let shared = SleepProtocol07API()
    override private init() {}
    
    func request(completion: @escaping (SleepResponse) -> Void) {
        if PoliAPI.shared.sessionId.isEmpty {
            completion(SleepResponse(retCd: "1", retMsg: "Session ID is empty", resDate: ""))
            return
        }
        // Encodable 요청 객체 생성
        let requestBody: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "sessionId": PoliAPI.shared.sessionId
        ]
        
        // API 요청 수행
        PoliAPI.shared.postMultipart(
            path: "/sleep/protocol7",
            parameters: requestBody,
            fileData: SleepProtocol07API.shared.flush(),
            fileName: "ios_protocol07")
        { result in
            do {
                let response = try SleepResponse.convertToSleepResponse(from: result)
                completion(response)
                
            } catch {
                print("[Error] Failed to parse SleepProtocol06Response\(error)")
            }
        }
    }
}
