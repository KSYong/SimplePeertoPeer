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
    
    private var recordedFileURL = URL(fileURLWithPath: "input.caf", isDirectory: false, relativeTo: URL(fileURLWithPath: NSTemporaryDirectory()))
    
    private var audioSession: AVAudioSession!
    private var audioEngine: AVAudioEngine!
    private var mixerNode: AVAudioMixerNode!
    
    private var state: RecordingState = .stopped
    private var isTouched: Bool?
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioSession()
        
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
        
        mixerNode.volume = 0
        
        audioEngine.attach(mixerNode)
        
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