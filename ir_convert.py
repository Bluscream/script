import math

# define constants
PRONTO_CODE = '0000'
FREQUENCY = '006D'
ZERO = '0000'
PULSE = 9025
SPACE = 4391

# input sequence (change this to your input)
ir_sequence = [0,9025,4391,643,448,617,469,643,443,643,448,638,448,617,470,643,443,643,1568,617,1597,643,1568,643,1572,643,1568,643,1568,621,1594,643,1568,643,448,643,1568,643,443,643,447,617,469,643,444,643,447,639,447,643,444,643,443,643,1568,621,1593,643,1568,617,1598,643,1567,643,1567,647,1568,643]

# convert IR sequence to Pronto Code
pronto_sequence = []

for i in range(2, len(ir_sequence), 2):
    space = ir_sequence[i]
    pulse = ir_sequence[i+1]
    
    pulse_hex = hex(int(pulse/PULSE*0x10))
    space_hex = hex(int(space/SPACE*0x10))
    
    pronto_sequence.append(str(space_hex)[2:].zfill(4))
    pronto_sequence.append(str(pulse_hex)[2:].zfill(4))

print(PRONTO_CODE, FREQUENCY, ZERO, ZERO, ''.join(pronto_sequence))


# 0000 006D 0022 0000 0159 00AD 0016 0016 0016 0016 0016 0016 0016 0016 0016 0016 0016 0016 0016 0016 0016 0042 0014 0042 0015 0041 0016 0041 0015 0042 0015 0042 0015 0042 0015 0042 0015 0016 0016 0042 0015 0016 0016 0016 0016 0016 0016 0016 0016 0016 0015 0016 0015 0016 0016 0016 0016 0041 0015 0041 0016 0042 0015 0042 0015 0042 0015 0041 0015 0041 0015 06C3