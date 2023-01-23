# Python code to
# demonstrate readlines()

# L = ["Geeks\n", "for\n", "Geeks\n"]

# writing to file
# file1 = open('myfile.txt', 'w')
# file1.writelines(L)
# file1.close()

# Using readlines()
from locale import atoi
from statistics import mean
import numpy
import matplotlib.pyplot as plt

period = 8
file_list = ['d7_single_real.txt']
f = open("d7_expanded.csv", "w")

for file in file_list:
    file1 = open(file, 'r')
    Lines = file1.readlines()

    count = 0
    # Strips the newline character
    for line in Lines:
        # count += 1
        # print("Line{}: {}".format(count, line.strip()))
        line2 = line.strip()
        arr = line2.split(",")
        # for i in range (20):
        #     print(str(i) +" "+arr[i])
        cycles = atoi(arr[0])
        count = atoi(arr[1])
        # print(cycles,count)
        for i in range(count):
            f.write(str(cycles)+"\n")

    # mu, sigma = 200, 25
    # n, bins, patches = plt.hist(cycles)
    # plt.show()


# file1 = open('results_d3_single_fpga', 'r')
# Lines = file1.readlines()
# cycles1= []

# count = 0
# # Strips the newline character
# for line in Lines:
#     # count += 1
#     # print("Line{}: {}".format(count, line.strip()))
#     line2 = line.strip()
#     arr = line2.split()
#     cycles1.append(atoi(arr[5]))

# file1 = open('results_d3_3fpga.txt', 'r')
# Lines = file1.readlines()
# cycles2= []

# count = 0
# # Strips the newline character
# for line in Lines:
#     # count += 1
#     # print("Line{}: {}".format(count, line.strip()))
#     line2 = line.strip()
#     arr = line2.split()
#     cycles2.append(atoi(arr[5]))

# bins = numpy.linspace(0, 500, 50)

# plt.hist(cycles2, bins, alpha=0.5, label='3 FPGA tree')
# plt.hist(cycles1, bins, alpha=0.5, label='single FPGA')
# plt.legend(loc='upper right')
# plt.show()
