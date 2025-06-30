import numpy as np
from PIL import Image
import easyocr

reader = easyocr.Reader(['en'], gpu=False)

def solve_captcha(pil_image):
    img_np = np.array(pil_image)
    result = reader.readtext(img_np, allowlist='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', detail=0)
    return ''.join(result).strip().lower() if result else ""
