import Combine
import Foundation
import os

// MARK: - API配置
enum APIConfig {
    private static func value(for key: String, default defaultValue: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? defaultValue
    }

    static var baseURL: String {
        value(for: "APIBaseURL", default: "http://8.156.83.92:8080/api/v1")
    }

    static var jdDemoBaseURL: String {
        value(for: "JDDemoBaseURL", default: "http://8.156.83.92:8080")
    }

    static var ragBaseURL: String {
        value(for: "RAGBaseURL", default: "http://8.156.83.92:8001")
    }

    static let timeout: TimeInterval = 30
    static let accessTokenKey = "accessToken"
    static let refreshTokenKey = "refreshToken"
    static let userIdKey = "userId"
    static let userEmailKey = "userEmail"
    static let isLoggedInKey = "isLoggedIn"
    static let allowMockDataKey = "AegisFlow.AllowMockData"

    static var shouldAllowMockData: Bool {
        UserDefaults.standard.bool(forKey: allowMockDataKey)
    }
}

// MARK: - API端点枚举
enum AegisAPI {
    // Auth
    case register(email: String, password: String, name: String, emailCode: String)
    case login(email: String, password: String)
    case refreshToken(refreshToken: String)
    case logout(refreshToken: String)
    case captcha
    case sendCode(email: String, captchaId: String, captchaAnswer: String)

    // Users
    case getProfile
    case updateProfile(name: String?, heightCm: Float?, weightKg: Float?)

    // Health
    case getDailyHealth(date: String?)
    case getWeeklyHealth(startDate: String?)

    // Logs
    case createLog(type: String, value: Int?, tags: [String]?, notes: String?)
    case getLogHistory(type: String?, startDate: String?, endDate: String?, limit: Int)
    case deleteLog(id: String)

    // Insights
    case getTodayInsights
    case getMotivation(steps: Int, stepsGoal: Int, waterMl: Int, waterGoal: Int, timeOfDay: String)
    case getWeeklyMotivation(steps: Int, stepsGoal: Int, waterMl: Int, waterGoal: Int)
    case getSmartRecommend(steps: Int, stepsGoal: Int, waterMl: Int, waterGoal: Int)
    case planAdjust(currentPlan: [String: Any], feedback: String)
    case generateHabits(goals: [String], lifestyle: [String: Any])
    case insightsChat(message: String, context: [String: Any]?)
    case generateExercisePlan(userRequest: String, sportType: String?, fitnessLevel: String)
    case dietaryCare(meals: [[String: Any]])
    case weeklyDietaryCare(startDate: String, endDate: String)
    case multimodalAnalyze(text: String?, imageBase64: String?)
    case getUserInsights(userId: String?)

    // Chat
    case sendChatMessage(message: String, context: [String: Any]?)
    case getChatHistory(limit: Int, offset: Int)

    // Devices
    case bindDevice(address: String, name: String, type: String)
    case unbindDevice(address: String)
    case getDevices
    case syncDeviceData(deviceAddress: String, healthData: [String: Any])
    case registerFcm(token: String)
    case unregisterFcm(token: String)
    case recordNotificationAction(notificationId: String, action: String)

    // Analysis
    case analyzeFoodImage

    // Twin 3D
    case getTwin3DOptions
    case getTwin3DDefaults
    case deleteTwin3DDefaults
    case submitTwin3D(description: String)
    case submitTwin3DProfile(profile: [String: Any])
    case submitTwin3DPhoto
    case queryTwin3D(jobId: String)
    case queryTwin3DWait(jobId: String)
    case avatarInteract(action: String, parameters: [String: Any]?)

    // Avatar (profile / customization)
    case getAvatar
    case saveAvatar(name: String, customization: [Int], equippedItems: [String: Int])
    case saveAvatarCustomization(customization: [Int], tab: Int)
    case equipAvatarItem(category: Int, itemIndex: Int)
    case resetAvatar
    case getAvatarHistory

    // JD Demo (external URLs)
    case sendJdDemoChat(message: String, sessionId: String?)
    case getJdOpenAppLink(itemId: String)
    case decideJdMode(query: String)
    case generateJdPage(prompt: String, sessionId: String?)
    case getJdPageHistory(sessionId: String)
}

