import Foundation

// MARK: - DailyResponse

public class DailyResponse: BaseResponse {
    public var data: Data?

    // required 초기화 메서드 구현
    public required init(retCd: String = "", retMsg: String = "", resDate: String = "") {
        super.init(retCd: retCd, retMsg: retMsg, resDate: resDate)
    }

    public init() {
        super.init()
    }

    public static func convertToDailyResponse(from dictionary: [String: Any]) throws -> DailyResponse {
        // 기본 응답 필드 추출
        let retCd = dictionary["retCd"] as? String ?? ""
        let retMsg = dictionary["retMsg"] as? String ?? ""
        let resDate = dictionary["resDate"] as? String ?? ""

        // SleepStartResponse 객체 생성
        let response = DailyResponse(retCd: retCd, retMsg: retMsg, resDate: resDate)

        return response
    }
}
