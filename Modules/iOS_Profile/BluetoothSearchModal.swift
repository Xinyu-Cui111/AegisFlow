import SwiftUI

struct BluetoothSearchModal: View {
    @Environment(\.dismiss) var dismiss
    @State private var isSearching = true
    
    // 模拟搜索到的设备列表
    let mockDevices = [
        "Smart Scale 2.0",
        "Heart Rate Monitor",
        "Health Watch S1"
    ]
    
    var body: some View {
        VStack(spacing: 25) {
            // 顶部条
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 10)
            
            HStack {
                Text("搜索设备")
                    .font(.title2)
                    .bold()
                Spacer()
                if isSearching {
                    ProgressView()
                        .tint(.androidBlue) // 修正：使用 androidBlue
                }
            }
            .padding(.horizontal, 25)
            
            if isSearching {
                VStack(spacing: 15) {
                    // 搜索动画效果
                    ZStack {
                        Circle()
                            .stroke(Color.androidBlue.opacity(0.1), lineWidth: 2)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .stroke(Color.androidBlue.opacity(0.3), lineWidth: 2)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 30))
                            .foregroundColor(.androidBlue) // 修正：使用 androidBlue
                    }
                    .padding(.vertical, 20)
                    
                    Text("正在寻找附近的蓝牙设备...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(mockDevices, id: \.self) { device in
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .foregroundColor(.androidBlue) // 修正：使用 androidBlue
                        Text(device)
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Text("连接")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 6)
                            .background(Color.androidBlue) // 修正：使用 androidBlue
                            .cornerRadius(15)
                    }
                    .padding()
                    .background(Color.androidBg)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.androidBlue) // 修正：使用 androidBlue
                    .cornerRadius(25)
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .onAppear {
            // 模拟搜索 3 秒后停止动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isSearching = false
            }
        }
    }
}

struct BluetoothSearchModal_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothSearchModal()
    }
}
