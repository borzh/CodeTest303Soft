//
//  PeopleViewController.swift
//  CodeTest
//
//  Created by Boris Godin on 4/21/19.
//  Copyright © 2019 Boris Godin. All rights reserved.
//

import RxSwift
import RxCocoa
import SwiftMessages

struct Person: Decodable {
    let fname: String
    let lname: String
    let city: String
}

class PeopleViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let url = "http://www.filltext.com/?rows=100&fname=%7BfirstName%7D&lname=%7BlastName%7D&city=%7Bcity%7D&pretty=true";
    
    let disposeBag = DisposeBag()
    
    let people: BehaviorRelay<[Person]> = BehaviorRelay(value: [])

    let refreshControl = UIRefreshControl()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl.addTarget(self, action: #selector(PeopleViewController.fetchData), for: UIControlEvents.valueChanged)
        
        self.tableView.addSubview(refreshControl)
        
        people.bind(to: tableView.rx.items(cellIdentifier: "cell")) { row, model, cell in
            (cell.viewWithTag(1) as? UILabel)?.text = "\(model.fname), \(model.lname)"
            (cell.viewWithTag(2) as? UILabel)?.text = model.city
        }.disposed(by: disposeBag)
        
        self.fetchData()
    }

    func showMessage(theme: Theme, message: String, seconds: TimeInterval) {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.button?.isHidden = true
        view.configureDropShadow()
        
        view.layoutMarginAdditions = UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 20)
        (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
        
        
        view.configureTheme(theme)
        let iconText = theme == .error ? "🥺 " : "😊 "
        let titleText = theme == .error ? NSLocalizedString("Error", comment: "Error") : NSLocalizedString("Info", comment: "Info")
        view.configureContent(title: titleText, body: message, iconText: iconText)
        
        var config = SwiftMessages.defaultConfig
        config.duration = .seconds(seconds: seconds)
        config.presentationStyle = .bottom
        
        SwiftMessages.show(config: config, view: view)
    }
    
    @objc func fetchData() {
        self.showMessage(theme: .info, message: NSLocalizedString("DownloadingJson", comment: "DownloadingJson"), seconds: 3)

        if let url = URL(string: url) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                    self.refreshControl.endRefreshing()
                    if let data = data {
                        do {
                            let p = try JSONDecoder().decode([Person].self, from: data)
                            self.people.accept(p)
                        } catch let error {
                            print(error)
                            self.showMessage(theme: .error, message: NSLocalizedString("ErrorJson", comment: "ErrorJson"), seconds: 5)
                        }
                    }
                    else {
                        let msg = error == nil ? NSLocalizedString("ErrorDownload", comment: "ErrorDownload") : error!.localizedDescription
                        self.showMessage(theme: .error, message: msg, seconds: 5)
                    }
                }
            }.resume()
        }
    }

}
