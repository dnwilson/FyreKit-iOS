//
//  VerifyPhoneNumberView.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/3/22.
//

import SwiftUI

struct VerifyPhoneNumberPage: View {
  @ObservedObject var viewModel: PhoneNumberViewModel
  @State private var isShowingModal = false
  
    var body: some View {
      VStack {
        Spacer(minLength: 0)
        Text("Please enter the verification code sent to \(viewModel.number)").padding(.bottom, 10)
        TextField("Code", text: $viewModel.code)
          .keyboardType(.phonePad)
          .textContentType(.oneTimeCode)
          .padding(EdgeInsets(top: 24, leading: 16, bottom: 24, trailing: 16))
          .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.placeholderText)))
        .padding(.bottom, 15)
        
        Button(action: {
          viewModel.verifyPhoneNumber { success in
            if success {
              isShowingModal = true
            }
          }
        }) {
          if (viewModel.showProgressView) {
            VStack {
              ProgressView()
                .foregroundColor(.white)
                .shadow(color: .white, radius: 1)
                .progressViewStyle(.circular)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)
          } else {
            Text("Verify")
              .font(.custom(baseFont, size: 20))
              .padding(20)
              .frame(maxWidth: .infinity)
              .foregroundColor(.white)
          }
        }
        .disabled(viewModel.disabled)
        .foregroundColor(textColor)
        .background(viewModel.disabled ? disabledPrimaryColor : primaryColor)
        .cornerRadius(8)
        
        HStack(spacing: 6) {
          Text("Didn't receive code?")
            .foregroundColor(textColor)
          
          Button(action: {}) {
            Text("Request Again")
              .fontWeight(.bold)
              .foregroundColor(primaryColor)
          }
        }
        .padding(.top, 10)
      }
      .sheet(isPresented: $isShowingModal) {
        RegistrationPage(viewModel: RegistrationViewModel(number: viewModel.number))
      }
      .alert(item: $viewModel.error) { error in
        Alert(title: Text("Error"), message: Text(error.message()))
      }
      .padding()
      .padding(.bottom)
    }
}

struct VerifyPhoneNumberPage_Previews: PreviewProvider {
    static var previews: some View {
      VerifyPhoneNumberPage(viewModel: PhoneNumberViewModel())
    }
}
