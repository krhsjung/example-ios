# SSL/TLS 인증서 핀닝 (Certificate Pinning)

## 목차
1. [개요](#개요)
2. [왜 필요한가?](#왜-필요한가)
3. [작동 원리](#작동-원리)
4. [핀닝 방식](#핀닝-방식)
5. [플랫폼별 구현](#플랫폼별-구현)
6. [장단점](#장단점)
7. [베스트 프랙티스](#베스트-프랙티스)
8. [주의사항](#주의사항)

---

## 개요

**SSL/TLS 인증서 핀닝(Certificate Pinning)**은 모바일 앱이 서버와 통신할 때, 미리 알고 있는 인증서나 공개키만을 신뢰하도록 하는 보안 기법입니다.

일반적인 HTTPS 통신에서는 운영체제나 브라우저에 설치된 **신뢰할 수 있는 CA(Certificate Authority)** 목록을 기반으로 서버 인증서를 검증합니다. 하지만 이 방식은 악의적인 CA가 발급한 인증서나, 사용자 기기에 설치된 악성 루트 인증서를 통한 공격에 취약합니다.

인증서 핀닝은 앱 내부에 서버의 인증서 또는 공개키 정보를 "핀(고정)"하여, 해당 정보와 일치하는 서버만 신뢰합니다.

```
┌─────────────────────────────────────────────────────────────────┐
│                    일반 HTTPS vs 인증서 핀닝                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  [일반 HTTPS]                                                   │
│  ┌──────┐     ┌──────────┐     ┌────────┐     ┌──────┐         │
│  │ 앱   │────▶│ OS/브라우저│────▶│ CA 목록 │────▶│ 서버 │         │
│  └──────┘     │ CA 검증   │     │ (수백개) │     └──────┘         │
│               └──────────┘     └────────┘                       │
│                                                                 │
│  [인증서 핀닝]                                                   │
│  ┌──────┐     ┌──────────┐     ┌────────┐     ┌──────┐         │
│  │ 앱   │────▶│ 앱 내장   │────▶│ 핀 정보 │────▶│ 서버 │         │
│  └──────┘     │ 인증서검증 │     │ (1-2개) │     └──────┘         │
│               └──────────┘     └────────┘                       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 왜 필요한가?

### MITM (Man-In-The-Middle) 공격 방지

MITM 공격은 공격자가 클라이언트와 서버 사이에서 통신을 가로채는 공격입니다.

```
┌─────────────────────────────────────────────────────────────────┐
│                      MITM 공격 시나리오                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  정상 통신:                                                     │
│  ┌──────┐ ◀───── 암호화된 통신 ─────▶ ┌──────┐                  │
│  │  앱  │                            │ 서버 │                  │
│  └──────┘                            └──────┘                  │
│                                                                 │
│  MITM 공격:                                                     │
│  ┌──────┐     ┌──────────┐     ┌──────┐                        │
│  │  앱  │◀───▶│  공격자   │◀───▶│ 서버 │                        │
│  └──────┘     │ (가짜인증서)│     └──────┘                        │
│               └──────────┘                                      │
│               ↑                                                 │
│               │ 통신 내용 열람/변조 가능                          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 주요 공격 벡터

| 공격 유형 | 설명 | 핀닝으로 방지 |
|----------|------|:------------:|
| 악성 CA 인증서 | 사용자 기기에 악성 루트 인증서 설치 | ✅ |
| 손상된 CA | 합법적 CA가 해킹되어 가짜 인증서 발급 | ✅ |
| 공용 Wi-Fi 공격 | 카페, 공항 등에서 가짜 핫스팟 운영 | ✅ |
| SSL Stripping | HTTPS를 HTTP로 다운그레이드 | ⚠️ 부분적 |
| DNS Spoofing | DNS 응답 조작으로 가짜 서버 연결 | ✅ |

### 실제 공격 사례

1. **Superfish 사건 (2015)**: Lenovo 노트북에 선탑재된 Superfish 소프트웨어가 자체 루트 인증서를 설치하여 모든 HTTPS 트래픽을 가로챔

2. **DigiNotar 해킹 (2011)**: 네덜란드 CA가 해킹되어 google.com 등에 대한 가짜 인증서 발급

3. **Comodo 해킹 (2011)**: 주요 CA가 해킹되어 여러 대형 서비스에 대한 가짜 인증서 발급

---

## 작동 원리

### TLS 핸드셰이크와 인증서 검증

```
┌─────────────────────────────────────────────────────────────────┐
│                    TLS 핸드셰이크 과정                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  클라이언트                                    서버              │
│  ──────────                                   ──────            │
│      │                                          │               │
│      │ ──────── 1. ClientHello ───────────────▶ │               │
│      │         (지원 암호화 방식 전송)            │               │
│      │                                          │               │
│      │ ◀─────── 2. ServerHello ──────────────── │               │
│      │         (암호화 방식 선택)                │               │
│      │                                          │               │
│      │ ◀─────── 3. Certificate ─────────────── │               │
│      │         (서버 인증서 전송)                │               │
│      │                                          │               │
│      │ ┌─────────────────────────┐              │               │
│      │ │ 4. 인증서 핀닝 검증      │              │               │
│      │ │    ┌───────────────┐   │              │               │
│      │ │    │ 핀 정보와 비교 │   │              │               │
│      │ │    └───────────────┘   │              │               │
│      │ │    일치 → 계속 진행     │              │               │
│      │ │    불일치 → 연결 거부   │              │               │
│      │ └─────────────────────────┘              │               │
│      │                                          │               │
│      │ ──────── 5. Key Exchange ──────────────▶ │               │
│      │                                          │               │
│      │ ◀──────── 암호화된 통신 ────────────────▶ │               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 인증서 체인 구조

```
┌─────────────────────────────────────────────────────────────────┐
│                       인증서 체인                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐                                           │
│  │   Root CA       │ ← 자체 서명 (OS에 사전 설치됨)              │
│  │   Certificate   │                                           │
│  └────────┬────────┘                                           │
│           │ 서명                                                │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │ Intermediate CA │ ← Root CA가 서명                          │
│  │   Certificate   │                                           │
│  └────────┬────────┘                                           │
│           │ 서명                                                │
│           ▼                                                    │
│  ┌─────────────────┐                                           │
│  │    Leaf/End     │ ← Intermediate CA가 서명                  │
│  │   Certificate   │   (실제 서버 인증서)                       │
│  │  (example.com)  │                                           │
│  └─────────────────┘                                           │
│                                                                 │
│  핀닝 위치 선택:                                                │
│  • Root CA: 가장 안정적, 보안 수준 낮음                          │
│  • Intermediate CA: 균형잡힌 선택                               │
│  • Leaf Certificate: 가장 엄격, 갱신 시 앱 업데이트 필요          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 핀닝 방식

### 1. 인증서 핀닝 (Certificate Pinning)

전체 인증서를 앱에 내장하고 비교합니다.

```
장점:
• 구현이 직관적
• 인증서의 모든 정보 검증 가능

단점:
• 인증서 갱신 시 앱 업데이트 필요
• 앱 크기 증가 (인증서 파일 포함)
```

### 2. 공개키 핀닝 (Public Key Pinning)

인증서에서 공개키(SPKI)만 추출하여 비교합니다.

```
장점:
• 인증서 갱신 시에도 같은 키 쌍 사용 가능
• 더 유연한 운영 가능

단점:
• 키 교체 시 앱 업데이트 필요
• 구현이 약간 복잡
```

### 3. 해시 핀닝 (Hash Pinning)

인증서나 공개키의 해시값(SHA-256)을 비교합니다.

```
장점:
• 저장 공간 최소화 (해시값만 저장)
• 빠른 비교 연산

단점:
• 디버깅이 어려울 수 있음
```

### 핀닝 방식 비교

| 방식 | 저장 크기 | 유연성 | 보안 수준 | 권장 용도 |
|------|----------|--------|----------|----------|
| 전체 인증서 | ~2KB | 낮음 | 높음 | 높은 보안 요구 |
| 공개키 | ~300B | 중간 | 높음 | 일반적 사용 (권장) |
| 해시 | 32B | 중간 | 높음 | 저장 공간 제한 시 |

---

## 플랫폼별 구현

### iOS (Swift)

#### URLSession을 이용한 구현

```swift
import Foundation
import CommonCrypto

class CertificatePinningDelegate: NSObject, URLSessionDelegate {

    // 핀닝할 공개키의 SHA-256 해시값들
    private let pinnedPublicKeyHashes: Set<String> = [
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",  // Primary
        "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="   // Backup
    ]

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // 인증서 체인 검증
        if validateCertificateChain(serverTrust) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    private func validateCertificateChain(_ serverTrust: SecTrust) -> Bool {
        let certificateCount = SecTrustGetCertificateCount(serverTrust)

        for index in 0..<certificateCount {
            guard let certificate = SecTrustCopyCertificateChain(serverTrust)?[index] as? SecCertificate else {
                continue
            }

            if let publicKeyHash = getPublicKeyHash(from: certificate),
               pinnedPublicKeyHashes.contains(publicKeyHash) {
                return true
            }
        }

        return false
    }

    private func getPublicKeyHash(from certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate),
              let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        publicKeyData.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return Data(hash).base64EncodedString()
    }
}

// 사용 예시
let delegate = CertificatePinningDelegate()
let session = URLSession(
    configuration: .default,
    delegate: delegate,
    delegateQueue: nil
)
```

#### Alamofire를 이용한 구현

```swift
import Alamofire

let serverTrustManager = ServerTrustManager(evaluators: [
    "api.example.com": PinnedCertificatesTrustEvaluator(
        certificates: [
            // Bundle에 포함된 .cer 파일들
        ],
        acceptSelfSignedCertificates: false,
        performDefaultValidation: true,
        validateHost: true
    )
])

let session = Session(serverTrustManager: serverTrustManager)
```

---

### Android (Kotlin)

#### OkHttp를 이용한 구현

```kotlin
import okhttp3.CertificatePinner
import okhttp3.OkHttpClient

class NetworkClient {

    private val certificatePinner = CertificatePinner.Builder()
        .add(
            "api.example.com",
            "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",  // Primary
            "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="   // Backup
        )
        .build()

    val client = OkHttpClient.Builder()
        .certificatePinner(certificatePinner)
        .build()
}
```

#### Network Security Configuration (Android 7.0+)

`res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">api.example.com</domain>
        <pin-set expiration="2025-12-31">
            <!-- Primary Pin -->
            <pin digest="SHA-256">AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=</pin>
            <!-- Backup Pin -->
            <pin digest="SHA-256">BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=</pin>
        </pin-set>
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </domain-config>
</network-security-config>
```

`AndroidManifest.xml`:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
</application>
```

#### Retrofit과 함께 사용

```kotlin
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

class ApiService {

    private val networkClient = NetworkClient()

    val retrofit: Retrofit = Retrofit.Builder()
        .baseUrl("https://api.example.com/")
        .client(networkClient.client)
        .addConverterFactory(GsonConverterFactory.create())
        .build()
}
```

---

### React Native

#### react-native-ssl-pinning 라이브러리

```javascript
import { fetch } from 'react-native-ssl-pinning';

// iOS: 인증서를 Xcode 프로젝트에 추가
// Android: res/raw/ 폴더에 인증서 추가

const response = await fetch('https://api.example.com/data', {
    method: 'GET',
    headers: {
        'Content-Type': 'application/json',
    },
    sslPinning: {
        certs: ['certificate_name'],  // 확장자 없이 파일명만
    },
    timeoutInterval: 10000,
});

const data = await response.json();
```

#### 공개키 해시 방식

```javascript
const response = await fetch('https://api.example.com/data', {
    method: 'GET',
    sslPinning: {
        publicKeys: [
            'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
            'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
        ],
    },
});
```

---

### Flutter

#### http_certificate_pinning 패키지

```dart
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class ApiClient {
  final List<String> allowedSHAFingerprints = [
    'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
  ];

  Future<String> fetchData() async {
    try {
      final response = await HttpCertificatePinning.check(
        serverURL: 'https://api.example.com/data',
        sha: SHA.SHA256,
        allowedSHAFingerprints: allowedSHAFingerprints,
        timeout: 50,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      return response.body;
    } on PlatformException catch (e) {
      // 핀닝 실패 처리
      throw Exception('Certificate pinning failed: ${e.message}');
    }
  }
}
```

#### Dio와 함께 사용 (네이티브 구현 필요)

```dart
// 플랫폼별 네이티브 코드에서 핀닝 구현 후
// MethodChannel을 통해 Flutter에서 호출

class SecureApiClient {
  static const platform = MethodChannel('com.example.app/ssl_pinning');

  Future<String> secureRequest(String url) async {
    try {
      final result = await platform.invokeMethod('secureRequest', {
        'url': url,
        'method': 'GET',
      });
      return result;
    } on PlatformException catch (e) {
      throw Exception('Secure request failed: ${e.message}');
    }
  }
}
```

---

## 장단점

### 장점

| 장점 | 설명 |
|------|------|
| **MITM 공격 방지** | 가짜 인증서를 사용한 중간자 공격 차단 |
| **손상된 CA 보호** | CA가 해킹되어도 앱은 안전 |
| **규정 준수** | 금융, 의료 등 높은 보안 요구 산업의 규정 충족 |
| **데이터 무결성** | 통신 데이터의 변조 방지 |
| **사용자 신뢰** | 민감한 정보를 다루는 앱의 신뢰성 향상 |

### 단점

| 단점 | 설명 | 완화 방법 |
|------|------|----------|
| **인증서 갱신 문제** | 인증서 만료 시 앱이 동작하지 않음 | 백업 핀 사용, 충분한 갱신 기간 확보 |
| **운영 복잡성** | 인증서 관리 프로세스 필요 | 자동화된 모니터링 시스템 구축 |
| **앱 업데이트 필요** | 핀 변경 시 앱 업데이트 배포 필요 | 긴 인증서 유효기간, 원격 핀 업데이트 고려 |
| **디버깅 어려움** | 개발/테스트 환경에서 프록시 사용 불가 | Debug 빌드에서 핀닝 비활성화 |
| **CDN 호환성** | 일부 CDN에서 인증서가 자주 변경됨 | CDN 제공자와 협의, 공개키 핀닝 사용 |

---

## 베스트 프랙티스

### 1. 백업 핀 필수 포함

```
권장: 최소 2개의 핀 (Primary + Backup)

┌─────────────────────────────────────────────────────────────────┐
│  Primary Pin    │ 현재 사용 중인 인증서/키                       │
│  Backup Pin 1   │ 다음 갱신 예정 인증서/키                       │
│  Backup Pin 2   │ 비상용 (다른 CA에서 발급받은 인증서)            │
└─────────────────────────────────────────────────────────────────┘

백업 핀이 없으면:
• 인증서 만료 시 앱 완전 중단
• 긴급 앱 업데이트 필요 (앱스토어 심사 시간 고려)
```

### 2. 핀 갱신 계획 수립

```
인증서 갱신 타임라인 예시:

Day 0      : 새 인증서 발급 (기존 + 새 인증서 모두 유효)
Day 1-30   : 새 핀을 포함한 앱 버전 배포
Day 31-60  : 대부분의 사용자가 새 앱으로 업데이트
Day 61     : 기존 인증서 만료
Day 62+    : 이전 핀 제거한 앱 버전 배포 (선택사항)

최소 2개월의 여유 기간 확보 권장
```

### 3. 환경별 핀닝 설정

```swift
// iOS 예시
#if DEBUG
    // 개발 환경: 핀닝 비활성화 또는 개발용 핀 사용
    let pinnedHashes: Set<String> = []
#else
    // 프로덕션: 실제 서버 핀 사용
    let pinnedHashes: Set<String> = [
        "sha256/ProductionPrimaryPin...",
        "sha256/ProductionBackupPin..."
    ]
#endif
```

### 4. 모니터링 및 알림

```
모니터링 항목:
• 인증서 만료일 (최소 60일 전 알림)
• 핀닝 실패율 (비정상적 증가 감지)
• 앱 버전별 핀 호환성

알림 설정:
• 인증서 만료 90일 전: 정보성 알림
• 인증서 만료 60일 전: 경고 알림
• 인증서 만료 30일 전: 긴급 알림
• 핀닝 실패율 1% 초과: 즉시 조사
```

### 5. Intermediate CA 핀닝 권장

```
핀닝 대상 선택:

┌──────────────┬────────────┬────────────┬─────────────────────┐
│   대상       │  보안 수준  │   유연성   │       권장도         │
├──────────────┼────────────┼────────────┼─────────────────────┤
│ Root CA      │    낮음    │    높음    │ ❌ 권장하지 않음     │
│ Intermediate │    높음    │    중간    │ ✅ 가장 권장         │
│ Leaf Cert    │   매우높음  │    낮음    │ ⚠️ 높은 보안 요구 시 │
└──────────────┴────────────┴────────────┴─────────────────────┘

Intermediate CA 핀닝이 권장되는 이유:
• Leaf보다 갱신 주기가 길어 운영 부담 감소
• Root보다 보안 수준이 높음
• 같은 Intermediate CA로 여러 인증서 발급 가능
```

### 6. 공개키 핀닝 선호

```
공개키(SPKI) 핀닝의 장점:
• 인증서 갱신 시 같은 키 쌍 재사용 가능
• 인증서 전체보다 작은 데이터 (약 300 bytes)
• 더 유연한 인증서 운영 가능

공개키 추출 명령어:
openssl x509 -in certificate.pem -pubkey -noout | \
openssl pkey -pubin -outform DER | \
openssl dgst -sha256 -binary | \
base64
```

---

## 주의사항

### 1. 핀닝 실패 시 처리

```swift
// 잘못된 예: 핀닝 실패를 무시
func handlePinningFailure() {
    // ❌ 절대 하지 말 것: 실패해도 연결 허용
    allowConnection = true
}

// 올바른 예: 적절한 오류 처리
func handlePinningFailure() {
    // ✅ 연결 차단 및 사용자에게 알림
    connectionAllowed = false
    showSecurityAlert()
    logSecurityEvent()
}
```

### 2. 하드코딩 주의

```
핀 정보 관리:
• 핀을 코드에 직접 하드코딩하는 것은 피하기 어려움
• 하지만 관리 용이성을 위해 별도 설정 파일로 분리 권장
• 핀 변경 시 영향받는 코드 최소화

안전한 관리 방법:
• 핀 정보를 상수로 정의
• 핀 목록을 중앙 집중화
• 변경 이력 관리 (버전 관리 시스템 활용)
```

### 3. 테스트 환경 고려

```
개발/테스트 시 고려사항:
• Charles Proxy, mitmproxy 등 디버깅 도구 사용 불가
• Debug 빌드에서 핀닝 비활성화 옵션 제공
• 테스트 서버용 별도 핀 설정

⚠️ 중요: 프로덕션 빌드에서는 반드시 핀닝 활성화
```

### 4. 앱 업데이트 강제 메커니즘

```
핀 변경이 불가피한 경우를 대비:
• 앱 내 강제 업데이트 메커니즘 구현
• 최소 지원 버전 서버에서 관리
• 구버전 앱 사용자에게 업데이트 안내

┌─────────────────────────────────────────────────────────────────┐
│                     강제 업데이트 흐름                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  앱 시작 → 버전 체크 API 호출 (핀닝 적용 전) → 버전 확인         │
│                                                                 │
│  if (현재버전 < 최소버전) {                                      │
│      강제 업데이트 화면 표시                                     │
│      앱스토어로 이동                                            │
│  }                                                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5. 인증서 투명성 (Certificate Transparency) 병행

```
CT(Certificate Transparency)란?
• 발급된 모든 인증서를 공개 로그에 기록
• 잘못 발급된 인증서 탐지 가능
• 핀닝과 함께 사용하면 보안 강화

iOS: App Transport Security에서 기본 지원
Android: Network Security Config에서 설정 가능
```

---

## 핀 정보 추출 방법

### 서버 인증서에서 공개키 해시 추출

```bash
# 1. 서버에서 인증서 다운로드
openssl s_client -connect api.example.com:443 -servername api.example.com \
    < /dev/null 2>/dev/null | openssl x509 -outform PEM > server.pem

# 2. 공개키 해시 추출 (SHA-256, Base64)
openssl x509 -in server.pem -pubkey -noout | \
    openssl pkey -pubin -outform DER | \
    openssl dgst -sha256 -binary | \
    base64

# 결과 예시: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
```

### 인증서 체인 전체 핀 추출

```bash
# 전체 체인의 핀 추출
openssl s_client -connect api.example.com:443 -servername api.example.com \
    -showcerts < /dev/null 2>/dev/null | \
    awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ print }' | \
    while openssl x509 -outform PEM 2>/dev/null; do :; done | \
    openssl x509 -pubkey -noout | \
    openssl pkey -pubin -outform DER | \
    openssl dgst -sha256 -binary | \
    base64
```

### 온라인 도구

- **SSL Labs**: https://www.ssllabs.com/ssltest/
- **Report URI**: https://report-uri.com/home/pkp_hash

---

## 요약

| 항목 | 권장 사항 |
|------|----------|
| 핀닝 방식 | 공개키(SPKI) 핀닝 |
| 핀닝 대상 | Intermediate CA |
| 백업 핀 | 최소 2개 (Primary + Backup) |
| 해시 알고리즘 | SHA-256 |
| 갱신 계획 | 최소 60일 전 새 핀 배포 |
| 환경 분리 | Debug 빌드에서 선택적 비활성화 |
| 모니터링 | 인증서 만료일, 핀닝 실패율 추적 |

인증서 핀닝은 모바일 앱 보안의 중요한 계층입니다. 올바르게 구현하면 MITM 공격으로부터 사용자를 보호할 수 있지만, 잘못 관리하면 앱 장애의 원인이 될 수 있습니다. 백업 핀을 포함하고, 충분한 갱신 기간을 확보하며, 철저한 모니터링을 통해 안전하게 운영하시기 바랍니다.

---

## 프로젝트 구현 현황

### 구조

```
Core/Security/
├── SSLPinningDelegate.swift    ← URLSessionDelegate (SPKI 공개 키 피닝)
├── KeychainManager.swift       ← Keychain 기반 안전한 데이터 저장
└── SecureCookieStorage.swift   ← Keychain 연동 쿠키 저장소

Core/Networking/
├── APIEndpoint.swift           ← pinnedDomain, pinnedKeyHashes 설정
└── NetworkManager.swift        ← URLSession에 SSLPinningDelegate 연결
```

### 핀닝 흐름

```
NetworkManager.init()
  ↓
URLSession(delegate: SSLPinningDelegate)
  ↓ HTTPS 요청 시
urlSession(_:didReceive:completionHandler:)
  ↓
도메인 확인 (pinnedDomain == challenge.host)
  ↓
pinnedKeyHashes가 비어있으면 → 기본 검증 (개발 환경)
  ↓
SecTrustCopyCertificateChain → 인증서 체인 추출
  ↓
SecCertificateCopyKey → 각 인증서의 공개 키 추출
  ↓
SHA256 해시 → Base64 인코딩
  ↓
pinnedKeyHashes 배열에 일치하는 해시 존재?
  ├── YES → .useCredential (연결 허용)
  └── NO  → .cancelAuthenticationChallenge (연결 거부)
```

### 설정 위치

`APIEndpoint.swift`의 `APIConfiguration`:

```swift
struct APIConfiguration {
    static let pinnedDomain = "hsjung.asuscomm.com"

    static let pinnedKeyHashes: [String] = [
        // TODO: 프로덕션 서버 공개 키 해시 추가
        // "AAAA...=" // Primary
        // "BBBB...=" // Backup
    ]
}
```

### 프로덕션 적용 단계

1. **서버 공개 키 해시 추출**

```bash
openssl s_client -connect hsjung.asuscomm.com:443 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform DER | \
  openssl dgst -sha256 -binary | base64
```

2. **백업 키 해시 생성** (다른 CA 또는 다음 갱신용 키)

```bash
openssl req -new -newkey rsa:2048 -nodes -keyout backup.key -out backup.csr
openssl pkey -in backup.key -pubout -outform DER | \
  openssl dgst -sha256 -binary | base64
```

3. **`APIConfiguration.pinnedKeyHashes`에 추가**

```swift
static let pinnedKeyHashes: [String] = [
    "실제_Primary_해시=",
    "실제_Backup_해시="
]
```

4. **테스트 후 배포**

### 현재 상태

| 항목 | 상태 |
|------|------|
| SSLPinningDelegate 구현 | 완료 |
| NetworkManager 연동 | 완료 |
| 피닝 해시 설정 | 미설정 (빈 배열 = 피닝 비활성화) |
| 프로덕션 적용 | 해시 추가 후 활성화 필요 |
