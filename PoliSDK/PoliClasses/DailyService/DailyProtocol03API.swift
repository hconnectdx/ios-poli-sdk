
class DailyProtocol03API: ProtocolHandlerUtil {
    public static let shared = DailyProtocol03API()
    
    /**
        * DailyProtocol03 API 요청
        * - Parameters:
        *   - data: [oxygenVal: Int, heartRateVal: Int]
     */
    func request(data: [String: Any], completion: @escaping (DailyProtocol03Response) -> Void) {
        let request: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "sessionId": PoliAPI.shared.sessionId,
            "data": data
        ]
        
        // API 요청 수행
        PoliAPI.shared.post(
            path: "/day/protocol3",
            body: request
        ) { result in
            do {
                var response = try DailyProtocol03Response.convertToDailyResponse(from: result)
                
                let heartRate = data["heartRateVal"] as? Int
                let spo2 = data["oxygenVal"] as? Int
                let hrSpO2Data = HRSpO2(heartRate: heartRate, spo2: spo2)
                
                // 새로운 Data 인스턴스 생성해서 할당
                response.data = DailyProtocol03Response.Data(hrSpO2: hrSpO2Data)
                
                completion(response)
            } catch {
                print("[Error] Failed to parse DailyProtocol03Response: \(error)")
                let response = DailyProtocol03Response(
                    retCd: "-1",
                    retMsg: error.localizedDescription,
                    resDate: DateUtil.getCurrentDateTime()
                )
                completion(response)
            }
        }
    }
}
