//
//  NibLoadable.swift
//  Wordament
//
//  Created by saif ahmed on 06/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//
import Foundation
import UIKit

/// NibLoadable - Protocol used to add Xib from owner, and enable IBDesignable for views
public protocol NibLoadable: class {
    func loadView(for name: String) -> UIView?
}

public extension NibLoadable where Self: UIView {
    
    /// Adding generated view from Nib, as first subview
    func addXib(withName name: String? = nil) {
        let selfName = name ?? String(describing: type(of: self))
        guard let view = loadView(for: selfName) else { return }
        
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [view.topAnchor.constraint(equalTo: topAnchor),
                           view.bottomAnchor.constraint(equalTo: bottomAnchor),
                           view.leadingAnchor.constraint(equalTo: leadingAnchor),
                           view.trailingAnchor.constraint(equalTo: trailingAnchor)]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    /// Generating first view from nib
    ///
    /// - Parameter name: name of nib file
    /// - Returns: Generated first view from nib named
    func loadView(for name: String) -> UIView? {
        let bundle = Bundle(for: Self.self)
        let nib = UINib(nibName: name, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
}
