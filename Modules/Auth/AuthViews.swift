import UIKit
import SwiftUI
import Combine
import WebKit

// MARK: - 登录视图
struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showRegister: Bool = false
    @State private var showForgotPassword: Bool = false
    
    // 网络请求配置
    private let baseURL = APIConfig.baseURL
    
    init(isLoggedIn: Binding<Bool> = .constant(false)) {
        _isLoggedIn = isLoggedIn
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Logo区域
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.sageBright, .tealDeep], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 100, height: 100)
                                    .shadow(color: .sageBright.opacity(0.3), radius: 20, x: 0, y: 10)
                                
                                Image(systemName: "heart.text.square.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                            }
                            
                            Text("AegisFlow")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.grayDark)
                            
                            Text("智能健康管理助手")
                                .font(.system(size: 15))
                                .foregroundColor(.grayMid)
                        }
                        .padding(.top, 60)
                        
                        // 输入区域
                        VStack(spacing: 16) {
                            // 邮箱输入
                            VStack(alignment: .leading, spacing: 8) {
                                Text("邮箱")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.grayDark)
                                
                                TextField("请输入邮箱", text: $email)
                                    .textFieldStyle(.plain)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(AegisCornerRadius.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AegisCornerRadius.input)
                                            .stroke(Color.grayLight, lineWidth: 1)
                                    )
                            }
                            
                            // 密码输入
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("密码")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.grayDark)
                                    
                                    Spacer()
                                    
                                    Button(action: { showForgotPassword = true }) {
                                        Text("忘记密码？")
                                            .font(.system(size: 13))
                                            .foregroundColor(.sageBright)
                                    }
                                }
                                
                                SecureField("请输入密码", text: $password)
                                    .textFieldStyle(.plain)
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(AegisCornerRadius.input)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AegisCornerRadius.input)
                                            .stroke(Color.grayLight, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                        
                        // 登录按钮
                        Button(action: login) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("登录")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(canLogin ? Color.sageBright : Color.grayLight)
                            .cornerRadius(AegisCornerRadius.medium)
                        }
                        .disabled(!canLogin || isLoading)
                        .padding(.horizontal, AegisSpacing.pageHorizontal)

                        Button(action: testLogin) {
                            Text("测试登录（离线）")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.tealDeep)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.tealDeep.opacity(0.08))
                                .cornerRadius(AegisCornerRadius.medium)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, AegisSpacing.pageHorizontal)
                        
                        // 注册提示
                        HStack {
                            Text("还没有账号？")
                                .font(.system(size: 14))
                                .foregroundColor(.grayMid)
                            
                            Button(action: { showRegister = true }) {
                                Text("立即注册")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.sageBright)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationDestination(isPresented: $showRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            .alert("登录失败", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    private func login() {
        guard canLogin else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            isLoading = false
            errorMessage = "无效的服务器地址"
            showError = true
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "服务器无响应"
                    self.showError = true
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(LoginResponse.self, from: data)
                    if result.success, let tokenData = result.data {
                        // 保存Token
                        TokenStorage.shared.accessToken = tokenData.token
                        TokenStorage.shared.refreshToken = tokenData.refreshToken
                        TokenStorage.shared.tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenData.expiresIn))
                        
                        // 保存用户信息
                        UserDefaults.standard.set(tokenData.user.id, forKey: APIConfig.userIdKey)
                        UserDefaults.standard.set(tokenData.user.email, forKey: APIConfig.userEmailKey)
                        completeLogin()
                    } else {
                        self.errorMessage = result.message
                        self.showError = true
                    }
                } catch {
                    self.errorMessage = "登录失败，请稍后重试"
                    self.showError = true
                }
            }
        }.resume()
    }

    private func testLogin() {
        let now = Date()
        TokenStorage.shared.accessToken = "debug_access_token"
        TokenStorage.shared.refreshToken = "debug_refresh_token"
        TokenStorage.shared.tokenExpiry = now.addingTimeInterval(60 * 60 * 24 * 30)

        UserDefaults.standard.set("debug-user", forKey: APIConfig.userIdKey)
        UserDefaults.standard.set("debug@aegisflow.local", forKey: APIConfig.userEmailKey)
        // 测试登录：视为已完成引导，与冷启动路由一致（否则下次启动会进 Onboarding 而不是登录页）
        PreferencesStorage.shared.onboardingCompleted = true
        completeLogin()
    }

    private func completeLogin() {
        PreferencesStorage.shared.isLoggedIn = true
        isLoggedIn = true
        appState.isShowingSplash = false
        // 与 AppState 启动逻辑一致：未标记完成引导则先进 Onboarding，否则进主页
        if PreferencesStorage.shared.onboardingCompleted {
            appState.currentRoute = .main
        } else {
            appState.currentRoute = .onboarding
        }
        NotificationCenter.default.post(name: .userDidLogin, object: nil)
        dismiss()
    }
}

