//
//  Xref.swift
//  Unbound Bible
//
//  Created by Vladimir Rybant on 25.05.2020.
//  Copyright © 2020 Vladimir Rybant. All rights reserved.
//

import Foundation

class TXref: Module {
    
    private struct Alias {
        var xrefs      = "xrefs"
        var book       = "Book"
        var chapter    = "Chapter"
        var verse      = "Verse"
        var xbook      = "xbook"
        var xchapter   = "xchapter"
        var xfromverse = "xfromverse"
        var xtoverse   = "xtoverse"
        var votes      = "Votes"
    }

    private let mybibleAlias = Alias(
        xrefs      : "cross_references",
        book       : "book",
        chapter    : "chapter",
        verse      : "verse",
//      toverse    : "verse_end",
        xbook      : "book_to",
        xchapter   : "chapter_to",
        xfromverse : "verse_to_start",
        xtoverse   : "verse_to_end",
        votes      : "votes"
    )

    private var z = Alias()
    
    override init?(atPath: String) {
        super.init(atPath: atPath)!
        if format == .mybible { z = mybibleAlias }
        if connected && !database!.tableExists(z.xrefs) { return nil }
    }
    
    func getData(_ verse : Verse) -> [Verse]? {
        let id = encodeID(verse.book)
        let v_from = verse.number
        let v_to   = verse.number + verse.count - 1
        
        let query = "select * from \(z.xrefs) " +
                    "where \(z.book) = \(id) " +
                    "and \(z.chapter) = \(verse.chapter) " +
                    "and (\(z.verse) between \(v_from) and \(v_to)) "
        
        var result = [Verse]()
        if let results = database!.executeQuery(query) {
            while results.next() {
                let book = results.int(forColumn: z.xbook).int
                let chapter = results.int(forColumn: z.xchapter).int
                let number = results.int(forColumn: z.xfromverse).int
                let toverse = results.int(forColumn: z.xtoverse).int
                let votes = results.int(forColumn: z.votes).int

                if votes <= 1 { continue }
                let count = toverse == 0 ? 1 : toverse - number + 1
                
                let item = Verse(book: decodeID(book), chapter: chapter, number: number, count: count)
                result.append(item)
            }
        }
        return result.isEmpty ? nil : result
    }

}

var xrefs = Xrefs()

class Xrefs {
    
    var items = [TXref]()
    
    init() {
        load()
    }
    
    private func load() {
        let files = databaseList().filter { $0.containsAny([".xrefs."]) } // .crossreferences.
        for file in files {
            if let item = TXref(atPath: file) {
                items.append(item)
                print(item.fileName)
            }
        }
    }

    func getData(_ verse: Verse, language: String) -> [Verse]? {
        let filename = language.hasPrefix("ru") ? "obru.xrefs.unbound" : "ob.xrefs.unbound"
        
        for item in items {
            if item.fileName != filename { continue }
            return item.getData(verse)
        }
        return nil
    }

}
