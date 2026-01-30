# Example iOS

SwiftUI 기반 iOS 인증 애플리케이션입니다. Clean Architecture와 MVVM 패턴을 적용하여 이메일/비밀번호 로그인, OAuth 소셜 로그인, Apple Sign In을 지원합니다.

---

## 기술 스택

| 항목      | 기술                                          |
| --------- | --------------------------------------------- |
| 언어      | Swift 5.9+                                    |
| UI        | SwiftUI                                       |
| 동시성    | Swift Concurrency (async/await)               |
| 상태 관리 | `@Observable` (iOS 17+)                       |
| 네트워크  | URLSession                                    |
| 보안      | Keychain Services, CryptoKit, SSL Pinning     |
| 인증      | AuthenticationServices (OAuth, Apple Sign In) |
| 로깅      | os.log                                        |
| 다국어    | xcstrings (73개 키)                           |

---

## 프로젝트 구조

```
example/
├── App/                            # 앱 진입점
│   └── exampleApp.swift
│
├── Core/                           # 인프라 계층
│   ├── Networking/                 # 네트워크 통신
│   │   ├── NetworkManager.swift    # URLSession + 재시도 + SSL 피닝
│   │   ├── APIEndpoint.swift       # API 설정 및 엔드포인트
│   │   ├── NetworkError.swift      # 에러 타입 정의
│   │   └── ErrorResponse.swift     # 서버 에러 응답 모델
│   │
│   ├── Security/                   # 보안
│   │   ├── SSLPinningDelegate.swift    # TLS 인증서 피닝
│   │   ├── KeychainManager.swift       # Keychain 저장소
│   │   └── SecureCookieStorage.swift   # 보안 쿠키 관리
│   │
│   ├── Utils/
│   │   └── Log.swift               # 구조화된 로깅
│   │
│   ├── Localization/
│   │   └── String+Localization.swift   # 다국어 확장
│   │
│   └── Testing/
│       └── TestFixtures.swift      # 테스트 데이터
│
├── Domain/                         # 비즈니스 로직 계층
│   ├── Managers/
│   │   └── AuthManager.swift       # 인증 상태 관리 (@Observable)
│   │
│   ├── Models/
│   │   └── Auth/
│   │       ├── User.swift
│   │       ├── AuthValidator.swift     # 입력 유효성 검사
│   │       ├── AuthProvider.swift      # SNS 제공자 열거형
│   │       ├── AuthRequests.swift      # 요청/응답 모델
│   │       ├── AuthFormData.swift      # 폼 데이터 + 검증
│   │       └── ValidationResult.swift
│   │
│   └── Services/
│       └── Auth/
│           └── AuthService.swift   # 인증 API 서비스
│
├── Presentation/                   # UI 계층
│   ├── ViewModels/
│   │   └── Auth/
│   │       ├── BaseAuthViewModel.swift # 공통 인증 로직
│   │       ├── LogInViewModel.swift
│   │       └── SignUpViewModel.swift
│   │
│   └── Views/
│       ├── Pages/
│       │   ├── Auth/
│       │   │   ├── LogInView.swift
│       │   │   └── SignUpView.swift
│       │   └── Main/
│       │       └── MainView.swift
│       │
│       ├── Components/
│       │   ├── Common/
│       │   │   ├── ExampleButton.swift
│       │   │   ├── ExampleInputBox.swift
│       │   │   ├── ExampleCheckbox.swift
│       │   │   ├── ExampleErrorAlert.swift
│       │   │   ├── ExampleLoadingOverlay.swift
│       │   │   └── ExampleDividerWithText.swift
│       │   ├── Auth/
│       │   │   └── SocialLoginButtonsView.swift
│       │   └── Layout/
│       │       └── ExamplePageLayout.swift
│       │
│       └── Extensions/
│           └── Color.swift         # Asset Catalog 색상 확장
│
└── Resources/
    ├── Assets.xcassets/            # 이미지, 색상, 앱 아이콘
    └── Localization/
        ├── Auth.xcstrings          # 인증 관련 (13키)
        ├── Common.xcstrings        # 공통 (20키)
        ├── Error.xcstrings         # 에러 메시지 (33키)
        └── ServerError.xcstrings   # 서버 에러 (7키)
```

---

## 주요 기능

### 인증

