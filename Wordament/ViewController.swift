//
//  ViewController.swift
//  Wordament
//
//  Created by saif ahmed on 06/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
protocol TableViewDataProvider {
    var reload : PublishSubject<Void> { get }
    var insertRows : PublishSubject<[IndexPath]> { get }
    func numberOfSectionsInTable() -> Int
    func numberOfWordsFound(in section : Int) -> Int
    func word(for indexPath : IndexPath) -> String
}
 protocol ViewModelprotocol :  CollectionViewDataProvider, TableViewDataProvider {
    func setupBindings(for view : WordamentViewControllerProtocol)
    var indexPathsPanned : PublishSubject<[IndexPath]> { get set }
    var disposeBag : DisposeBag { get set }
    var isValidWord : Observable<(String?, Bool)> { get }
    var wordsFound : Array<String> { get set }
    var insertRows : PublishSubject<[IndexPath]> {get set}
    //var isAWord : PublishSubject<Bool> { get set}
    
}

class ViewController: UIViewController,UICollectionViewDelegateFlowLayout, UITableViewDelegate {
    
    @IBOutlet var wordsFoundTableView: UITableView!
    
    @IBOutlet var restartButton: UIBarButtonItem!
    @IBOutlet var solutionButton: UIBarButtonItem!
    var viewModel = WordamentModel()
    var numOfRows = 5
    var numOfCols = 4
    let disposeBag = DisposeBag()
    var tableViewdataProvider : TableViewDataProvider?
    
    @IBOutlet var mainView: WordamentCollectionView!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        viewModel.setupBindings(for: self)
        setupBindingsForTableView()
    }
    
   func  setupBindingsForTableView() {
    wordsFoundTableView.layer.cornerRadius = 5.0
    wordsFoundTableView.dataSource = self
    wordsFoundTableView.register(UITableViewCell.self, forCellReuseIdentifier: "WordsFoundCell")
    tableViewdataProvider = viewModel
    
        tableViewdataProvider?.reload
            .subscribe(onNext : { [weak self] _ in
                self?.wordsFoundTableView.reloadData()
                
            })
            .disposed(by : disposeBag)
    tableViewdataProvider?.insertRows
        .subscribe(onNext : { [weak self] indexPaths in
            self?.wordsFoundTableView.insertRows(at: indexPaths, with: .automatic)
            
            
        })
        .disposed(by : disposeBag)
    solutionButton.rx
        .tap
        .subscribe(onNext : { [weak self] in
            self?.gotoSolutionViewController()
            
        })
        .disposed(by : disposeBag)
    restartButton.rx
        .tap
        .subscribe(onNext : { [weak self] in
            self?.restartGame()
            
        })
        .disposed(by : disposeBag)
    
    }
    func restartGame() {
        viewModel.setNewGrid()
        
    }
    func gotoSolutionViewController() {
        let solutionVC = UIStoryboard.create(for: SolutionViewController.self, with: viewModel.solver)
        self.present(solutionVC, animated: true, completion: nil)
    }

}
extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewdataProvider?.numberOfWordsFound(in: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WordsFoundCell") else { return UITableViewCell() }
        let word = tableViewdataProvider?.word(for: indexPath)
        cell.textLabel?.text = word ?? ""
        return cell 
    }
    
    
}
extension ViewController : WordamentViewControllerProtocol { 
   
    var didFormWord: PublishSubject<WordState> {
        return mainView!.didFormWord
    }
    
    
    
    var dataProviderSubject: PublishSubject<CollectionViewDataProvider> {
        return mainView!.dataProviderSubject
    }
    

    var lastIndexPath: BehaviorRelay<IndexPath?> {
        return mainView.lastIndexPath
    }
    
    var indexPathsPannedSubject: PublishSubject<Array<IndexPath>> {
        return mainView.indexPathsPannedSubject
    }
    
    var reloadCollectionView : Binder<Void> {
        return mainView.collectionView.rx.reload
    }
    
}


public extension UIStoryboard {
    
    class internal func create<T>(for viewController: T.Type, with solver: WordamentSolver) -> T where  T: SolutionViewController {
        
        let name = String(describing: viewController.self)
        
        guard let instantiatedViewController = UIStoryboard(name: name, bundle: nil).instantiateInitialViewController() else {
            fatalError("Instantiate Initial ViewController for storyboard named \(name) do not exist")
        }
        
        guard let genericViewConroller = instantiatedViewController as? T else {
            fatalError("Instantiate view controller Custom Class is not \(viewController.self)")
        }
        
        genericViewConroller.solver = solver
        
        return genericViewConroller
    }
    
    // swiftlint:disable:next line_length
   
}
