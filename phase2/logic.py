# this code gets a picture and makes a txt file from its 1000x1000 matrix
# then it gets first image matrix from file and processes it to two files using
# convolution one time with our assembly code and then with python code which is exactly
# doing what our assembly code does. then it compares the time and saves the images
from PIL import Image
import numpy as np
import tkinter as tk
from tkinter import filedialog
from datetime import datetime
import subprocess
import re

def list_to_matrix(matrix: list) :
    matrix = np.array(matrix)
    matrix = matrix.reshape(998,998)
    return matrix

def matrix_to_picture(matrix, destination:str) :
    grayscale_image = Image.fromarray(matrix.astype(np.uint8))
    grayscale_image.save(destination)

def picture_to_matrix(source: str):
    image = Image.open(source)
    image_resized1 = image.resize((1000, 1000), Image.ADAPTIVE)
    grayscale_image = np.array(image_resized1.convert('L'))
    matrix = grayscale_image.astype(int)
    return matrix

root = tk.Tk()
root.withdraw()
image_path1 = filedialog.askopenfilename()
matrix1 = picture_to_matrix(image_path1)
list1 = []

file = open ("image1.txt", "w")
file.write("1000\n")
for a in matrix1 :
    for b in a :
        file.write(f"{b} ")
        list1.append(b)
    file.write("\n")

sharpen = [-2,-1,0,-1,1,1,0,1,2]
for a in sharpen:
    file.write(f"{a} ")
file.write("\n")
file.close()

assembly_start_time = datetime.now().timestamp()
command = "bash -c \"./run.sh main_code < image1.txt > image_assembly.txt\""
subprocess.run(command, shell=True)
assembly_finish_time = datetime.now().timestamp()

python_start_time = datetime.now().timestamp()
image_file = open("image1.txt", "r")
image_python = open("image_python.txt", "w")
text = image_file.read()
sharpen = []
pattern = r'-?\b\d+(?:\.\d+)?\b'
list1 = re.findall(pattern, text)

list2 = []
for i in range(1, len(list1)) :
    num = float(list1[i])
    if i < len(list1) - 9 :
        list2.append(num)
    else :
        sharpen.append(num)
        
python_matrix = []
i = 1
while i < 999 :
    j = 1
    while j < 999 :
        sum = 0
        k = -1
        while k < 2 :
            z = -1
            while z < 2 :
                sum += list2[(i+k)*1000 + (j+z)] * sharpen[3*k + z + 4]
                z+=1
            k+=1
        
        python_matrix.append(sum)
        image_python.write(f"{sum} ")
        j+=1
    image_python.write("\n")
    i+=1
image_python.close()
python_finish_time = datetime.now().timestamp()

image_assembly = open("image_assembly.txt", "r")
text = image_assembly.read()
pattern = r'-?\b\d+(?:\.\d+)?\b'
assembly_matrix = re.findall(pattern, text)
assembly_matrix = [float(num) for num in assembly_matrix]

python_matrix = list_to_matrix(python_matrix)
matrix_to_picture(python_matrix, "image_python.jpg")
assembly_matrix = list_to_matrix(assembly_matrix)
matrix_to_picture(assembly_matrix, "image_assembly.jpg")

print("python image matrix:")
print(python_matrix)
print("\nassembly image matrix:")
print(assembly_matrix)
print()

print(f"assembly run time: {assembly_finish_time - assembly_start_time}")
print(f"python run time: {python_finish_time - python_start_time}")
