//
//  PeerBrowser.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/21.
//

import Foundation
import Network

// PeerBrowser는 Bonjour service 타입을 통해 endpoint를 발견(discover)한다.

// VC와 공유할 브라우저
var sharedBrowser: PeerBrowser?

// delegate 프로토콜
// Anyobject 프로토콜을 준수하여 클래스만이 아래 delegate 프로토콜을 사용하도록 한다.
protocol PeerBrowserDelegate: AnyObject {
    // 결과 새로고침 및 브라우징 에러 표시 기능을 위임함
    func refreshResults(results: Set<NWBrowser.Result>)
    func displayBrowseError(_ error: NWError)
}

class PeerBrowser {
    
    weak var delegate: PeerBrowserDelegate?
    var browser: NWBrowser?
    
    // delgate를 사용하여 browsing 객체를 생성하기
    init(delegate: PeerBrowserDelegate) {
        // PeerBrowser 객체를 생성하여 사용할 뷰 컨트롤러에서 선언한 델리게이트를 인자로 받아와
        // 특정 동작들을 뷰 컨트롤러로 책임 넘기기
        self.delegate = delegate
        startBrowsing()
    }
    
    func startBrowsing() {
        // NWParameter 객체 생성
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: "_simpleP2P._udp", domain: nil), using: parameters)
        self.browser = browser
        
        // stateUpdateHandler 작성
        browser.stateUpdateHandler = { newState in
            switch newState {
            case .failed(let error):
                // 브라우저가 에러가 났을 때
                // 에러가 연결 실패 에러라면 다시 시작
                if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_DefunctConnection)) {
                    print("NWBrowser가 다음 이유로 실패했습니다. 브라우징을 다시 시작합니다. \(error)")
                    browser.cancel()
                    self.startBrowsing()
                } else {
                    // 그 외 에러라면 브라우징 stop
                    print("NWBrowser가 다음 이유로 실패했습니다. 브라우징을 멈춥니다. \(error)")
                    browser.cancel()
                }
            case .ready:
                // 브라우저가 discovering service들에 등록되었을 때
                // 델리게이트의 refreshResults 에 브라우징 결과를 전달하며 실행
                self.delegate?.refreshResults(results: browser.browseResults)
            case .cancelled:
                // 브라우저가 cancel되었을 때
                // 델리게이트의 refreshResults에 빈 Set 전달
                sharedBrowser = nil
                self.delegate?.refreshResults(results: Set())
            default:
                break
            }
        }
        
        // 브라우징 결과가 변할 때마다 호출되는 browseResultsChangedHandler 호출
        browser.browseResultsChangedHandler = { results, changes in
            self.delegate?.refreshResults(results: results)
        }
        
        // browser 스타트
        browser.start(queue: .main)
    }
    
}
