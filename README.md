# Öğrenci Bilgi Sistemi (OIS) Mobil Uygulaması

Bu proje, SwiftUI ile yazılmış modern bir iOS uygulamasıdır. Amaç, İstanbul Sağlık ve Teknoloji Üniversitesi OIS (Öğrenci Bilgi Sistemi) üzerinden öğrenci notlarını ve sınav sonuçlarını güvenli şekilde mobilde görüntülemek ve günlük şifre işlemlerini otomatikleştirmektir.

---

## Özellikler
- OIS web arayüzüne doğrudan istek atarak notlarınızı ve sınav sonuçlarınızı otomatik çeker.
- Günlük şifreyi okul mailinizden otomatik olarak bulur (MSAL/Azure kimlik doğrulama ile).
- Notlar, ders başlıkları ve sınav detayları modern ve kaydırılabilir bir tablo olarak gösterilir.
- HTML parse işlemi SwiftSoup ile yapılır.
- Açıklanma tarihi, etki oranı, tür ve puan gibi tüm detaylar ekranda sunulur.

---

## Kurulum ve Çalıştırma

### Gereksinimler
- Xcode 14+
- Gerçek bir iOS cihaz veya simülatör

### Kurulum ve Çalıştırma
1. Proje klasörünü açın: `oisNotification/oisNotification.xcodeproj` dosyasını Xcode ile açın.
2. `ContentView.swift` dosyasındaki aşağıdaki alanları kendi ortamınıza göre güncelleyin:
    ```swift
    let kRedirectUri = "msauth.eyupaydin.oisNotification://auth"
    let clientId = "<Azure Client ID>"
    let authorityUrl = "https://login.microsoftonline.com/<Tenant ID>"
    ```
3. iPhone veya simülatör seçin ve çalıştırın.

---

## MSAL/Azure ve Redirect URI Ayarları

Uygulama Microsoft kimlik doğrulaması (MSAL) ile okul mailinden günlük şifreyi otomatik çeker. Kendi Azure hesabınızda kullanmak için:

1. Azure Portal’da uygulama kaydı oluşturun.
2. **Redirect URI** olarak: `msauth.eyupaydin.oisNotification://auth` (veya kendi URI’nızı) ekleyin.
3. Client ID ve Tenant ID’yi alın, `ContentView.swift` içinde güncelleyin.
4. info.plist > URL Types’a redirect URI scheme’ini ekleyin.
5. Azure’da uygulamanıza “Microsoft Graph” için `Mail.Read` izni verin.

---

## Notlar ve HTML Parse

- Uygulama, OIS web arayüzünden notları ve sınav sonuçlarını otomatik olarak çeker ve HTML’yi SwiftSoup ile parse eder.
- Notlar, ders başlıkları ve sınav detayları ekranda modern ve kaydırılabilir bir tablo olarak gösterilir.
- HTML parse işlemi, Python’daki BeautifulSoup mantığına benzer şekilde Swift’te uygulanmıştır.
- Açıklanma tarihi, etki oranı, tür ve puan gibi tüm detaylar ekranda yatay kaydırılabilir şekilde sunulur.

---

## Sık Karşılaşılan Sorunlar

- **MSAL ile girişte hata:**
  - Redirect URI ve info.plist ayarlarını kontrol edin.
  - Azure’da gerekli izinlerin tanımlı olduğundan emin olun.


---

## Katkı ve Lisans

Katkıda bulunmak için pull request gönderebilirsiniz. Lisans: MIT

---