// MARK: - 请求路径
extension AegisAPI {
    var path: String {
        switch self {
        case .register: return "/auth/register"
        case .login: return "/auth/login"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/auth/logout"
        case .captcha: return "/auth/captcha"
        case .sendCode: return "/auth/send-code"
        case .getProfile: return "/users/profile"
        case .updateProfile: return "/users/profile"
        case .getDailyHealth: return "/health/daily"
        case .getWeeklyHealth: return "/health/weekly"
        case .createLog: return "/logs"
        case .getLogHistory: return "/logs/history"
        case .deleteLog(let id): return "/logs/\(id)"
        case .getTodayInsights: return "/insights/today"
        case .getMotivation: return "/insights/motivation"
        case .getWeeklyMotivation: return "/insights/weekly-motivation"
        case .getSmartRecommend: return "/insights/smart-recommend"
        case .planAdjust: return "/insights/plan-adjust"
        case .generateHabits: return "/insights/generate-habits"
        case .insightsChat: return "/insights/chat"
        case .generateExercisePlan: return "/insights/generate-plan"
        case .dietaryCare: return "/insights/dietary-care"
        case .weeklyDietaryCare: return "/insights/weekly-dietary-care"
        case .multimodalAnalyze: return "/insights/multimodal-analyze"
        case .getUserInsights: return "/insights/user-insights"
        case .sendChatMessage: return "/chat/completions"
        case .getChatHistory: return "/chat/history"
        case .bindDevice: return "/devices/bind"
        case .unbindDevice(let address): return "/devices/\(address)"
        case .getDevices: return "/devices"
        case .syncDeviceData: return "/devices/sync"
        case .registerFcm: return "/devices/register-fcm"
        case .unregisterFcm: return "/devices/unregister-fcm"
        case .recordNotificationAction: return "/notifications/action"
        case .analyzeFoodImage: return "/analysis/food"
        case .getTwin3DOptions: return "/twin/generate-3d/options"
        case .getTwin3DDefaults: return "/twin/generate-3d/defaults"
        case .deleteTwin3DDefaults: return "/twin/generate-3d/defaults"
        case .submitTwin3D: return "/twin/generate-3d"
        case .submitTwin3DProfile: return "/twin/generate-3d/profile"
        case .submitTwin3DPhoto: return "/twin/generate-3d/photo"
        case .queryTwin3D: return "/twin/query-3d"
        case .queryTwin3DWait: return "/twin/query-3d/wait"
        case .avatarInteract: return "/twin/avatar/interact"
        case .getAvatar: return "/avatar"
        case .saveAvatar: return "/avatar/save"
        case .saveAvatarCustomization: return "/avatar/customization"
        case .equipAvatarItem: return "/avatar/equip"
        case .resetAvatar: return "/avatar/reset"
        case .getAvatarHistory: return "/avatar/history"
        case .sendJdDemoChat: return "/sendJdDemoChat"
        case .getJdOpenAppLink: return "/getJdOpenAppLink"
        case .decideJdMode: return "/decideJdMode"
        case .generateJdPage: return "/generateJdPage"
        case .getJdPageHistory: return "/getJdPageHistory"
        }
    }

    var method: String {
        switch self {
        case .getProfile, .getDailyHealth, .getWeeklyHealth, .getLogHistory,
            .getTodayInsights, .getChatHistory, .getDevices,
            .getTwin3DOptions, .getTwin3DDefaults, .queryTwin3D, .queryTwin3DWait,
            .getUserInsights, .getJdPageHistory, .getAvatar, .getAvatarHistory:
            return "GET"
        case .updateProfile:
            return "PUT"
        case .deleteLog, .unbindDevice, .unregisterFcm, .deleteTwin3DDefaults:
            return "DELETE"
        default:
            return "POST"
        }
    }

    var usesExternalBaseURL: Bool {
        switch self {
        case .sendJdDemoChat, .getJdOpenAppLink, .decideJdMode,
            .generateJdPage, .getJdPageHistory:
            return true
        default:
            return false
        }
    }

    var isMultipart: Bool {
        switch self {
        case .analyzeFoodImage, .submitTwin3DPhoto:
            return true
        default:
            return false
        }
    }
}

// MARK: - API响应
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String?
    let data: T?
    let errorCode: String?
    let timestamp: String?
}

// MARK: - 通用响应
struct EmptyResponse: Codable {}

// MARK: - 网络错误
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized
    case networkUnavailable
    case tokenRefreshFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .noData: return "没有数据"
        case .decodingError(let error): return "解码错误: \(error.localizedDescription)"
        case .serverError(let message): return "服务器错误: \(message)"
        case .unauthorized: return "未授权"
        case .networkUnavailable: return "网络不可用"
        case .tokenRefreshFailed: return "令牌刷新失败"
        }
    }
}

