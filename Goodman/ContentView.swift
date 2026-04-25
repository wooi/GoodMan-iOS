//
//  ContentView.swift
//  Goodman
//
//  Created by Wooi on 2023/12/16.
//

import SwiftUI

struct ContentView: View {
    let items = ["CHN", "AUS", "EUR", "HK", "JPN", "BRA", "CAN", "KOR", "TW", "UK"]
    @ObservedObject var viewModel = ViewModel()
    @State private var isSheetPresented = false
    @ObservedObject private var keyboard = KeyboardResponder()

    var body: some View {
        GeometryReader { gemotry in
            VStack {
                //第一部分
                HStack {
                    VStack {
                        HStack {
                            Text("基础货币：\(viewModel.baseCurrencyName)")
                                .foregroundColor(.gray)
                                .font(Font.system(size: 16))

                            Spacer()

                            HStack {
                                Image(systemName: "plus.square.fill.on.square.fill")
                                    .foregroundColor(.white)
                                    .onTapGesture {
                                        isSheetPresented.toggle()
                                    }
                                Image(systemName: "gear")
                                    .foregroundColor(.white)
                            }
                        }

                        TextField("Enter text here", text: Binding(
                            get: { viewModel.basePrice },
                            set: { newPrice in
                                viewModel.changeEdit(newPrice: newPrice, countryCode: viewModel.baseCountryCode)
                            }
                        ))
                            .font(Font.system(size: 36))
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .padding(.leading, 0)
                        HStack {
                            BaseCurrencyButton(
                                title: "USD",
                                isSelected: viewModel.baseCountryCode == "USA"
                            ) {
                                viewModel.switchBase(countryCode: "USA")
                            }

                            Spacer()

                            BaseCurrencyButton(
                                title: "CNY",
                                isSelected: viewModel.baseCountryCode == "CHN"
                            ) {
                                viewModel.switchBase(countryCode: "CHN")
                            }
                        }
                    }
                }
                .padding()
                .background(.black)
                .ignoresSafeArea(.keyboard, edges: .bottom)


                Text(viewModel.updateTime.isEmpty ? "更新时间: --" : "更新时间: \(viewModel.updateTime)")
                    .foregroundColor(.white)
                    .font(.system(size: 12))
                
                //第二部分
                VStack {
                    HStack {
                        Text("转换货币")
                            .font(.system(size: 20))
                            .bold()
                        Spacer()

                        Image(systemName: "arrow.clockwise")
                            .onTapGesture {
                                self.viewModel.fetchData()
                            }
                            .onAppear() {
                                self.viewModel.fetchData()
                            }
                        Image(systemName: "plus.square.fill.on.square.fill")

                    }
                    .padding(.top)
                    .padding(.trailing)
                    .padding(.leading)
                    
                    VStack {
                        List {
                            ForEach(0..<viewModel.items.count, id: \.self) { index in
                                ExchangeItemView(
                                    exchangeRateData: viewModel.items[index],
                                    inputValue: Binding(
                                        get: { viewModel.items[index].price },
                                        set: { newPrice in
                                            viewModel.changeEdit(newPrice: newPrice, countryCode: viewModel.items[index].countryCode)
                                        }
                                    )
                                )
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                    }
                    .padding(.bottom, keyboard.keyboardHeight)

                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .background {
                    Color.white.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
            }
            .background {
                Color.black.edgesIgnoringSafeArea(.all)
            }
            .edgesIgnoringSafeArea(.bottom)
            .sheet(isPresented: $isSheetPresented) {
                Text("sheet")
                    .presentationDetents([.large])
                    .presentationBackground(.thinMaterial)
            }
            .onTapGesture {
                print("Root tapped")
                //隐藏键盘
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .accentColor(Color.black)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }

    }

}


struct BaseCurrencyButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .bold()
            .foregroundColor(isSelected ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(isSelected ? Color.white : Color.gray)
            .cornerRadius(20)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}

struct ExchangeItemView: View {
    let exchangeRateData: ExchangeRateData
    @Binding var inputValue: String

    var body: some View {
        HStack {
            Image(addPrefix(to: exchangeRateData.countryCode))
                .resizable()
                .padding(0)
                .scaledToFit()
                .frame(width: 58, height: 58)
            VStack(alignment: .leading) {
                Text(exchangeRateData.currencyCode)
                    .bold()
                    .font(.headline)
                    .foregroundColor(.black)
                Text(exchangeRateData.currencyName)
                    .font(Font.system(size: 12))
                    .foregroundColor(.gray)
            }
                .padding(.leading, 4)

            Spacer()

            CurrencyView(inputValue: $inputValue)
        }
    }
}

struct CurrencyView: View {
    @Binding var inputValue: String
    var fontSize: CGFloat = 18
    var fontColor: Color = .black

    var body: some View {
        HStack(spacing: 0) {
            Text("$")
                .bold()
                .font(Font.system(size: fontSize))
                .foregroundColor(fontColor)
            TextField("Enter text", text: $inputValue)
                .foregroundColor(fontColor)
                .font(Font.system(size: fontSize))
                .bold()
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: inputValue.widthOfString(usingFont: UIFont.systemFont(ofSize: fontSize, weight: .bold)))
                .padding(0)
        }.padding(0)
    }
}



#Preview {
    let previewViewModel = ViewModel()
    previewViewModel.items = [
        ExchangeRateData(currencyCode: "USD", countryCode: "USA", trend: "Down", price: "123"),
        ExchangeRateData(currencyCode: "CNY", countryCode: "CHN", trend: "Down", price: "123"),
        ExchangeRateData(currencyCode: "USD", countryCode: "TW", trend: "Down", price: "123")
    ]
    return ContentView(viewModel: previewViewModel)
}

