//
//  OTPFieldView.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/5/22.
//

import SwiftUI

public struct OTPFieldView: View {
  var maxDigits: Int = 4
  
  @State var pin: String = "123"
  @State var isDisabled = false
  
  var handler: (String, @escaping (Bool) -> Void) -> Void
  
  public var body: some View {
    VStack(spacing: 20) {
      ZStack {
        pinDots
        backgroundField
      }
    }
  }
  
  private var pinDots: some View {
    HStack(spacing: 14) {
      ForEach(0..<maxDigits) { index in
        ZStack {
          RoundedRectangle(cornerRadius: 5)
            .foregroundColor(.clear)
            .padding()
            .background(RoundedRectangle(cornerRadius: 5)            .stroke(Color(.lightGray), lineWidth: 0.5))
            .frame(width: 60, height: 60)

          Text(self.getDigits(at: index))
            .font(.custom(FyreKit.baseFont, size: 50))
            .fontWeight(.thin)
            .foregroundColor(FyreKit.textColor)
        }
      }
    }
    .padding(.horizontal)
  }
  
  private var backgroundField: some View {
    let boundPin = Binding<String>(get: { self.pin }, set: { newValue in
      self.pin = newValue
      self.submitPin()
    })
    
    return TextField("", text: boundPin, onCommit: submitPin)
      .keyboardType(.numberPad)
      .foregroundColor(.clear)
      .accentColor(.clear)
  }
  
  
  
  private func submitPin() {
    guard !pin.isEmpty else {
      return
    }
    
    if pin.count == maxDigits {
      isDisabled = true
      
      handler(pin) { isSuccess in
        if !isSuccess {
          pin = ""
          isDisabled = false
        }
      }
    }
    
    // this code is never reached under  normal circumstances. If the user pastes a text with count higher than the
    // max digits, we remove the additional characters and make a recursive call.
    if pin.count > maxDigits {
      pin = String(pin.prefix(maxDigits))
      submitPin()
    }
  }
  
  private func getDigits(at index: Int) -> String {
    if index >= self.pin.count {
      return ""
    }
    
    return self.pin.digits[index].numberString
  }
}

extension String {
  
  var digits: [Int] {
    var result = [Int]()
    
    for char in self {
      if let number = Int(String(char)) {
        result.append(number)
      }
    }
    
    return result
  }
  
}

extension Int {
  var numberString: String {
    guard self < 10 else { return "0" }

    return String(self)
  }
}


struct OTPFieldView_Previews: PreviewProvider {
  static var previews: some View {
    OTPFieldView { otp, completionHandler in }.preferredColorScheme(.dark)
  }
}
