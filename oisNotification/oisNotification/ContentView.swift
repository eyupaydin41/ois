import SwiftUI
import MSAL

struct NotDetay: Codable, Hashable {
    let tur: String
    let etkiOrani: String
    let puan: String
    let tarih: String

    enum CodingKeys: String, CodingKey {
        case tur
        case etkiOrani = "etki_orani"
        case puan
        case tarih
    }
}

struct DersModel: Codable, Hashable {
    let kod: String
    let ad: String
    let harfNotu: String
    let basariPuani: String
    let notlar: [NotDetay]

    enum CodingKeys: String, CodingKey {
        case kod
        case ad
        case harfNotu = "harf_notu"
        case basariPuani = "basari_puani"
        case notlar
    }
}

struct ContentView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var gunlukSifre = ""
    @State private var accessToken = ""
    @State private var grades: [DersModel] = []
    @State private var errorMessage = ""
    @State private var isLoggedInStep1 = false
    @State private var isLoggedInStep2 = false
    @State private var isLoading = false

    private let backendURL = "http://192.168.1.115:5001" // API adresin

    private let kRedirectUri = "msauth.eyupaydin.oisNotification://auth"

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.white]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 28) {
                Text("Öğrenci Bilgi Sistemi")
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
                } else if !isLoggedInStep2 {
                    VStack(spacing: 18) {
                        Image(systemName: "envelope.open.fill")
                            .resizable()
                            .frame(width: 60, height: 48)
                            .foregroundColor(.green)
                        Text("OIS giriş başarılı! Şimdi okul maili ile giriş yap.")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        Button(action: authenticateWithMSAL) {
                            HStack {
                                Image(systemName: "mail")
                                Text("Okul Maili ile Giriş Yap")
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
                                VStack(spacing: 16) {
                                    ForEach(grades, id: \ .kod) { ders in
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("\(ders.kod)")
                                                    .font(.headline)
                                                    .foregroundColor(.purple)
                                                Text(ders.ad)
                                                    .font(.subheadline)
                                                    .foregroundColor(.primary)
                                            }
                                            HStack(spacing: 18) {
                                                Text("Harf Notu: ")
                                                    .font(.subheadline).bold()
                                                Text(ders.harfNotu)
                                                    .font(.subheadline)
                                                Text("Başarı Puanı: ")
                                                    .font(.subheadline).bold()
                                                Text(ders.basariPuani)
                                                    .font(.subheadline)
                                            }
                                            if !ders.notlar.isEmpty {
                                                Divider()
                                                VStack(alignment: .leading, spacing: 8) {
                                                    ForEach(ders.notlar, id: \ .tur) { not in
                                                        VStack(alignment: .leading, spacing: 2) {
                                                            Text(not.tur)
                                                                .font(.subheadline).bold()
                                                            Text("Etki Oranı: \(not.etkiOrani)")
                                                                .font(.caption2)
                                                                .foregroundColor(.secondary)
                                                            HStack {
                                                                Text("Puan: \(not.puan)")
                                                                    .font(.caption)
                                                                    .foregroundColor(.primary)
                                                                Spacer()
                                                                if !not.tarih.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                                    Text(not.tarih)
                                                                        .font(.caption2)
                                                                        .foregroundColor(.secondary)
                                                                }
                                                            }
                                                        }
                                                        .padding(10)
                                                        .background(Color(.systemGray6))
                                                        .cornerRadius(8)
                                                    }
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.white)
                                        .cornerRadius(14)
                                        .shadow(radius: 2)
                                    }
                                }
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

    func loginStep1() {
        guard !username.isEmpty && !password.isEmpty else {
            errorMessage = "Kullanıcı adı ve şifre boş olamaz."
            return
        }
        errorMessage = ""
        isLoading = true
        // API'ye kullanıcı adı ve şifreyi gönder
        guard let url = URL(string: "\(backendURL)/api/login") else {
            errorMessage = "Backend URL hatası."
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "İstek hatası: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            guard let data = data,
                  let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.errorMessage = "Sunucudan veri alınamadı."
                    self.isLoading = false
                }
                return
            }
            if let errorMsg = responseJSON["error"] as? String {
                DispatchQueue.main.async {
                    self.errorMessage = errorMsg
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoggedInStep1 = true
                    self.errorMessage = ""
                    self.isLoading = false
                }
            }
        }.resume()
    }

    func authenticateWithMSAL() {
        isLoading = true
        let clientId = "99beb4a7-a1e0-44b9-bbf1-71924d4155b4"
        let authority = try! MSALAuthority(url: URL(string: "https://login.microsoftonline.com/de65fda5-7a6d-400c-b2a5-ac255787cfae")!)
        let config = MSALPublicClientApplicationConfig(clientId: clientId,
                                                       redirectUri: kRedirectUri,
                                                       authority: authority)
        let application = try! MSALPublicClientApplication(configuration: config)
        guard let rootVC = UIApplication.shared.rootViewController else {
            errorMessage = "Root view controller bulunamadı."
            isLoading = false
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
                self.accessToken = result.accessToken
                self.errorMessage = ""
            }
            fetchMailMessages(token: result.accessToken)
        }
    }

    func fetchMailMessages(token: String) {
        guard let url = URL(string: "https://graph.microsoft.com/v1.0/me/messages?$top=5&$orderby=receivedDateTime desc&$select=subject,body") else {
            DispatchQueue.main.async {
                self.errorMessage = "Mail API URL hatası."
                self.isLoading = false
            }
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
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

                        sendGunlukSifreToAPI(sifre: sifre)
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

    func sendGunlukSifreToAPI(sifre: String) {
        guard let url = URL(string: "\(backendURL)/api/mail-login") else {
            errorMessage = "Backend mail-login URL hatası."
            isLoading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["gunluk_sifre": sifre]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Mail şifresi API isteği hatası: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            guard let data = data,
                  let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.errorMessage = "Mail şifresi API yanıtı alınamadı."
                    self.isLoading = false
                }
                return
            }
            if let errorMsg = responseJSON["error"] as? String {
                DispatchQueue.main.async {
                    self.errorMessage = errorMsg
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoggedInStep2 = true
                    self.errorMessage = ""
                    self.isLoading = false
                    if let gradesData = try? JSONSerialization.data(withJSONObject: responseJSON["grades"] ?? []),
                       let parsedGrades = try? JSONDecoder().decode([DersModel].self, from: gradesData) {
                        self.grades = parsedGrades
                    }
                }
            }
        }.resume()
    }

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
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}