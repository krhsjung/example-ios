# Swift Annotations (@) 가이드

이 프로젝트에서 사용하는 Swift 어노테이션(Property Wrapper, Attribute)들에 대한 설명입니다.

---

## 목차

1. [SwiftUI 관련](#swiftui-관련)
   - [@Published](#published)
   - [@StateObject](#stateobject)
   - [@ObservedObject](#observedobject)
   - [@EnvironmentObject](#environmentobject)
   - [@State](#state)
   - [@Binding](#binding)
   - [@Environment](#environment)
2. [Swift Concurrency 관련](#swift-concurrency-관련)
   - [@MainActor](#mainactor)
   - [@escaping](#escaping)
3. [기타](#기타)
   - [@discardableResult](#discardableresult)

---

## SwiftUI 관련

### @Published

**역할**: 프로퍼티 값이 변경될 때 자동으로 View에 알림을 보냄

**사용 위치**: `ObservableObject`를 채택한 클래스 내부

```swift
class LogInViewModel: ObservableObject {
    @Published var email: String = ""      // 값 변경 시 View 자동 업데이트
    @Published var isLoading: Bool = false
}
```

**동작 원리**:
- 값이 변경되면 `objectWillChange.send()`가 자동 호출됨
- 이를 구독하는 SwiftUI View가 다시 렌더링됨
- `Combine` 프레임워크 import 필요

---

### @StateObject

**역할**: View가 소유하는 ObservableObject 인스턴스 생성 및 생명주기 관리

**사용 위치**: View 내부에서 ViewModel 최초 생성 시

```swift
struct LogInView: View {
    @StateObject private var viewModel = LogInViewModel()  // View가 소유

    var body: some View {
        TextField("Email", text: $viewModel.email)
    }
}
```

**특징**:
- View가 처음 생성될 때 한 번만 인스턴스 생성
- View가 다시 그려져도 인스턴스 유지
- View가 완전히 사라질 때 메모리에서 해제

**vs @ObservedObject**:
| @StateObject | @ObservedObject |
|--------------|-----------------|
| 인스턴스 생성 및 소유 | 외부에서 주입받음 |
| View 재생성 시 유지 | View 재생성 시 초기화될 수 있음 |

---

### @ObservedObject

**역할**: 외부에서 주입받은 ObservableObject 관찰

**사용 위치**: 부모 View에서 전달받은 ViewModel 사용 시

```swift
struct LogInFormView: View {
    @ObservedObject var viewModel: LogInViewModel  // 외부에서 주입

    var body: some View {
        TextField("Email", text: $viewModel.email)
    }
}

// 사용
LogInFormView(viewModel: viewModel)
```

**주의사항**:
- 직접 인스턴스를 생성하면 View 재생성 시 상태가 초기화될 수 있음
- 인스턴스 생성은 `@StateObject`로, 전달받을 때만 `@ObservedObject` 사용

---

### @EnvironmentObject

**역할**: View 계층 전체에서 공유되는 객체에 접근

**사용 위치**: 앱 전역에서 공유해야 하는 상태 (예: AuthManager)

```swift
// 앱 최상위에서 주입
@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthManager.shared)  // 주입
        }
    }
}

// 하위 View에서 사용
struct FirstTabView: View {
    @EnvironmentObject private var authManager: AuthManager  // 접근

    var body: some View {
        Text(authManager.currentUser?.name ?? "Guest")
    }
}
```

**특징**:
- 명시적으로 전달하지 않아도 하위 View에서 접근 가능
- 주입하지 않고 사용하면 런타임 크래시 발생
- 앱 전역 상태 관리에 적합

---

### @State

**역할**: View 내부의 단순한 값 타입 상태 관리

**사용 위치**: View 내부에서 로컬 상태 관리 시

```swift
struct HomeView: View {
    @State private var selectedTab: Int = 0      // 단순 값 타입
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            // ...
        }
    }
}
```

**특징**:
- `String`, `Int`, `Bool` 등 값 타입에 사용
- View 내부에서만 사용 (외부 전달 시 `@Binding` 사용)
- `private`으로 선언하는 것이 권장됨

---

### @Binding

**역할**: 부모 View의 상태에 대한 양방향 참조

**사용 위치**: 자식 View에서 부모의 상태를 읽고 수정해야 할 때

```swift
// 부모 View
struct SignUpFormView: View {
    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        TermsAgreementCheckbox(isAgreed: $viewModel.isAgreeToTerms)  // $ 접두사로 Binding 전달
    }
}

// 자식 View
struct TermsAgreementCheckbox: View {
    @Binding var isAgreed: Bool  // 부모의 상태 참조

    var body: some View {
        Button(action: { isAgreed.toggle() }) {  // 부모 상태 수정
            Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
        }
    }
}
```

**특징**:
- 값을 복사하지 않고 참조
- 자식에서 변경하면 부모의 상태도 변경됨
- `$` 접두사로 Binding 생성

---

### @Environment

**역할**: 시스템 환경 값에 접근

**사용 위치**: 시스템이 제공하는 값 (dismiss, colorScheme 등) 사용 시

```swift
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss        // 화면 닫기 액션
    @Environment(\.colorScheme) private var colorScheme  // 다크/라이트 모드

    var body: some View {
        Button("닫기") {
            dismiss()  // 현재 화면 닫기
        }
    }
}
```

**자주 사용하는 환경 값**:
| KeyPath | 설명 |
|---------|------|
| `\.dismiss` | 현재 View 닫기 |
| `\.colorScheme` | 다크/라이트 모드 |
| `\.locale` | 현재 언어 설정 |
| `\.horizontalSizeClass` | 화면 크기 클래스 |

---

## Swift Concurrency 관련

### @MainActor

**역할**: 해당 코드가 메인 스레드에서 실행되도록 보장

**사용 위치**: UI 업데이트가 필요한 클래스/메서드

```swift
// 클래스 전체에 적용
@MainActor
class LogInViewModel: ObservableObject {
    @Published var isLoading: Bool = false  // UI 상태

    func logIn() {
        isLoading = true  // 메인 스레드에서 실행 보장
    }
}

// 특정 메서드에만 적용
class NetworkService {
    @MainActor
    func updateUI(with data: Data) {
        // 메인 스레드에서 실행
    }
}
```

**왜 필요한가?**:
- UIKit/SwiftUI의 UI 업데이트는 반드시 메인 스레드에서 수행해야 함
- 백그라운드 스레드에서 UI 업데이트 시 크래시 발생 가능
- `@Published` 프로퍼티 변경은 메인 스레드에서 해야 함

**예전 방식 vs 현재 방식**:
```swift
// 예전 (DispatchQueue)
DispatchQueue.main.async {
    self.isLoading = false
}

// 현재 (@MainActor)
@MainActor
func updateLoading() {
    isLoading = false  // 자동으로 메인 스레드
}
```

---

### @escaping

**역할**: 클로저가 함수 실행이 끝난 후에도 호출될 수 있음을 표시

**사용 위치**: 비동기 작업의 콜백, 저장되는 클로저

```swift
class BaseAuthViewModel {
    func performAsyncTask(
        fallbackError: String,
        action: @escaping () async throws -> Void  // 함수 종료 후 호출됨
    ) {
        Task {
            // action은 Task 내부에서 나중에 호출됨
            try await action()
        }
    }
}
```

**@escaping이 필요한 경우**:
```swift
// 1. 비동기 콜백
func fetchData(completion: @escaping (Data) -> Void) {
    DispatchQueue.global().async {
        let data = // ...
        completion(data)  // 함수 종료 후 호출
    }
}

// 2. 프로퍼티에 저장
class Handler {
    var savedClosure: (() -> Void)?

    func save(closure: @escaping () -> Void) {
        savedClosure = closure  // 저장됨
    }
}
```

**@escaping이 필요 없는 경우**:
```swift
func process(items: [Int], transform: (Int) -> Int) -> [Int] {
    return items.map(transform)  // 함수 내에서 즉시 실행 후 종료
}
```

---

## 기타

### @discardableResult

**역할**: 함수의 반환 값을 사용하지 않아도 경고가 발생하지 않음

**사용 위치**: 반환 값이 선택적으로 사용되는 함수

```swift
class NetworkManager {
    @discardableResult
    func post<T: Decodable>(endpoint: APIEndpoint) async throws -> T {
        // ...
    }
}

// 사용
try await networkManager.post(endpoint: .logOut)  // 반환 값 무시해도 경고 없음
let user: User = try await networkManager.post(endpoint: .logIn)  // 반환 값 사용
```

---

## 어노테이션 선택 가이드

### 상태 관리

| 상황 | 어노테이션 |
|------|-----------|
| View 내부 단순 상태 | `@State` |
| View가 ViewModel 생성 | `@StateObject` |
| ViewModel 전달받음 | `@ObservedObject` |
| 앱 전역 상태 공유 | `@EnvironmentObject` |
| 자식에게 상태 전달 | `@Binding` |

### ViewModel 프로퍼티

| 상황 | 어노테이션 |
|------|-----------|
| UI 바인딩 필요 | `@Published` |
| UI 업데이트 보장 | `@MainActor` (클래스에) |

### 클로저

| 상황 | 어노테이션 |
|------|-----------|
| 비동기 콜백 | `@escaping` |
| 저장되는 클로저 | `@escaping` |
| 즉시 실행되는 클로저 | 없음 |

---

## 참고 자료

- [Apple Developer Documentation - Property Wrappers](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/#Property-Wrappers)
- [Apple Developer Documentation - Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [SwiftUI State Management](https://developer.apple.com/documentation/swiftui/state-and-data-flow)
