//
//  WordamentModel.swift
//  Wordament
//
//  Created by saif ahmed on 06/08/19.
//  Copyright © 2019 saif ahmed. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
class WordamentModel {
    var grid : Array<[Character]> = []
    var root : TrieNode = TrieNode()
    var numOfRows = 5
    var numOfCols = 4
    var disposeBag = DisposeBag()
    var reload = PublishSubject<Void>()
    var reloadCollectionView = PublishSubject<Void>()
    var insertRows = PublishSubject<[IndexPath]>()
    var indexPathsPanned: PublishSubject<[IndexPath]> = PublishSubject()
    var url = URL(string: "https://raw.githubusercontent.com/dwyl/english-words/master/words_dictionary.json")
    var remoteFileUrl = URL(string: "https://raw.githubusercontent.com/dwyl/english-words/master/words_alpha.txt")
   lazy var solver : WordamentSolver = WordamentSolver(grid, numOfRows, numOfCols, root)
    var wordsFound : Array<String> = []
    var isValidWord : Observable<(String?, Bool)> {
        return  indexPathsPanned
            .map { [weak self] (indexPathArray) -> (String?,Bool) in
                guard let `self` = self else { return (nil,false) }
                var arr : [Character] = []
                for i in indexPathArray {
                    let char = self.grid[i.row / self.numOfCols][i.row % self.numOfCols]
                    arr.append(char)
                }
                return ( String(arr),self.root.search(for: arr) )
        }
    }
    init() {
        setRandomChars(numOfRows, numOfCols)
        downloadDictionaryData(with: {
            print("successfully parsed data")
        }, with: { (error) in
            print(error)
        })
        setupBindings()
    }
    
    func setRandomChars(_ r : Int , _ c : Int ) {
        let aToZ = (0..<26).map({Character(UnicodeScalar("a".unicodeScalars.first!.value + $0)!)})
        var vowels : Array<Character> = ["a", "e" , "i" , "o" , "u"]
         var rareLetters : Array<Character> = ["x", "y", "z" , "q", "j" , "v"]
        var consonants = aToZ.filter{ !vowels.contains($0) && !rareLetters.contains($0) }
        let twoVowelRows = [Int.random(in: 0...r - 1), Int.random(in: 0...r - 1)]
        let rareLetterRow = Int.random(in: 0...r - 1)
        for curRow in 0...r-1 {
            var charArray : Array<Character> = []
            var vowelCol = [Int.random(in: 0...c - 1)]
           var rareLetterCol : Int = rareLetterRow == curRow ? Int.random(in: 0...c - 1) : -1
            while( rareLetterRow == curRow && vowelCol.contains(rareLetterCol) == true ) {
                rareLetterCol = Int.random(in: 0...c - 1)
            }
            if twoVowelRows.contains(curRow) {
                vowelCol.append(Int.random(in: 0...c - 1))
            }
            for curCol in 0...c-1 {
                var randomChar : Character
                if vowelCol.contains(curCol) {
                    let randomInt = Int.random(in: 0...vowels.count - 1)
                    randomChar = vowels[randomInt]
                }
                else if rareLetterCol == curCol {
                    let randomInt = Int.random(in: 0...rareLetters.count - 1)
                    randomChar = rareLetters[randomInt]
                }
                else  {
                let randomInt = Int.random(in: 0...consonants.count - 1)
                randomChar = consonants.remove(at: randomInt)
                }
                charArray.append(randomChar)
            }
            grid.append(charArray)
        }
        reloadCollectionView.onNext(())
    }
    
    func setupBindings() {
       reloadCollectionView
        .subscribe(onNext : { _ in
            print("reload collection view")
            
        })
        .disposed(by: disposeBag)
    }
    
    func setNewGrid() {
        grid.removeAll()
        wordsFound.removeAll()
        reload.onNext(())
        setRandomChars(numOfRows, numOfCols)
        solver = WordamentSolver(grid, numOfRows, numOfCols, root)
    }
}
extension WordamentModel : ViewModelprotocol,CollectionViewDataProvider , TableViewDataProvider {
    func numberOfSectionsInTable() -> Int {
        return 1
    }
    
    func numberOfWordsFound(in section: Int) -> Int {
        return wordsFound.count
    }
    
    func word(for indexPath: IndexPath) -> String {
        guard   indexPath.row < wordsFound.count else  { return "" }
        return wordsFound[indexPath.row]
    }
    
     
    
    func numberOfSections() -> Int {
        return 1
    }
    
    func numberOfRows(in section: Int) -> Int {
        return numOfCols * numOfRows
    }
    