| 기능                     | 설명                                       |
| ------------------------ | ------------------------------------------ |
| 이메일 로그인            | 이메일/비밀번호 기반 인증                  |
| 회원가입                 | 입력 유효성 검사 포함                      |
| Google OAuth             | ASWebAuthenticationSession 기반 웹 OAuth   |
| Apple Sign In (네이티브) | ASAuthorizationAppleIDProvider + 생체 인증 |
| Apple Sign In (웹)       | ASWebAuthenticationSession 기반            |
| 세션 관리                | 앱 활성화 시 자동 세션 검증                |
| 보안 로그아웃            | Keychain + 메모리 + 쿠키 일괄 삭제         |

### 네트워크

| 기능            | 설명                               |
| --------------- | ---------------------------------- |
| 재시도 로직     | Exponential backoff + Jitter       |
| 타임아웃 세분화 | 연결 10초, 요청 30초, 리소스 60초  |
| SSL 피닝        | SPKI 공개 키 피닝 (SHA-256)        |
| 보안 쿠키       | Keychain 기반 이중 레이어 저장     |
| 민감정보 마스킹 | 로그에서 토큰/비밀번호 자동 마스킹 |

### 보안

| 계층     | 구현                               |
| -------- | ---------------------------------- |
| 전송     | SSL/TLS 인증서 피닝                |
| 저장     | Keychain (AES-256 하드웨어 암호화) |
| 세션     | Secure 쿠키 + 도메인/경로 검증     |
| 로그     | 민감 헤더/바디 필드 마스킹         |
| 로그아웃 | 메모리 + Keychain + 쿠키 완전 삭제 |

---

## 아키텍처

### Clean Architecture + MVVM

```
┌─────────────────────────────────────────────┐
│  Presentation (Views + ViewModels)          │
│  SwiftUI Views ←→ @Observable ViewModels    │
├─────────────────────────────────────────────┤
│  Domain (Managers + Services + Models)      │
│  AuthManager ←→ AuthService ←→ Models       │
├─────────────────────────────────────────────┤
│  Core (Networking + Security + Utils)       │
│  NetworkManager / KeychainManager / Log     │
└─────────────────────────────────────────────┘
```

### 인증 플로우

```
exampleApp (앱 진입)
  ↓
authManager.checkSession()
  ├── 세션 유효 → MainView
  └── 세션 없음 → LogInView
                    ├── 이메일 로그인 → AuthService.logIn()
                    ├── Google OAuth → ASWebAuthenticationSession
                    ├── Apple (네이티브) → ASAuthorizationAppleIDProvider
                    └── 회원가입 → SignUpView → AuthService.signUp()
```

---

## API 엔드포인트

| 메서드 | 경로                 | 설명                       |
| ------ | -------------------- | -------------------------- |
| POST   | `/auth/login`        | 이메일/비밀번호 로그인     |
| POST   | `/user`              | 회원가입                   |
| POST   | `/auth/exchange`     | OAuth 토큰 교환            |
| POST   | `/auth/apple/native` | Apple Sign In              |
| POST   | `/auth/logout`       | 로그아웃                   |
| GET    | `/auth/me`           | 세션 검증 + 사용자 정보    |
| GET    | `/auth/{provider}`   | OAuth 시작 (google, apple) |

---

## Todo

### 보안

- [ ] SSL Pinning 프로덕션 해시 추가 (`APIConfiguration.pinnedKeyHashes`)

### 아키텍처

- [ ] DI 컨테이너 구현 (ServiceContainer)
- [ ] 타입 안전 네비게이션 (NavigationPath)

### UX

- [ ] 입력 필드 실시간 유효성 검사 UI (에러 테두리, 인라인 메시지)
- [ ] 에러 복구 옵션 추가 (재시도 메커니즘)

### 네트워크

- [ ] 중복 요청 방지 (Request coalescing)
- [ ] 오프라인 지원 (SwiftData 캐싱)

### 테스트

- [ ] TestFixtures 확장 (API Mock 데이터, 실패 시나리오)
- [ ] Unit/UI 테스트 추가

### 최신 기술 도입

- [ ] Typed Throws (Swift 6.0)
- [ ] Actor 기반 토큰 관리 (TokenStore)
- [ ] Async Sequences (인증 상태 스트리밍)
