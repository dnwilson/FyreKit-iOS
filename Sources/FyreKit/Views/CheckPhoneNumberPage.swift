//
//  PhoneNumberLookupPage.swift
//  FyreKit
//
//  Created by Dane Wilson on 3/3/22.
//

import SwiftUI
import iPhoneNumberField

public struct CheckPhoneNumberPage: View {
  @ObservedObject var viewModel = PhoneNumberViewModel()
  @StateObject var authentication = Authentication()
  var notificationCenter = NotificationCenter.default
  
  @State var phoneEditing = false
  
  @State private var isShowingModal = false
  
  
  public var body: some View {
    VStack {
      Spacer()
      VStack {
        Image("logo")
          .resizable()
          .frame(width: 200, height: 200, alignment: .center)
        Text("Take My Signs")
          .font(.custom(FyreKit.headingFont, size: 24))
          .fontWeight(.black)
          .foregroundColor(FyreKit.headingColor)
      }.frame(maxWidth: .infinity, alignment: .center)
      
      Spacer()

      TextInputView("Phone number", text: $viewModel.number, type: "phone")
        .padding(.bottom, 15)
      
      Button(action: {
        viewModel.checkPhoneNumber { success in
          if (success) {
            isShowingModal = true
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
          Text("Next")
            .font(.custom(FyreKit.baseFont, size: 20))
            .padding(20)
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
        }
      }
      .disabled(viewModel.disabled)
      .foregroundColor(.white)
      .background(viewModel.disabled ? FyreKit.disabledPrimaryColor : FyreKit.primaryColor)
      .cornerRadius(8)
    }
    .sheet(isPresented: $isShowingModal) {
      VerifyPhoneNumberPage(viewModel: viewModel)
    }
    .alert(item: $viewModel.error) { error in
      Alert(title: Text("Error"), message: Text(error.message()))
    }
    .padding()
    .padding(.bottom, 20)
    
  }
}

struct CheckPhoneNumberPage_Preview: PreviewProvider {
  static var previews: some View {
    CheckPhoneNumberPage()
  }
}
