# Use this function only to generate the latency tests on single FPGA. Also please change code distance manually in top level module and in the testbench.

import random

codeDistanceX = 11
codeDistanceZ = 10

class hdlTemplate:
    out = ""
    def __init__(self, out):
        self.out = out
    def r(self, keyword, repl):
        self.out = self.out.replace("/*$$" + str(keyword) + "*/", str(repl))
def inlineCase(var, pairs, otw):
    ret = ""
    for p in pairs:
        conditions = ""
        conditionsInit = False
        for i in range(len(var)):
            if(not conditionsInit):
                conditionsInit = True
            else:
                conditions = conditions + "&&"
            conditions = conditions + var[i] + "==" + str(p[i])
        ret = ret + conditions + "?" + str(p[-1]) + ":"
    if(ret == "" or ret[-1]==":"):
        ret = ret + str(otw)
    return ret

def complete_rnd_gen_top():
    with open("./templates/rand_gen_top.sv","r") as f:
        templateSV = f.read()
        OF = hdlTemplate(templateSV)
        s0 = generate_rand_string(codeDistanceX*(codeDistanceZ + 1) + (codeDistanceX-1)*codeDistanceZ + codeDistanceX*codeDistanceZ)
        OF.r("S0_ARRAY", s0)
        s1 = generate_rand_string(codeDistanceX*(codeDistanceZ + 1) + (codeDistanceX-1)*codeDistanceZ + codeDistanceX*codeDistanceZ)
        OF.r("S1_ARRAY", s1)
        f = open("../design/generated/rand_gen_top.sv" , "w")
        f.write(OF.out)
        f.close()

    return

def generate_rand_string(length):
    output_string = ""
    start_string = "64'h"
    for i in range(length):
        temp_string = ""
        for j in range(4):
            temp_string = temp_string + hex(random.randrange(65536)).lstrip("0x").rstrip("L").zfill(4)
        output_string = output_string + start_string + temp_string + ", "
    output_string = output_string + "64'h0"
    return output_string

complete_rnd_gen_top()