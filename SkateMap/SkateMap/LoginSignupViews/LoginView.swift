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
            Spacer()
            Text("Skate Maps")
                .frame(height: 100)
                .padding()
                .font(.system(size: 50, design: .serif))
                .bold()
                
            Spacer()
            VStack(spacing: 25) {
                //username
                TextField("Enter email", text: $viewModel.email)
                    .frame(width: 335)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray, lineWidth: 1)
                    )
                
                //password
                SecureField("Enter Password", text: $viewModel.password)
                    .frame(width: 335)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.gray, lineWidth: 1)
                    )
                if !authService.errorMessage.isEmpty {
                    Text(authService.errorMessage)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                
                
                Text("Forgot password?")
                    .foregroundStyle(.secondary)
                    .padding()
                
                //login button
                Button {
                    Task { await authService.login(email: viewModel.email, password: viewModel.password) }
                } label: {
                    Text("Log In")
                        .padding()
                        .frame(width: 340)
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .frame(height: 60)
                .cornerRadius(20)
            }
            Spacer()
 //destination to signupView
            
            Spacer()
            HStack {
                Text("Don't have an account?")
                    .foregroundStyle(.secondary)
                NavigationLink("Sign Up") {
                    SignUpView()
                }
                
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService())
}
