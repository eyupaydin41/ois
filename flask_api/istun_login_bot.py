from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from utils.ocr_solver import solve_captcha
from utils.parse_grades import parse_grades_from_html
from PIL import Image
from io import BytesIO
import time

class OISBot:
    def __init__(self):
        options = webdriver.ChromeOptions()
        options.add_argument("--headless")
        self.driver = webdriver.Chrome(options=options)
        self.wait = WebDriverWait(self.driver, 10)

    def close(self):
        self.driver.quit()

    def login_with_captcha(self, username, password, max_attempts=5):
        self.driver.get("https://ois.istun.edu.tr/auth/login")
        try:
            self.wait.until(EC.element_to_be_clickable((By.XPATH, "//button[text()='Öğrenci']"))).click()
        except:
            pass

        for attempt in range(max_attempts):
            captcha_img = self.wait.until(EC.presence_of_element_located((By.ID, "img_captcha")))
            captcha_png = captcha_img.screenshot_as_png
            captcha_image = Image.open(BytesIO(captcha_png))
            captcha_guess = solve_captcha(captcha_image)

            if len(captcha_guess) < 4:
                continue

            self.wait.until(EC.presence_of_element_located((By.ID, "kullanici_adi"))).clear()
            self.wait.until(EC.presence_of_element_located((By.ID, "kullanici_adi"))).send_keys(username)

            self.wait.until(EC.presence_of_element_located((By.ID, "kullanici_sifre"))).clear()
            self.wait.until(EC.presence_of_element_located((By.ID, "kullanici_sifre"))).send_keys(password)

            self.wait.until(EC.presence_of_element_located((By.ID, "captcha"))).clear()
            self.wait.until(EC.presence_of_element_located((By.ID, "captcha"))).send_keys(captcha_guess)

            self.wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(text(), 'Giriş Yap')]"))).click()
            time.sleep(2)

            try:
                self.driver.find_element(By.XPATH, "//button[text()='Kapat']").click()
                continue
            except:
                return True
        return False

    def login_with_gunluk_sifre(self, daily_code):
        try:
            print(f"[DEBUG] Günlük şifreyle giriş yapılıyor: {daily_code}")
            input_field = self.wait.until(EC.presence_of_element_located((By.ID, "akilli_sifre")))
            input_field.clear()
            input_field.send_keys(daily_code)
            
            submit_button = self.wait.until(EC.element_to_be_clickable((By.ID, "submit")))
            submit_button.click()
            devam_et_buton = self.wait.until(
                EC.element_to_be_clickable((By.XPATH, "//input[@type='button' and @value='Devam Et']"))
            )
            devam_et_buton.click()
            time.sleep(2)
            print("[INFO] Devam Et butonuna tıklandı, URL:", self.driver.current_url)
            return True

        except Exception as e:
            print(f"'Devam Et' butonuna tıklanırken hata: {e}")
            return False

    def fetch_grades(self):
        try:
            self.wait.until(EC.presence_of_element_located((By.ID, "sidr-left7")))
            links = self.driver.find_elements(By.XPATH, "//a[@href='/ogrenciler/belge/sinavsonuc']")
            if not links:
                return []

            link = links[0]
            self.driver.execute_script("arguments[0].scrollIntoView(true);", link)
            time.sleep(0.5)
            self.driver.execute_script("arguments[0].click();", link)

            self.wait.until(EC.presence_of_element_located((By.TAG_NAME, "table")))
            html = self.driver.page_source

            return parse_grades_from_html(html)

        except Exception as e:
            print(f"[HATA] Notlar sayfasına erişilemedi: {e}")
            return []
