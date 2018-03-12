//
//  TryingTestDrivenArchitectureTests.swift
//  TryingTestDrivenArchitectureTests
//
//  Created by fadi on 3/12/18.
//  Copyright © 2018 fadi. All rights reserved.
//

import XCTest
@testable import TryingTestDrivenArchitecture

/// Defined in the test cases, because the test target is supposed to be generic
///   which can take any type of object.
struct SimpleCriteria {
    var userName: String
    var password: String
}

@objc class UserData: NSObject {
    let userName: String
    let email: String
    let phone: String
    
    init(userName: String, email: String, phone: String) {
        self.userName = userName
        self.email = email
        self.phone = phone
        super.init()
    }
}

class FakeLoginRepository: LoginRepository {
    func tryToLogin(userNamePassword: SimpleCriteria, completion: @escaping (UserData?, Error?) -> ()) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            if userNamePassword.userName == "firstUser" && userNamePassword.password == "firstPass" {
                completion(UserData(userName: "firstUser", email: "user1@users.com", phone: "12345678"), nil)
            } else if userNamePassword.userName == "secondUser" && userNamePassword.password == "secondPass" {
                completion(UserData(userName: "secondUser", email: "user2@users.com", phone: "87654321"), nil)
            } else {
                completion(nil, LoginRepositoryUtil.errorFactory())
            }
        }
    }
}

class MockLoginRepositoryThatReturnsNetworkError: LoginRepository {
    func tryToLogin(userNamePassword: SimpleCriteria, completion: @escaping (UserData?, Error?) -> ()) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            completion(nil, NSError.init(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil))
        }
    }
}

class LoginViewModelTests: XCTestCase {
    
    var fakeRepository: FakeLoginRepository?
    var mockRepositoryReturningError: MockLoginRepositoryThatReturnsNetworkError?
    
    override func setUp() {
        fakeRepository = FakeLoginRepository()
        mockRepositoryReturningError = MockLoginRepositoryThatReturnsNetworkError()
    }
    
    private func commonLoginTest(todoWithViewModel: (LoginViewModel) -> (),
                                then: (LoginViewModel) -> ()) {
        let loginViewModel = LoginViewModel()
        let loggedUserExpectation = XCTKVOExpectation(keyPath: "loggedUser", object: loginViewModel)
        let errorExpectation = XCTKVOExpectation(keyPath: "error", object: loginViewModel)
        todoWithViewModel(loginViewModel)
        wait(for: [loggedUserExpectation, errorExpectation], timeout: 1)
        then(loginViewModel)
    }
    
    func testSuccessfulLogin() {
        commonLoginTest(todoWithViewModel: { loginViewModel in
            loginViewModel.login(criteria: SimpleCriteria(userName: "firstUser", password: "firstPass"),
                                 using: fakeRepository!)
        }) { loginViewModel in
            XCTAssertEqual((loginViewModel.loggedUser as? UserData)?.userName, "firstUser")
            XCTAssertEqual((loginViewModel.loggedUser as? UserData)?.email, "user1@users.com")
            XCTAssertEqual((loginViewModel.loggedUser as? UserData)?.phone, "12345678")
            XCTAssert(loginViewModel.error == nil)
        }

        commonLoginTest(todoWithViewModel: { loginViewModel in
            loginViewModel.login(criteria: SimpleCriteria(userName: "secondUser", password: "secondPass"),
                                 using: fakeRepository!)
        }) { loginViewModel in
            XCTAssertEqual((loginViewModel.loggedUser as? UserData)?.userName, "secondUser")
            XCTAssertEqual((loginViewModel.loggedUser as? UserData)?.email, "user2@users.com")
            XCTAssertEqual((loginViewModel.loggedUser as? UserData)?.phone, "87654321")
            XCTAssert(loginViewModel.error == nil)
        }
    }

    func testUnsuccessfulLogin() {
        commonLoginTest(todoWithViewModel: { loginViewModel in
            loginViewModel.login(criteria: SimpleCriteria(userName: "firstUser2", password: "firstPass"),
                                 using: fakeRepository!)
        }) { loginViewModel in
            XCTAssertEqual(loginViewModel.loggedUser, nil)
            XCTAssertEqual((loginViewModel.error as NSError?)?.domain, LoginRepositoryUtil.errorFactory().domain)
            XCTAssertEqual((loginViewModel.error as NSError?)?.code, LoginRepositoryUtil.errorFactory().code)
        }

        commonLoginTest(todoWithViewModel: { loginViewModel in
            loginViewModel.login(criteria: SimpleCriteria(userName: "firstUser", password: "firstPass2"),
                                 using: fakeRepository!)
        }) { loginViewModel in
            XCTAssertEqual(loginViewModel.loggedUser, nil)
            XCTAssertEqual((loginViewModel.error as NSError?)?.domain, LoginRepositoryUtil.errorFactory().domain)
            XCTAssertEqual((loginViewModel.error as NSError?)?.code, LoginRepositoryUtil.errorFactory().code)
        }
    }

    func testNoNetworkWhenLogin() {
        commonLoginTest(todoWithViewModel: { loginViewModel in
            loginViewModel.login(criteria: SimpleCriteria(userName: "firstUser", password: "firstPass"),
                                 using: mockRepositoryReturningError!)
        }) { loginViewModel in
            XCTAssertEqual(loginViewModel.loggedUser, nil)
            XCTAssertEqual((loginViewModel.error as NSError?)?.domain, NSURLErrorDomain)
            XCTAssertEqual((loginViewModel.error as NSError?)?.code, NSURLErrorCannotConnectToHost)
        }
    }
}

