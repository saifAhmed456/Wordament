//
//  WordamentCollectionView.swift
//  Wordament
//
//  Created by saif ahmed on 06/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import AudioToolbox
enum WordState {
    case notAWord
    case rightWord
    case formedWord
}
struct CollectionViewCellConfig : CollectionViewCellConfigProtocol {
    
    var borderColor: UIColor = .black
    
    var backgroundColor: UIColor
    
    var textColor: UIColor
    
    var textAlignment: NSTextAlignment = .center
    
    var textFontRatio: CGFloat =  40.0/77.4418
    
    var borderWidth: CGFloat = 3.0
    init(backgroundColor : UIColor , textColor : UIColor) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    
}
protocol WordamentViewControllerProtocol {
    var indexPathsPannedSubject : PublishSubject<Array<IndexPath>>  { get }
    var lastIndexPath : BehaviorRelay<IndexPath?> { get }
    var dataProviderSubject : PublishSubject<CollectionViewDataProvider> { get  }
    var didFormWord : PublishSubject<WordState> { get }
    var reloadCollectionView : Binder<Void> { get }
}
protocol CollectionViewDataProvider {
    func numberOfSections() -> Int
    func numberOfRows(in section : Int) -> Int
    func element(for indexPath : IndexPath) -> String
    var reloadCollectionView : PublishSubject<Void> { get set }
}
class WordamentCollectionView : UIView,NibLoadable,UIGestureRecognizerDelegate {
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var collectionView: UICollectionView!
    var indexPathsPannedSubject = PublishSubject<Array<IndexPath>>()
    var lastIndexPath = BehaviorRelay<IndexPath?>(value : nil)
    var pannedRows : Array<IndexPath> = []
    var previousPannedRows : Array<IndexPath> = []
    var didEndPan = BehaviorRelay<Bool>(value: false)
    var disposeBag = DisposeBag()
    var dataProvider : CollectionViewDataProvider?
     var dataProviderSubject : PublishSubject<CollectionViewDataProvider> = PublishSubject()
    var defaultCellConfig = CollectionViewCellConfig(backgroundColor: .mjaOrange, textColor: UIColor(white: 1.0, alpha: 1.0) )
    var selectedCellConfig = CollectionViewCellConfig(backgroundColor: UIColor(white: 0.8, alpha: 1.0) , textColor: .black)
    var rightCellConfig = CollectionViewCellConfig(backgroundColor: UIColor.green.withAlphaComponent(0.8) , textColor: .black)
    var wrongCellConfig = CollectionViewCellConfig(backgroundColor: UIColor.red.withAlphaComponent(0.8) , textColor: .black)
    var formedCellConfig = CollectionViewCellConfig(backgroundColor: UIColor.yellow.withAlphaComponent(0.8) , textColor: .black)
    var didFormWord = PublishSubject<WordState>()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    private func commonInit() {
        addXib()
        addPanGesture()
        setupBindings()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(WordamentCollectionViewCell.self, forCellWithReuseIdentifier: "WordamentCell")
    }
    func addPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(WordamentCollectionView.panDetected(_:)))
        panGesture.delegate = self
        self.collectionView.addGestureRecognizer(panGesture)
    }
    @objc func panDetected(_ panGesture : UIPanGestureRecognizer) {
        let panLocation = panGesture.location(in: collectionView)
        guard   let pannedIndexPath = collectionView.indexPathForItem(at: panLocation), let pannedCell = collectionView.cellForItem(at: pannedIndexPath)
            else {
                if panLocation.y > self.collectionView.frame.size.height || panLocation.y < 0  || panGesture.state == .ended {
                    panEnded()
                }
                return }
        let panFrame = CGRect(center: pannedCell.center, size: CGSize(width: pannedCell.frame.size.width * 0.8, height: pannedCell.frame.size.height * 0.8))
        
        if lastIndexPath.value == nil  {
            lastIndexPath.accept(pannedIndexPath)
            pannedRows = [pannedIndexPath]
            
        }
        else if panGesture.state == .changed {
            
            guard pannedIndexPath.row != lastIndexPath.value!.row, panFrame.contains(panLocation) else { return }
            guard !pannedRows.contains(where: { $0.row == pannedIndexPath.row
            }) else {
                panEnded()
                return
            }
            pannedRows.append(pannedIndexPath)
            lastIndexPath.accept(pannedIndexPath)
            
        }
        else if panGesture.state == .ended {
            
            if  !pannedRows.contains(where: { $0.row == pannedIndexPath.row })  {
                
                pannedRows.append(pannedIndexPath)
            }
            panEnded()
            
        }
        
    }
    func panEnded() {
        guard lastIndexPath.value != nil else { return}
        lastIndexPath.accept(nil)
        indexPathsPannedSubject.onNext(pannedRows)
        //previousPannedRows = pannedRows
        //collectionView.reloadItems(at: pannedRows.reversed())
    }
    func setupBindings() {
        lastIndexPath
            .asDriver()
            .map { [weak self] (indexPath) -> WordamentCollectionViewCell? in
                return  indexPath != nil ? self?.collectionView.cellForItem(at: indexPath!) as? WordamentCollectionViewCell : nil
            }
            .drive(onNext : { [weak self] cell in
                guard let cell = cell , let `self` = self  else { return }
                cell.state.onNext(.selected(self.selectedCellConfig))
                
            })
            .disposed(by: disposeBag)
        
        dataProviderSubject
            .subscribe(onNext : { [weak self] provider in
                self?.dataProvider = provider
                
            })
            .disposed(by : disposeBag)
        didFormWord
            .asDriver(onErrorJustReturn: .notAWord)
            .do(onNext : { wordState in
                switch wordState { 
                case .notAWord : SoundManager.playVibration()
                case .rightWord : SoundManager.playSoundForRightWord()
                case .formedWord : SoundManager.playImpactFeedback()
                }
                
            })
            .drive(onNext : { [weak self ] wordState in
                guard let `self` = self else { return }
                for indexPath in self.pannedRows  {
                   guard  let cell = self.collectionView.cellForItem(at: indexPath) , let wordamentCell = cell as? WordamentCollectionViewCell
                    else {continue }
                    guard wordState != .notAWord  else {
                        wordamentCell.state.onNext(.wrong(self.wrongCellConfig))
                        
                        continue
                    }
                    if wordState == .formedWord {
                        wordamentCell.state.onNext(.formed(self.formedCellConfig))
                        
                    }
                    else if wordState == .rightWord {
                        wordamentCell.state.onNext(.right(self.rightCellConfig))
                       
                    }
                }
               
                    self.collectionView.reloadItems(at: self.pannedRows.reversed())
                
            })
            .disposed(by : disposeBag)
        
    }
    
}
extension WordamentCollectionView : UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    // MARK : - Delegate Methods
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.frame.size.width * 10.0 ) / 43.0
        //let height = ((collectionView.frame.size.width * 10.0 ) - (4 * width) ) / 50.0
        return CGSize(width: width, height: width)
        
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return collectionView.frame.size.width / 43.0
    }
}
extension WordamentCollectionView : UICollectionViewDataSource {
    
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataProvider?.numberOfSections() ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataProvider?.numberOfRows(in: section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "WordamentCell", for: indexPath)
        guard let collectionViewCell = cell as? WordamentCollectionViewCell,
        let text = dataProvider?.element(for: indexPath) else { return UICollectionViewCell() }
            collectionViewCell.setConfig(defaultCellConfig)
            collectionViewCell.label.text = text
        return collectionViewCell
    }
    
    
}
extension CGRect {
    init (center : CGPoint , size : CGSize) {
        self.init(origin: CGPoint(x: center.x - size.width/2, y: center.y - size.height/2 ), size: size)
    }
}
extension Reactive where Base : UICollectionView {
    var reload : Binder<Void> {
        return Binder(base) {(view, _) in
            view.reloadData()
        }
    }
}
