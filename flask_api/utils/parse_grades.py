from bs4 import BeautifulSoup

def parse_grades_from_html(html):
    soup = BeautifulSoup(html, "html.parser")
    dersler = []

    # Her dersin başlangıcı: <td colspan="5" style="border-color: white;">
    for ders_kutu in soup.find_all("td", colspan="5", style=lambda x: x and "border-color" in x):
        try:
            # 1. Satır: Ders adı
            h3 = ders_kutu.find("h3")
            if not h3:
                continue
            ders_adi_raw = h3.get_text(strip=True)
            if " - " in ders_adi_raw:
                kod, ad = ders_adi_raw.split(" - ", 1)
            else:
                kod, ad = ders_adi_raw, ""

            # Sonraki <tr> dersin not tablosu başlığı (içinde harf notu ve başarı puanı var)
            tr_baslik = ders_kutu.find_parent("tr").find_next_sibling("tr")
            ths = tr_baslik.find_all("th")
            # Harf notu ve başarı puanı, ikinci <th> içinde <h3> etiketlerinde
            harf_notu = ""
            basari_puani = ""
            if len(ths) > 1:
                h3s = ths[1].find_all("h3")
                if len(h3s) > 0:
                    harf_notu = h3s[0].get_text(strip=True)
                if len(h3s) > 1:
                    basari_puani = h3s[1].get_text(strip=True).replace("Başarı Puanı:", "").strip()

            # Sonraki <tr> ler not satırları, bir sonraki ders kutusuna kadar
            notlar = []
            tr = tr_baslik.find_next_sibling("tr")
            while tr:
                # Eğer yeni ders kutusu başladıysa veya boş satırsa kır
                td = tr.find("td", colspan="5", style=lambda x: x and "border-color" in x)
                if td or not tr.find_all("td"):
                    break
                tds = tr.find_all("td")
                if len(tds) == 4:
                    etki_orani = tds[0].get_text(strip=True)
                    tur = tds[1].get_text(strip=True)
                    puan = tds[2].get_text(strip=True)
                    tarih = tds[3].get_text(strip=True)
                    notlar.append({
                        "tur": tur,
                        "etki_orani": etki_orani,
                        "puan": puan,
                        "tarih": tarih
                    })
                tr = tr.find_next_sibling("tr")

            dersler.append({
                "kod": kod,
                "ad": ad,
                "harf_notu": harf_notu,
                "basari_puani": basari_puani,
                "notlar": notlar
            })
        except Exception as e:
            print(f"[HATA] Kutu parsellenemedi: {e}")
            continue

    print(dersler)
    return dersler