    func element(for indexPath: IndexPath) -> String {
        guard indexPath.row < numOfCols * numOfRows else { return "" }
        return String(grid[indexPath.row/numOfCols][indexPath.row % numOfCols]).uppercased()
    }
    
    
}
extension WordamentModel {
    func downloadDictionaryData(with successcompletionhandler : @escaping () -> () , with errorCompletionhandler : @escaping (String) -> () ) {
        let fileManager = FileManager.default
        var fileUrl : URL?
        do {
            let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
            fileUrl = documentDirectory.appendingPathComponent("dictionary")//.appendingPathExtension(".txt")
            
            
        } catch {
            print(error)
        }
        guard let url = remoteFileUrl, let fileUrl1 = fileUrl, fileManager.fileExists(atPath : fileUrl1.path) == false  else {
            readFile(at: fileUrl)
            
            return }
        let sessionConfiguration =  URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.downloadTask(with: url) { [weak self](localUrl, response,  error) in
            guard error == nil,let localUrl = localUrl  else {
                print(error!.localizedDescription)
                errorCompletionhandler(error!.localizedDescription)
                return
            }
            do {
                let data = try Data(contentsOf: localUrl)
                try  data.write(to:fileUrl1 )
            }
            catch {
                print(error.localizedDescription)
            }
            self?.readFile(at: fileUrl1)
            successcompletionhandler()
        }
        task.resume()
    }
    func getDictionaryData(with successcompletionhandler : @escaping () -> () , with errorCompletionhandler : @escaping (String) -> ())  {
        
        guard let url = url else { return }
        let sessionConfiguration =  URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.downloadTask(with: url) { [weak self](localUrl, response,  error) in
            guard error == nil,let localUrl = localUrl  else {
                print(error!.localizedDescription)
                errorCompletionhandler(error!.localizedDescription)
                return
            }
            self?.parseData(at : localUrl)
            successcompletionhandler()
        }
        task.resume()
    }
    func readFile(at url : URL?) {
        var dictionary : String?
        var words : [String]?
        guard let url = url else {return }
        do {
          dictionary =  try String(contentsOf: url)
            words = dictionary?.components(separatedBy: CharacterSet.newlines)
        }
        catch {
            print(error.localizedDescription)
        }
        guard let words1 = words else {
            print("could not read file")
            return
        }
        for word in words1 {
            let charcterArray = Array<Character>(word.lowercased())
            guard charcterArray.count > 2 else { continue }
            let didInsert = root.insert(word: charcterArray)
            if didInsert == false {
                print("could not insert the word \(word)")
            }
        }
        print("successfully parsed  data")
        
       
    }
    func parseData(at url : URL) {
        let data : Data?
        let dictionary : Dictionary<String,Int>?
        do {
            data = try Data(contentsOf: url)
            dictionary = try JSONSerialization.jsonObject(with:data! , options: .init(rawValue: 0)) as? Dictionary<String,Int>
        }
        catch  {
            print("can not retrieve data from url")
            return
        }
        
        guard let dic = dictionary else {
            return
        }
        for (key,_) in dic {
            
           let charcterArray = Array<Character>(key.lowercased())
            guard charcterArray.count > 2 else { continue }
           let didInsert = root.insert(word: charcterArray)
            if didInsert == false {
                print("could not insert the word \(key)")
            }
            
            
            
        }
        //solver.findSolution()
    }
    
}
extension WordamentModel {
    
    func setupBindings(for view : WordamentViewControllerProtocol) {
        view.dataProviderSubject.onNext(self)
        view.indexPathsPannedSubject
            .bind(to : indexPathsPanned)
            .disposed(by: disposeBag)
        isValidWord
            .map({ [weak self] (tuple) -> WordState  in
                guard tuple.1 == true , let word = tuple.0, let `self` = self else { return WordState.notAWord }
                if self.wordsFound.contains(word) {
                    return WordState.formedWord
                }
                return WordState.rightWord
            })
            .bind(to: view.didFormWord)
            .disposed(by: disposeBag)
        
        isValidWord
            .filter{ $0.1 }
            .subscribe(onNext : { [weak self] (word,_) in
                guard let word = word ,  self?.wordsFound.contains(word) == false, let `self` = self  else { return }
                self.wordsFound.insert(word, at: 0)
                self.insertRows.onNext([IndexPath(row: 0, section: 0)])
                
            })
            .disposed(by : disposeBag)
        reloadCollectionView
            .bind(to: view.reloadCollectionView)
            .disposed(by : disposeBag)
        
    }
}
