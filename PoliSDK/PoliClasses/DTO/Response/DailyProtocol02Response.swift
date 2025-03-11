import Foundation

// MARK: - SleepResponse

public class DailyProtocol02Response: BaseResponse {
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
        public let userSystolic: Int
        public let userDiastolic: Int
        public let userStress: Int
        public let userHighGlucose: Int

        public init(userSystolic: Int, userDiastolic: Int, userStress: Int, userHighGlucose: Int) {
            self.userSystolic = userSystolic
            self.userDiastolic = userDiastolic
            self.userStress = userStress
            self.userHighGlucose = userHighGlucose
        }
    }

    public static func convertToDailyResponse(from dictionary: [String: Any]) throws -> DailyProtocol02Response {
        // 기본 응답 필드 추출
        let retCd = dictionary["retCd"] as? String ?? ""
        let retMsg = dictionary["retMsg"] as? String ?? ""
        let resDate = dictionary["resDate"] as? String ?? ""

        // 기본 응답 객체 생성
        let response = DailyProtocol02Response(retCd: retCd, retMsg: retMsg, resDate: resDate)

        // data 필드 처리
        guard let dataDict = dictionary["data"] as? [String: Any] else {
            return response // data 필드가 없으면 기본 응답만 반환
        }

        // 데이터 필드 추출 (nil인 경우 0으로 기본값 설정)
        let userSystolic = dataDict["userSystolic"] as? Int ?? 0
        let userDiastolic = dataDict["userDiastolic"] as? Int ?? 0
        let userStress = dataDict["userStress"] as? Int ?? 0
        let userHighGlucose = dataDict["userHighGlucose"] as? Int ?? 0

        // 데이터 객체 생성 및 할당
        response.data = DailyProtocol02Response.Data(
            userSystolic: userSystolic,
            userDiastolic: userDiastolic,
            userStress: userStress,
            userHighGlucose: userHighGlucose
        )

        return response
    }
}
