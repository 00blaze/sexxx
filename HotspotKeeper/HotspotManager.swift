import Foundation
import AVFoundation
import Combine

class HotspotManager: ObservableObject {
    static let shared = HotspotManager()
    
    @Published var isActive: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var pingCount: Int = 0
    @Published var lastPingStatus: String = "Hazır"
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var pingTimer: Timer?
    private var startTime: Date?
    
    init() {
        setupAudioSession()
        prepareSilentAudio()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession hatası: \(error.localizedDescription)")
        }
    }
    
    private func prepareSilentAudio() {
        let silentData = generateSilentWAV(durationSeconds: 3.0, sampleRate: 8000)
        do {
            audioPlayer = try AVAudioPlayer(data: silentData)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.01
            audioPlayer?.prepareToPlay()
        } catch {
            print("Sessiz ses oluşturma hatası: \(error.localizedDescription)")
        }
    }
    
    func toggle() {
        if isActive {
            stop()
        } else {
            start()
        }
    }
    
    func start() {
        guard !isActive else { return }
        
        setupAudioSession()
        audioPlayer?.play()
        
        isActive = true
        startTime = Date()
        elapsedTime = 0
        pingCount = 0
        lastPingStatus = "Aktif (Arka plan canlı)"
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
        
        pingTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: true) { [weak self] _ in
            self?.sendKeepAlivePulse()
        }
        
        sendKeepAlivePulse()
    }
    
    func stop() {
        guard isActive else { return }
        
        audioPlayer?.stop()
        timer?.invalidate()
        timer = nil
        pingTimer?.invalidate()
        pingTimer = nil
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("AudioSession kapatma hatası: \(error.localizedDescription)")
        }
        
        isActive = false
        lastPingStatus = "Durduruldu"
    }
    
    private func sendKeepAlivePulse() {
        guard let url = URL(string: "https://captive.apple.com/hotspot-detect.html") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if error == nil {
                    self.pingCount += 1
                    self.lastPingStatus = "Sinyal OK (\(Date().formatted(date: .omitted, time: .standard)))"
                } else {
                    self.lastPingStatus = "Hata veya Çevrimdışı"
                }
            }
        }.resume()
    }
    
    private func generateSilentWAV(durationSeconds: Double, sampleRate: Int) -> Data {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate * Int(numChannels) * Int(bitsPerSample / 8))
        let blockAlign = Int16(numChannels * (bitsPerSample / 8))
        let numSamples = Int(Double(sampleRate) * durationSeconds)
        let dataSize = Int32(numSamples * Int(numChannels) * Int(bitsPerSample / 8))
        let chunkSize = 36 + dataSize
        
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        data.append(withUnsafeBytes(of: chunkSize.littleEndian) { Data($0) })
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        data.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: Int32(sampleRate).littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        data.append(Data(count: Int(dataSize)))
        return data
    }
}
