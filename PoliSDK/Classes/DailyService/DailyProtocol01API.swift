class DailyProtocol01API: ProtocolHandlerUtil {
    public static let shared = DailyProtocol01API()
    
    // LTMModel 옵셔널 변수
    var ltmModel: LTMModel?
    
    // 각 데이터를 저장할 배열 (private 프로퍼티)
    private var lstLux: [LTMModel.Lux] = []
    private var lstSkinTemp: [LTMModel.SkinTemp] = []
    private var lstMets: [LTMModel.Mets] = []
    
    func request(completion: @escaping (DailyResponse) -> Void) {
        let requestBody: [String: Any] = [
            "reqDate": Date().currentTimeString(),
            "userSno": PoliAPI.shared.userSno,
            "sessionId": PoliAPI.shared.sessionId,
            "data": ltmModel?.toDictionary() as Any,
        ]
        
        // API 요청 수행
        PoliAPI.shared.post(
            path: "/day/protocol1",
            body: requestBody
        ) { result in
            do {
                let response = try DailyResponse.convertToDailyResponse(from: result)
                completion(response)
            } catch {
                print("[Error] Failed to parse SleepProtocol06Response\(error)")
            }
        }
    }
    
    /**
     * 데이터를 카테고리화하여 저장
     * 카테고리화 된 데이터들은 계속 저장되어, 전송할때 취합하여 전송
     * lstMets, lstSkinTemp, lstLux
     * @param data Data 타입 데이터
     */
    func categorizeData(data: Data) {
        let sampleSize = 16
        let totalSamples = 12
        var offset = 2 // 헤더와 dataNum 건너뛰기
        
        // Data를 [UInt8] 배열로 변환
        let bytes = [UInt8](data)
        
        for i in 0..<totalSamples {
            // METs 데이터 추출 (2Bytes * 5EA)
            for j in 0..<5 {
                let metsValue = (UInt16(bytes[offset + 2 * j]) << 8) | UInt16(bytes[offset + 2 * j + 1])
                
                print("DailyProtocol01API - metsValue UInt: \(metsValue)")
                print("DailyProtocol01API - metsValue Int: \(Int(metsValue))")
                
                lstMets.append(LTMModel.Mets(value: Int(metsValue) / 1000))
            }
            
            // Temp 데이터 추출 (4Bytes)
            let tempValue = (Int32(bytes[offset + 10]) << 24) |
                (Int32(bytes[offset + 11]) << 16) |
                (Int32(bytes[offset + 12]) << 8) |
                Int32(bytes[offset + 13])
            
            // Float 비트 변환
            let tempFloat = Float(bitPattern: UInt32(bitPattern: tempValue))
            
            lstSkinTemp.append(
                LTMModel.SkinTemp(value: tempFloat)
            ) // i*5 분씩 감소 해야 함.
            
            // Lux 데이터 추출 (2Bytes)
            let luxValue = (Int(bytes[offset + 14]) << 8) | Int(bytes[offset + 15])
            
            lstLux.append(LTMModel.Lux(value: luxValue))
            
            // 오프셋 증가
            offset += sampleSize
        }
    }
    
    /**
     *  categorizeData 를 통해 lstSkinTemp, lstLux, lstMet 를 모아두고
     *  최종적으로 ltmModel을 만드는 함수
     */
    func createLTMModel() {
        let currentTime = DateUtil.getCurrentDateTime()
        
        // Lux 데이터에 시간 추가 (5분 간격으로 감소)
        let lstLuxWithTime = lstLux.enumerated().map { index, lux in
            var updatedLux = lux
            updatedLux.time = DateUtil.adjustDateTime(currentTime, minusMin: 5 * Int64(index))
            return updatedLux
        }
        
        // SkinTemp 데이터에 시간 추가 (5분 간격으로 감소)
        let lstSkinWithTime = lstSkinTemp.enumerated().map { index, skinTemp in
            var updatedSkinTemp = skinTemp
            updatedSkinTemp.time = DateUtil.adjustDateTime(currentTime, minusMin: 5 * Int64(index))
            return updatedSkinTemp
        }
        
        // Mets 데이터에 시간 추가 (1분 간격으로 감소)
        let lstMetsWithTime = lstMets.enumerated().map { index, mets in
            var updatedMets = mets
            updatedMets.time = DateUtil.adjustDateTime(currentTime, minusMin: Int64(index))
            return updatedMets
        }
        
        // LTMModel 생성
        let ltmModel = LTMModel(
            lux: lstLuxWithTime,
            skinTemp: lstSkinWithTime,
            mets: lstMetsWithTime
        )
        
        // 전역 변수에 할당
        self.ltmModel = ltmModel
    }
    
    let testRawData: Data = .init([
        0x01,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x42,
        0x12,
        0x00,
        0x00,
        0xff,
        0xff,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x41,
        0xc8,
        0x00,
        0x00,
        0x80,
        0x00,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x42,
        0x34,
        0x00,
        0x00,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x42,
        0x12,
        0x00,
        0x00,
        0xff,
        0xff,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x41,
        0xc8,
        0x00,
        0x00,
        0x80,
        0x00,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x42,
        0x34,
        0x00,
        0x00,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x42,
        0x12,
        0x00,
        0x00,
        0xff,
        0xff,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x41,
        0xc8,
        0x00,
        0x00,
        0x80,
        0x00,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x42,
        0x34,
        0x00,
        0x00,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x42,
        0x12,
        0x00,
        0x00,
        0xff,
        0xff,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x41,
        0xc8,
        0x00,
        0x00,
        0x80,
        0x00,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x75,
        0x30,
        0x3a,
        0x98,
        0x00,
        0x00,
        0x42,
        0x34,
        0x00,
        0x00,
        0x00,
        0x00,
    ])
}
