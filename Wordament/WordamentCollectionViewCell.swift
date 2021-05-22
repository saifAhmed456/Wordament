//
//  WordamentCollectionViewCell.swift
//  Wordament
//
//  Created by saif ahmed on 06/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
protocol CollectionViewCellConfigProtocol {
    var backgroundColor : UIColor { get }
    var textColor : UIColor { get }
    var textAlignment : NSTextAlignment { get }
    var textFontRatio : CGFloat { get }
    var borderWidth : CGFloat { get }
    var borderColor : UIColor { get }
    
}
enum CellState {
    case `default`( CollectionViewCellConfigProtocol)
    case selected ( CollectionViewCellConfigProtocol)
    case right (CollectionViewCellConfigProtocol)
    case wrong (CollectionViewCellConfigProtocol)
    case formed(CollectionViewCellConfigProtocol)
    
}
class WordamentCollectionViewCell : UICollectionViewCell {
    
    let label = UILabel()
    var state = PublishSubject<CellState>()
    let disposeBag = DisposeBag()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBindings()
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBindings()
        
    }
    func setupBindings() {
        setup()
        
         state
            .subscribe(onNext : { [weak self] cellState in
                switch cellState {
                case .default(let viewconfig) : self?.setConfig(viewconfig)
                case .selected(let viewconfig) : self?.setConfig(viewconfig)
                case .right(let viewconfig)    : self?.setConfig(viewconfig)
                case .wrong(let viewconfig)    : self?.setConfig(viewconfig)
                case .formed(let viewconfig)   : self?.setConfig(viewconfig)
                    
                }
                
            })
            .disposed(by: disposeBag)
        
        
    }
    func setConfig(_ config : CollectionViewCellConfigProtocol) {
        
        self.backgroundColor = config.backgroundColor
        self.label.textColor = config.textColor
        self.label.textAlignment = config.textAlignment
        self.label.font = UIFont.systemFont(ofSize: config.textFontRatio * self.frame.width)
        self.layer.borderWidth = config.borderWidth
        self.layer.borderColor = config.borderColor.cgColor
    }
    func setup() {
        self.addSubview(label)
        activateConstraints(for: label)
    }
    func activateConstraints(for view : UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0).isActive = true
    }
}