// MARK: - 刷新令牌互斥状态（配合 OSAllocatedUnfairLock，避免在 async 中使用 NSLock）
private final class TokenRefreshState: @unchecked Sendable {
    var isRefreshing = false
    var pending: [CheckedContinuation<Void, Never>] = []
}

// MARK: - API客户端
class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let tokenRefreshLock = OSAllocatedUnfairLock(initialState: TokenRefreshState())

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfig.timeout
        self.session = URLSession(configuration: config)
    }

    private var authToken: String? {
        get { UserDefaults.standard.string(forKey: APIConfig.accessTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: APIConfig.accessTokenKey) }
    }

    private var refreshTokenValue: String? {
        get { UserDefaults.standard.string(forKey: APIConfig.refreshTokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: APIConfig.refreshTokenKey) }
    }

    // MARK: - 请求方法
    func request<T: Codable>(_ endpoint: AegisAPI, responseType: T.Type) async throws -> T {
        let urlRequest = try buildRequest(for: endpoint)
        return try await executeWithAutoRefresh(
            urlRequest, endpoint: endpoint, responseType: responseType)
    }

    // MARK: - 兼容旧接口（字符串 endpoint）
    func request(
        endpoint: String,
        method: String,
        parameters: [String: Any]? = nil
    ) async throws -> [String: Any] {
        let request = try buildLegacyRequest(
            endpoint: endpoint, method: method, parameters: parameters)
        return try await executeLegacyWithAutoRefresh(request)
    }

    // MARK: - Multipart上传
    func uploadMultipart<T: Codable>(
        _ endpoint: AegisAPI,
        imageData: Data,
        fileName: String = "image.jpg",
        mimeType: String = "image/jpeg",
        fieldName: String = "file",
        additionalFields: [String: String]? = nil,
        responseType: T.Type
    ) async throws -> T {
        let baseURL = endpoint.usesExternalBaseURL ? APIConfig.jdDemoBaseURL : APIConfig.baseURL
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.timeoutInterval = APIConfig.timeout

        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue(
            "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        if let fields = additionalFields {
            for (key, value) in fields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append(
                    "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append(
            "Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n"
                .data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        return try await executeWithAutoRefresh(
            request, endpoint: endpoint, responseType: responseType)
    }

    // MARK: - 构建请求
    private func buildRequest(for endpoint: AegisAPI) throws -> URLRequest {
        let baseURL = endpoint.usesExternalBaseURL ? APIConfig.jdDemoBaseURL : APIConfig.baseURL
        guard var urlComponents = URLComponents(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }

        let queryItems = buildQueryItems(for: endpoint)
        if !queryItems.isEmpty {
            urlComponents.queryItems = queryItems
        }

        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.timeoutInterval = APIConfig.timeout

        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = createBody(for: endpoint) {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        return request
    }

    private func buildLegacyRequest(
        endpoint: String,
        method: String,
        parameters: [String: Any]?
    ) throws -> URLRequest {
        let fullURLString: String
        if endpoint.hasPrefix("http://") || endpoint.hasPrefix("https://") {
            fullURLString = endpoint
        } else if endpoint.hasPrefix("/api/") {
            fullURLString = APIConfig.jdDemoBaseURL + endpoint
        } else {
            fullURLString = APIConfig.baseURL + endpoint
        }

        guard let url = URL(string: fullURLString) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = APIConfig.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }

        return request
    }

    // MARK: - 查询参数
    private func buildQueryItems(for endpoint: AegisAPI) -> [URLQueryItem] {
        var items: [URLQueryItem] = []

        switch endpoint {
        case .getDailyHealth(let date):
            if let date = date { items.append(URLQueryItem(name: "date", value: date)) }

        case .getWeeklyHealth(let startDate):
            if let startDate = startDate {
                items.append(URLQueryItem(name: "startDate", value: startDate))
            }

        case .getLogHistory(let type, let startDate, let endDate, let limit):
            if let type = type { items.append(URLQueryItem(name: "type", value: type)) }
            if let startDate = startDate {
                items.append(URLQueryItem(name: "startDate", value: startDate))
            }
            if let endDate = endDate { items.append(URLQueryItem(name: "endDate", value: endDate)) }
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))

        case .getChatHistory(let limit, let offset):
            items.append(URLQueryItem(name: "limit", value: "\(limit)"))
            items.append(URLQueryItem(name: "offset", value: "\(offset)"))

        case .queryTwin3D(let jobId):
            items.append(URLQueryItem(name: "jobId", value: jobId))

        case .queryTwin3DWait(let jobId):
            items.append(URLQueryItem(name: "jobId", value: jobId))

        case .getUserInsights(let userId):
            if let userId = userId { items.append(URLQueryItem(name: "userId", value: userId)) }

        case .getJdPageHistory(let sessionId):
            items.append(URLQueryItem(name: "sessionId", value: sessionId))

        default:
            break
        }

        return items
    }

    // MARK: - 执行请求（带自动刷新令牌）
    private func executeWithAutoRefresh<T: Codable>(
        _ request: URLRequest,
        endpoint: AegisAPI,
        responseType: T.Type
    ) async throws -> T {
        do {
            return try await execute(request, responseType: responseType)
        } catch NetworkError.unauthorized {
            if case .refreshToken = endpoint { throw NetworkError.unauthorized }
            if case .login = endpoint { throw NetworkError.unauthorized }

            let newToken = try await attemptTokenRefresh()

            var retryRequest = request
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            return try await execute(retryRequest, responseType: responseType)
        }
    }

    private func execute<T: Codable>(_ request: URLRequest, responseType: T.Type) async throws -> T
    {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        do {
            let apiResponse = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            if apiResponse.success, let responseData = apiResponse.data {
                return responseData
            } else {
                throw NetworkError.serverError(apiResponse.message ?? "未知错误")
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func executeLegacyWithAutoRefresh(_ request: URLRequest) async throws -> [String: Any] {
        do {
            return try await executeLegacy(request)
        } catch NetworkError.unauthorized {
            let newToken = try await attemptTokenRefresh()
            var retryRequest = request
            retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
            return try await executeLegacy(retryRequest)
        }
    }

    private func executeLegacy(_ request: URLRequest) async throws -> [String: Any] {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw NetworkError.decodingError(NSError(domain: "APIClient", code: -1))
        }

        if let success = object["success"] as? Bool, !success {
            throw NetworkError.serverError((object["message"] as? String) ?? "未知错误")
        }

        return object
    }

    // MARK: - 令牌自动刷新
    private func attemptTokenRefresh() async throws -> String {
        let shouldWait = tokenRefreshLock.withLock { state -> Bool in
            if state.isRefreshing {
                return true
            }
            state.isRefreshing = true
            return false
        }

        if shouldWait {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                tokenRefreshLock.withLock { state in
                    state.pending.append(continuation)
                }
            }
            guard let token = authToken else { throw NetworkError.tokenRefreshFailed }
            return token
        }

        defer {
            let waiters = tokenRefreshLock.withLock { state -> [CheckedContinuation<Void, Never>] in
                state.isRefreshing = false
                let w = state.pending
                state.pending.removeAll()
                return w
            }
            waiters.forEach { $0.resume() }
        }

        guard let refreshToken = refreshTokenValue else {
            throw NetworkError.unauthorized
        }

        guard let url = URL(string: APIConfig.baseURL + "/auth/refresh") else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = APIConfig.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "refreshToken": refreshToken
        ])

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            authToken = nil
            refreshTokenValue = nil
            UserDefaults.standard.set(false, forKey: APIConfig.isLoggedInKey)
            throw NetworkError.unauthorized
        }

        struct TokenResponse: Codable {
            let accessToken: String
            let refreshToken: String?
        }

        let apiResponse = try JSONDecoder().decode(APIResponse<TokenResponse>.self, from: data)
        guard apiResponse.success, let tokenData = apiResponse.data else {
            throw NetworkError.tokenRefreshFailed
        }

        authToken = tokenData.accessToken
        if let newRefresh = tokenData.refreshToken {
            refreshTokenValue = newRefresh
        }

        return tokenData.accessToken
    }

    // MARK: - 创建请求体
    private func createBody(for endpoint: AegisAPI) -> [String: Any]? {
        switch endpoint {
        case .register(let email, let password, let name, let emailCode):
            return ["email": email, "password": password, "name": name, "emailCode": emailCode]

        case .login(let email, let password):
            return ["email": email, "password": password]

        case .refreshToken(let token):
            return ["refreshToken": token]

        case .logout(let token):
            return ["refreshToken": token]

        case .sendCode(let email, let captchaId, let captchaAnswer):
            return ["email": email, "captchaId": captchaId, "captchaAnswer": captchaAnswer]

        case .updateProfile(let name, let heightCm, let weightKg):
            var body: [String: Any] = [:]
            if let name = name { body["name"] = name }
            if let heightCm = heightCm { body["heightCm"] = heightCm }
            if let weightKg = weightKg { body["weightKg"] = weightKg }
            return body

        case .createLog(let type, let value, let tags, let notes):
            var body: [String: Any] = ["type": type]
            if let value = value { body["value"] = value }
            if let tags = tags { body["tags"] = tags }
            if let notes = notes { body["notes"] = notes }
            return body

        case .getMotivation(let steps, let stepsGoal, let waterMl, let waterGoal, let timeOfDay):
            return [
                "steps": steps, "stepsGoal": stepsGoal, "waterMl": waterMl, "waterGoal": waterGoal,
                "timeOfDay": timeOfDay,
            ]

        case .getWeeklyMotivation(let steps, let stepsGoal, let waterMl, let waterGoal):
            return [
                "steps": steps, "stepsGoal": stepsGoal, "waterMl": waterMl, "waterGoal": waterGoal,
            ]

        case .getSmartRecommend(let steps, let stepsGoal, let waterMl, let waterGoal):
            return [
                "steps": steps, "stepsGoal": stepsGoal, "waterMl": waterMl, "waterGoal": waterGoal,
            ]

        case .planAdjust(let currentPlan, let feedback):
            return ["currentPlan": currentPlan, "feedback": feedback]

        case .generateHabits(let goals, let lifestyle):
            return ["goals": goals, "lifestyle": lifestyle]

        case .insightsChat(let message, let context):
            var body: [String: Any] = ["message": message]
            if let context = context { body["context"] = context }
            return body

        case .generateExercisePlan(let userRequest, let sportType, let fitnessLevel):
            var body: [String: Any] = ["userRequest": userRequest, "fitnessLevel": fitnessLevel]
            if let sportType = sportType { body["sportType"] = sportType }
            return body

        case .dietaryCare(let meals):
            return ["meals": meals]

        case .weeklyDietaryCare(let startDate, let endDate):
            return ["startDate": startDate, "endDate": endDate]

        case .multimodalAnalyze(let text, let imageBase64):
            var body: [String: Any] = [:]
            if let text = text { body["text"] = text }
            if let imageBase64 = imageBase64 { body["imageBase64"] = imageBase64 }
            return body

        case .sendChatMessage(let message, let context):
            var body: [String: Any] = ["message": message]
            if let context = context { body["context"] = context }
            return body

        case .bindDevice(let address, let name, let type):
            return ["address": address, "name": name, "type": type]

        case .syncDeviceData(let deviceAddress, let healthData):
            return ["deviceAddress": deviceAddress, "healthData": healthData]

        case .registerFcm(let token):
            return ["token": token]

        case .unregisterFcm(let token):
            return ["token": token]

        case .recordNotificationAction(let notificationId, let action):
            return ["notificationId": notificationId, "action": action]

        case .submitTwin3D(let description):
            return ["description": description]

        case .submitTwin3DProfile(let profile):
            return profile

        case .avatarInteract(let action, let parameters):
            var body: [String: Any] = ["action": action]
            if let parameters = parameters { body["parameters"] = parameters }
            return body

        case .saveAvatar(let name, let customization, let equippedItems):
            return [
                "name": name,
                "customization": customization,
                "equipped_items": equippedItems,
            ]

        case .saveAvatarCustomization(let customization, let tab):
            return [
                "customization": customization,
                "tab": tab,
            ]

        case .equipAvatarItem(let category, let itemIndex):
            return [
                "category": category,
                "item_index": itemIndex,
            ]

        case .sendJdDemoChat(let message, let sessionId):
            var body: [String: Any] = ["message": message]
            if let sessionId = sessionId { body["sessionId"] = sessionId }
            return body

        case .getJdOpenAppLink(let itemId):
            return ["itemId": itemId]

        case .decideJdMode(let query):
            return ["query": query]

        case .generateJdPage(let prompt, let sessionId):
            var body: [String: Any] = ["prompt": prompt]
            if let sessionId = sessionId { body["sessionId"] = sessionId }
            return body

        default:
            return nil
        }
    }

    // MARK: - Token管理
    func setAuthToken(_ token: String) {
        authToken = token
    }

    func setRefreshToken(_ token: String) {
        refreshTokenValue = token
    }

    func clearToken() {
        authToken = nil
        refreshTokenValue = nil
    }

    func isAuthenticated() -> Bool {
        return authToken != nil
    }

    // MARK: - Convenience: Fetch log history as typed model
    func fetchLogHistory(
        type: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        limit: Int = 50
    ) async throws -> LogHistoryResponse {
        return try await request(.getLogHistory(type: type, startDate: startDate, endDate: endDate, limit: limit), responseType: LogHistoryResponse.self)
    }
}
