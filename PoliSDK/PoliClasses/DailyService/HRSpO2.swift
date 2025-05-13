import Foundation

// HRSpO2 구조체 정의
public struct HRSpO2: Codable, Equatable {
    public let heartRate: Int
    public let spo2: Int
    
    // 간편 초기화를 위한 생성자
    public init(heartRate: Int, spo2: Int) {
        self.heartRate = heartRate
        self.spo2 = spo2
    }
    
    // 문자열 표현 메서드 (JSON 형식)
    func toString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("JSON 인코딩 오류: \(error)")
        }
        
        return "HRSpO2 인코딩 실패"
    }
    
    // Dictionary로 변환하는 함수
    func toDictionary() -> [String: Any] {
        return [
            "heartRate": heartRate,
            "spo2": spo2
        ]
    }
    
    // Dictionary에서 HRSpO2 생성하는 정적 함수
    static func fromDictionary(_ dict: [String: Any]) -> HRSpO2? {
        guard let heartRate = dict["heartRate"] as? Int,
              let spo2 = dict["spo2"] as? Int
        else {
            return nil
        }
        
        return HRSpO2(heartRate: heartRate, spo2: spo2)
    }
}