// MARK: - 注册视图
struct RegisterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var name: String = ""
    @State private var verificationCode: String = ""
    @State private var captchaId: String = ""
    @State private var captchaSVG: String = ""
    @State private var captchaAnswer: String = ""
    @State private var isLoading: Bool = false
    @State private var isSendingCode: Bool = false
    @State private var isLoadingCaptcha: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var countdown: Int = 0
    @State private var hasSentCode: Bool = false
    @State private var countdownTimer: Timer? = nil
    
    // 网络请求配置
    private let baseURL = APIConfig.baseURL
    
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 标题
                    VStack(spacing: 8) {
                        Text("创建账号")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.grayDark)
                        
                        Text("开启您的健康管理之旅")
                            .font(.system(size: 15))
                            .foregroundColor(.grayMid)
                    }
                    .padding(.top, 32)
                    
                    // 输入区域
                    VStack(spacing: 16) {
                        // 昵称
                        InputField(title: "昵称", placeholder: "请输入昵称", text: $name)
                        
                        // 邮箱
                        InputField(title: "邮箱", placeholder: "请输入邮箱", text: $email, keyboardType: .emailAddress)

                        CaptchaSection(
                            captchaSVG: captchaSVG,
                            captchaAnswer: $captchaAnswer,
                            isLoadingCaptcha: isLoadingCaptcha,
                            refreshCaptcha: loadCaptcha
                        )
                        
                        // 验证码
                        HStack(alignment: .bottom, spacing: 12) {
                            InputField(title: "邮箱验证码", placeholder: "请输入邮箱验证码", text: $verificationCode, keyboardType: .numberPad)
                            
                            Button(action: sendVerificationCode) {
                                if isSendingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .sageBright))
                                        .frame(width: 100, height: 50)
                                } else {
                                    Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(hasSentCode ? .grayMid : .sageBright)
                                        .frame(width: 100, height: 50)
                                        .background(hasSentCode ? Color.grayLight.opacity(0.5) : Color.sageBright.opacity(0.1))
                                        .cornerRadius(AegisCornerRadius.input)
                                }
                            }
                            .disabled(countdown > 0 || email.isEmpty || captchaId.isEmpty || captchaAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingCode)
                        }
                        
                        // 密码
                        InputField(title: "密码", placeholder: "请输入密码（至少8位，包含大小写字母和数字）", text: $password, isSecure: true)
                        
                        // 确认密码
                        InputField(title: "确认密码", placeholder: "请再次输入密码", text: $confirmPassword, isSecure: true)
                        
                        // 密码确认提示
                        if !confirmPassword.isEmpty && password != confirmPassword {
                            Text("两次输入的密码不一致")
                                .font(.system(size: 12))
                                .foregroundColor(.errorRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    
                    // 注册按钮
                    Button(action: register) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("注册")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canRegister ? Color.sageBright : Color.grayLight)
                        .cornerRadius(AegisCornerRadius.medium)
                    }
                    .disabled(!canRegister || isLoading)
                    .padding(.horizontal, AegisSpacing.pageHorizontal)
                    
                    // 服务条款
                    HStack(spacing: 4) {
                        Text("注册即表示同意")
                            .font(.system(size: 12))
                            .foregroundColor(.grayMid)
                        
                        Button(action: { openTerms() }) {
                            Text("《服务条款》")
                                .font(.system(size: 12))
                                .foregroundColor(.sageBright)
                        }
                        
                        Text("和")
                            .font(.system(size: 12))
                            .foregroundColor(.grayMid)
                        
                        Button(action: { openPrivacy() }) {
                            Text("《隐私政策》")
                                .font(.system(size: 12))
                                .foregroundColor(.sageBright)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("注册失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear(perform: loadCaptcha)
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }
    
    private var canRegister: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        !name.isEmpty && 
        !verificationCode.isEmpty && 
        password == confirmPassword && 
        password.count >= 8
    }
    
    private func sendVerificationCode() {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaptchaAnswer = captchaAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !captchaId.isEmpty, !trimmedCaptchaAnswer.isEmpty else {
            errorMessage = "请先填写邮箱和图形验证码"
            showError = true
            return
        }

        guard let url = URL(string: "\(baseURL)/auth/send-code") else { return }
        
        isSendingCode = true
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": trimmedEmail,
            "captchaId": captchaId,
            "captchaAnswer": trimmedCaptchaAnswer
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isSendingCode = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.loadCaptcha()
                    return
                }

                guard let data = data else {
                    self.errorMessage = "服务器无响应"
                    self.showError = true
                    self.loadCaptcha()
                    return
                }

                do {
                    let result = try JSONDecoder().decode(CodeSendResponse.self, from: data)
                    if result.success {
                        self.hasSentCode = true
                        self.startCountdown(seconds: min(result.data?.expiresIn ?? 60, 60))
                        self.loadCaptcha()
                    } else {
                        self.errorMessage = result.message
                        self.showError = true
                        self.loadCaptcha()
                    }
                } catch {
                    self.errorMessage = "验证码发送失败，请稍后重试"
                    self.showError = true
                    self.loadCaptcha()
                }
            }
        }.resume()
    }
    
    private func register() {
        guard canRegister else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(baseURL)/auth/register") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password,
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "emailCode": verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "服务器无响应"
                    self.showError = true
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(RegisterResponse.self, from: data)
                    if result.success, let tokenData = result.data, let loginData = tokenData.asLoginData {
                        TokenStorage.shared.accessToken = loginData.token
                        TokenStorage.shared.refreshToken = loginData.refreshToken
                        TokenStorage.shared.tokenExpiry = Date().addingTimeInterval(TimeInterval(loginData.expiresIn))
                        UserDefaults.standard.set(loginData.user.id, forKey: APIConfig.userIdKey)
                        UserDefaults.standard.set(loginData.user.email, forKey: APIConfig.userEmailKey)
                        PreferencesStorage.shared.isLoggedIn = true
                        NotificationCenter.default.post(name: .userDidLogin, object: nil)
                        self.dismiss()
                    } else {
                        self.errorMessage = result.message
                        self.showError = true
                        self.loadCaptcha()
                    }
                } catch {
                    self.errorMessage = "注册失败，请稍后重试"
                    self.showError = true
                    self.loadCaptcha()
                }
            }
        }.resume()
    }

    private func loadCaptcha() {
        guard let url = URL(string: "\(baseURL)/auth/captcha") else { return }

        isLoadingCaptcha = true
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingCaptcha = false

                if error != nil {
                    self.captchaId = ""
                    self.captchaSVG = ""
                    return
                }

                guard let data = data,
                      let result = try? JSONDecoder().decode(CaptchaResponse.self, from: data),
                      result.success,
                      let payload = result.data else {
                    self.captchaId = ""
                    self.captchaSVG = ""
                    return
                }

                self.captchaId = payload.sessionId
                self.captchaSVG = payload.svgData
                self.captchaAnswer = ""
            }
        }.resume()
    }

    private func startCountdown(seconds: Int) {
        countdownTimer?.invalidate()
        countdown = seconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    private func openTerms() {
        if let url = URL(string: "https://aegisflow.com/terms") {
            UIApplication.shared.open(url)
        }
    }

    private func openPrivacy() {
        if let url = URL(string: "https://aegisflow.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - 忘记密码视图
struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email: String = ""
    @State private var verificationCode: String = ""
    @State private var captchaId: String = ""
    @State private var captchaSVG: String = ""
    @State private var captchaAnswer: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var step: Int = 1
    @State private var countdown: Int = 0
    @State private var isLoading: Bool = false
    @State private var isLoadingCaptcha: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var countdownTimer: Timer? = nil
    
    // 网络请求配置
    private let baseURL = APIConfig.baseURL
    
    var body: some View {
        ZStack {
            Color.cream.ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("找回密码")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.grayDark)
                    
                    Text(step == 1 ? "输入您的邮箱地址" : "设置新密码")
                        .font(.system(size: 15))
                        .foregroundColor(.grayMid)
                }
                .padding(.top, 32)
                
                VStack(spacing: 16) {
                    if step == 1 {
                        InputField(title: "邮箱", placeholder: "请输入注册邮箱", text: $email, keyboardType: .emailAddress)

                        CaptchaSection(
                            captchaSVG: captchaSVG,
                            captchaAnswer: $captchaAnswer,
                            isLoadingCaptcha: isLoadingCaptcha,
                            refreshCaptcha: loadCaptcha
                        )
                        
                        HStack(alignment: .bottom, spacing: 12) {
                            InputField(title: "邮箱验证码", placeholder: "请输入邮箱验证码", text: $verificationCode, keyboardType: .numberPad)
                            
                            Button(action: sendVerificationCode) {
                                Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.sageBright)
                                    .frame(width: 100, height: 50)
                                    .background(Color.sageBright.opacity(0.1))
                                    .cornerRadius(AegisCornerRadius.input)
                            }
                            .disabled(countdown > 0 || email.isEmpty || captchaId.isEmpty || captchaAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        }
                        
                        Button(action: continueToResetStep) {
                            Text("下一步")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canVerifyStep1 ? Color.sageBright : Color.grayLight)
                                .cornerRadius(AegisCornerRadius.medium)
                        }
                        .disabled(!canVerifyStep1 || isLoading)
                    } else {
                        InputField(title: "新密码", placeholder: "请输入新密码（至少8位，包含大小写字母和数字）", text: $newPassword, isSecure: true)
                        
                        InputField(title: "确认密码", placeholder: "请再次输入新密码", text: $confirmPassword, isSecure: true)
                        
                        Button(action: resetPassword) {
                            Text("重置密码")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(canResetPassword ? Color.sageBright : Color.grayLight)
                                .cornerRadius(AegisCornerRadius.medium)
                        }
                        .disabled(!canResetPassword || isLoading)
                    }
                }
                .padding(.horizontal, AegisSpacing.pageHorizontal)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("操作失败", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear(perform: loadCaptcha)
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }
    
    private var canVerifyStep1: Bool {
        !email.isEmpty &&
        !verificationCode.isEmpty
    }
    
    private var canResetPassword: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 8
    }
    
    private func sendVerificationCode() {
        let trimmedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCaptchaAnswer = captchaAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !captchaId.isEmpty, !trimmedCaptchaAnswer.isEmpty else {
            errorMessage = "请先填写邮箱和图形验证码"
            showError = true
            return
        }

        guard let url = URL(string: "\(baseURL)/auth/forgot-password") else { return }
        
        isLoading = true
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": trimmedEmail,
            "captchaId": captchaId,
            "captchaAnswer": trimmedCaptchaAnswer
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.loadCaptcha()
                    return
                }

                guard let data = data else {
                    self.errorMessage = "服务器无响应"
                    self.showError = true
                    self.loadCaptcha()
                    return
                }

                if let result = try? JSONDecoder().decode(CodeSendResponse.self, from: data), result.success {
                    self.startCountdown(seconds: min(result.data?.expiresIn ?? 60, 60))
                    self.loadCaptcha()
                } else if let result = try? JSONDecoder().decode(GenericResponse.self, from: data) {
                    self.errorMessage = result.message
                    self.showError = true
                    self.loadCaptcha()
                } else {
                    self.errorMessage = "验证码发送失败，请稍后重试"
                    self.showError = true
                    self.loadCaptcha()
                }
            }
        }.resume()
    }
    
    private func continueToResetStep() {
        guard canVerifyStep1 else { return }
        step = 2
    }
    
    private func resetPassword() {
        guard canResetPassword else { return }
        
        isLoading = true
        
        guard let url = URL(string: "\(baseURL)/auth/reset-password") else {
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email": email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
            "code": verificationCode,
            "newPassword": newPassword
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let data = data, let result = try? JSONDecoder().decode(GenericResponse.self, from: data) {
                    if result.success {
                        self.dismiss()
                    } else {
                        self.errorMessage = result.message
                        self.showError = true
                    }
                } else {
                    self.errorMessage = error?.localizedDescription ?? "密码重置失败，请稍后重试"
                    self.showError = true
                }
            }
        }.resume()
    }

    private func loadCaptcha() {
        guard let url = URL(string: "\(baseURL)/auth/captcha") else { return }

        isLoadingCaptcha = true
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoadingCaptcha = false

                if error != nil {
                    self.captchaId = ""
                    self.captchaSVG = ""
                    return
                }

                guard let data = data,
                      let result = try? JSONDecoder().decode(CaptchaResponse.self, from: data),
                      result.success,
                      let payload = result.data else {
                    self.captchaId = ""
                    self.captchaSVG = ""
                    return
                }

                self.captchaId = payload.sessionId
                self.captchaSVG = payload.svgData
                self.captchaAnswer = ""
            }
        }.resume()
    }

    private func startCountdown(seconds: Int) {
        countdownTimer?.invalidate()
        countdown = seconds
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.countdown > 0 {
                    self.countdown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - 输入框组件
struct CaptchaSection: View {
    let captchaSVG: String
    @Binding var captchaAnswer: String
    let isLoadingCaptcha: Bool
    let refreshCaptcha: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("图形验证码")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.grayDark)

                Spacer()

                Button(action: refreshCaptcha) {
                    Text("刷新")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.sageBright)
                }
                .disabled(isLoadingCaptcha)
            }

            if isLoadingCaptcha {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 96)
                    .background(Color.white)
                    .cornerRadius(AegisCornerRadius.input)
            } else if captchaSVG.isEmpty {
                Button(action: refreshCaptcha) {
                    Text("加载验证码失败，点击重试")
                        .font(.system(size: 14))
                        .foregroundColor(.grayMid)
                        .frame(maxWidth: .infinity, minHeight: 96)
                        .background(Color.white)
                        .cornerRadius(AegisCornerRadius.input)
                        .overlay(
                            RoundedRectangle(cornerRadius: AegisCornerRadius.input)
                                .stroke(Color.grayLight, lineWidth: 1)
                        )
                }
            } else {
                SVGImageView(svg: captchaSVG)
                    .frame(height: 96)
                    .background(Color.white)
                    .cornerRadius(AegisCornerRadius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: AegisCornerRadius.input)
                            .stroke(Color.grayLight, lineWidth: 1)
                    )
            }

            InputField(title: "图形验证码答案", placeholder: "请输入图中字符", text: $captchaAnswer)
        }
    }
}

