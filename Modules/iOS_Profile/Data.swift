import SwiftUI

struct DataView: View {
    var body: some View {
        ZStack {
            Color.androidBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    Text("数据概览").font(.system(size: 28, weight: .bold)).padding(.horizontal, 24).padding(.top, 20)
                    
                    // 横排滑动小卡片
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            SmallInfoCard(title: "步数", val: "8,540", unit: "步", icon: "figure.walk", color: .orange)
                            SmallInfoCard(title: "消耗", val: "420", unit: "kcal", icon: "flame.fill", color: .red)
                            SmallInfoCard(title: "心率", val: "72", unit: "bpm", icon: "heart.fill", color: .pink)
                        }.padding(.horizontal, 24)
                    }
                    
                    // 纵排大卡片
                    VStack(spacing: 20) {
                        LargeChartPlaceholder(title: "运动趋势分析")
                        LargeChartPlaceholder(title: "睡眠质量评估")
                    }.padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
        }
    }
}

struct SmallInfoCard: View {
    let title, val, unit, icon: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.gray)
            HStack(alignment: .bottom, spacing: 2) {
                Text(val).font(.title3).bold()
                Text(unit).font(.system(size: 10)).foregroundColor(.gray).padding(.bottom, 3)
            }
        }.padding().frame(width: 110).background(Color.white).cornerRadius(25)
    }
}

struct LargeChartPlaceholder: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.bottom, 8)
            RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.1)).frame(height: 150)
        }.padding().frame(maxWidth: .infinity).background(Color.white).cornerRadius(30)
    }
}
