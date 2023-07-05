//
//  ContentView.swift
//  Computer
//
//  Created by 金子広樹 on 2023/06/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel = ContentViewModel.shared
    
    var body: some View {
        VStack {
            Spacer()
            Text(addCommma(viewModel.displayText))
                .padding(.horizontal, 30)
                .font(.system(size: calculatedTextSize))
                .frame(width: UIScreen.main.bounds.width, height: calculatedFrameSize, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .contentShape(RoundedRectangle(cornerRadius: 0))
            LazyVGrid(columns: Array(repeating: GridItem(), count: 4)) {
                ForEach(viewModel.keyboard, id: \.self) { index in
                    Button {
                        viewModel.apply(index)
                    } label: {
                        Text("\(index)")
                            .font(.system(size: keyboardTextSize))
                            .frame(width: keyboardFrameSize, height: keyboardFrameSize)
                            .foregroundColor(able)
                    }
                    .padding(.vertical, 7)
                }
            }
            .padding()
            .padding(.bottom, 50)
            .onAppear {
                // データを格納するモデルが作成されていない場合、新規作成する。
                if viewModel.data.count == 0 {
                    viewModel.create()
                    viewModel.displayText = "0"
                } else {
                    viewModel.read()
                }
            }
            .onChange(of: viewModel.displayText) { value in
                viewModel.update()
            }
        }
    }
    
    ///　表示テキストに","を含める。
    /// - Parameters:
    ///   - text: ディスプレイ表示用テキスト
    /// - Returns: コンマを含めたテキスト
    private func addCommma(_ text: String) -> String {
        // テキストに"."や"e"が含まれていた場合、テキストをそのまま返す。そうでない場合、テキストに","を含める。
        if text.contains(".") {
            return text
        } else {
            var displayText: String = text              // ディスプレイ表示テキスト
            let removeText: Set<Character> = [","]      // 取り除く文字
            var calculatedText: String = text           // ","を除いたテキスト
            let commaCount = Int((text.count - 1) / 3)  // コンマの数
            
            for comma in 0..<commaCount {
                calculatedText.removeAll(where: { removeText.contains($0) })
                displayText.insert(contentsOf: ",",
                                   at: calculatedText.index(calculatedText.endIndex, offsetBy: -(comma + 1) * 3))
            }
            return displayText
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
