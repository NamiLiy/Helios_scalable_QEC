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
file_list = ['results_d13_t14_gpio_40.txt']

for file in file_list:
    file1 = open(file, 'r')
    Lines = file1.readlines()
    cycles= []

    count = 0
    # Strips the newline character
    for line in Lines:
        # count += 1
        # print("Line{}: {}".format(count, line.strip()))
        line2 = line.strip()
        arr = line2.split()
        cycles.append(atoi(arr[5]))


    # print(cycles)
    mean_val = mean(cycles)
    p75 = numpy.percentile(cycles,75)
    p25 = numpy.percentile(cycles,25)
    print(round(mean_val*period,2),round(p25*period,2), round(p75*period,2))


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
