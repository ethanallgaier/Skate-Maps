//
//  SignUpView.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//

import SwiftUI

struct SignUpView: View {
    @State var viewModel = SignUpViewModel()
    @Environment(AuthService.self) var authService// track if user has logged in or not
    
    var body: some View {
            Text("Welcome to SkateMap")
                .padding()
                
                .font(.system(size: 40, design: .serif))
                .bold()
            
            
        VStack(spacing: 25) {
            Spacer()
            //Username
            TextField("Create a username", text: $viewModel.username)
                .frame(width: 335)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray, lineWidth: 1)
                )
            
            if viewModel.isValid && viewModel.username.isEmpty {
                Text("Please enter a username")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            //Email
            TextField("Enter a email", text: $viewModel.email)
                .frame(width: 335)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray, lineWidth: 1)
                )
            if viewModel.isValid && viewModel.email.isEmpty {
                Text("Please enter a email")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            //Password
            SecureField("Enter a password", text: $viewModel.password)
                .frame(width: 335)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.gray, lineWidth: 1)
                )
            if viewModel.isValid && viewModel.email.isEmpty {
                Text("Please enter a password")
                    .foregroundStyle(.red)
                    .font(.footnote)
            } else if viewModel.isValid && viewModel.email.count < 6 {
                Text("Password is too short")
                    .foregroundStyle(.red)
                    .font(.footnote)
            }
            
           Spacer()
            
            //SignUp/Save/Next screen button-
            Button {
                viewModel.isValid = true
                guard viewModel.isSignUpValid else { return }
                
                Task {
                    await authService.signUp(email: viewModel.email, password: viewModel.password, username: viewModel.username)
                }
            } label: {
                Text("Sign Up")
                    .padding()
                    .frame(width: 340)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .frame(height: 60)
            .cornerRadius(20)
            Spacer()
        }
    }
}


#Preview {
    NavigationStack {
        SignUpView()
    }
    .environment(AuthService())
}
