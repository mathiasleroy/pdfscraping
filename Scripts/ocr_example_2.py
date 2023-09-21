# OCR with img2table - Example 2

from Scripts.ocr_functions import *
import pdf2image
from img2table.document import Image
from PIL import Image as PILImage
from img2table.ocr import TesseractOCR

path = "./Examples/PDF-2.pdf"
imgs = pdf2image.convert_from_path(path)
img = imgs[6]

## page 6
img_path = './Images/PDF-2_6.jpg'
table_path = './Tables/PDF-2_6.xlsx'

img_array = np.asarray(img)
show_image(img_array)
cv2.imwrite(img_path, img_array)
borderless_tables = False

# Table extraction
image = Image(src = img_path)
ocr = TesseractOCR(lang = "ben")
tables = image.extract_tables(ocr = ocr, borderless_tables = borderless_tables)
image.to_xlsx(table_path, ocr = ocr)