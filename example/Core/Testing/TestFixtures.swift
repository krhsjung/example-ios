//
//  TestFixtures.swift
//  example
//
//  Path: Core/Testing/TestFixtures.swift
//  Created by Claude on 1/21/26.
//

import Foundation

#if DEBUG
/// 테스트 및 Preview용 Fixture 데이터
/// DEBUG 빌드에서만 사용 가능
enum TestFixtures {
    // MARK: - Auth Fixtures

    enum Auth {
        /// 테스트용 이메일
        static let email = "test@test.com"

        /// 테스트용 비밀번호
        static let password = "Test2022@!"

        /// 테스트용 이름
        static let name = "Tester"
    }

    // MARK: - LogIn Fixtures

    enum LogIn {
        /// 미리 채워진 로그인 폼 데이터
        static let formData = LogInFormData(
            email: Auth.email,
            password: Auth.password
        )
    }

    // MARK: - SignUp Fixtures

    enum SignUp {
        /// 미리 채워진 회원가입 폼 데이터
        static let formData = SignUpFormData(
            email: Auth.email,
            password: Auth.password,
            confirmPassword: Auth.password,
            name: Auth.name,
            isAgreeToTerms: true
        )
    }
}
#endif
