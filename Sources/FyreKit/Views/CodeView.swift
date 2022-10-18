//
//  CodeView.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/5/22.
//

import SwiftUI

public struct CodeView: View {
  var code: String

  public var body: some View {
    VStack(spacing: 10) {
      Text(code)
        .foregroundColor(FyreKit.textColor)
        .fontWeight(.bold)
        .font(.custom(FyreKit.headingFont, size: 24))
        .frame(height: 45)
        .padding()
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.placeholderText)))
    }
  }
}

struct CodeView_Previews: PreviewProvider {
  static var previews: some View {
    CodeView(code: "1234")
  }
}
