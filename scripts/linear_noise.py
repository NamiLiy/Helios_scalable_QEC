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
file_names = ['001', '005', '0005']

for name in file_names:
    # open input file for reading
    input_file = open('d13_unexpanded_' + name +'.csv', 'r')

    # open output file for writing
    f = open('d13_expanded_' + name + '.csv', 'w')
    Lines = input_file.readlines()

    count = 0
    # Strips the newline character
    for line in Lines:
        # count += 1
        # print("Line{}: {}".format(count, line.strip()))
        line2 = line.strip()
        arr = line2.split(",")
        # for i in range (20):
        #     print(str(i) +" "+arr[i])
        cycles = atoi(arr[0])*10
        count = round(atoi(arr[1])*0.8)
        div = 20;
        count_div = count//div;
        # print(cycles,count,count_d_10);
        my_array = [None] * div;
        if(count_div > div):
            for i in range(div):
                my_array[i] = (div-i) * (count_div//div)
            for i in range(div):
                for j in range(my_array[i]):
                    f.write(str(cycles+i)+"\n")
                for j in range(my_array[i]):
                    if(i>0):
                        f.write(str(cycles-i)+"\n")
        else:
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
