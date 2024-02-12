import tkinter as tk
from tkinter import filedialog
from PIL import Image, ImageTk
import numpy as np
from datetime import datetime
import subprocess
import re
from random import choice

# logical part

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

def write_source_image(image_path: str, processor: list) :
    matrix1 = picture_to_matrix(image_path)
    list1 = []
    file = open ("image1.txt", "w")
    file.write("1000\n")
    for a in matrix1 :
        for b in a :
            file.write(f"{b} ")
            list1.append(b)
        file.write("\n")

    for a in processor:
        file.write(f"{a} ")
    file.write("\n")
    file.close()
    
def assembly_process() -> float:
    assembly_start_time = datetime.now().timestamp()
    command = "bash -c \"./run.sh main_code < image1.txt > image_assembly.txt\""
    subprocess.run(command, shell=True)
    assembly_finish_time = datetime.now().timestamp()
    image_assembly = open("image_assembly.txt", "r")
    text = image_assembly.read()
    pattern = r'-?\b\d+(?:\.\d+)?\b'
    assembly_matrix = re.findall(pattern, text)
    assembly_matrix = [float(num) for num in assembly_matrix]
    assembly_matrix = list_to_matrix(assembly_matrix)
    matrix_to_picture(assembly_matrix, "image_assembly.jpg")
    return assembly_finish_time - assembly_start_time

def python_process() -> float:
    python_start_time = datetime.now().timestamp()
    image_file = open("image1.txt", "r")
    image_python = open("image_python.txt", "w")
    text = image_file.read()
    processor = []
    pattern = r'-?\b\d+(?:\.\d+)?\b'
    list1 = re.findall(pattern, text)

    list2 = []
    for i in range(1, len(list1)) :
        num = float(list1[i])
        if i < len(list1) - 9 :
            list2.append(num)
        else :
            processor.append(num)
            
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
                    sum += list2[(i+k)*1000 + (j+z)] * processor[3*k + z + 4]
                    z+=1
                k+=1
            
            python_matrix.append(sum)
            image_python.write(f"{sum} ")
            j+=1
        image_python.write("\n")
        i+=1
    image_python.close()
    python_finish_time = datetime.now().timestamp()
    python_matrix = list_to_matrix(python_matrix)
    matrix_to_picture(python_matrix, "image_python.jpg")
    return python_finish_time - python_start_time


# graphical part

def choose_file():
    check_labels(1)
    file_path = filedialog.askopenfilename()
    if file_path:
        open_image(file_path)
    label.info = file_path
        
def open_image(file_path) :
    image = Image.open(file_path)
    label_width = 600
    label_height = 600
    image = image.resize((label_width, label_height), Image.FIXED)
    photo = ImageTk.PhotoImage(image)
    label.config(image=photo)
    label.image = photo
    label.pack()
    
def add_text(context: str) :
    check_labels(3)
    label1 = tk.Label(root, text=context)
    label1.pack()
    
def check_labels(limit) :
    all_widgets = root.winfo_children()
    label_widgets = [widget for widget in all_widgets if isinstance(widget, tk.Label)]
    if len(label_widgets) >= limit :
        for i in range(1,len(label_widgets)) :
            label_widgets[i].destroy()
        
processors = [[0,-1,0,-1,5,-1,0,-1,0],[0.0625,0.125,0.0625,0.125,0.25,0.125,0.0625,0.125,0.0625],[-2,-1,0,-1,1,1,0,1,2],[-1,-1,-1,-1,8,-1,-1,-1,-1]]        
        
def process(mode: int) :
    processor = processors[mode]
    image_path = label.info
    write_source_image(image_path, processor)
    assembly_time = assembly_process()
    open_image("image_assembly.jpg")
    add_text(f"assembly time: {assembly_time}")
    python_time = python_process()
    add_text(f"python time: {python_time}")
    
def luck_process() :
    check_labels(1)
    processor = choice(processors)
    image_path = label.info
    write_source_image(image_path, processor)
    assembly_time = assembly_process()
    open_image("image_assembly.jpg")

root = tk.Tk()
root.title("File Chooser and Image Display")
root.state('zoomed')

button_frame = tk.Frame(root)
button_frame.pack(side=tk.TOP, padx=10, pady=10)

blank_label = tk.Label(button_frame, text="")
blank_label.pack(side=tk.LEFT, padx=10)

choose_button = tk.Button(button_frame, text="Choose File", command=choose_file)
choose_button.pack(side=tk.LEFT)

choice1_button = tk.Button(button_frame, text="Sharpen", command= lambda: process(0))
choice1_button.pack(side=tk.LEFT, padx=5)
choice2_button = tk.Button(button_frame, text="Blur", command=lambda: process(1))
choice2_button.pack(side=tk.LEFT, padx=5)
choice3_button = tk.Button(button_frame, text="Emboss", command=lambda: process(2))
choice3_button.pack(side=tk.LEFT, padx=5)
choice4_button = tk.Button(button_frame, text="Outline", command=lambda: process(3))
choice4_button.pack(side=tk.LEFT, padx=5)
choice5_button = tk.Button(button_frame, text="Luck", command=luck_process)
choice5_button.pack(side=tk.LEFT, padx=5)


label = tk.Label(root)

root.mainloop()