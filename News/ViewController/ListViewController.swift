//
//  ViewController.swift
//  News
//
//  Created by 김기현 on 2020/03/17.
//  Copyright © 2020 김기현. All rights reserved.
//


import UIKit
import Kingfisher

class ListViewController: UIViewController {
    @IBOutlet private var tableView: UITableView!
    private let refreshController = UIRefreshControl()
    
    var xmlParser = XMLParser()
    var newsItems = [RSSData]()
    let url = "https://news.google.com/rss"
    var parse = Parse()
    var htmlParser = HtmlParser()
    var keyword = Keyword()
    
    func requestNewsInfo() {
        DispatchQueue.global().async {
            guard let xmlParser = XMLParser(contentsOf: URL(string: self.url)!) else { return }
            
            xmlParser.delegate = self.parse
            xmlParser.parse()
            self.newsItems = self.parse.getNewsItems()
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshController.endRefreshing()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestNewsInfo()
        tableView.dataSource = self
        
        tableView.refreshControl = refreshController
        refreshController.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        self.title = "News"
    }
    
    @objc func refresh() {
        requestNewsInfo()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "content" {
            if let row = tableView.indexPathForSelectedRow {
                let vc = segue.destination as? ContentViewController
                let content = self.newsItems[row.row]
                
                vc?.newsItems = content
                
                tableView.deselectRow(at: row, animated: true)
            }
        }
    }
    

}

extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell", for: indexPath) as! ListTableViewCell
        
        let url = newsItems[indexPath.row].link
        cell.link = url
        cell.titleLabel?.text = newsItems[indexPath.row].title
        if newsItems[indexPath.row].imageAddress == nil && newsItems[indexPath.row].description == nil {
            htmlParser.sendRequest(url: url!) { (result: [String]) in
                self.newsItems[indexPath.row].imageAddress = result[0]
                self.newsItems[indexPath.row].description = result[1]
                
                guard cell.link == url else { return }
                DispatchQueue.main.async {
                    cell.contentLabel?.text = result[1]
                    let url = URL(string: result[0])
                    cell.thumbNailImage.kf.setImage(with: url, placeholder: UIImage(named: "noImage"))
                    
                    self.keyword.getKeyword(str: self.newsItems[indexPath.row].description ?? "") { (result: [String]) in
                        if result != [] {
                            self.newsItems[indexPath.row].keyword = result
                            cell.firstLabel?.text = result[0]
                            cell.secondLabel?.text = result[1]
                            cell.thirdLabel?.text = result[2]
                        }
                        else {
                            cell.firstLabel?.text = ""
                            cell.secondLabel?.text = ""
                            cell.thirdLabel?.text = ""
                        }
                    }
                }
            }
        } else {
            cell.contentLabel?.text = newsItems[indexPath.row].description
            let url = URL(string: newsItems[indexPath.row].imageAddress ?? "")
            cell.thumbNailImage.kf.setImage(with: url, placeholder: UIImage(named: "noImage"))
            if newsItems[indexPath.row].keyword != nil {
                cell.firstLabel?.text = newsItems[indexPath.row].keyword?[0]
                cell.secondLabel?.text = newsItems[indexPath.row].keyword?[1]
                cell.thirdLabel?.text = newsItems[indexPath.row].keyword?[2]
            } else {
                cell.firstLabel?.text = ""
                cell.secondLabel?.text = ""
                cell.thirdLabel?.text = ""
            }
            
        }
        
        return cell
    }
}
