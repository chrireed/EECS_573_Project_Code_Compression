import sys
import math

riscv_opcode_to_format_extra = {
    '0110011': 'R(add)',  # R-type (e.g., arithmetic operations)
    '0010011': 'I(imm)',  # I-type (e.g., immediate instructions)
    '0000011': 'I(ld )',  # I-type (e.g., load instructions)
    '0100011': 'S(st )',  # S-type (e.g., store instructions)
    '1100011': 'B(beq)',  # B-type (e.g., branch instructions)
    '0110111': 'U(lui)',  # U-type (e.g., LUI)
    '0010111': 'U(aui)',  # U-type (e.g., AUIPC)
    '1101111': 'J(jal)',  # J-type (e.g., JAL)
    '1100111': 'I(jlr)',  # I-type (e.g., JALR)
    '1110011': 'I(sys)',  # I-type (e.g., system instructions)
}

riscv_opcode_to_format = {
    '0110011': 'R',  # R-type (e.g., arithmetic operations)
    '0010011': 'I',  # I-type (e.g., immediate instructions)
    '0000011': 'I',  # I-type (e.g., load instructions)
    '0100011': 'S',  # S-type (e.g., store instructions)
    '1100011': 'B',  # B-type (e.g., branch instructions)
    '0110111': 'U',  # U-type (e.g., LUI)
    '0010111': 'U',  # U-type (e.g., AUIPC)
    '1101111': 'J',  # J-type (e.g., JAL)
    '1100111': 'I',  # I-type (e.g., JALR)
    '1110011': 'I',  # I-type (e.g., system instructions)
}

def parse_assembly_file(filename, num_instrs=-1):
    with open(filename, 'r') as file:
        lines = file.readlines()

    assembly_start = False
    instructions = []

    for line in lines:
        if "MEMACCES/REGWRITE" in line:
            assembly_start = True
            continue

        if assembly_start:
            if not line.strip():
                continue

            parts = [part.strip() for part in line.split('|')]
            if len(parts) < 4:
                continue

            if parts[0][0] != "@": #prevent double counting
                instruction = bin(int(parts[2], 16))[2:].zfill(32)  # Convert to binary
                #print(instruction)
                instructions.append(instruction)
    if num_instrs == -1:
        return instructions
    print("############################################")
    print("# instrs:")
    print(len(instructions))
    # count the instructions and return only the top [num_instrs] common

    unique_instr = []
    instr_count = {}
    for instr in instructions: 
        if instr not in unique_instr:
            unique_instr.append(instr)
            instr_count[instr] = 0
        instr_count[instr] += 1

    trimmed_instr = []

    sorted_instr = sorted(instr_count.items(), key=lambda x: x[1], reverse=True)
    sorted_instr_dict = dict(sorted_instr)
    trimmed_instr_count = 0
    num = 0
    for entry in sorted_instr_dict:
        num += 1
        #print(entry)
        trimmed_instr.append(entry)
        trimmed_instr_count += sorted_instr_dict[entry]
        if num == num_instrs:
            break

    print("Top ",num_instrs, " unique # trimmed instrs")
    print("trimmmed instr count/Num instructions total: ", trimmed_instr_count/len(instructions))
    print("############################################")
    print("\n\n")
    return trimmed_instr



def get_bit_range(instruction, end, start):
    start_idx   = 32 - start
    end_idx     = 32 - end - 1
    opcode_bin = instruction[end_idx:start_idx]  # Extract last 7 bits as opcode
    return opcode_bin

def get_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if opcode not in unique_opcodes:
            unique_opcodes.append(opcode)
            opcodes[opcode] = 0
        opcodes[opcode] += 1

    return opcodes

def get_RISB_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if riscv_opcode_to_format[opcode] != 'U' and riscv_opcode_to_format[opcode] != 'J':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += 1

    return opcodes

def get_UJ_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if riscv_opcode_to_format[opcode] == 'U' or riscv_opcode_to_format[opcode] == 'J':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += 1

    return opcodes

