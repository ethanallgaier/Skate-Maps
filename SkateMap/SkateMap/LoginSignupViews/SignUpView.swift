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
        Text("Sign Up")
        
        
        TextField("Enter a email", text: $viewModel.email)
            .padding()
        
        SecureField("Enter a password", text: $viewModel.password)
            .padding()
        
        
        Button {
            Task {
                await authService.signUp(email: viewModel.email, password: viewModel.password, username: viewModel.username)
            }
        } label: {
            Text("Sign Up")
        }
    }
}


#Preview {
    SignUpView()
        .environment(AuthService())
}
