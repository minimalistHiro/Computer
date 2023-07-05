//
//  Data.swift
//  Computer
//
//  Created by 金子広樹 on 2023/06/23.
//

import SwiftUI
import RealmSwift

// 各種設定
var maxNumberOfDigits: Int = 9                          // テキストに表示できる最大桁数
var maxCalculateNumberOfDigits: Int = 16                // 計算できる最大桁数

// サイズ
let calculatedTextSize: CGFloat = 70                    // 計算結果表示文字サイズ
let calculatedFrameSize: CGFloat = 80                   // 計算結果表示フレームサイズ
let keyboardTextSize: CGFloat = 30                      // キーボード文字サイズ
let keyboardFrameSize: CGFloat = 60                     // キーボードフレームサイズ

// 固定色
let able: Color = Color("Able")                         // 文字・ボタン色
let disable: Color = Color("Disable")                   // 背景色


class Data: Object {
    @Persisted var text: String = "0"                   // ディルプレイテキスト
}

extension Data {
    private static var config = Realm.Configuration(schemaVersion: 1)
    private static var realm = try! Realm(configuration: config)
    
    static func findAll() -> Results<Data> {
        realm.objects(self)
    }
    
    static func add(_ data: Data) {
        try! realm.write {
            realm.add(data)
        }
    }
    
    static func update(text: String) {
        let result = findAll().last!
        try! realm.write {
            result.text = text
        }
    }
    
    static func delete() {
        try! realm.write {
            let table = realm.objects(self)
            realm.delete(table)
        }
    }
}