def parse_funct7_funct3(instructions):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        upper = get_bit_range(instr, 31, 25) #funct7 or immediate
        lower = get_bit_range(instr, 14, 12) #funct3

        bitfield = upper + lower
        if bitfield not in unique_bitfields:
            #print(upper, "        ", lower)
            unique_bitfields.append(bitfield)
            bitfields[bitfield] = 0
        bitfields[bitfield] += 1

    return bitfields

def parse_funct7_funct3_RISB(instructions):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if riscv_opcode_to_format[opcode] != 'U' and riscv_opcode_to_format[opcode] != 'J':
            upper = get_bit_range(instr, 31, 25) #funct7 or immediate
            lower = get_bit_range(instr, 14, 12) #funct3

            bitfield = upper + lower
            if bitfield not in unique_bitfields:
                #print(upper, "        ", lower)
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += 1

    return bitfields

def parse_register(instructions):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        upper = get_bit_range(instr, 24, 15) #rs2 rs1
        lower = get_bit_range(instr, 11, 7) #rd

        bitfield = upper + lower
        if bitfield not in unique_bitfields:
            #print(upper, "        ", lower)
            unique_bitfields.append(bitfield)
            bitfields[bitfield] = 0
        bitfields[bitfield] += 1

    return bitfields

def parse_register_RISB(instructions):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if riscv_opcode_to_format[opcode] != 'U' and riscv_opcode_to_format[opcode] != 'J':
            upper = get_bit_range(instr, 24, 15) #rs2 rs1
            lower = get_bit_range(instr, 11, 7) #rd

            bitfield = upper + lower
            if bitfield not in unique_bitfields:
                #print(upper, "        ", lower)
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += 1

    return bitfields

def parse_immediate_UJ(instructions):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if riscv_opcode_to_format[opcode] == 'U' or riscv_opcode_to_format[opcode] == 'J':

            bitfield = get_bit_range(instr, 31, 12) #rs2 rs1

            if bitfield not in unique_bitfields:
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += 1

    return bitfields

def parse_register_UJ(instructions):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_bit_range(instr, 6, 0)
        if riscv_opcode_to_format[opcode] == 'U' or riscv_opcode_to_format[opcode] == 'J':

            bitfield = get_bit_range(instr, 11, 7) #rs2 rs1

            if bitfield not in unique_bitfields:
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += 1

    return bitfields


def get_sum(entries):
    sum = 0
    for entry in entries:
        sum += entries[entry]
    
    return sum

def sort_and_print(entries, limit=10):
    sorted_entries = sorted(entries.items(), key=lambda x: x[1], reverse=True)
    sorted_entries_dict = dict(sorted_entries)
    num = 0
    for entry in sorted_entries_dict:
        num += 1
        print(entry, " ", sorted_entries_dict[entry])
        if num == limit:
            break
    print("\n\n")

def print_stats(entries, title):
    # Sort and Print
    sum = get_sum(entries)
    print("Num unique " + title + ": ", len(entries))
    print("Num " + title, sum)
    #print(len(entries))
    num_bits = 0
    if len(entries) >= 2:
        num_bits = math.ceil(math.log2(len(entries)))
    if num_bits > 0:
        print("Numbits needed: ", num_bits)
        print("Num/Numbits: ", sum/num_bits)
    print("========================")
    sort_and_print(entries)
    if num_bits > 0:
        return num_bits
    return 0

