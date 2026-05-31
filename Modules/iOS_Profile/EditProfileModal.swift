import PhotosUI
import SwiftUI

enum EditProfileField {
    case nickname, signature, height, weight
}

struct EditProfileModal: View {
    @Environment(\.dismiss) var dismiss

    // 可选注入的业务视图模型
    @ObservedObject var viewModel: ProfileViewModel

    // 如果没有传入，默认提供一个仅用于 UI 预览的对象
    init(viewModel: ProfileViewModel? = nil) {
        self.viewModel = viewModel ?? ProfileViewModel()
    }

    // MARK: - 用户状态数据
    @State private var nickname: String = "Sarah Chen"
    @State private var signature: String = "自律给我自由，坚持成就卓越。"
    @State private var gender: String = "女"
    @State private var birthday: Date =
        Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var height: String = "168"
    @State private var weight: String = "52"

    @FocusState private var focusedField: EditProfileField?

    // 底部滑出弹窗状态
    @State private var showGenderSheet = false
    @State private var showBirthdaySheet = false

    // 头像相册选择状态
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: Image? = nil
    @State private var avatarData: Data? = nil

    // MARK: - 清新贵气配色 (Pale Gold + Emerald Green)
    let bgGradient = LinearGradient(
        colors: [Color(hex: "#FFFCF2"), Color(hex: "#F9F0D4")], startPoint: .top, endPoint: .bottom)
    let cardBgColor = Color.white.opacity(0.9)
    let accent = Color(hex: "#2C5A4C")
    let goldAccent = Color(hex: "#D4AF37")

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 0
    }

    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy.MM.dd"
        return df
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // 背景
                bgGradient.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {

                        // MARK: 1. 头像相册选区
                        VStack(spacing: 12) {
                            PhotosPicker(
                                selection: $avatarItem, matching: .images, photoLibrary: .shared()
                            ) {
                                ZStack(alignment: .bottomTrailing) {
                                    Group {
                                        if let avatarImage = avatarImage {
                                            avatarImage
                                                .resizable()
                                                .scaledToFill()
                                        } else {
                                            LinearGradient(
                                                colors: [
                                                    Color(hex: "#87661E").opacity(0.8),
                                                    Color(hex: "#D4AF37"),
                                                ], startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            .overlay(
                                                Text(String(nickname.prefix(1).uppercased()))
                                                    .font(
                                                        .system(
                                                            size: 38, weight: .semibold,
                                                            design: .serif)
                                                    )
                                                    .foregroundColor(.white)
                                            )
                                        }
                                    }
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(
                                            LinearGradient(
                                                colors: [Color.white, Color(hex: "#F9D976")],
                                                startPoint: .topLeading, endPoint: .bottomTrailing),
                                            lineWidth: 3)
                                    )
                                    .shadow(color: goldAccent.opacity(0.2), radius: 12, x: 0, y: 6)

                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 30, height: 30)
                                        .shadow(
                                            color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2
                                        )
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(accent)
                                        )
                                        .offset(x: 2, y: 2)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())

                            Text("点击更换头像")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#87661E").opacity(0.7))
                        }
                        .padding(.top, 24)

                        // MARK: 2. 基础资料 Section
                        VStack(spacing: 0) {
                            ProfileInputRow(
                                icon: "person.text.rectangle.fill", title: "昵称", text: $nickname,
                                keyboardType: .default, field: .nickname,
                                focusedField: _focusedField)
                            Divider().padding(.leading, 56)

                            ProfileInputRow(
                                icon: "pencil.and.outline", title: "个性签名", text: $signature,
                                keyboardType: .default, field: .signature,
                                focusedField: _focusedField)
                            Divider().padding(.leading, 56)

                            Button(action: {
                                focusedField = nil
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    showGenderSheet = true
                                }
                            }) {
                                ProfileSelectionRow(
                                    icon: "figure.stand", title: "性别", value: gender)
                            }

                            Divider().padding(.leading, 56)

                            Button(action: {
                                focusedField = nil
                                let impact = UIImpactFeedbackGenerator(style: .light)
                                impact.impactOccurred()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    showBirthdaySheet = true
                                }
                            }) {
                                ProfileSelectionRow(
                                    icon: "birthday.cake.fill", title: "生日",
                                    value: "\(dateFormatter.string(from: birthday)) (\(age)岁)")
                            }
                        }
                        .background(cardBgColor)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color(hex: "#87661E").opacity(0.08), radius: 15, x: 0, y: 5)
                        .padding(.horizontal, 20)

                        // MARK: 3. 身体数据 Section
                        VStack(alignment: .leading, spacing: 10) {
                            Text("身体数据 (用于更精准的健康分析)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "#87661E").opacity(0.7))
                                .padding(.horizontal, 32)

                            VStack(spacing: 0) {
                                ProfileInputRow(
                                    icon: "ruler.fill", title: "身高 (cm)", text: $height,
                                    keyboardType: .numberPad, field: .height,
                                    focusedField: _focusedField)
                                Divider().padding(.leading, 56)
                                ProfileInputRow(
                                    icon: "scalemass.fill", title: "体重 (kg)", text: $weight,
                                    keyboardType: .decimalPad, field: .weight,
                                    focusedField: _focusedField)
                            }
                            .background(cardBgColor)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(
                                color: Color(hex: "#87661E").opacity(0.08), radius: 15, x: 0, y: 5
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 80)
                    }
                }

                // MARK: - 丝滑遮罩与底部弹窗
                if showGenderSheet || showBirthdaySheet {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                showGenderSheet = false
                                showBirthdaySheet = false
                            }
                        }
                        .transition(.opacity)
                }

                if showGenderSheet {
                    GenderSelectionSheet(selectedGender: $gender, accent: accent) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showGenderSheet = false
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }

                if showBirthdaySheet {
                    BirthdaySelectionSheet(birthday: $birthday, accent: accent) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showBirthdaySheet = false
                        }
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(2)
                }
            }
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("取消").font(.system(size: 16, weight: .regular)).foregroundColor(
                            Color(hex: "#87661E").opacity(0.8))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()

                        // 保存逻辑绑定到真实 ViewModel
                        viewModel.editName = nickname
                        viewModel.persistAvatarData(avatarData)
                        if gender == "男" {
                            viewModel.updateEditGender("male")
                        } else if gender == "女" {
                            viewModel.updateEditGender("female")
                        } else {
                            viewModel.updateEditGender("other")
                        }

                        let df = DateFormatter()
                        df.dateFormat = "yyyy-MM-dd"
                        viewModel.updateEditBirthDate(df.string(from: birthday))

                        viewModel.saveEditProfile()

                        dismiss()
                    }) {
                        Text("保存")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accent)
                    }
                }
            }
            .onChange(of: avatarItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                        let uiImage = UIImage(data: data)
                    {
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                self.avatarData = data
                                self.avatarImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.titleTextAttributes = [
                    .foregroundColor: UIColor(Color(hex: "#87661E")),
                    .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                ]
                UINavigationBar.appearance().standardAppearance = appearance

                // 从 ViewModel 同步真实数据到当前的编辑状态
                self.nickname = viewModel.editName.isEmpty ? viewModel.userName : viewModel.editName

                if viewModel.editGender == "male" {
                    self.gender = "男"
                } else if viewModel.editGender == "female" {
                    self.gender = "女"
                } else {
                    self.gender = "保密"
                }

                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd"
                if let dateStr = viewModel.editBirthDate, let date = df.date(from: dateStr) {
                    self.birthday = date
                }

                if let path = viewModel.avatarLocalPath,
                    let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                    let uiImage = UIImage(data: data)
                {
                    self.avatarData = data
                    self.avatarImage = Image(uiImage: uiImage)
                }
            }
        }
    }
}

