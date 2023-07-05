//
//  ContentViewModel.swift
//  Computer
//
//  Created by 金子広樹 on 2023/06/23.
//

import SwiftUI

final class ContentViewModel: ObservableObject {
    static var shared: ContentViewModel = ContentViewModel()
    
    @Published var data: [Data] = Array(Data.findAll())
    @Published var inputs: Inputs = .tappedAC                   // ボタン押下実行処理
    @Published var calculateState: CalculateState = .none       // 記号押下実行処理
    @Published var previousCalculateState: CalculateState = .none// 1つ前の計算ステータス
    @Published var displayText: String = ""                     // ディスプレイ表示用テキスト
    @Published var selectedNumber: Double = 0                   // キーボード入力による数字
    @Published var calculatedNumber: Double = 0                 // "+、"-"用の計算値
    @Published var priorityCalculatedNumber: Double = 0         // "×"、"÷"用の一時的に保管するための計算値
    @Published var isHaveDoneCalculated: Bool = false           // 一度でも計算したか否か
    @Published var isHaveDonePriorityCalculated: Bool = false   // 一度でも"×"、"÷"を計算したか否か
    @Published var isError: Bool = false                        // エラーの有無
    var keyboard: [String] {
        if inputs == .tappedAC {
            return  ["AC", "+/-", "←", "÷", "7", "8", "9", "×", "4", "5", "6", "-", "1", "2", "3", "+", "0", "00", ".", "="]
        } else {
            return  ["C", "+/-", "←", "÷", "7", "8", "9", "×", "4", "5", "6", "-", "1", "2", "3", "+", "0", "00", ".", "="]
        }
    }                                                       // キーボード
    var comprehensiveCalculatedNumber: Double {
        if inputs == .tappedEqual {
            return calculatedNumber
        } else {
            if calculateState == .multiplication || calculateState == .division {
                return priorityCalculatedNumber
            } else {
                return calculatedNumber
            }
        }
    }                                                       // ディスプレイ表示用の計算結果
    // "×"、"÷"計算前の符号。"+"の場合true、"-"の場合false。
    var beforeMulAndDivCalculateState: PreviousCalculateState = .none
    
    // 入力ステータス
    enum Inputs {
        case tappedAC                   // キーボード（"AC","C"）
        case tappedCalculateState       // キーボード（記号）
        case tappedNumberPad            // キーボード（数字）
        case tappedDot                  // キーボード（"."）
        case tappedEqual                // キーボード（"="）
    }
    
    // 計算ステータス
    enum CalculateState {
        case none
        case addition           // "+"
        case substraction       // "-"
        case multiplication     // "×"
        case division           // "÷"
    }
    
    // "×"、"÷"計算前の符号
    enum PreviousCalculateState {
        case none
        case plus
        case minus
    }
    
    ///　キーボード入力から実行処理を分配する。
    /// - Parameters:
    ///   - keyboard: 入力されたキーボード
    /// - Returns: なし
    func apply(_ keyboard: String) {
        // エラーの場合、"C"以外のボタンを押せない状態にする。
        if isError {
            if keyboard != self.keyboard[0] {
                return
            }
        }
        // 入力したキーボードから入力ステータス（Inputs）を振り分ける。
        if let _ = Double(keyboard) {
            tappedNumberPadProcess(keyboard)
        } else if keyboard == "." {
            // テキストに"."が含まれていない場合のみ、実行する。
            if !displayText.contains(".") {
                displayText += keyboard
                inputs = .tappedDot
            }
        } else if keyboard == "=" {
            equalProcess()
        } else if keyboard == "AC" || keyboard == "C" {
            initializationProcess()
            inputs = .tappedAC
        } else if keyboard == "+/-" {
            // 0以外の場合のみ実行
            if displayText == "0" {
                return
            }
            plusMinusProcess()
        } else if keyboard == "←" {
            backSpaceProcess()
        } else {
            fourArithmeticOperations(keyboard)
        }
    }
    
