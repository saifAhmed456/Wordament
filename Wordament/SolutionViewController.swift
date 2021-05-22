//
//  SolutionViewController.swift
//  Wordament
//
//  Created by saif ahmed on 06/09/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
protocol SolutionTableViewDataProvider {
    var reload : PublishSubject<Bool> { get }
    func numberOfSectionsInTable() -> Int
    func numberOfWordsFound(in section : Int) -> Int
    func word(for indexPath : IndexPath) -> String
    var didFindSolution : Bool { get }
    
}
class SolutionViewController : UIViewController {
    var solver : WordamentSolver?
    var dataProvider : SolutionTableViewDataProvider?
    var disposeBag = DisposeBag()
    
    @IBOutlet var closeButton: UIBarButtonItem!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    override func viewDidLoad() {
        super.viewDidLoad()
        dataProvider = solver
        if dataProvider?.didFindSolution == false {
            spinner.startAnimating()
        }
        setupBindings()
    }
    func setupBindings() {
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SolutionCell")
        dataProvider?.reload
            .subscribe(onNext : { [weak self] shouldStop in
                DispatchQueue.main.async {
                    if shouldStop  {
                    self?.spinner.stopAnimating()
                }
                    self?.tableView.reloadData()
                }
                
                
                
            })
            .disposed(by : disposeBag)
        closeButton.rx.tap
            .subscribe(onNext : { [weak self]  _ in
                self?.dismiss(animated: true, completion: nil)
                
            })
            .disposed(by : disposeBag)
    }
    
    
}
extension SolutionViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider?.numberOfWordsFound(in: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SolutionCell") , let word = dataProvider?.word(for: indexPath)else { return UITableViewCell()}
        cell.textLabel?.text =  word
        
        return cell
    }
    
    
}