struct InputField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.grayDark)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AegisCornerRadius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: AegisCornerRadius.input)
                            .stroke(Color.grayLight, lineWidth: 1)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .sentences)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AegisCornerRadius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: AegisCornerRadius.input)
                            .stroke(Color.grayLight, lineWidth: 1)
                    )
            }
        }
    }
}

struct SVGImageView: UIViewRepresentable {
    let svg: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>
        body {
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
            background: transparent;
        }
        svg {
            max-width: 100%;
            height: auto;
        }
        </style>
        </head>
        <body>\(svg)</body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - 通知名称
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
}

// MARK: - 网络响应结构

struct LoginResponse: Codable {
    let success: Bool
    let message: String
    let data: LoginData?
}

struct LoginData: Codable {
    let token: String
    let refreshToken: String
    let expiresIn: Int
    let user: AuthUser
}

struct RegisterResponse: Codable {
    let success: Bool
    let message: String
    let data: RegisterData?
}

struct RegisterData: Codable {
    let token: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: AuthUser?

    var asLoginData: LoginData? {
        guard let token, let refreshToken, let expiresIn, let user else {
            return nil
        }
        return LoginData(token: token, refreshToken: refreshToken, expiresIn: expiresIn, user: user)
    }
}

struct AuthUser: Codable {
    let id: String
    let email: String
    let name: String
}

struct GenericResponse: Codable {
    let success: Bool
    let message: String
    let data: String?
}

struct CaptchaResponse: Codable {
    let success: Bool
    let message: String
    let data: CaptchaPayload?
}

struct CaptchaPayload: Codable {
    let sessionId: String
    let svgData: String
}

struct CodeSendResponse: Codable {
    let success: Bool
    let message: String
    let data: CodeSendPayload?
}

struct CodeSendPayload: Codable {
    let expiresIn: Int
}

// MARK: - 预览
#Preview {
    LoginView()
}
