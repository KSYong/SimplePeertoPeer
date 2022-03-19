//
//  ViewController.swift
//  SimplePeertoPeer
//
//  Created by SEUNGYONG KWON on 2022/02/21.
//

import UIKit
import Network

class PeerListViewController: UITableViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var frequencyLabel: UILabel!
    
    // NWBrowser: 사용 가능한 네트워크 서비스를 브라우징하는 객체
    // NWBrowser.Result : 발견된 서비스들과 마지막 브라우징 결과로부터 변경된 사항들의 집합
    var results: [NWBrowser.Result] = [NWBrowser.Result]()
    var name: String = "Default"
    var frequency: String = ""
    
    var sections: [CallFinderSection] = [.host, .join]
    
    enum CallFinderSection {
        case host
        case frequency
        case join
    }
    
    /**
     sharedListener가 존재한다면 주파수 공개, 그렇지 않다면 주파수 비공개
     */
    func shouldShowFrequency() -> Bool {
        if sharedListener != nil {
            return true
        }
        return false
    }
    
    /**
    사용 가능한 네트워크 서비스가 없다면 결과 row 갯수 1, 그렇지 않다면 6개 이하로 row 표시
     */
    func resultRows() -> Int {
        if results.isEmpty {
            return 1
        } else {
            return min(results.count, 6)
        }
    }
    
    /**
     앱이 게임 호스팅을 시작하면 새로운 4자리의  랜덤 주파수를 생성한다.
     */
    func generateFrequency() -> String {
        return String("\(Int.random(in: 0...9))\(Int.random(in: 0...9))\(Int.random(in: 0...9))\(Int.random(in: 0...9))")
    }
    
    // MARK: -viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // 새로운 주파수 생성하기
        frequency = generateFrequency()
        frequencyLabel.text = frequency
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "joinCallCell")
    }
    
    /**
     host call 버튼을 클릭했을 때 실행되는 함수
     */
    func hostCallButton() {
        // 유저가 hosting을 시작하면 키보드 dismiss 하기
        view.endEditing(true)
        
        // 유저가 입력한 이름이 empty가 아님을 확인하기
        // 여기서 콤마(,)는 condition을 이어붙인다는 뜻이다.
        guard let name = nameField.text,
              !name.isEmpty else {
                  return
        }
        
        // 입력한 이름이 empty가 아니라면 self.name에 nameField에서 가져온 이름 할당
        self.name = name
        if let listener = sharedListener {
            listener.resetName(name)
        } else {
            sharedListener = PeerListener(name: name, frequency: frequency, delegate: self)
        }
        
        sections = [.host, .frequency, .join]
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let frequencyVC = segue.destination as? FrequencyViewController {
            frequencyVC.browseResult = sender as? NWBrowser.Result
            frequencyVC.peerListViewController = self
        }
    }
    
    /**
     section의 수 return 하는 함수
     */
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    /**
     section 안의 row 수 return 하는 함수
     */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentSection = sections[section]
        // 각 section마다 반환할 row 수 switch-case문으로 구현
        switch currentSection {
        case .host:
            return 2
        case .frequency:
            return 1
        case .join:
            return resultRows()
        }
    }
    
    /**
     각 section 의 header 에 들어갈 title String을 반환하는 함수
     */
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let currentSection = sections[section]
        switch currentSection {
        case .host:
            return "Host Call"
        case .frequency:
            return "Frequency"
        case .join:
            return "Join Call"
        }
    }
    
    /**
     각 Row에 들어갈 UITableViewCell 객체를 반환하는 함수
     */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentSection = sections[indexPath.section]
        if currentSection == .join {
            let cell = tableView.dequeueReusableCell(withIdentifier: "joinCallCell") ?? UITableViewCell(style: .default, reuseIdentifier: "joinCallCell")
            if sharedBrowser == nil {
                cell.textLabel?.text = "Search for calls"
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .systemBlue
            } else if results.isEmpty {
                cell.textLabel?.text = "Searching for calls..."
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = .systemGray
            } else {
                let peerEndpoint = results[indexPath.row].endpoint
                if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = peerEndpoint {
                    cell.textLabel?.text = name
                } else {
                    cell.textLabel?.text = "Unknown Endpoint"
                }
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.textColor = .systemGray
            }
            return cell
        }
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentSection = sections[indexPath.section]
        
        switch currentSection {
        case .host:
            if indexPath.row == 1 {
                hostCallButton()
            }
        case .join:
            if sharedBrowser == nil {
                sharedBrowser = PeerBrowser(delegate: self)
            } else if !results.isEmpty {
                let result = results[indexPath.row]
                performSegue(withIdentifier: "showFrequencySegue", sender: result)
            }
        default:
            print("비활성화된 열을 터치하였습니다: \(indexPath)")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

/**
 PeerBrowserDelegate를 준수하기 위한 extension 이다.
 */
extension PeerListViewController: PeerBrowserDelegate {
    func refreshResults(results: Set<NWBrowser.Result>) {
        self.results = [NWBrowser.Result]()
        for result in results {
            if case let NWEndpoint.service(name: name, type: _, domain: _, interface: _) = result.endpoint {
                if name != self.name {
                    self.results.append(result)
                }
            }
        }
        tableView.reloadData()
    }
    
    func displayBrowseError(_ error: NWError) {
        var message = "Error \(error)"
        if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
            message = "네트워크 접근 권한이 없습니다"
        }
        let alert = UIAlertController(title: "다른 사용자들을 발견할 수 없습니다", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}

/**
 PeerConnectionDelegate를 준수하기 위한 extension 이다.
 */
extension PeerListViewController: PeerConnectionDelegate {
    
    // connection이 Ready 상태라면 call mode로 진입한다
    func connectionReady() {
        navigationController?.performSegue(withIdentifier: "showCallSegue", sender: nil)
    }
    
    // peer advertise가 실패했다면 advertise error 표시하기
    func displayAdvertiseError(_ error: NWError) {
        var message = "Error \(error)"
        if error == NWError.dns(DNSServiceErrorType(kDNSServiceErr_NoAuth)) {
            message = "네트워크 접근 권한이 없습니다"
        }
        let alert = UIAlertController(title: "통화를 host할 수 없습니다", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    // 통화를 시작하기 전에는 connection fail 무시하기
    func connectionFailed() { }
}

