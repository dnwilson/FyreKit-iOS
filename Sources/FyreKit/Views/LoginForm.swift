//
//  LoginForm.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/3/22.
//

import SwiftUI

public struct LoginForm: View {
  @ObservedObject var viewModel = LoginViewModel()
  @StateObject var authentication = Authentication()
  var notificationCenter = NotificationCenter.default
  
  public var body: some View {
    VStack(alignment: .leading) {
      TextInputView("Phone number", text: $viewModel.credentials.phoneNumber, type: "phone")
        .padding(.bottom, 10)
      
      TextInputView("Password", text: $viewModel.credentials.password, type: "password")
        .padding(.bottom, 10)
      
      Button(action: {
        viewModel.login { success in
          if success {
            authentication.updateValidation(success: success)
            notificationCenter.post(name: NSNotification.Name("User Logged In"), object: nil)
          }
        }
      }) {
        if (viewModel.showProgressView) {
          VStack {
            ProgressView()
              .foregroundColor(.yellow)
              .shadow(color: .white, radius: 1)
              .progressViewStyle(.circular)
          }
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(20)
        } else {
          Text("Login")
            .font(.custom(FyreKit.fonts.baseFont, size: 20))
            .padding(20)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
        }
      }
      .disabled(viewModel.loginDisabled)
      .foregroundColor(.white)
      .background(viewModel.loginDisabled ? FyreKit.colors.disabledPrimaryColor : FyreKit.colors.primaryColor)
      .cornerRadius(8)
    }
    .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
    .padding()
    .alert(item: $viewModel.error) { error in
      Alert(title: Text("Invalid Login"), message: Text(error.message()))
    }
  }
}

struct LoginForm_Previews: PreviewProvider {
  static var previews: some View {
    LoginForm()
  }
}
