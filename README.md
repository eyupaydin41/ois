# Öğrenci Bilgi Sistemi (OIS)

- Bu proje, Flask tabanlı bir backend API ve SwiftUI ile yazılmış bir iOS istemcisinden oluşur. 
- Amaç: Öğrenci notlarını güvenli şekilde görüntülemek ve günlük şifre işlemlerini otomatikleştirmektir.

---

## İçerik

- [Kurulum ve Çalıştırma](#kurulum-ve-çalıştırma)
- [Backend (Flask API)](#backend-flask-api)
- [iOS Uygulaması (SwiftUI)](#ios-uygulaması-swiftui)
- [MSAL/Azure ve Redirect URI Ayarları](#msalazure-ve-redirect-uri-ayarları)
- [Sık Karşılaşılan Sorunlar](#sık-karşılaşılan-sorunlar)
- [Katkı ve Lisans](#katkı-ve-lisans)

---

## Kurulum ve Çalıştırma

### 1. Backend (Flask API)

#### Gereksinimler
- Python 3.8+
- pip

#### Kurulum

```sh
cd flask_api
pip install -r requirements.txt
```

#### Çalıştırma

```sh
python3 app.py --host=0.0.0.0 --port=5001
```

> **Not:**  
> Bilgisayarınızın IP adresini öğrenmek için terminalde `ipconfig getifaddr en0` (Mac) veya `ipconfig` (Windows) komutunu kullanabilirsiniz.

---

### 2. iOS Uygulaması (SwiftUI)

#### Gereksinimler
- Xcode 14+
- Gerçek bir iOS cihaz veya simülatör

#### Kurulum ve Çalıştırma

1. Proje klasörünü açın:  
   `ois/ois.xcodeproj` dosyasını Xcode ile açın.
2. `ContentView.swift` dosyasındaki aşağıdaki değişkenleri kendi ortamınıza göre güncelleyin:
    ```swift
    private let backendURL = "http://<bilgisayar-ip-adresi>:5001"
    private let kRedirectUri = "msauth.eyupaydin.oisNotification://auth"
    ```
3. iPhone veya simülatör seçin ve çalıştırın.

---

## MSAL/Azure ve Redirect URI Ayarları

Uygulama Microsoft kimlik doğrulaması (MSAL) kullanmaktadır.  
Kendi Azure hesabınızda kullanmak için aşağıdaki adımları uygulayın:

### 1. Azure Portal’da Uygulama Kaydı Oluşturun

- Azure Portal’a girin: https://portal.azure.com/
- Azure Active Directory > App registrations > New registration
- Bir isim verin.
- **Redirect URI** olarak:  
  `msauth.eyupaydin.oisNotification://auth`  
  (veya kendi URI’nızı belirleyin)

### 2. Client ID ve Authority Bilgilerini Alın

- Kayıt sonrası “Application (client) ID” ve “Directory (tenant) ID”’yi not alın.
- `ContentView.swift` dosyasında aşağıdaki alanları güncelleyin:
    ```swift
    let clientId = "<Sizin Client ID'niz>"
    let authority = try! MSALAuthority(url: URL(string: "https://login.microsoftonline.com/<Sizin Tenant ID'niz>")!)
    ```

### 3. info.plist Ayarı

- Xcode’da `info.plist` dosyasını açın.
- “URL Types” bölümüne yeni bir item ekleyin.
- “URL Schemes” kısmına redirect URI’nızın başındaki scheme’i (ör: `msauth.eyupaydin.oisNotification`) ekleyin.

### 4. Gerekli API İzinleri

- Azure Portal’da uygulamanıza “Microsoft Graph” için gerekli izinleri (ör: `Mail.Read`) ekleyin.

---

## Sık Karşılaşılan Sorunlar

- **iOS cihazdan backend’e erişemiyorum:**  
  - Bilgisayar ve iPhone aynı Wi-Fi’da olmalı.
  - Backend’i `--host=0.0.0.0` ile başlatmalısınız.
  - Firewall veya ağ kısıtlamalarını kontrol edin.
- **Not Found hatası:**  
  - Doğru endpoint’e istek attığınızdan emin olun (ör: `/api/login`).
- **MSAL ile girişte hata:**  
  - Redirect URI ve info.plist ayarlarını kontrol edin.
  - Azure’da gerekli izinlerin tanımlı olduğundan emin olun.

---

## Katkı ve Lisans

Katkıda bulunmak için pull request gönderebilirsiniz.  
Lisans: MIT

---
