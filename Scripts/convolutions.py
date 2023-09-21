# Convolutions approach
# The idea is try to identify vertical and horizontal lines in order to build up the table structure 
import pdf2image
import scipy.ndimage as nd
from Scripts.ocr_functions import *

path = "./Examples/PDF-1.pdf"
imgs = pdf2image.convert_from_path(path)
img = imgs[3]

# Using convolutions to identify borders
## Generating gray-scale image
show_image(img)

gray_img = gray_image(img)
show_image(gray_img)

## Generating binary-scale image
bin_img = binary_image(img, thresh = 50)
show_image(bin_img)

## Vertical borders Kernel
kernel = np.array([[1,0,-1],[1,0,-1],[1,0,-1]])
img_v = nd.convolve(gray_img, kernel)
show_image(img_v)

## Horizontal borders Kernel
kernel = np.array([[1,1,1],[0,0,0],[-1,-1,-1]])
img_h = nd.convolve(gray_img, kernel)
show_image(img_h)

