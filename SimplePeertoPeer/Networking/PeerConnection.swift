//
//  PeerConnection.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/21.
//

import Foundation
import Network

var sharedConnection: PeerConnection?

protocol PeerConnectionDelegate: AnyObject {
    func connectionReady()
    func connectionFailed()
//    func receivedAudio()
    func displayAdvertiseError(_ error: NWError)
}

class PeerConnection {
    
    weak var delegate: PeerConnectionDelegate?
    var connection: NWConnection?
    let initiatedConnection: Bool
    
    // 유저가 워키토키 방을 만들면 outbound connection 생성
    init(endpoint: NWEndpoint, interface: NWInterface?, frequency: String, delegate: PeerConnectionDelegate) {
        self.delegate = delegate
        self.initiatedConnection = true
        
        // frequency를 인자로 하는 NWParameters를 사용해 endpoint를 향한 NWConnection 수립
        let connection = NWConnection(to: endpoint, using: NWParameters(frequency: frequency))
        self.connection = connection
        
        startConnection()
    }
    
    // 유저가 연결 요청을 받으면(다른 유저가 워키토키 방에 들어오면) inbound 연결 handle
    init(connection: NWConnection, delegate: PeerConnectionDelegate) {
        self.delegate = delegate
        self.connection = connection
        self.initiatedConnection = false
        
        startConnection()
    }
    
    // 워키토키 연결을 cancel하는 함수
    func cancel() {
        if let connection = self.connection {
            connection.cancel()
            self.connection = nil
        }
    }
    
    // inbound와 outbound 연결을 위한 p2p 연결 시작
    func startConnection() {
        guard let connection = connection else {
            return
        }
        
        connection.stateUpdateHandler = { newState in
            switch newState{
            case .ready:
                print("\(connection) established")
                
                // 연결이 수립되면 오디오 통신 시작
                self.receiveAudio()
                
                // delegate에게 연결이 ready 상태임을 알린다
                if let delegate = self.delegate {
                    delegate.connectionReady()
                }
            case .failed(let error):
                print("\(connection) failed with \(error)")
                
                // 연결 실패일 경우 connection cancel
                connection.cancel()
                
                // delegate에게 연결이 실패했음을 알린다
                if let delegate = self.delegate{
                    delegate.connectionFailed()
                }
            default:
                break
            }
        }
    }
    
    
    // 추후 작성
    func sendAudio() {
        return
    }
    
    // 추후 작성
    func receiveAudio() {
        return
    }
}
