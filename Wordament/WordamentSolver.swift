//
//  WordamentSolver.swift
//  Wordament
//
//  Created by saif ahmed on 08/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
class WordamentSolver  {
    var grid : Array<[Character]>
    var rows : Int
    var cols : Int
    var root : TrieNode
    var solution : [String] = []
    var reload = PublishSubject<Bool>()
    var didFindSolution = false
    init(_ grid : Array<[Character]> , _ rows : Int , _ cols : Int , _ root : TrieNode) {
        self.grid = grid
        self.rows = rows
        self.cols = cols
        self.root = root
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.findSolution()
        }
    }
    func findSolution() {
        let tempAray : [Bool] =  Array<Bool>(repeating: false, count: cols)
        let visited : Array<[Bool]> = Array<[Bool]>(repeating: tempAray, count: rows)
        for i in 0...rows-1 {
            for j in 0...cols-1 {
                helper(grid, visited,i,j,[])
            }
        }
        reload.onNext(true)
        didFindSolution = true 
        
    }
    
    
    func helper(_ grid : Array<[Character]> , _ constVisited : Array<[Bool]> , _ i : Int , _ j : Int , _ formedWord : [Character] ) {
        if i < 0 || j < 0 || i >= rows || j >= cols {
            return
        }
        if constVisited[i][j] {
            return
        }
        var visited = constVisited
        var word = formedWord
        word.append(grid[i][j])
        visited[i][j] = true
        if root.search(for: word){
            solution.append(String(word))
            reload.onNext(false)
        }
        if root.doWordsExist(with: word) == false {
            
             return
        }
        let rowSeq = -1...1
        for curRow in rowSeq {
            for curCol in rowSeq {
                helper(grid,visited,i+curRow,j+curCol,word)
            }
        }
        
    }
}
extension WordamentSolver : SolutionTableViewDataProvider {
    
  
    func numberOfSectionsInTable() -> Int {
        return  1
    }
    
    func numberOfWordsFound(in section: Int) -> Int {
        return solution.count
    }
    
    func word(for indexPath: IndexPath) -> String {
        guard indexPath.row < solution.count else { return ""}
        return solution[indexPath.row]
    }
    
    
}
extension Reactive where Base : WordamentSolver {
    var calculateSolution : Binder<Void> {
        return Binder(base) { (solver, _) in
            solver.didFindSolution = false
            solver.findSolution()
            
        }
    }
}
