import Foundation

// LTMModel 구조체 정의
struct LTMModel: Codable, Equatable {
    let lux: [Lux]
    let skinTemp: [SkinTemp]
    let mets: [Mets]
    
    // Lux 구조체
    struct Lux: Codable, Equatable {
        let lux: Int
        var time: String?
        
        // 간편 초기화를 위한 생성자
        init(value: Int, time: String? = nil) {
            self.lux = value
            self.time = time
        }
    }
    
    // SkinTemp 구조체
    struct SkinTemp: Codable, Equatable {
        let skinTemp: Float
        var time: String?
        
        // 간편 초기화를 위한 생성자
        init(value: Float, time: String? = nil) {
            self.skinTemp = value
            self.time = time
        }
    }
    
    // Mets 구조체
    struct Mets: Codable, Equatable {
        let mets: Int
        var time: String?
        
        // 간편 초기화를 위한 생성자
        init(value: Int, time: String? = nil) {
            self.mets = value
            self.time = time
        }
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
        
        return "LTMModel 인코딩 실패"
    }
    
    // Dictionary로 변환하는 함수
    func toDictionary() -> [String: Any] {
        let luxDicts = lux.map { $0.toDictionary() }
        let skinTempDicts = skinTemp.map { $0.toDictionary() }
        let metsDicts = mets.map { $0.toDictionary() }
        
        return [
            "lux": luxDicts,
            "skinTemp": skinTempDicts,
            "mets": metsDicts
        ]
    }
    
    // Dictionary에서 LTMModel 생성하는 정적 함수
    static func fromDictionary(_ dict: [String: Any]) -> LTMModel? {
        guard let luxArray = dict["lux"] as? [[String: Any]],
              let skinTempArray = dict["skinTemp"] as? [[String: Any]],
              let metsArray = dict["mets"] as? [[String: Any]]
        else {
            return nil
        }
        
        let luxItems = luxArray.compactMap { luxDict -> Lux? in
            guard let luxValue = luxDict["lux"] as? Int else { return nil }
            let time = luxDict["time"] as? String
            return Lux(value: luxValue, time: time)
        }
        
        let skinTempItems = skinTempArray.compactMap { skinTempDict -> SkinTemp? in
            guard let skinTempValue = skinTempDict["skinTemp"] as? Float else { return nil }
            let time = skinTempDict["time"] as? String
            return SkinTemp(value: skinTempValue, time: time)
        }
        
        let metsItems = metsArray.compactMap { metsDict -> Mets? in
            guard let metsValue = metsDict["mets"] as? Int else { return nil }
            let time = metsDict["time"] as? String
            return Mets(value: metsValue, time: time)
        }
        
        return LTMModel(lux: luxItems, skinTemp: skinTempItems, mets: metsItems)
    }
}

// 배열 확장을 통한 편의 메서드
extension Array where Element == LTMModel.Lux {
    func toArray() -> [LTMModel.Lux] {
        return self
    }
}

extension Array where Element == LTMModel.SkinTemp {
    func toArray() -> [LTMModel.SkinTemp] {
        return self
    }
}

extension Array where Element == LTMModel.Mets {
    func toArray() -> [LTMModel.Mets] {
        return self
    }
}

// Lux 구조체에 toDictionary 메서드 추가
extension LTMModel.Lux {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["lux": lux]
        if let time = time {
            dict["time"] = time
        }
        return dict
    }
}

// SkinTemp 구조체에 toDictionary 메서드 추가
extension LTMModel.SkinTemp {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["skinTemp": skinTemp]
        if let time = time {
            dict["time"] = time
        }
        return dict
    }
}

// Mets 구조체에 toDictionary 메서드 추가
extension LTMModel.Mets {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["mets": mets]
        if let time = time {
            dict["time"] = time
        }
        return dict
    }
}
