//
//  PassCodeView.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/5/22.
//

import SwiftUI

struct OTPView: View {
  // 5 minutes
  @State private var timeRemaining = 120
  @State private var isOtpMatching = false
  
  @ObservedObject var viewModel = PhoneNumberViewModel()
  @ObservedObject var registrationVM: RegistrationViewModel
  
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  
  var body: some View {
    VStack {
      
      HStack {
        Text("Please enter the verification code sent to \(viewModel.number)")
          .font(.body)
          .frame(maxWidth: .infinity, alignment: .center)
        Spacer()
      }
      .padding(.leading)
      .padding(.top, 5)
      .padding(.bottom, 30)
      
      VStack {
        OTPFieldView { otp, completionHandler in
          viewModel.verifyPhoneNumber { success in
            isOtpMatching = success
            completionHandler(success)
          }
        }

        Text(getTimer())
          .padding()
          .onReceive(timer) { _ in
            if timeRemaining > 0 {
              timeRemaining -= 1
            }
          }
        
        Button(action: {
          viewModel.checkPhoneNumber { success in
            if (success) {
              timeRemaining = 120
            }
          }
        }, label: {
          Text("Request a new code")
            .font(.custom(baseFont, size: 16))
            .foregroundColor(.white)
        })
          .padding()
          .disabled(timeRemaining != 0)
          .frame(maxWidth: .infinity)
          .background(primaryColor)
          .clipShape(RoundedRectangle(cornerRadius: 5))
          .padding(.horizontal)
      }
      
    }.fullScreenCover(isPresented: $isOtpMatching) {
      RegistrationPage(viewModel: registrationVM)
    }
  }
  
  func getTimer() -> String{
    let minutes = Int(timeRemaining) / 60 % 60
    let seconds = Int(timeRemaining) % 60
    return String(format:"%02i:%02i", minutes, seconds)
  }
}

struct OTPView_Previews: PreviewProvider {
  static var previews: some View {
    OTPView(registrationVM: RegistrationViewModel(number: "3475124367"))
  }
}
