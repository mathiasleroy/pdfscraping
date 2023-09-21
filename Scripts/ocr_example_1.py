# OCR with img2table - Example 1

from Scripts.ocr_functions import *
import pdf2image
from img2table.document import Image
from PIL import Image as PILImage
from img2table.ocr import TesseractOCR

path = "./Examples/PDF-1.pdf"
imgs = pdf2image.convert_from_path(path)
img = imgs[3]

## original image
img_path = './Images/PDF-1_orig.jpg'
table_path = './Tables/PDF-1_orig.xlsx'
img_array = np.asarray(img)  
borderless_tables = False               

## binarised image
# img_path = './Images/PDF-1_bin.jpg'
# table_path = './Tables/PDF-1_bin.xlsx'
# img_array = binary_image(img, thresh = 170) 
# borderless_tables = True

## gray-scaled image 
# img_path = './Images/PDF-1_gray.jpg'
# table_path = './Tables/PDF-1_gray.xlsx'
# img_array = gray_image(img)
# borderless_tables = False

## show and save image
show_image(img_array)
cv2.imwrite(img_path, img_array)


# table extraction
image = Image(src = img_path)
ocr = TesseractOCR(lang = "eng")
tables = image.extract_tables(ocr = ocr, borderless_tables = borderless_tables)
image.to_xlsx(table_path, ocr = ocr)