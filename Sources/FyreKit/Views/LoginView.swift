//
//  LoginView.swift
//  FyreKit
//
//  Created by Dane Wilson on 9/21/21.
//

import SwiftUI

struct LoginView: View {
  var body: some View {
    VStack(alignment: .leading) {
      Spacer(minLength: 0)
      VStack {
        Image("logo")
          .resizable()
          .frame(width: 200, height: 200, alignment: .center)
        Text("Take My Signs")
          .font(.custom(headingFont, size: 24))
          .fontWeight(.black)
          .foregroundColor(headingColor)
      }.frame(maxWidth: .infinity, alignment: .center)
      Spacer(minLength: 0)

      LoginForm()
    }
  }
}

struct LoginView_Preview: PreviewProvider {
  static var previews: some View {
    LoginView()
  }
}
