//
//  LoginView.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import SwiftUI

public struct LoginView: View {
  public init() {}

  public var body: some View {
    VStack(alignment: .leading) {
      Spacer(minLength: 0)
      VStack {
        Image("logo")
          .resizable()
          .frame(width: 200, height: 200, alignment: .center)
        Text("Take My Signs")
          .font(.custom(FyreKit.headingFont, size: 24))
          .fontWeight(.black)
          .foregroundColor(FyreKit.headingColor)
      }.frame(maxWidth: .infinity, alignment: .center)
      Spacer(minLength: 0)

      LoginForm()
    }
  }
}

public struct LoginView_Preview: PreviewProvider {
  public static var previews: some View {
    LoginView()
  }
}
