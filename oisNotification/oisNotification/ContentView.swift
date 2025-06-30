import SwiftUI
import MSAL
import SwiftSoup

struct NotDetay: Codable, Hashable {
    let tur: String
    let etkiOrani: String
    let puan: String
    let tarih: String
}

struct DersModel: Codable, Hashable {
    let kod: String
    let ad: String
    let harfNotu: String
    let basariPuani: String
    let notlar: [NotDetay]
}

struct ContentView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var captchaCode = ""
    @State private var captchaImage: UIImage? = nil
    @State private var sessionCookie = ""
    @State private var gunlukSifre = ""
    @State private var grades: [DersModel] = []
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var isLoggedInStep1 = false
    @State private var isLoggedInStep2 = false
    @State private var didAppear = false // Captcha sadece ilk açılışta otomatik yüklensin

    // MSAL ayarları
    private let kRedirectUri = "msauth.eyupaydin.oisNotification://auth"
    private let clientId = "99beb4a7-a1e0-44b9-bbf1-71924d4155b4"
    private let authorityUrl = "https://login.microsoftonline.com/de65fda5-7a6d-400c-b2a5-ac255787cfae"

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 28) {
                Text("OIS Mobil Giriş")
                    .font(.largeTitle).bold()
                    .foregroundColor(.blue)
                    .padding(.top, 10)

                if isLoading {
                    ProgressView("Lütfen bekleyin...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.3)
                        .padding()
                } else if !isLoggedInStep1 {
                    VStack(spacing: 16) {
                        TextField("Kullanıcı Adı", text: $username)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .disabled(isLoading)

                        SecureField("Şifre", text: $password)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .disabled(isLoading)

                        if let image = captchaImage {
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 120, height: 48)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        } else {
                            Button("Captcha Yenile", action: fetchCaptcha)
                                .padding(.vertical, 4)
                        }

                        HStack {
                            TextField("Captcha", text: $captchaCode)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .disabled(isLoading)
                            Button(action: fetchCaptcha) {
                                Image(systemName: "arrow.clockwise")
                            }
                        }

                        Button(action: loginStep1) {
                            HStack {
                                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                Text("OIS'e Giriş Yap")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                        .disabled(isLoading)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(18)
                    .shadow(radius: 8)
                    .onAppear {
                        if !didAppear {
                            fetchCaptcha()
                            didAppear = true
                        }
                    }
                } else if !isLoggedInStep2 {
                    VStack(spacing: 18) {
                        Image(systemName: "envelope.open.fill")
                            .resizable()
                            .frame(width: 60, height: 48)
                            .foregroundColor(.green)
                        Text("OIS giriş başarılı! Şimdi okul maili ile günlük şifreyi çek.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        Button(action: authenticateWithMSAL) {
                            HStack {
                                Image(systemName: "mail")
                                Text("Mailden Günlük Şifreyi Al")
                                    .bold()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                        .disabled(isLoading)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(18)
                    .shadow(radius: 8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notlar")
                            .font(.title2).bold()
                            .foregroundColor(.blue)
                            .padding(.bottom, 4)
                        if grades.isEmpty {
                            Text("Not bulunamadı.")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView {
                                VStack(spacing: 18) {
                                    ForEach(grades.uniqued(by: { $0.kod }), id: \.kod) { ders in
                                        VStack(alignment: .leading, spacing: 10) {
                                            // Ders başlığı ve genel bilgiler
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text("\(ders.kod) - \(ders.ad)")
                                                        .font(.headline)
                                                        .foregroundColor(.blue)
                                                    HStack(spacing: 16) {
                                                        Label("Harf Notu: \(ders.harfNotu)", systemImage: "character.book.closed")
                                                            .font(.subheadline)
                                                            .foregroundColor(.purple)
                                                        Label("Başarı Puanı: \(ders.basariPuani)", systemImage: "star.fill")
                                                            .font(.subheadline)
                                                            .foregroundColor(.orange)
                                                    }
                                                }
                                                Spacer()
                                            }
                                            .padding(.bottom, 4)

                                            // Not detayları başlık
                                            if !ders.notlar.isEmpty {
                                                ScrollView(.horizontal, showsIndicators: false) {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack(alignment: .bottom) {
                                                            Text("Etki").font(.caption).bold().frame(width: 55, alignment: .leading)
                                                            Text("Tür").font(.caption).bold().frame(width: 90, alignment: .leading)
                                                            Text("Puan").font(.caption).bold().frame(width: 50, alignment: .leading)
                                                            Text("Tarih").font(.caption).bold().frame(width: 90, alignment: .leading)
                                                            Spacer()
                                                        }
                                                        .foregroundColor(.secondary)
                                                        Divider()
                                                        ForEach(ders.notlar, id: \.self) { not in
                                                            HStack(alignment: .center) {
                                                                Text(not.etkiOrani)
                                                                    .font(.caption)
                                                                    .frame(width: 55, alignment: .leading)
                                                                Text(not.tur)
                                                                    .font(.caption)
                                                                    .frame(width: 90, alignment: .leading)
                                                                Text(not.puan)
                                                                    .font(.caption)
                                                                    .frame(width: 50, alignment: .leading)
                                                                Text(not.tarih)
                                                                    .font(.caption2)
                                                                    .foregroundColor(.secondary)
                                                                    .frame(width: 90, alignment: .leading)
                                                                Spacer()
                                                            }
                                                            .padding(.vertical, 2)
                                                        }
                                                    }
                                                    .padding(.top, 4)
                                                }
                                            } else {
                                                Text("Not detayı bulunamadı.")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                        .cornerRadius(14)
                                        .shadow(color: Color(.systemGray4), radius: 2, x: 0, y: 1)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(18)
                    .shadow(radius: 8)
                }

                if !gunlukSifre.isEmpty {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                        Text("Günlük Şifre: ")
                            .bold()
                        Text(gunlukSifre)
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }

                if !errorMessage.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding()
        }
    }

    // 1. Captcha görselini çek
    func fetchCaptcha() {
        print("fetchCaptcha çağrıldı")
        isLoading = true
        errorMessage = ""
        let url = URL(string: "https://ois.istun.edu.tr/auth/captcha")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                print("fetchCaptcha tamamlandı, error: \(String(describing: error))")
                self.isLoading = false
                if let error = error {
                    print("Captcha alınamadı: \(error.localizedDescription)")
                    self.errorMessage = "Captcha alınamadı: \(error.localizedDescription)"
                    self.captchaImage = nil
                    return
                }
                guard let data = data, let image = UIImage(data: data) else {
                    print("Captcha alınamadı, data veya image nil")
                    self.errorMessage = "Captcha alınamadı."
                    self.captchaImage = nil
                    return
                }
                print("Captcha başarıyla alındı")
                self.captchaImage = image
                // PHPSESSID çerezini al
                if let httpResponse = response as? HTTPURLResponse,
                   let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String,
                   let phpsessid = setCookie.components(separatedBy: ";").first(where: { $0.contains("PHPSESSID") }) {
                    self.sessionCookie = phpsessid
                }
            }
        }
        task.resume()
    }

    // 2. OIS'e giriş (kullanıcı adı, şifre, captcha)
    func loginStep1() {
        guard !username.isEmpty && !password.isEmpty && !captchaCode.isEmpty else {
            errorMessage = "Tüm alanları doldurun."
            return
        }
        isLoading = true
        errorMessage = ""
        let url = URL(string: "https://ois.istun.edu.tr/auth/login/ln/tr")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
        let bodyString = "tip=2&kullanici_adi=\(username)&kullanici_sifre=\(password)&captcha=\(captchaCode)"
        request.httpBody = bodyString.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Sunucu yanıtı alınamadı."
                    return
                }
                // Login sonrası yeni bir Set-Cookie varsa sessionCookie'yi güncelle
                if let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String,
                   let phpsessid = setCookie.components(separatedBy: ";").first(where: { $0.contains("PHPSESSID") }) {
                    self.sessionCookie = phpsessid
                }
                if httpResponse.statusCode == 200 {
                    self.isLoggedInStep1 = true
                    self.errorMessage = ""
                } else {
                    self.errorMessage = "Giriş başarısız. Bilgileri ve captcha'yı kontrol edin."
                    self.fetchCaptcha()
                }
            }
        }.resume()
    }

    // 3. MSAL ile mailden günlük şifreyi çek
    func authenticateWithMSAL() {
        isLoading = true
        errorMessage = ""
        let authority = try! MSALAuthority(url: URL(string: authorityUrl)!)
        let config = MSALPublicClientApplicationConfig(clientId: clientId, redirectUri: kRedirectUri, authority: authority)
        let application = try! MSALPublicClientApplication(configuration: config)
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.rootViewController else {
                self.errorMessage = "Root view controller bulunamadı. Lütfen uygulamayı kapatıp tekrar deneyin."
                self.isLoading = false
                return
            }
            let webParameters = MSALWebviewParameters(authPresentationViewController: rootVC)
            let parameters = MSALInteractiveTokenParameters(scopes: ["Mail.Read"], webviewParameters: webParameters)
            application.acquireToken(with: parameters) { result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Mail oturum açma hatası: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }
                guard let result = result else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Mail oturum açma sonucu alınamadı."
                        self.isLoading = false
                    }
                    return
                }
                DispatchQueue.main.async {
                    self.errorMessage = ""
                }
                self.fetchGunlukSifreFromMail(token: result.accessToken)
            }
        }
    }

    // 4. Mailden günlük şifreyi bul
    func fetchGunlukSifreFromMail(token: String) {
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages?$top=10&$orderby=receivedDateTime desc&$select=subject,body") else {
            DispatchQueue.main.async {
                self.errorMessage = "Mail API URL hatası."
                self.isLoading = false
            }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Mail mesajları alınırken hata: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "Mail mesajları alınamadı."
                    self.isLoading = false
                }
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let value = json["value"] as? [[String: Any]] {
                    let gunlukSifreMailleri = value.filter { ($0["subject"] as? String)?.contains("Gunluk Sifre") ?? false }
                    if let ilkMail = gunlukSifreMailleri.first,
                       let body = (ilkMail["body"] as? [String: Any])?["content"] as? String,
                       let sifre = extractSifre(from: body) {
                        DispatchQueue.main.async {
                            self.gunlukSifre = sifre
                            self.errorMessage = ""
                        }
                        self.loginStep2WithGunlukSifre(sifre: sifre)
                    } else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Gunluk Sifre konulu mail bulunamadı veya şifre çıkarılamadı."
                            self.isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Mail JSON çözümlenemedi."
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Mail JSON parse hatası: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }.resume()
    }

    // 5. Günlük şifre ile ikinci aşama giriş
    func loginStep2WithGunlukSifre(sifre: String) {
        isLoading = true
        let url = URL(string: "https://ois.istun.edu.tr/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
        let bodyString = "akilli_sifre=\(sifre)"
        request.httpBody = bodyString.data(using: .utf8)
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Sunucu yanıtı alınamadı."
                    return
                }
                // 2. aşama login sonrası yeni bir Set-Cookie varsa sessionCookie'yi güncelle
                if let setCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String,
                   let phpsessid = setCookie.components(separatedBy: ";").first(where: { $0.contains("PHPSESSID") }) {
                    self.sessionCookie = phpsessid
                }
                if httpResponse.statusCode == 200 {
                    self.isLoggedInStep2 = true
                    self.errorMessage = ""
                    self.fetchGrades()
                } else {
                    self.errorMessage = "Günlük şifre ile giriş başarısız."
                }
            }
        }.resume()
    }

    // 6. Notları çek
    func fetchGrades() {
        isLoading = true
        let url = URL(string: "https://ois.istun.edu.tr/ogrenciler/belge/sinavsonuc")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(sessionCookie, forHTTPHeaderField: "Cookie")
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                self.isLoading = false
                guard let data = data, let html = String(data: data, encoding: .utf8) else {
                    self.errorMessage = "Notlar alınamadı."
                    return
                }
                do {
                    let doc = try SwiftSoup.parse(html)
                    let dersKutular = try doc.select("td[colspan=5][style*=border-color]")
                    var dersler: [DersModel] = []
                    for dersKutu in dersKutular.array() {
                        do {
                            guard let h3 = try? dersKutu.select("h3").first() else { continue }
                            let h3Text = try h3.text().trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !h3Text.isEmpty else { continue }
                            let dersAdiRaw = h3Text
                            let kodAd = dersAdiRaw.components(separatedBy: " - ")
                            let kod = kodAd.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            let ad = kodAd.dropFirst().joined(separator: " - ").trimmingCharacters(in: .whitespacesAndNewlines)
                            // Sonraki <tr> dersin not tablosu başlığı (içinde harf notu ve başarı puanı var)
                            guard let trBaslik = try dersKutu.parent()?.nextElementSibling() else { continue }
                            let ths = try trBaslik.select("th")
                            var harfNotu = ""
                            var basariPuani = ""
                            if ths.size() > 1 {
                                let h3s = try ths[1].select("h3")
                                if h3s.size() > 0 {
                                    harfNotu = try h3s[0].text().trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                                if h3s.size() > 1 {
                                    basariPuani = try h3s[1].text().replacingOccurrences(of: "Başarı Puanı:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                                }
                            }
                            // Sonraki <tr> ler not satırları, bir sonraki ders kutusuna kadar
                            var notlar: [NotDetay] = []
                            var tr = try trBaslik.nextElementSibling()
                            while let row = tr {
                                // Eğer yeni ders kutusu başladıysa veya boş satırsa kır
                                if let td = try? row.select("td[colspan=5][style*=border-color]"), td.size() > 0 { break }
                                let tds = try row.select("td")
                                if tds.size() == 4 {
                                    let etkiOrani = try tds[0].text().trimmingCharacters(in: .whitespacesAndNewlines)
                                    let tur = try tds[1].text().trimmingCharacters(in: .whitespacesAndNewlines)
                                    let puan = try tds[2].text().trimmingCharacters(in: .whitespacesAndNewlines)
                                    let tarih = try tds[3].text().trimmingCharacters(in: .whitespacesAndNewlines)
                                    notlar.append(NotDetay(tur: tur, etkiOrani: etkiOrani, puan: puan, tarih: tarih))
                                }
                                // Eğer satırda hiç td yoksa veya yeni ders kutusu ise kır
                                if tds.size() == 0 { break }
                                tr = try row.nextElementSibling()
                            }
                            dersler.append(DersModel(kod: kod, ad: ad, harfNotu: harfNotu, basariPuani: basariPuani, notlar: notlar))
                        } catch {
                            print("[HATA] Kutu parsellenemedi: \(error)")
                            continue
                        }
                    }
                    print("[DEBUG] Çekilen ders sayısı: \(dersler.count)")
                    self.grades = dersler
                    self.errorMessage = dersler.isEmpty ? "Not bulunamadı." : ""
                } catch {
                    self.errorMessage = "Notlar parse edilemedi: \(error.localizedDescription)"
                    self.grades = []
                }
            }
        }.resume()
    }

    // Mail içeriğinden 6 haneli şifreyi çıkar
    func extractSifre(from text: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: "\\b\\d{6}\\b")
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let range = Range(match.range, in: text) {
                return String(text[range])
            }
        } catch {
            print("Regex hatası: \(error)")
        }
        return nil
    }
}

// Root ViewController Extension
extension UIApplication {
    var rootViewController: UIViewController? {
        // En güncel ve güvenli yol: aktif window'dan root'u bul
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let root = window.rootViewController else {
            return nil
        }
        // En üstteki presented VC'yi bul
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}

// Helper extension for unique dersler
extension Array {
    func uniqued<T: Hashable>(by key: (Element) -> T) -> [Element] {
        var seen = Set<T>()
        return filter { seen.insert(key($0)).inserted }
    }
}
