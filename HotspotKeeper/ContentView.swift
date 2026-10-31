import SwiftUI

struct ContentView: View {
    @StateObject private var manager = HotspotManager.shared
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: manager.isActive
                    ? [Color(hex: "0D1B2A"), Color(hex: "1B263B")]
                    : [Color(hex: "121212"), Color(hex: "1E1E24")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "personalhotspot")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(manager.isActive ? .green : .gray)
                        Text("Hotspot Keeper")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Text("Ekran kilitliyken bağlantı kopmasını engeller")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        manager.toggle()
                    }
                }) {
                    ZStack {
                        if manager.isActive {
                            Circle()
                                .stroke(Color.green.opacity(0.3), lineWidth: 16)
                                .frame(width: 210, height: 210)
                                .scaleEffect(1.08)
                                .animation(
                                    Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                    value: manager.isActive
                                )
                        }
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: manager.isActive
                                        ? [Color(hex: "00B4D8"), Color(hex: "0077B6")]
                                        : [Color(hex: "2B2D42"), Color(hex: "1F202F")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 170, height: 170)
                            .shadow(color: manager.isActive ? Color.cyan.opacity(0.5) : Color.black.opacity(0.3), radius: 20)
                        
                        VStack(spacing: 12) {
                            Image(systemName: manager.isActive ? "bolt.shield.fill" : "power")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(manager.isActive ? .white : .gray)
                            
                            Text(manager.isActive ? "AKTİF" : "BAŞLAT")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(manager.isActive ? .white : .gray)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(spacing: 14) {
                    InfoRow(
                        icon: "clock.arrow.circlepath",
                        title: "Çalışma Süresi",
                        value: formatDuration(manager.elapsedTime)
                    )
                    
                    InfoRow(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Ağ Koruma Sinyali",
                        value: "\(manager.pingCount) paket (\(manager.lastPingStatus))"
                    )
                    
                    InfoRow(
                        icon: "battery.100.bolt",
                        title: "Pil Etkisi",
                        value: "< %0.3 / saat (Ultra Düşük)"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.yellow.opacity(0.8))
                        .font(.caption)
                    Text("Ekranı kilitleyip cebinize koysanız bile Hotspot aktif kalır.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 24)
            }
        }
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
