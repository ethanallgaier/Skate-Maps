//
//  LoginView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/2/26.
//

import SwiftUI

struct LoginView: View {
    
    @State var viewModel = LoginViewModel()
    @Environment(AuthService.self) var authService// track if user has logged in or not

    
    var body: some View {
        NavigationStack {
            Text("Skate Maps")
                .font(Font.largeTitle)
            
    
 //username
            TextField("Enter email", text: $viewModel.email)
                .textFieldStyle(.roundedBorder)
                .padding()
            
 //password
            SecureField("Enter Password", text: $viewModel.password)
                .padding()
                .textFieldStyle(.roundedBorder)
            
            if !authService.errorMessage.isEmpty {
                Text(authService.errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
            Spacer()
//login button
            Button {
              
                Task { await authService.login(email: viewModel.email, password: viewModel.password) }
            } label: {
                Text("Login")
                    .padding()
            }
            .buttonStyle(GlassButtonStyle())
            .frame(width:250)
            
 //destination to signupView
            NavigationLink("Don't have an account? Sign Up") {
                SignUpView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
