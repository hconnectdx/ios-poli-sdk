import Foundation

// MARK: - DailyProtocol01Response

public class DailyProtocol01Response: BaseResponse {
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
        public let ltmModel: LTMModel
        
        public init(ltmModel: LTMModel) {
            self.ltmModel = ltmModel
        }
    }
    
    static func convertToDailyResponse(from dictionary: [String: Any], ltmModel: LTMModel) throws -> DailyProtocol01Response {
        // 기본 응답 필드 추출
        let retCd = dictionary["retCd"] as? String ?? ""
        let retMsg = dictionary["retMsg"] as? String ?? ""
        let resDate = dictionary["resDate"] as? String ?? ""
        
        // 기본 응답 객체 생성
        let response = DailyProtocol01Response(retCd: retCd, retMsg: retMsg, resDate: resDate)
        
        // LTMModel 생성
        if let ltmModelTmp = LTMModel.fromDictionary(ltmModel.toDictionary()) {
            response.data = DailyProtocol01Response.Data(ltmModel: ltmModelTmp)
        } else {
            throw NSError(
                domain: "ResponseParsingError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Invalid LTMModel data"]
            )
        }
        
        return response
    }
}