    ///　数字キーボード実行処理
    /// - Parameters:
    ///   - keyboard: 入力されたキーボード
    /// - Returns: なし
    private func tappedNumberPadProcess(_ keyboard: String) {
        // テキストが初期値"0"の時に、"0"若しくは"00"が入力された時、何もしない。
        if displayText == "0" && (keyboard == "0" || keyboard == "00") {
            return
        }
        // 連続した数字入力ならば、数字を付け加える。そうでなければ、そのまま数字を入れる。
        if inputs == .tappedNumberPad {
            // テキストに表示できる最大数字を超えないように制御
            if isCheckOverMaxNumberOfDigits(displayText + keyboard) {
                return
            }
            if displayText == "0" {
                displayText = keyboard
            } else {
                displayText += keyboard
            }
        } else if inputs == .tappedDot {
            displayText += keyboard
        } else {
            // 初回に"00"が入力された時、"0"と表記する。
            if keyboard == "00" {
                displayText = "0"
            } else {
                displayText = keyboard
            }
        }
        inputs = .tappedNumberPad
    }
    
    ///　"AC"または"C"実行処理
    /// - Parameters: なし
    /// - Returns: なし
    private func initializationProcess() {
        // 全て初期化
        calculateState = .none
        selectedNumber = 0
        calculatedNumber = 0
        priorityCalculatedNumber = 0
        isHaveDoneCalculated = false
        isHaveDonePriorityCalculated = false
        isError = false
        beforeMulAndDivCalculateState = .none
        Data.delete()
        create()
        displayText = "0"
    }
    
    ///　"="実行処理
    /// - Parameters: なし
    /// - Returns: なし
    private func equalProcess() {
        if let number = Double(displayText) {
            // 連続した"="入力でない時、且つ計算ステータスを入力されていない時、代入する。
            if inputs != .tappedEqual && inputs != .tappedCalculateState {
                selectedNumber = number
            }
        }
        inputs = .tappedEqual
        calculate(calculateState)
        
        // 特定条件以外の場合のみ、"×"、"÷"計算前の"+"、"-"を実行。
        if !((beforeMulAndDivCalculateState == .none) && (calculateState == .addition || calculateState == .substraction)) {
            previousCalculateStateProcess()
        }
        //        if previousCalculateState {
        //            calculatedNumber += priorityCalculatedNumber
        //        } else {
        //            calculatedNumber -= priorityCalculatedNumber
        //        }
        
        if inputs != .tappedEqual {
            priorityCalculatedNumber = 0
        }
        checkError()
        checkDisplayTextLabels()
    }
    
    ///　"+/-"実行処理
    /// - Parameters: なし
    /// - Returns: なし
    private func plusMinusProcess() {
        if displayText.contains("-") {
            displayText.removeFirst()
            // 入力ステータスが"="、または四則演算の場合、計算値に変更を代入。
            if inputs == .tappedEqual || inputs == .tappedCalculateState {
                if let number = Double(displayText) {
                    calculatedNumber = number
                }
            }
        } else {
            displayText = "-" + displayText
            // 入力ステータスが"="、または四則演算の場合、計算値に変更を代入。
            if inputs == .tappedEqual || inputs == .tappedCalculateState {
                if let number = Double(displayText) {
                    calculatedNumber = number
                }
            }
        }
    }
    
    ///　"←"実行処理
    /// - Parameters: なし
    /// - Returns: なし
    private func backSpaceProcess() {
        // 文字入力中のみ実行。
        if inputs == .tappedNumberPad {
            // テキストの文字数が0、あるいは負の数の時の文字数が1だった場合、テキストを0に戻す。
            if (String(displayText.dropLast()).count == 0) || (String(displayText.dropLast()).count == 1 && displayText.contains("-")) {
                displayText = "0"
            } else {
                displayText = String(displayText.dropLast())
            }
        }
    }
    
