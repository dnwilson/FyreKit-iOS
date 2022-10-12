//
//  CustomPasswordField.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/5/22.
//

import SwiftUI

struct CustomPasswordField: View {
  var label = "Password"
  @Binding var text: String
  @State var showPassword: Bool = false
  @State var hasFocus = false
  
  private var shrinkLabel: Bool {
    return !text.isEmpty || hasFocus
  }
  
  var body: some View {
    secureField()
    .padding(EdgeInsets(top: 12, leading: 12, bottom: 8, trailing: 12))
    .overlay(Text(label)
              .foregroundColor(text.isEmpty ? Color(.placeholderText) : .accentColor)
              .offset(x: 16, y: shrinkLabel ? -32 : 0)
              .scaleEffect(shrinkLabel ? 0.75 : 1, anchor: .leading), alignment: .leading)
    .overlay(
      Button(action: {
        self.showPassword.toggle()
      }, label: {
        Color.clear
          .frame(maxWidth: 29, maxHeight: 60, alignment: .center)
        Image(systemName: self.showPassword ? "eye.slash" : "eye")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(Color.init(red: 160.0/255.0, green: 160.0/255.0, blue: 160.0/255.0))
          .offset(x: -16)
      }), alignment: .trailing
    )
    .overlay(RoundedRectangle(cornerRadius: 8).stroke(shrinkLabel ? primaryColor : Color(.placeholderText)))
  }
  
  @ViewBuilder
  func secureField() -> some View {
    if self.showPassword {
      TextField("", text: $text, onEditingChanged: { (editingChanged) in
        if editingChanged {
          hasFocus = true
        } else {
          hasFocus = false
        }
      })
        .font(.custom(baseFont, size: 16))
        .keyboardType(.default)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 60, alignment: .center)
    } else {
      SecureField("", text: $text, onCommit: {
        hasFocus = false
      })
        .onTapGesture {
          hasFocus = true
        }
        .font(.custom(baseFont, size: 16))
        .keyboardType(.default)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 60, alignment: .center)
    }
  }
}

struct CustomPasswordField_Previews: PreviewProvider {
  static var previews: some View {
    CustomPasswordField(text: .constant(""))
  }
}
