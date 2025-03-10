//
//  PoliAPI.swift
//  PoliSDK
//
//  Created by 곽민우 on 3/4/25.
//

import Foundation

public class PoliAPI {
    // MARK: - Singleton

    public static let shared = PoliAPI()

    // MARK: - Properties

    private var baseUrl: String = ""
    private var clientId: String = ""
    private var clientSecret: String = ""
    private var session: URLSession!
    private var _userAge: Int = 0
    public var userAge: Int {
        get {
            return _userAge
        }
        set {
            _userAge = newValue
        }
    }
    
    private var _userSno: Int = 0
    public var userSno: Int {
        get {
            return _userSno
        }
        set {
            _userSno = newValue
        }
    }
    
    private var _sessionId: String = ""
    public var sessionId: String {
        get {
            return _sessionId
        }
        set {
            _sessionId = newValue
        }
    }
    
    public func initialize(baseUrl: String, clientId: String, clientSecret: String) {
        self.baseUrl = baseUrl
        self.clientId = clientId
        self.clientSecret = clientSecret
        
        // URLSession 설정
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 30.0
        
        session = URLSession(configuration: configuration)
    }
    
    /// GET 요청 수행
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: URL 파라미터
    ///   - completion: 완료 콜백
    public func get<T: Decodable>(path: String, parameters: [String: String]? = nil, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = buildURL(path: path, parameters: parameters) else {
            completion(.failure(PoliError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addDefaultHeaders(to: &request)
        
        logRequest(request)
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            self?.handleResponse(data: data, response: response, error: error, completion: completion)
        }
        
        task.resume()
    }
    
    /// POST 요청 수행
    /// - Parameters:
    ///   - path: API 경로
    ///   - body: 요청 바디
    ///   - completion: 완료 콜백
    public func post(
        path: String,
        body: [String: Any],
        completion: @escaping ([String: Any]) -> Void)
    {
        // URL 생성
        guard let url = URL(string: baseUrl + path) else {
            print("Invalid URL")
            return
        }
        
        // 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addDefaultHeaders(to: &request)
        
        // 요청 바디 설정
        do {
            logRequest(request)
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error: \(error)")
            return
        }
        
        // 네트워크 요청 실행
        URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            
            // 응답 로깅
            if let urlResponse = urlResponse {
                self.logResponse(urlResponse, data: data, error: error)
            }
            
            if let error = error {
                return
            }
            guard let data = data else {
                return
            }
            
            do {
                // JSON 파싱
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Invalid JSON")
                    return
                }
                completion(json)
            } catch {
                return
            }
        }.resume()
    }
    
    /// 멀티파트 폼 데이터로 POST 요청 수행
    /// - Parameters:
    ///   - path: API 경로
    ///   - parameters: 텍스트 파라미터 딕셔너리
    ///   - fileData: 파일 데이터
    ///   - fileName: 파일 이름 (기본값: 빈 문자열)
    ///   - fileParameterName: 파일 파라미터 이름 (기본값: "file")
    ///   - mimeType: 파일 MIME 타입 (기본값: "application/octet-stream")
    ///   - completion: 완료 콜백
    public func postMultipart(
        path: String,
        parameters: [String: Any],
        fileData: Data,
        fileName: String = "file.bin",
        fileParameterName: String = "file",
        mimeType: String = "application/octet-stream",
        completion: @escaping ([String: Any]) -> Void)
    {
        // URL 생성
        guard let url = URL(string: baseUrl + path) else {
            print("Invalid URL")
            return
        }
        
        // 경계선 문자열 생성
        let boundary = UUID().uuidString
        
        // 요청 생성
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // 기본 헤더 추가
        request.addValue(clientId, forHTTPHeaderField: "ClientId")
        request.addValue(clientSecret, forHTTPHeaderField: "ClientSecret")
        
        // 멀티파트 폼 데이터 생성
        let httpBody = createMultipartFormData(parameters: parameters, fileData: fileData, fileName: fileName, fileParameterName: fileParameterName, mimeType: mimeType, boundary: boundary)
        
        // 요청 바디 설정
        request.httpBody = httpBody
        
        // 요청 로깅
        logRequest(request)
        
        // 네트워크 요청 실행
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // 응답 로깅
            if let response = response {
                self.logResponse(response, data: data, error: error)
            }
            
            // 오류 처리
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                return
            }
            
