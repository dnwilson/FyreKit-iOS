//
//  TextInputView.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/22/21.
//

import SwiftUI
import Turbo
import iPhoneNumberField

@available(iOS 15.0, *)
struct TextInputView: View {
  var title: String
  var type: String
  @Binding var text: String
  @State var showPassword: Bool = false
  @State var isFocused: Bool = false
  @FocusState private var focusedField: Field?
  
  private enum Field: Hashable {
    case field
  }
  
  var isActive: Bool {
    return (focusedField != nil) || !text.isEmpty
  }
  
  private var isPhoneField:Bool { type == "phone" }
  private func shrinkLabel() -> Bool {
    !text.isEmpty || (focusedField != nil)
  }
  
  init(_ title: String, text: Binding<String>, type: String = "text") {
    self._text = text
    self.title = title
    self.type = type
  }
  
  var body: some View {
    ZStack(alignment: .leading) {
      Text(title)
        .foregroundColor(text.isEmpty ? Color(.placeholderText) : .accentColor)
        .offset(x: 0, y: isActive ? -24 : 0)
        .scaleEffect(isActive ? 0.75 : 1, anchor: .leading)
      switch type {
      case "password":
        secureField()
          .overlay(
            Button(action: {
              self.showPassword.toggle()
            }, label: {
              if (!self.text.isEmpty) {
                Image(systemName: self.showPassword ? "eye.slash" : "eye")
                  .font(.system(size: 18, weight: .medium))
                  .foregroundColor(Color.init(red: 160.0/255.0, green: 160.0/255.0, blue: 160.0/255.0))
                  .offset(x: 0)
              }
            }), alignment: .trailing)
      case "phone":
        TextField("", text: $text)
          .onChange(of: text) { newValue in
            if newValue.count > 16 {
              self.text = String(newValue.prefix(16))
            } else {
              self.text = PhoneNumberFormatter().formatPhoneNumber(phoneNumber: newValue)
            }
          }
          .focused($focusedField, equals: .field)
          .textContentType(.telephoneNumber)
          .keyboardType(.phonePad)
      case "email":
        TextField("", text: $text)
          .focused($focusedField, equals: .field)
          .textContentType(.emailAddress)
          .disableAutocorrection(true)
          .autocapitalization(.none)
          .keyboardType(.emailAddress)
      default:
        TextField("", text: $text)
          .focused($focusedField, equals: .field)
      }
    }
    .padding(EdgeInsets(top: 20, leading: 16, bottom: 20, trailing: 16))
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(isActive ? Color.blue : Color(.placeholderText)))
    .animation(Animation.easeInOut(duration: 0.125), value: isActive)
  }
  
  @ViewBuilder
  func secureField() -> some View {
    if (self.showPassword) {
      TextField("", text: $text)
        .focused($focusedField, equals: .field)
        .keyboardType(.default)
        .autocapitalization(.none)
        .disableAutocorrection(true)
    } else {
      SecureField("", text: $text)
        .focused($focusedField, equals: .field)
        .keyboardType(.default)
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
  }
}

class PhoneNumberFormatter: Formatter {
  override func string(for obj: Any?) -> String? {
    if let string = obj as? String {
      return formatPhoneNumber(phoneNumber: string)
    }
    return nil
  }
  
  override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
    obj?.pointee = string as AnyObject?
    return true
  }
  
  func formatPhoneNumber(phoneNumber: String) -> String {
    let cleanPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let mark = "(XXX) XXX-XXXX"
    
    var result = ""
    var startIndex = cleanPhoneNumber.startIndex
    let endIndex = cleanPhoneNumber.endIndex
    
    for character in mark where startIndex < endIndex {
      if character == "X" {
        result.append(cleanPhoneNumber[startIndex])
        startIndex = cleanPhoneNumber.index(after: startIndex)
      } else {
        result.append(character)
      }
    }
    
    return result
  }
}

struct PhoneFieldModifer: ViewModifier {
  @Binding var value: String
  var length: Int
  
  func body(content: Content) -> some View {
    content
      .onReceive(value.publisher.collect()) {
        value = PhoneNumberFormatter().formatPhoneNumber(phoneNumber: String($0.prefix(length)))
      }
  }
}

extension View {
  func limitInputLength(value: Binding<String>, length: Int) -> some View {
    self.modifier(PhoneFieldModifer(value: value, length: length))
  }
}

@available(iOS 15.0, *)
struct TextInputView_Preview: PreviewProvider {
  static var previews: some View {
    TextInputView("Password", text: .constant("foobar"), type: "password")
  }
}