    ///　四則演算実行処理
    /// - Parameters:
    ///   - keyboard: 入力されたキーボード
    /// - Returns: なし
    private func fourArithmeticOperations(_ keyboard: String) {
        previousCalculateState = calculateState
        divideCalculateState(keyboard)
        
        if let number = Double(displayText) {
            selectedNumber = number
        }
        
        // "="、計算記号からの入力でない時、計算する。
        if inputs != .tappedEqual && inputs != .tappedCalculateState {
            // 以前の計算ステータスが"×"または"÷"で、今回の計算ステータスが"+"または"-"の場合と、その他の場合で計算処理を分ける。
            if (previousCalculateState == .multiplication || previousCalculateState == .division) &&
                (calculateState == .addition || calculateState == .substraction) {
                calculate(previousCalculateState)
                previousCalculateStateProcess()
//                if previousCalculateState {
//                    calculatedNumber += priorityCalculatedNumber
//                } else {
//                    calculatedNumber -= priorityCalculatedNumber
//                }
                priorityCalculatedNumber = 0
                isHaveDonePriorityCalculated = false
            } else {
                // 以前の計算ステータスが"+"または"-"で、今回の計算ステータスが"×"または"÷"の場合の処理。
                if (previousCalculateState == .addition || previousCalculateState == .substraction) && (calculateState == .multiplication || calculateState == .division) {
                    
                    // 一つ前の計算ステータスによって、previousCalculateStateを振り分ける。
                    if previousCalculateState == .addition {
                        beforeMulAndDivCalculateState = .plus
                    } else if previousCalculateState == .substraction {
                        beforeMulAndDivCalculateState = .minus
                    }
                    calculate(calculateState)
                } else if (previousCalculateState != calculateState) && previousCalculateState != .none {
                    // その他、符号が変更した時、以前の計算ステータスで計算。
                    calculate(previousCalculateState)
                } else {
                    // 計算ステータスが変更しない場合は、現在の計算ステータスで計算。
                    calculate(calculateState)
                }
                
            }
            checkError()
            checkDisplayTextLabels()
        } else if inputs == .tappedEqual {
            // "="の後の"×"、"÷"計算の処理と"+"、"-"計算の処理。
            if calculateState == .multiplication || calculateState == .division {
                priorityCalculatedNumber = calculatedNumber
                calculatedNumber = 0
            } else {
                priorityCalculatedNumber = 0
                isHaveDonePriorityCalculated = false
            }
        }
        inputs = .tappedCalculateState
    }
    
    ///　"×"、"÷"計算前の符号によって、"+"または"-"を実行。
    /// - Parameters: なし
    /// - Returns: なし
    func previousCalculateStateProcess() {
        switch beforeMulAndDivCalculateState {
        case .none:
            if calculateState == .multiplication || calculateState == .division {
                calculatedNumber = priorityCalculatedNumber
            } else if calculateState == .addition {
                if previousCalculateState == .multiplication || previousCalculateState == .division {
                    calculatedNumber = priorityCalculatedNumber
                }
            } else if calculateState == .substraction {
                if previousCalculateState == .multiplication || previousCalculateState == .division {
                    calculatedNumber = priorityCalculatedNumber
                }
            }
        case .plus:
            calculatedNumber += priorityCalculatedNumber
        case .minus:
            calculatedNumber -= priorityCalculatedNumber
        }
    }
    
    ///　計算ステータス（CalculateState）を振り分ける。
    /// - Parameters:
    ///   - state: 計算ステータス
    /// - Returns: なし
    private func divideCalculateState(_ state: String) {
        switch state {
        case "+":
            calculateState = .addition
        case "-":
            calculateState = .substraction
        case "×":
            calculateState = .multiplication
        case "÷":
            calculateState = .division
        default:
            calculateState = .none
        }
    }
    
    ///　計算実行処理
    /// - Parameters:
    ///   - state: 計算ステータス
    /// - Returns: なし
    private func calculate(_ state: CalculateState) {
        // 初回"×"、"÷"計算時のみ計算値に入力値を代入
        if state == .multiplication || state == .division {
            if !isHaveDonePriorityCalculated {
                priorityCalculatedNumber = selectedNumber
                isHaveDonePriorityCalculated = true
                isHaveDoneCalculated = true
                return
            }
        } else {
            if !isHaveDoneCalculated {
                calculatedNumber = selectedNumber
                isHaveDoneCalculated = true
                return
            }
        }

        switch state {
        case .addition:
            calculatedNumber += selectedNumber
        case .substraction:
            calculatedNumber -= selectedNumber
        case .multiplication:
            priorityCalculatedNumber *= selectedNumber
        case .division:
            // 0で割った場合、エラーを返す。
            if selectedNumber == 0 {
                displayText = "Error"
                isError = true
                return
            }
            priorityCalculatedNumber /= selectedNumber
        default:
            break
        }
    }
    
