from flask import Flask, request, jsonify
from istun_login_bot import OISBot

app = Flask(__name__)

bot = None

@app.route("/api/login", methods=["POST"])
def api_login():
    global bot
    data = request.json
    username = data.get("username")
    password = data.get("password")

    if not username or not password:
        return jsonify({"error": "username ve password zorunlu"}), 400

    bot = OISBot()
    success = bot.login_with_captcha(username, password)
    if not success:
        bot.close()
        bot = None
        return jsonify({"error": "OIS giriş başarısız veya captcha hatası"}), 401

    return jsonify({"message": "OIS giriş başarılı, lütfen mail ile giriş yapın."})

@app.route("/api/mail-login", methods=["POST"])
def api_mail_login():
    global bot
    if not bot:
        return jsonify({"error": "Önce /api/login endpoint'ini çağırmalısınız."}), 400

    data = request.json
    gunluk_sifre = data.get("gunluk_sifre")

    if not gunluk_sifre:
        return jsonify({"error": "gunluk_sifre zorunlu"}), 400

    success = bot.login_with_gunluk_sifre(gunluk_sifre)
    if not success:
        bot.close()
        bot = None
        return jsonify({"error": "Mail şifresi ile giriş başarısız"}), 401

    grades = bot.fetch_grades()
    bot.close()
    bot = None
    return jsonify({"message": "İkinci aşama başarılı", "grades": grades})

if __name__ == "__main__":
    app.run(debug=True)
