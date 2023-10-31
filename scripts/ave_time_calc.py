from locale import atoi
from statistics import mean
import numpy
import matplotlib.pyplot as plt

period = 8
file_list = ['d7_cutoff_accuracy.txt']

for file in file_list:
    file1 = open(file, 'r')
    Lines = file1.readlines()

    entry = 1;
    total = 0;
    # Strips the newline character
    for line in Lines:
        # count += 1
        # print("Line{}: {}".format(count, line.strip()))
        line2 = line.strip()
        arr = line2.split("\t")
        cycles = atoi(arr[0])
        count = atoi(arr[1])
        # print("cycles count accuracy {} {}".format(cycles,count))
        for i in range(entry,cycles):
            print (i, ",0,", total)
        total = total  + count
        print (cycles, ",",count,",", total)
        entry = cycles + 1;
        # for i in range(count):
        #     f.write(str(cycles)+"\n")