//
//  LoginViewModel.swift
//  SkateMap
//
//  Created by Ethan Allgaier on 3/3/26.
//

import Foundation
import FirebaseAuth


@Observable//If something changes in here, update the UI.
class LoginViewModel {
     var email: String = ""
     var password: String = ""
    
    
   var isLoginValid: Bool {
       !email.isEmpty && password.count >= 6
    }
    
    }
