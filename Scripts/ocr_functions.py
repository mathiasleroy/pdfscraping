# import pdf2image
import matplotlib.pyplot as plt
import numpy as np
import cv2

def show_image(image):
    plt.figure(figsize=(8, 8))  # Adjust the figure size if needed
    plt.imshow(image)  # Display the first image (index 0)
    plt.axis('off')  # Turn off axis labels and ticks
    plt.show()

def gray_image(image):
    image_array = np.asarray(image)
    image_gray = cv2.cvtColor(image_array, cv2.COLOR_BGR2GRAY)
    return(image_gray)

def binary_image(image, thresh = 70):
    image_gray = gray_image(image)
    ret, bin_image = cv2.threshold(image_gray, thresh, 255, cv2.THRESH_BINARY)
    return(bin_image)




