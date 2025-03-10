
class DailyProtocol03API: ProtocolHandlerUtil {
    public static let shared = DailyProtocol03API()
    
    /**
        * DailyProtocol03 API 요청
        * - Parameters:
        *   - data: [oxygenVal: Int, heartRateVal: Int]
     */
    func request(data: [String: Any], completion: @escaping (DailyResponse) -> Void) {
        let request: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "sessionId": PoliAPI.shared.sessionId,
            "data": data
        ]
        
        // API 요청 수행
        PoliAPI.shared.post(
            path: "/day/protocol3",
            body: request)
        { result in
            do {
                let response = try DailyResponse.convertToDailyResponse(from: result)
                completion(response)
            } catch {
                print("[Error] Failed to parse DailyResponse\(error)")
            }
        }
    }
}