    ///　エラーチェック。計算結果が計算できる最大文字数を超えた場合returnする。
    /// - Parameters: なし
    /// - Returns: なし
    private func checkError() {
        if checkDecimal(comprehensiveCalculatedNumber).count > maxCalculateNumberOfDigits {
            displayText = "Error"
            isError = true
            return
        }
    }
    
    ///　計算結果がテキストに表示できる最大桁数を超えた場合、累乗表記に変える。そうでない場合、そのままテキストに表記する。
    /// - Parameters: なし
    /// - Returns: なし
    private func checkDisplayTextLabels() {
        if isCheckOverMaxNumberOfDigits(checkDecimal(comprehensiveCalculatedNumber)) {
            displayText = switchToPowerNotation(comprehensiveCalculatedNumber)
        } else {
            displayText = checkDecimal(comprehensiveCalculatedNumber)
        }
    }
    
    ///　テキストに表示する数字の小数点以下の表示有無をチェック。
    /// - Parameters:
    ///   - number: 計算結果
    /// - Returns: テキストに表示できる最大桁数に合わせて小数点以下を丸めたテキスト
    private func checkDecimal(_ number: Double) -> String {
        let decimal = number.truncatingRemainder(dividingBy: 1)
        
        // 絶対値を算出した後、小数点第一位が0ならば小数点以下を切り捨て。そうでなければ、小数点以下をテキストに表示できる最大桁数までを表示。
        if abs(decimal.truncatingRemainder(dividingBy: 1)).isLess(than: .ulpOfOne) {
            return String(Int(number))
        } else {
            let intNumber = String(Int(number))
            let intDigits = intNumber.count
            
            return String(round(number * pow(10, Double(maxNumberOfDigits - intDigits))) /
                          pow(10, Double(maxNumberOfDigits - intDigits))
            )
        }
    }
    
    ///　計算結果がテキスト最大文字数を超えているかをチェックする。
    /// - Parameters:
    ///   - numberText: テキストに表示できる最大桁数に合わせて小数点以下を丸めたテキスト
    /// - Returns: テキスト最大文字数以内の場合True、そうでない場合false。
    private func isCheckOverMaxNumberOfDigits(_ numberText: String) -> Bool {
        // テキスト文字数カウントに、"."と"-"を省く。
        if numberText.contains(".") && numberText.contains("-") {
            if numberText.count > maxNumberOfDigits + 2 {
                return true
            }
        } else if numberText.contains(".") || numberText.contains("-") {
            if numberText.count > maxNumberOfDigits + 1 {
                return true
            }
        } else {
            if numberText.count > maxNumberOfDigits {
                return true
            }
        }
        return false
    }
    
    ///　累乗表記に変更
    /// - Parameters:
    ///   - number: 計算結果
    /// - Returns: 累乗表記後のテキスト
    private func switchToPowerNotation(_ number: Double) -> String {
        let digits = checkDecimal(number).count - 1
        // 計算結果の桁数の桁数を算出
        let digitsOfDigits = String(digits).count
        // 計算結果を、最大桁数1の位になるように割る。
        let dividedNumber = number / pow(10, Double(digits))
        
        // 計算結果から"e○○"分の桁数を丸める
        let roundedText = String(round(
            dividedNumber * pow(10, Double((maxNumberOfDigits - 1) - (1 + digitsOfDigits)))) /
                                 pow(10, Double((maxNumberOfDigits - 1) - (1 + digitsOfDigits)))
        )
        return "\(roundedText)e\(digits)"
    }
    
// MARK: - RealmCRUD
    ///　新規データの作成
    /// - Parameters: なし
    /// - Returns: なし
    func create() {
        let model = Data()
        Data.add(model)
    }
    
    ///　データの取得
    /// - Parameters: なし
    /// - Returns: なし
    func read() {
        // modelからviewModelに各データを追加
        if let result = data.last {
            displayText = result.text
        }
    }
    
    ///　データを更新
    /// - Parameters: なし
    /// - Returns: なし
    func update() {
        // viewModelからmodelにテキストデータを更新
        Data.update(text: displayText)
    }
}

