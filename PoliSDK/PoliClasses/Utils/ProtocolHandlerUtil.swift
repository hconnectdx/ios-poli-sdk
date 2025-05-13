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
    
    public func addDaily02ByteNew(data: Data, isLast: Bool = false) {
        // 디버깅용: 들어오는 데이터 정보 출력
        print("▶️ addDaily02ByteNew 호출 - 데이터 크기: \(data.count) 바이트, isLast: \(isLast)")
        if data.count > 0 {
//            print("▶️ 첫 5바이트: \(data.prefix(min(5, data.count)).map { String(format: "%02X", $0) }.joined(separator: " "))")
        }
        
        // 상수 정의
        let maxChunks = isLast ? 48 : 144 // FF일 경우 PPG ECG 24쌍, 평상시에는 72쌍
        let offsetIndexStart = isLast ? 78 : 234
        
        // 1. 입력 데이터 준비 및 검증
        let dataSize = data.count
        let processingSize = min(dataSize, offsetIndexStart)
        
        // 2. 오프셋 값 추출
        let offsetValue = extractOffsetValue(data: data, isLast: isLast)
        
        // 3. 13비트 청크 추출 및 처리
        let intChunks = extractAndProcessChunks(data: data, processingSize: processingSize, offsetValue: offsetValue, maxChunks: maxChunks)
        
        // 각 정수를 4바이트로 변환하고 하나의 Data로 합침
        var byteChunks = Data()
        for chunk in intChunks {
            byteChunks.append(intToByteArray(chunk))
        }
        
        // 4. 원본 바이트 배열 저장
        _dailyByte02Array.append(byteChunks)
        
        // 디버깅용: 처리 후 바이트 배열 크기 출력
        print("▶️ 처리 후 _dailyByte02Array 크기: \(_dailyByte02Array.count) 바이트")
    }
    
    private func intToByteArray(_ value: UInt16) -> Data {
        // UInt16을 4바이트로 확장하여 반환
        return Data([
            UInt8(0), // 최상위 바이트 (패딩)
            UInt8(0), // 두 번째 바이트 (패딩)
            UInt8((value >> 8) & 0xFF), // 세 번째 바이트 (상위 바이트)
            UInt8(value & 0xFF) // 최하위 바이트 (하위 바이트)
        ])
    }
    
    private func extractOffsetValue(data: Data, isLast: Bool) -> Int {
        var offsetValue = 0
        
        if isLast && data.count >= 81 {
            offsetValue = (Int(data[80]) & 0xFF) << 16 |
                (Int(data[79]) & 0xFF) << 8 |
                (Int(data[78]) & 0xFF)
//            print("[오프셋 계산 - Last] 바이트 값: [\(data[78]), \(data[79]), \(data[80])]")
        } else if !isLast && data.count >= 237 {
            offsetValue = (Int(data[236]) & 0xFF) << 16 |
                (Int(data[235]) & 0xFF) << 8 |
                (Int(data[234]) & 0xFF)
//            print("[오프셋 계산 - Normal] 바이트 값: [\(data[234]), \(data[235]), \(data[236])]")
        }
        
//        print("계산된 오프셋 값: \(offsetValue) (0x\(String(offsetValue, radix: 16)), 이진수=\(String(offsetValue, radix: 2).padding(toLength: 24, withPad: "0", startingAt: 0)))")
        
        // 디버깅용: 오프셋을 하드코딩으로 10000으로 설정
        // offsetValue = 10000
        // print("설정된 오프셋 값(하드코딩): \(offsetValue)")
        
        return offsetValue
    }
    
    private func extractAndProcessChunks(data: Data, processingSize: Int, offsetValue: Int, maxChunks: Int) -> [UInt16] {
        var processedChunks = [UInt16](repeating: 0, count: maxChunks)
        var bitPosition = 0
        var currentValue = 0
        var chunkIndex = 0
        
        // 바이트 배열 처리
        for bytePos in 0 ..< processingSize {
            let currentByte = Int(data[bytePos]) & 0xFF
            
            // 각 비트 처리
            for bitInByte in 0 ..< 8 {
                // 비트 추출 및 값 구성
                let bitValue = (currentByte >> bitInByte) & 1
                currentValue = currentValue | (bitValue << bitPosition)
                bitPosition += 1
                
                // 13비트가 모이면 청크 처리
                if bitPosition == 13 {
                    processedChunks[chunkIndex] = processChunk(originalValue: currentValue, chunkIndex: chunkIndex, offsetValue: offsetValue)
                    
                    // 다음 청크 준비
                    currentValue = 0
                    bitPosition = 0
                    chunkIndex += 1
                    
                    if chunkIndex >= maxChunks { break }
                }
            }
            
            if chunkIndex >= maxChunks { break }
        }
        
        // 남은 비트가 있으면 마지막 청크 처리
        if bitPosition > 0, chunkIndex < maxChunks {
            processedChunks[chunkIndex] = processChunk(originalValue: currentValue, chunkIndex: chunkIndex, offsetValue: offsetValue)
        }
        
        return processedChunks
    }
    
    private func processChunk(originalValue: Int, chunkIndex: Int, offsetValue: Int) -> UInt16 {
        let isEvenChunk = chunkIndex % 2 == 0
        var finalValue: Int
        
        if isEvenChunk {
            // 짝수 청크: 원래 값 + 오프셋
            finalValue = (originalValue + offsetValue) & 0xFFFFFFFF
//            print("[짝수 청크 계산] 원본값(\(originalValue)) + 오프셋(\(offsetValue)) = \(finalValue)")
        } else {
            // 홀수 청크: 3비트 쉬프트 후 int16_t 변환 (16비트로 제한)
            // 부호 확장 방지를 위해 딱 16비트만 유지
            finalValue = (originalValue << 3) & 0xFFFF
//            print("[홀수 청크 계산] 원본값(\(originalValue)) << 3 = \(finalValue)")
        }
        
        // 로그 출력
        logChunkProcessing(originalValue: originalValue, finalValue: finalValue, chunkIndex: chunkIndex)
        
        // 최종값은 16비트로 제한됩니다 (8비트에서 수정)
        return UInt16(truncatingIfNeeded: finalValue)
    }
    
    private func logChunkProcessing(originalValue: Int, finalValue: Int, chunkIndex: Int) {
        let isEvenChunk = chunkIndex % 2 == 0
        let chunkType = isEvenChunk ? "짝수" : "홀수"
        let binaryOriginal = String(originalValue, radix: 2).padding(toLength: 13, withPad: "0", startingAt: 0)
        let binaryFinal = String(finalValue, radix: 2).padding(toLength: isEvenChunk ? 24 : 16, withPad: "0", startingAt: 0)
        
//        print("\(chunkType) Chunk[\(chunkIndex)]: 원래값=\(originalValue) (0x\(String(originalValue, radix: 16)), 이진수=\(binaryOriginal)), 최종값=\(finalValue) (0x\(String(finalValue, radix: 16)), 이진수=\(binaryFinal))")
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
        let currentSize = _dailyByte02Array.count
        print("⚠️ flushDaily02 호출 - 현재 크기: \(currentSize) 바이트")
        
        if _dailyByte02Array.isEmpty {
            print("⚠️ _dailyByte02Array가 비어있어 빈 데이터 반환")
            return Data()
        }
        
        let tempData = _dailyByte02Array // 현재 _byteArray를 복사
        _dailyByte02Array = Data() // _byteArray 초기화
        
        print("⚠️ flushDaily02 완료 - 반환 크기: \(tempData.count) 바이트, _dailyByte02Array는 초기화됨")
        
        if saveToFile {
            let fileName = "protocol \(DateUtil.getCurrentDateTime()).bin"
            saveDataToFile(data: tempData, fileName: fileName)
        }
        
        return tempData // 복사한 데이터를 반환
    }
    
    /// 현재 _dailyByte02Array의 크기를 반환하는 함수
    /// - Returns: 현재까지 수집된 데이터의 크기
    public func getDaily02ByteArraySize() -> Int {
        return _dailyByte02Array.count
    }
    
    /// _dailyByte02Array를 비우는 함수
    public func clearDaily02ByteArray() {
        _dailyByte02Array = Data()
    }
    
    /// 현재 _dailyByte02Array의 데이터를 파일로 저장하고 경로를 반환하는 함수 (데이터를 비우지 않음)
    /// - Parameter fileName: 저장할 파일 이름
    /// - Returns: 저장된 파일의 경로
    public func saveDaily02DataToFile(fileName: String) -> String {
        if _dailyByte02Array.isEmpty {
            print("⚠️ _dailyByte02Array가 비어있어 파일로 저장할 수 없습니다.")
            return ""
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
            try _dailyByte02Array.write(to: fileURL)
            print("데이터가 파일에 성공적으로 저장되었습니다: \(fileName)")
            print("파일 경로: \(fileURL.path)")
            
            return fileURL.path
        } catch {
            print("Error saving data to file: \(error.localizedDescription)")
            return ""
        }
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