def profile_various(instructions):
    #####################
    ###### OPCODES ######
    #####################

    # Parse the opcodes
    opcodes = get_opcodes(instructions)
    
    # Sort and Print
    print("Num Unique Opcodes: ", len(opcodes))
    print("Num Opcodes: ", get_sum(opcodes))
    opcode_num_bits = math.ceil(math.log2(len(opcodes)))
    print("Numbits needed: ", opcode_num_bits)
    print("Num/Numbits: ", get_sum(opcodes)/opcode_num_bits)
    print("Opcodes   Type     Count")
    print("========================")
    sorted_opcodes = sorted(opcodes.items(), key=lambda x: x[1], reverse=True)
    sorted_opcodes_dict = dict(sorted_opcodes)
    for opcode in sorted_opcodes_dict:
        print(opcode, " ", riscv_opcode_to_format_extra[opcode], " ", sorted_opcodes_dict[opcode])
    print("\n\n")

    # Parse the RISB opcodes
    RISB_opcodes = get_RISB_opcodes(instructions)
    
    # Sort and Print
    opcode_num_bits = print_stats(RISB_opcodes, "RISB_opcodes")

    # Parse the RISB opcodes
    UJ_opcodes = get_UJ_opcodes(instructions)
    
    # Sort and Print
    print_stats(UJ_opcodes, "UJ_opcodes")

    print("#UJ Opcode / # Opcodes:")
    print(get_sum(UJ_opcodes)/ get_sum(opcodes))


    #######################
    ###### BITFIELDS ######
    #######################

    # Parse the funct7/funct3 bitfields together (all)
    bitfields_funct7_funct3 = parse_funct7_funct3(instructions)

    # Sort and print
    print_stats(bitfields_funct7_funct3, "funct7_funct3 bitfields")

    # Parse the funct7/funct3 bitfields (RISB)
    bitfields_funct7_funct3_RISB = parse_funct7_funct3_RISB(instructions)

    # Sort and print
    funct7_funct3_RISB_bits = print_stats(bitfields_funct7_funct3_RISB, "funct7_funct3_RISB bitfields")

    # Parse register bitfields (all)
    bitfields_register = parse_register(instructions)

    # Sort and print
    print_stats(bitfields_register, "register bitfields")

    # Parse register bitfields (RISB)
    bitfields_register_RISB = parse_register_RISB(instructions)

    # Sort and print
    register_RISB_bits = print_stats(bitfields_register_RISB, "register RISB bitfields")

    # Parse immediate bitfields (UJ)
    bitfields_immediate_UJ = parse_immediate_UJ(instructions)

    # Sort and print
    print_stats(bitfields_immediate_UJ, "immediate UJ bitfields")

    # Parse register bitfield (UJ)
    bitfields_register_UJ = parse_register_UJ(instructions)

    # Sort and print
    print_stats(bitfields_register_UJ, "register UJ bitfield")

    print("===================================================")
    print("#funct7_funct3_RISB_bits:", funct7_funct3_RISB_bits)
    print("# register_RISB_bits:", register_RISB_bits)
    print("# opcode bits:", opcode_num_bits)
    print("# bits needed for opcodes + RISB registers + functs")
    print(funct7_funct3_RISB_bits + register_RISB_bits + opcode_num_bits)
    print("===================================================")
    print("\n")

def main():
    # Parse trace
    filename = sys.argv[1]
    instructions_all = parse_assembly_file(filename)
    # # print("Num of instructions: " + get_sum(instructions_all))
    # # print("\n")
    profile_various(instructions_all)

    instructions_trimmed = parse_assembly_file(filename, 128)
    # print("Num of instructions: " + get_sum(instructions_trimmed))
    # print("\n")
    profile_various(instructions_trimmed)

    instructions_trimmed = parse_assembly_file(filename, 256)
    # print("Num of instructions: " + get_sum(instructions_trimmed))
    # print("\n")
    profile_various(instructions_trimmed)

    instructions_trimmed = parse_assembly_file(filename, 512)
    # print("Num of instructions: " + get_sum(instructions_trimmed))
    # print("\n")
    profile_various(instructions_trimmed)

    #instructions_trimmed = parse_assembly_file(filename, 1024)
    # print("Num of instructions: " + get_sum(instructions_trimmed))
    # print("\n")
    #profile_various(instructions_trimmed)

if __name__ == "__main__":
    main()