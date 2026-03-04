//
//  LoginView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI

struct LoginView: View {
    
    var viewModel = LoginViewModel()
    
    var body: some View {
        TextField("Enter Username", text: viewModel.$username)
            .textFieldStyle(.roundedBorder)
            .padding()
        SecureField("Enter Password", text: viewModel.$password)
            .padding()
            .textFieldStyle(.roundedBorder)
            
        
        Button {
            print("user logged in")
        } label: {
            Text("Login")
                .padding()
        }
        .buttonStyle(GlassButtonStyle())
        .frame(width:250)
    }
}

#Preview {
    LoginView()
}
