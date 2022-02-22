//
//  PeerListener.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/21.
//

import Foundation
import Network

var sharedListener: PeerListener?

// PeerListener 클래스는 peer의 advertise를 담당한다.

class PeerListener {
    
    weak var delegate: PeerConnectionDelegate?
    var listener: NWListener?
    var name: String
    var frequency: String
    
    /**
     listener 생성
     
     - parameter name: name to advertise
     - parameter frequency: frequency for authentication and advertise
     - parameter delegate: delegate to handle inbound connections
     */
    init(name: String, frequency: String, delegate: PeerConnectionDelegate) {
        self.delegate = delegate
        self.name = name
        self.frequency = frequency
        
        startListening()
    }
    
    // listening and advertising 시작
    func startListening() {
        do {
            // listener 객체 생성
            let listener = try NWListener(using: NWParameters(frequency: frequency))
            self.listener = listener
            
            // advertise 할 서비스 set
            listener.service = NWListener.Service(name: self.name, type: "_simpleP2P._udp")
            
            listener.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    print("Listener ready on \(String(describing: listener.port))")
                case .failed(let error):
                    if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                        print("Listener failed with \(error), restarting")
                        listener.cancel()
                        self.startListening()
                    } else {
                        print("Listener failed with \(error), stopping")
                        self.delegate?.displayAdvertiseError(error)
                        listener.cancel()
                    }
                case .cancelled:
                    sharedListener = nil
                default:
                    break
                }
            }
            
            listener.newConnectionHandler = { newConnection in
                if let delegate = self.delegate {
                    // 연결된 connection이 없다면 connection 생성
                    if sharedConnection == nil {
                        sharedConnection = PeerConnection(connection: newConnection, delegate: delegate)
                    } else {
                        // 이미 연결된 connection이 있다면 새로운 inbound connection reject
                        newConnection.cancel()
                    }
                }
            }
            
            // listening 시작, 메인 큐에서 업데이트 요청
            listener.start(queue: .main)
        } catch {
            print("Listener 생성 실패")
            abort()
        }
    }
    
}
