//
//  NWParameters.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/22.
//

import Network
import CryptoKit

extension NWParameters {
    
    // 주파수를 인자로 받아서 NWParameters 객체를 생성하는 init 구현
    convenience init(frequency: String) {
        
        let udpOptions = NWProtocolUDP.Options()
        
        // 커스텀 DTLS와 UDP 옵션으로 NWParameters 생성
        self.init(dtls: NWParameters.dtlsOptions(frequency: frequency), udp: udpOptions)
        
        // p2p 링크 사용 허용
        self.includePeerToPeer = true
    }
    
    // frequency를 사용해 pre-shared key를 만드는 커스텀 dtls 옵션 구현
    private static func dtlsOptions(frequency: String) -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()
        
        let authenticationKey = SymmetricKey(data: frequency.data(using: .utf8)!)
        var authenticationCode = HMAC<SHA256>.authenticationCode(for: "SimplePeertoPeer".data(using: .utf8)!, using: authenticationKey)
        
        let authenticationDispatchData = withUnsafeBytes(of: &authenticationCode) {
            (ptr: UnsafeRawBufferPointer) in
            DispatchData(bytes: ptr)
        }
        
        sec_protocol_options_add_pre_shared_key(tlsOptions.securityProtocolOptions,
                                                authenticationDispatchData as __DispatchData,
                                                stringToDispatchData("SimplePeertoPeer")! as __DispatchData)
        sec_protocol_options_append_tls_ciphersuite(tlsOptions.securityProtocolOptions,
                                                    tls_ciphersuite_t(rawValue: TLS_PSK_WITH_AES_128_GCM_SHA256)!)
        return tlsOptions
    }
    
    // string을 pre-shared key data로 encode하는 유틸리티 함수 구현
    private static func stringToDispatchData(_ string: String) -> DispatchData? {
        guard let stringData = string.data(using: .unicode) else {
            return nil
        }
        
        let dispatchData = withUnsafeBytes(of: stringData) { (ptr: UnsafeRawBufferPointer) in
            DispatchData(bytes: UnsafeRawBufferPointer(start: ptr.baseAddress, count: stringData.count))
        }
        return dispatchData
    }
}
