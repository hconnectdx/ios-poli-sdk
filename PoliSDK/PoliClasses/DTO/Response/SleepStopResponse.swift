import Foundation

// MARK: - SleepResponse

public class SleepStopResponse: BaseResponse {
    public var data: Data?

    // required 초기화 메서드 구현
    public required init(retCd: String = "", retMsg: String = "", resDate: String = "") {
        super.init(retCd: retCd, retMsg: retMsg, resDate: resDate)
    }

    public init(data: Data? = nil) {
        self.data = data
        super.init()
    }

    public class Data {
        public let sleepQuality: Int

        public init(sleepQuality: Int) {
            self.sleepQuality = sleepQuality
        }
    }

    public static func convertToSleepStopResponse(from dictionary: [String: Any]) throws -> SleepStopResponse {
        // 기본 응답 필드 추출
        let retCd = dictionary["retCd"] as? String ?? ""
        let retMsg = dictionary["retMsg"] as? String ?? ""
        let resDate = dictionary["resDate"] as? String ?? ""

        // SleepStopResponse 객체 생성
        let response = SleepStopResponse(retCd: retCd, retMsg: retMsg, resDate: resDate)

        // data 필드 처리
        if let dataDict = dictionary["data"] as? [String: Any] {
            if let sleepQuality = dataDict["sleepQuality"] as? Int {
                response.data = SleepStopResponse.Data(sleepQuality: sleepQuality)
            } else {
                // sleepQuality가 없거나 Int 타입이 아닌 경우 오류 발생
                print("sleepQuality is missing or invalid")
                response.data = SleepStopResponse.Data(sleepQuality: 0)
                return response
            }
        }

        return response
    }
}
