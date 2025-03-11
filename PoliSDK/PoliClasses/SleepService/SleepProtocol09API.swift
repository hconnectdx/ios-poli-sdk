class SleepProtocol09API: ProtocolHandlerUtil {
    public static let shared = SleepProtocol09API()
    override private init() {}
    
    func request(data: [String: Any], completion: @escaping (SleepResponse) -> Void) {
        if PoliAPI.shared.sessionId.isEmpty {
            completion(SleepResponse(retCd: "1", retMsg: "Session ID is empty", resDate: ""))
            return
        }
        // Encodable 요청 객체 생성
        let request: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "sessionId": PoliAPI.shared.sessionId,
            "data": data
        ]
        
        // API 요청 수행
        PoliAPI.shared.post(
            path: "/sleep/protocol9",
            body: request)
        { result in
            do {
                let response = try SleepResponse.convertToSleepResponse(from: result)
                PoliAPI.shared.sessionId = response.data?.sessionId ?? ""
                completion(response)
            } catch {
                print("[Error] Failed to parse SleepProtocol09Response\(error)")
            }
        }
    }
}
