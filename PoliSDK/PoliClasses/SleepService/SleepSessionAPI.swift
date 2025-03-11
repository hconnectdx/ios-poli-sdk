class SleepSessionAPI: ProtocolHandlerUtil {
    public static let shared = SleepSessionAPI()

    func requestSleepStart(completion: @escaping (SleepResponse) -> Void) {
        // Encodable 요청 객체 생성
        let request: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno
        ]

        // API 요청 수행
        PoliAPI.shared.post(
            path: "/sleep/start",
            body: request)
        { result in
            do {
                let response = try SleepResponse.convertToSleepResponse(from: result)
                PoliAPI.shared.sessionId = response.data?.sessionId ?? ""
                completion(response)
            } catch {
                print("[Error] Failed to parse SleepStartResponse\(error)")
            }
        }
    }

    func requestSleepStop(completion: @escaping (SleepStopResponse) -> Void) {
        if PoliAPI.shared.sessionId.isEmpty {
            completion(SleepStopResponse(retCd: "1", retMsg: "Session ID is empty", resDate: ""))
            return
        }

        // Encodable 요청 객체 생성
        let request: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "sessionId": PoliAPI.shared.sessionId
        ]

        // API 요청 수행
        PoliAPI.shared.post(
            path: "/sleep/stop",
            body: request)
        { result in
            do {
                let response = try SleepStopResponse.convertToSleepStopResponse(from: result)
                completion(response)
            } catch {
                print("[Error] Failed to parse SleepStopResponse\(error)")
            }
        }
    }
}