            // 데이터 확인
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                // JSON 파싱
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                    print("Invalid JSON")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("Response data: \(responseString)")
                    }
                    return
                }
                
                // 완료 콜백 호출
                DispatchQueue.main.async {
                    completion(json)
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response data: \(responseString)")
                }
                return
            }
        }.resume()
    }
    
    // 멀티파트 폼 데이터 생성 함수
    private func createMultipartFormData(
        parameters: [String: Any],
        fileData: Data,
        fileName: String,
        fileParameterName: String,
        mimeType: String,
        boundary: String) -> Data
    {
        var body = Data()
        
        // 텍스트 파라미터 추가
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // 파일 데이터 추가
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fileParameterName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // 멀티파트 폼 데이터 종료
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    // MARK: - Private Methods
    
    /// URL 생성
    private func buildURL(path: String, parameters: [String: String]? = nil) -> URL? {
        guard var components = URLComponents(string: baseUrl + path) else {
            return nil
        }
        
        if let parameters = parameters {
            components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        return components.url
    }
    
    /// 기본 헤더 추가
    private func addDefaultHeaders(to request: inout URLRequest) {
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(clientId, forHTTPHeaderField: "ClientId")
        request.addValue(clientSecret, forHTTPHeaderField: "ClientSecret")
    }
    
    /// 요청 로깅
    private func logRequest(_ request: URLRequest) {
        print("\n[Request]")
        print("Method: \(request.httpMethod ?? "Unknown")")
        print("URL: \(request.url?.absoluteString ?? "Unknown")")
        
        if let headers = request.allHTTPHeaderFields {
            print("Headers: \(headers)")
        }
        
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("Body: \(prettyPrintJson(bodyString))")
        }
    }
    
    /// 응답 로깅
    private func logResponse(_ response: URLResponse, data: Data? = nil, error: Error? = nil) {
        print("\n[Response]")
        
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
            print("Status Message: \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
            print("URL: \(response.url?.absoluteString ?? "Unknown")")
            print("MIME Type: \(response.mimeType ?? "Unknown")")
            print("Expected Content Length: \(response.expectedContentLength)")
            
            if let headers = httpResponse.allHeaderFields as? [String: Any] {
                print("Headers: \(headers)")
            }
        } else {
            print("Status: \(response)")
        }
        
        if let error = error {
            print("Error: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("Error Code: \(nsError.code)")
                print("Error Domain: \(nsError.domain)")
                if let failureReason = nsError.localizedFailureReason {
                    print("Failure Reason: \(failureReason)")
                }
            }
        }
        
        if let data = data {
            print("Data Size: \(data.count) bytes")
            
            if let bodyString = String(data: data, encoding: .utf8) {
                print("Body: \(prettyPrintJson(bodyString))")
            } else {
                print("Body: [Binary data]")
            }
        } else {
            print("Body: [No data]")
        }
    }
    
    /// 응답 로깅 및 처리
    private func handleResponse<T: Decodable>(data: Data?, response: URLResponse?, error: Error?, completion: @escaping (Result<T, Error>) -> Void) {
        if let error = error {
            print("\n[Response Error]")
            print("Error: \(error.localizedDescription)")
            completion(.failure(error))
            return
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(PoliError.invalidResponse))
            return
        }
        
        print("\n[Response]")
        print("Status: \(httpResponse.statusCode)")
        print("Headers: \(httpResponse.allHeaderFields)")
        
        guard let data = data else {
            completion(.failure(PoliError.noData))
            return
        }
        
        if let bodyString = String(data: data, encoding: .utf8) {
            print("Body: \(prettyPrintJson(bodyString))")
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(T.self, from: data)
            completion(.success(result))
        } catch {
            print("Decoding error: \(error)")
            completion(.failure(error))
        }
    }
    
    /// JSON 문자열을 보기 좋게 변환
    private func prettyPrintJson(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8)
        else {
            return jsonString
        }
        return prettyString
    }
}

// MARK: - Error Types

extension PoliAPI {
    enum PoliError: Error {
        case notInitialized
        case invalidURL
        case invalidResponse
        case noData
        
        var localizedDescription: String {
            switch self {
            case .notInitialized:
                return "PoliClient is not initialized"
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response"
            case .noData:
                return "No data received"
            }
        }
    }
}

public extension PoliAPI {
    func requestSleepStart(completion: @escaping (SleepResponse) -> Void) {
        SleepSessionAPI.shared.requestSleepStart(completion: { response in
            completion(response)
        })
    }
    
    func requestSleepStop(completion: @escaping (SleepStopResponse) -> Void) {
        SleepSessionAPI.shared.requestSleepStop(completion: { response in
            completion(response)
        })
    }
    
    func requestProtocol01(completion: @escaping (DailyResponse) -> Void) {
        DailyProtocol01API.shared.categorizeData(data: DailyProtocol01API.shared.testRawData)
        DailyProtocol01API.shared.createLTMModel()
        DailyProtocol01API.shared.request { response in
            completion(response)
        }
    }
    
    func requestSleepProtocol06(completion: @escaping (SleepResponse) -> Void) {
        SleepProtocol06API.shared.request(completion: { response in
            completion(response)
        })
    }
    
    func requestSleepProtocol09(data: [String: Any], completion: @escaping (SleepResponse) -> Void) {
        SleepProtocol09API.shared.request(data: data, completion: { response in
            completion(response)
        })
    }
}
