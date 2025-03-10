import Foundation

// MARK: - SleepResponse

public class SleepResponse: BaseResponse {
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
        public let sessionId: String

        public init(sessionId: String) {
            self.sessionId = sessionId
        }
    }

    public static func convertToSleepResponse(from dictionary: [String: Any]) throws -> SleepResponse {
        // 기본 응답 필드 추출
        let retCd = dictionary["retCd"] as? String ?? ""
        let retMsg = dictionary["retMsg"] as? String ?? ""
        let resDate = dictionary["resDate"] as? String ?? ""

        // SleepStartResponse 객체 생성
        let response = SleepResponse(retCd: retCd, retMsg: retMsg, resDate: resDate)

        // data 필드 처리
        if let dataDict = dictionary["data"] as? [String: Any] {
            if let sessionId = dataDict["sessionId"] as? String {
                response.data = SleepResponse.Data(sessionId: sessionId)
            } else {
                // sessionId가 없거나 String 타입이 아닌 경우 오류 발생
                throw NSError(
                    domain: "ResponseParsingError",
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Missing or invalid sessionId in data"]
                )
            }
        }

        return response
    }
}
