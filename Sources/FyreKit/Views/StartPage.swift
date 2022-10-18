//
//  OnboardingPage.swift
//  FyreKit
//
//  Created by Dane Wilson on 1/25/22.
//

import SwiftUI
import AlertToast


@available(iOS 15.0, *)
public struct StartPage: View {
  @State private var currentPage: CurrentPage? = nil

  @ObservedObject var viewModel = LoginViewModel()
  @StateObject var authentication = Authentication()
  
  @State private var showToast = false
  @State private var taps = 0
  var notificationCenter = NotificationCenter.default
  
  enum CurrentPage: Identifiable {
    case login, registration
    
    var id: Int {
      hashValue
    }
  }

  let imageExists: Bool = UIImage(named: "logo") != nil
  let image : Image = Image("logo")
  
  public var body: some View {
    NavigationView {
      VStack(alignment: .center) {
        Spacer()
        
        VStack(alignment: .center) {
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .onTapGesture {
              self.taps += 1
              if taps == 7 {
                FyreKit.toggleDemoMode()
                taps = 0
                showToast.toggle()
              }
            }
        }.frame(width: 200, height: 200, alignment: .center)
          .padding(.bottom, 40)
        
        Text(FyreKit.loginHeaderMessage)
          .font(.custom(FyreKit.headingFont, size: 24))
          .fontWeight(.bold)
          .foregroundColor(.white)
          .lineLimit(20)
          .padding(.vertical, 40)
          .multilineTextAlignment(.center)
        
        Spacer()
        Button(action: {
          currentPage = .registration
        }) {
          Text("Get Started")
            .font(.custom(FyreKit.baseFont, size: 18))
            .fontWeight(.semibold)
            .padding(.vertical, 18)
            .frame(maxWidth: CGFloat(250.0), alignment: .center)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 5, y: 5)
            .foregroundColor(FyreKit.primaryColor)
        }
        .padding(.horizontal, 30)
        .offset(y: 0)
        
        Button(action: {
          currentPage = .login

        }) {
          Text("Login")
            .font(.custom(FyreKit.baseFont, size: 16))
            .padding(.vertical, 9)
            .frame(maxWidth: CGFloat(250.0))
            .foregroundColor(.white)
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .foregroundColor(.white)
        .background(FyreKit.primaryColor)
        .cornerRadius(8)
        
        Spacer(minLength: 0)
      }
      .padding(.top, getRect().height < 750 ? 0 : 20)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(FyreKit.primaryColor)
      .toast(isPresenting: $showToast) {
        let toastMessage = FyreKit.isDemoMode ? "activated" : "deactivated"
        return AlertToast(displayMode: .banner(.pop), type: .regular, title: "Demo mode \(toastMessage)!")
      }
      .sheet(item: $currentPage) { page in
        switch page {
          case .login: LoginView()
          case .registration: CheckPhoneNumberPage()
        }
      }
    }
    .navigationViewStyle(StackNavigationViewStyle())
  }
}

public struct StartPage_Previews: PreviewProvider {
  public static var previews: some View {
    Group {
      StartPage()
        .previewDevice("iPhone 13 Pro")
      
      StartPage()
        .previewDevice("iPad Pro (12-inch)")
    }
  }
}

extension View {
    func getRect() -> CGRect {
        return UIScreen.main.bounds
    }
}
