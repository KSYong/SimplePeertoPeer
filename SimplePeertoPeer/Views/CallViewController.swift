//
//  CallViewController.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/25.
//

/*
 CallViewController에서는 통화 버튼 터치를 유지하는 동안에만 오디오 레코딩이 진행되고, 터치를 떼면 오디오 레코딩이 끝나고 상대방에게 전송된다.
 또한 버튼을 터치하지 않을 때만 상대방으로부터 수신된 음성이 들리고, 버튼을 터치하고 있을 때는 상대방으로부터 수신된 음성이 들리지 않는다.
 */

import Foundation
import UIKit
import Network
import AVFoundation

class CallViewController: UIViewController {
    
    enum RecordingState {
        case recording, stopped
    }
    
    @IBOutlet weak var callRecordButton: UIButton!
    
    private var audioSession: AVAudioSession!
    private var audioEngine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    private var audioPlayer: AVAudioPlayerNode!
    private var file: AVAudioFile!
    
    private var state: RecordingState = .stopped
    private var isTouched: Bool?
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudioSession()
        setupAudioEngine()
    }
    
    /// AVAudioSession 셋업
    private func setupAudioSession() -> Void {
        audioSession = AVAudioSession.sharedInstance()
        do {
            // 스피커폰 기본 사용으로, play and record가 가능하게 설정
            try audioSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch (let error) {
            print("Error while setupAudioSession : \(error)")
        }
    }
    
    /// AVAudioEngine 셋업
    private func setupAudioEngine() {
        // 오디오 엔진 및 커스텀 믹서 노드 생성
        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        audioPlayer = AVAudioPlayerNode()
        
        mixerNode.volume = 0
        
        audioEngine.attach(mixerNode)
        audioEngine.attach(audioPlayer)
        
        makeConnection()
        
        audioEngine.prepare()
    }
    
    /// 노드를 엔진에 연결하는 함수
    private func makeConnection() {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        // format은 PCM 오디오 포맷을 준수하여야 한다.
        // 오디오노드의 포맷은 소스 노드의 출력 오디오 포맷을 의미한다.
        let mixerFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: inputFormat.sampleRate, channels: 1, interleaved: false)
        
        audioEngine.connect(inputNode, to: mixerNode, format: inputFormat)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: mixerFormat)
        audioEngine.connect(audioPlayer, to: audioEngine.outputNode, format: inputFormat)
    }
    
    /// 녹음 실행하기
    private func startRecording() throws {
        let tapNode: AVAudioNode = mixerNode
        let format = tapNode.outputFormat(forBus: 0)
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.file = try AVAudioFile(forWriting: documentURL.appendingPathComponent("recording.caf"), settings: format.settings)
        
        tapNode.installTap(onBus: 0, bufferSize: 4096, format: format, block: { (buffer, time) in
            try? self.file.write(from: buffer)
        })
        
        try audioEngine.start()
        
        state = .recording
        
    }
    
    /// 녹음 중지하기
    private func stopRecording() {
        // 기존에 탭했던 노드 제거하기
        mixerNode.removeTap(onBus: 0)
        
        audioEngine.stop()
        state = .stopped
    }
    
    
    /// 통화 버튼이 클릭되었을 때 음성 녹음을 시작하는 함수
    /// - Parameter sender: 클릭된 버튼 객체
    @IBAction func touchDownCallButton(_ sender: UIButton) {
        do{
            try startRecording()
        } catch (let error){
            print("error while startRecording : \(error)")
        }
        
    }
    
    /// 통화 버튼에서 손을 떼었을 때 녹음을 중단하는 함수
    /// - Parameter sender: touch up 된 버튼 객체
    @IBAction func touchUpCallButton(_ sender: UIButton) {
       stopRecording()
    }
    
    
    /// 플레이 레코드 버튼을 클릭했을 때 녹음된 파일을 재생하는 함수
    /// - Parameter sender: 클릭된 버튼 객체
    @IBAction func touchDownPlayButton(_ sender: UIButton) {
        audioPlayer.scheduleFile(file, at: nil)
        
        try! audioEngine.start()
        audioPlayer.play()
    }
    
    /// 플레이 레코드 버튼에서 손을 떼었을 때 녹음된 파일 재생을 끝내는 함수
    /// - Parameter sender: 클릭된 버튼 객체
    @IBAction func touchUpPlayButton(_ sender: UIButton) {
        audioPlayer.stop()
        audioEngine.stop()
    }
    
}

// TODO: - 델리게이트 함수 작성
/*
extension CallViewController: PeerConnectionDelegate {
    func connectionReady() {
        return
    }
    
    func connectionFailed() {
        return
    }
    
    func receivedAudio() {
        retu
    }
    
    func displayAdvertiseError(_ error: NWError) {
        <#code#>
    }
}
 */
