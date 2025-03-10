import Foundation
import UIKit

/// 프로토콜 핸들러 유틸리티 클래스
open class ProtocolHandlerUtil {
    private var _byteArray: Data = .init()
    private var _dailyByte01Array: Data = .init()
    private var _dailyByte02Array: Data = .init()
        
    /// 바이트 배열을 추가하는 함수
    /// - Parameter data: 추가할 바이트 데이터
    public func addByte(data: Data) {
        _byteArray.append(data) // 기존의 _byteArray에 새로운 data를 추가
    }
    
    public func addDaily01Byte(data: Data) {
        _dailyByte01Array.append(data)
    }

    public func addDaily02Byte(data: Data) {
        _dailyByte02Array.append(data)
    }
        
    /// 데이터를 반환하고 _byteArray를 비우는 함수
    /// - Parameter saveToFile: 파일로 저장할지 여부 (기본값: true)
    /// - Returns: 현재까지 수집된 바이트 데이터
    public func flush(saveToFile: Bool = false) -> Data {
        if _byteArray.isEmpty {
            return Data()
        }
            
        let tempData = _byteArray // 현재 _byteArray를 복사
        _byteArray = Data() // _byteArray 초기화
            
        if saveToFile {
            let fileName = "protocol \(DateUtil.getCurrentDateTime()).bin"
            saveDataToFile(data: tempData, fileName: fileName)
        }
            
        return tempData // 복사한 데이터를 반환
    }
    
    /// 데이터를 반환하고 _byteArray를 비우는 함수
    /// - Parameter saveToFile: 파일로 저장할지 여부 (기본값: true)
    /// - Returns: 현재까지 수집된 바이트 데이터
    public func flushDaily01(saveToFile: Bool = false) -> Data {
        if _dailyByte01Array.isEmpty {
            return Data()
        }
        
        let tempData = _dailyByte01Array // 현재 _byteArray를 복사
        _dailyByte01Array = Data() // _byteArray 초기화
        
        if saveToFile {
            let fileName = "protocol \(DateUtil.getCurrentDateTime()).bin"
            saveDataToFile(data: tempData, fileName: fileName)
        }
        
        return tempData // 복사한 데이터를 반환
    }
    
    /// 데이터를 반환하고 _byteArray를 비우는 함수
    /// - Parameter saveToFile: 파일로 저장할지 여부 (기본값: true)
    /// - Returns: 현재까지 수집된 바이트 데이터
    public func flushDaily02(saveToFile: Bool = false) -> Data {
        if _dailyByte02Array.isEmpty {
            return Data()
        }
        
        let tempData = _dailyByte02Array // 현재 _byteArray를 복사
        _dailyByte02Array = Data() // _byteArray 초기화
        
        if saveToFile {
            let fileName = "protocol \(DateUtil.getCurrentDateTime()).bin"
            saveDataToFile(data: tempData, fileName: fileName)
        }
        
        return tempData // 복사한 데이터를 반환
    }
        
    /// 바이트 데이터를 16진수 문자열로 변환하는 함수
    /// - Parameter data: 변환할 바이트 데이터
    /// - Returns: 16진수 문자열
    public func dataToHexString(data: Data) -> String {
        return data.map { String(format: "%02x", $0) }.joined(separator: " ")
    }
        
    /// 데이터를 파일로 저장하는 함수
    /// - Parameters:
    ///   - data: 저장할 바이트 데이터
    ///   - fileName: 파일 이름
    private func saveDataToFile(data: Data, fileName: String) {
        guard !data.isEmpty else {
            print("No data to save")
            return
        }
            
        do {
            // 문서 디렉토리 경로 가져오기
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                
            // poli_log 디렉토리 경로 생성
            let poliLogDirectory = documentsDirectory.appendingPathComponent("poli_log")
                
            // poli_log 디렉토리가 없으면 생성
            if !FileManager.default.fileExists(atPath: poliLogDirectory.path) {
                try FileManager.default.createDirectory(at: poliLogDirectory, withIntermediateDirectories: true)
            }
                
            // 파일 경로 생성
            let fileURL = poliLogDirectory.appendingPathComponent(fileName)
                
            // 데이터를 파일에 쓰기
            try data.write(to: fileURL)
            print("Data saved to file: \(fileName) in Documents/poli_log folder")
        } catch {
            print("Error saving data to file: \(error.localizedDescription)")
        }
    }
    
    /// 바이트 데이터의 앞부분을 제거하는 함수
    /// - Parameters:
    ///   - data: 처리할 바이트 데이터
    ///   - size: 제거할 바이트 수
    /// - Returns: 앞부분이 제거된 바이트 데이터
    public func removeFrontBytes(data: Data, size: Int) -> Data {
        // 데이터의 길이가 size보다 큰 경우에만 앞의 size 바이트를 제거
        if data.count > size {
            return data.subdata(in: size ..< data.count)
        }
        // 데이터의 길이가 size 이하인 경우 빈 데이터 반환
        return Data()
    }

    // 헥사값을 ASCII로 변환하는 함수
    func hexToAscii(byteArray: [UInt8]) -> String {
        var output = ""
        for byte in byteArray {
            let decimal = Int(byte)
            if let scalar = UnicodeScalar(decimal) {
                output.append(Character(scalar))
            }
        }
        return output
    }

    // ByteArray를 받아서 ASCII 문자열로 변환하고, HRSpO2 객체를 생성하는 함수
    func asciiToHRSpO2(data: Data) throws -> [String: Any] {
        // Data를 [UInt8]로 변환
        let byteArray = [UInt8](data)
    
        let ascii = hexToAscii(byteArray: byteArray)
    
        // Kotlin의 split(":", ",")와 동일한 기능 구현
        let parts = ascii.components(separatedBy: CharacterSet(charactersIn: ":,"))
    
        if parts.count == 3 {
            guard let heartRate = Int(parts[1]),
                  let spo2 = Int(parts[2])
            else {
                throw NSError(domain: "ParsingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert values to integers"])
            }
            return ["oxygenVal": spo2, "heartRateVal": heartRate]
        } else {
            throw NSError(domain: "ParsingError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid ASCII string format"])
        }
    }
}

/// 날짜 유틸리티 클래스
class DateUtil {
    /// 현재 날짜와 시간을 "yyyyMMdd_HHmmss" 형식의 문자열로 반환
    static func getCurrentDateTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return dateFormatter.string(from: Date())
    }
    
    static func adjustDateTime(_ dateTime: String, minusMin: Int64) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let date = formatter.date(from: dateTime) {
            let adjustedDate = Calendar.current.date(byAdding: .minute, value: -Int(minusMin), to: date)!
            return formatter.string(from: adjustedDate)
        }
        return dateTime
    }
}
