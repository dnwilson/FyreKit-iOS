//
//  RegistrationPage.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/3/22.
//

import SwiftUI
import Turbo

public struct RegistrationPage: View {
  @ObservedObject var viewModel : FyreKitRegistrationViewModel

  var notificationCenter = NotificationCenter.default
  
  public var body: some View {
    ScrollView {
      VStack(alignment: .center) {
        Image("logo")
          .resizable()
          .frame(width: 150, height: 150, alignment: .center)
        
        Text("Post Your Signs")
          .font(.custom(FyreKit.headingFont, size: 24))
          .fontWeight(.black)
          .foregroundColor(FyreKit.headingColor)
          .frame(alignment: .center)
          .multilineTextAlignment(.center)
      }
      
      Spacer()
      
      VStack {
        ForEach(viewModel.formInputs) { input in
          TextInputView(input.label, text: input.$value, type: input.type).padding(.bottom, 10)
        }
        
        if (FyreKit.termsMessage.isPresent) {
          HStack(alignment: .top) {
            Toggle("Terms", isOn: $viewModel.agreeTerms)
              .labelsHidden()
            Text("I agree to the [Terms of Service]($viewModel.termsUrl), [Privacy Policy]($viewModel.privacyUrl), Arbitration of Disputes and waiver of class actions claims.")
          }
        }
        
        Button(action: {
          viewModel.register { success in
            if (success) {
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
            Text("Sign Up")
              .font(.custom(FyreKit.baseFont, size: 20))
              .padding(20)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
          }
        }
        .disabled(viewModel.submitDisabled)
        .foregroundColor(.white)
        .background(viewModel.submitDisabled ? FyreKit.disabledPrimaryColor : FyreKit.primaryColor)
        .cornerRadius(8)
        .padding(.bottom, 15)

        NavigationLink(destination: LoginView()) {
          Text("Login")
            .font(.custom(FyreKit.baseFont, size: 18))
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(FyreKit.primaryColor)
            .padding(.vertical, 4)
        }
      }
      .autocapitalization(/*@START_MENU_TOKEN@*/.none/*@END_MENU_TOKEN@*/)
      .padding()
      .alert(item: $viewModel.error) { error in
        Alert(title: Text("Registration Error"), message: Text(error.message()))
      }
    }
  }
}

struct RegistrationPage_Previews: PreviewProvider {
  static var previews: some View {
    RegistrationPage(viewModel: FyreKitRegistrationViewModel(number: "3475124367")).preferredColorScheme(.dark)
  }
}