// MARK: - 清新输入行组件
struct ProfileInputRow: View {
    let icon: String
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let field: EditProfileField
    @FocusState var focusedField: EditProfileField?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#87661E").opacity(0.7))
                .frame(width: 32)

            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black.opacity(0.8))
                .frame(width: 90, alignment: .leading)

            TextField("请输入", text: $text)
                .keyboardType(keyboardType)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black)
                .multilineTextAlignment(.trailing)
                .focused($focusedField, equals: field)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = field
        }
    }
}

// MARK: - 清新选择行组件
struct ProfileSelectionRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#87661E").opacity(0.7))
                .frame(width: 32)

            Text(title)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.black.opacity(0.8))

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "#87661E"))

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#87661E").opacity(0.5))
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.01))
    }
}

// MARK: - 质感性别选择弹窗
struct GenderSelectionSheet: View {
    @Binding var selectedGender: String
    let accent: Color
    let onClose: () -> Void
    let options = ["男", "女", "保密"]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            Text("选择性别")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: "#87661E"))
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        let impact = UISelectionFeedbackGenerator()
                        impact.selectionChanged()
                        selectedGender = option
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onClose()
                        }
                    }) {
                        HStack {
                            Text(option)
                                .font(
                                    .system(
                                        size: 16,
                                        weight: selectedGender == option ? .bold : .regular)
                                )
                                .foregroundColor(
                                    selectedGender == option ? accent : .primary.opacity(0.8))
                            Spacer()
                            if selectedGender == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(accent)
                                    .font(.system(size: 16, weight: .bold))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 24)
                        .frame(height: 56)
                        .background(
                            selectedGender == option
                                ? accent.opacity(0.08) : Color.gray.opacity(0.03)
                        )
                        .cornerRadius(16)
                        .scaleEffect(selectedGender == option ? 1.02 : 1.0)
                        .animation(
                            .spring(response: 0.3, dampingFraction: 0.6), value: selectedGender)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 40)
        }
        .background(Color.white)
        // 这一步使用了系统原生的 .cornerRadius 和 ignoreSafeArea 等组合特性，不再依赖全局 RoundedCorner 扩展，避免重复冲突。
        .cornerRadius(32)
        .ignoresSafeArea(.all, edges: .bottom)
        .shadow(color: Color.black.opacity(0.1), radius: 30, x: 0, y: -10)
    }
}

// MARK: - 质感生日日期选择弹窗
struct BirthdaySelectionSheet: View {
    @Binding var birthday: Date
    let accent: Color
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 20)

            HStack {
                Text("选择生日")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#87661E"))
                Spacer()
                Button("完成") {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    onClose()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(accent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)

            DatePicker("", selection: $birthday, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .frame(height: 220)
                .padding(.horizontal, 20)

            Spacer().frame(height: 40)
        }
        .background(Color.white)
        .cornerRadius(32)
        .ignoresSafeArea(.all, edges: .bottom)
        .shadow(color: Color.black.opacity(0.1), radius: 30, x: 0, y: -10)
    }
}
