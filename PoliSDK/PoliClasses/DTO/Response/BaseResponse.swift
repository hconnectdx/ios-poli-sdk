// 기본 응답 클래스 정의
public class BaseResponse {
    public var retCd: String
    public var retMsg: String
    public var resDate: String

    // 기본 생성자
    public required init(retCd: String = "", retMsg: String = "", resDate: String = "") {
        self.retCd = retCd
        self.retMsg = retMsg
        self.resDate = resDate
    }
}
