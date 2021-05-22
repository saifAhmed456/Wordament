//
//  TrieNode.swift
//  Wordament
//
//  Created by saif ahmed on 06/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
class TrieNode {
    var isEOW = false
    var child : Array<TrieNode?> = Array<TrieNode?>(repeating: nil, count: 26)
    func insert(word : Array<Character>) -> Bool {
        guard  let AsciiValOfFirstLetter  = Character("a").asciiValue else {return false }
        var root = self
        for char in word {
            guard let asciiValOfChar = char.asciiValue , char >= "a" && char <= "z" else { continue }
            if  root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)] == nil
             {
                root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)] = TrieNode()
                
            }
            
            root = root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)]!
        }
        root.isEOW = true
        return true
    }
    func search(for word : Array<Character>) -> Bool {
        guard  let AsciiValOfFirstLetter  = Character("a").asciiValue else {return false }
        var root = self
        for char in word {
            guard let asciiValOfChar = char.asciiValue else { return false }
            if root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)] == nil {
                return false
            }
            root = root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)]!
        }
        return root.isEOW
    }
    func doWordsExist(with prefix : Array<Character>) -> Bool {
        guard  let AsciiValOfFirstLetter  = Character("a").asciiValue else {return false }
        var root = self
        for char in prefix {
            guard let asciiValOfChar = char.asciiValue else { return false }
            if root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)] ==  nil {
                return false
            }
            root = root.child[Int(asciiValOfChar - AsciiValOfFirstLetter)]!
        }
        return root.child.reduce(false, { (result, root) -> Bool in
            return result || root != nil 
        })
    }
}
