//
//  LoginViewModel.swift
//  TryingTestDrivenArchitecture
//
//  Created by fadi on 3/12/18.
//  Copyright © 2018 fadi. All rights reserved.
//

import UIKit

protocol LoginRepository {
    associatedtype T
    associatedtype U
    func tryToLogin(userNamePassword: T, completion: @escaping (U?, Error?) -> ())
}

struct LoginRepositoryUtil {
    static func errorFactory() -> NSError {
        return NSError.init(domain: "com.experiments.TryingTestDrivenArchitecture.authError",
                            code: 401,
                            userInfo: nil)
    }
}

class LoginViewModel: NSObject {
    func login<R: LoginRepository>(criteria: R.T, using: R) where R.U: NSObject {
    }
    
    @objc dynamic var loggedUser: NSObject?
    @objc dynamic var error: NSError?
}
