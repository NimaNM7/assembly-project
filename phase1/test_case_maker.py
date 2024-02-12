# this code makes two n*n matrices and writes them in test-case.txt in our input format
# after that it writes the real answer of matrix1 * matrix2 which we must see in result.txt

import numpy as np

file = open('test-case.txt', "w") 

n = 500
A = np.random.randint(10, size=(n,n))
B = np.random.randint(10, size=(n,n))



print(A)
print(B)

# print(n)
file.write(f"{n}\n")
for a in A:
    for b in a :
        file.write(f"{b} ")
file.write("\n")
for b in B:
    for a in b :
        file.write(f"{a} ")
print()
C = np.dot(A,B)
file.close()
print(C)
