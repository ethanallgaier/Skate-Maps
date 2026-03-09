//
//  SignUpViewModel.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/4/26.
//

import Foundation
import FirebaseAuth

@Observable
class SignUpViewModel {
    var username: String = ""
    var email: String = ""
    var password: String = ""
    var isValid: Bool = false
    
    var isSignUpValid: Bool {
        !username.isEmpty && !email.isEmpty && password.count >= 6

     }
    
}
