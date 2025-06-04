import Foundation

// MARK: - DailyProtocol03Response

public class DailyProtocol03Response: BaseResponse {
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
        public var hrSpO2: HRSpO2
        
        public init(hrSpO2: HRSpO2) {
            self.hrSpO2 = hrSpO2
        }
    }
    
    public static func convertToDailyResponse(from dictionary: [String: Any]) throws -> DailyProtocol03Response {
        // 기본 응답 필드 추출
        let retCd = dictionary["retCd"] as? String ?? ""
        let retMsg = dictionary["retMsg"] as? String ?? ""
        let resDate = dictionary["resDate"] as? String ?? ""
        
        // 기본 응답 객체 생성
        let response = DailyProtocol03Response(retCd: retCd, retMsg: retMsg, resDate: resDate)
        
        // data 필드 처리
        if let dataDict = dictionary["data"] as? [String: Any] {
            let heartRateVal = dataDict["heartRateVal"] as? Int
            let oxygenVal = dataDict["oxygenVal"] as? Int
            
            let hrSpO2 = HRSpO2(heartRate: heartRateVal, spo2: oxygenVal)
            response.data = DailyProtocol03Response.Data(hrSpO2: hrSpO2)
        }
        
        return response
    }
}
