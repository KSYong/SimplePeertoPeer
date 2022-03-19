//
//  FrequencyViewController.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/24.
//

import UIKit
import Network

/**
 주파수를 입력하고 통화에 join하는 화면의 View Controller이다.
 */
class FrequencyViewController: UITableViewController {
    
    @IBOutlet weak var frequencyField: UITextField!
    var browseResult: NWBrowser.Result?
    var peerListViewController: PeerListViewController?
    
    var hasMadeCall = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let browseResult = browseResult,
           case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = browseResult.endpoint {
            title = "Join \(name)"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if hasMadeCall {
            navigationController?.popToRootViewController(animated: false)
            hasMadeCall = false
        }
    }
    
    func joinPressed() {
        hasMadeCall = true
        if let frequency = frequencyField.text,
            let browseResult = browseResult,
           let peerListViewController = peerListViewController {
            sharedConnection = PeerConnection(endpoint: browseResult.endpoint, interface: browseResult.interfaces.first, frequency: frequency, delegate: peerListViewController)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            joinPressed()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
