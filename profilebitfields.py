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

# Returns list of all unique instructions in a program sorted by count based on the provided trace
def parse_assembly_file(filename):
    with open(filename, 'r') as file:
        lines = file.readlines()

    assembly_start = False
    instructions = []
    max_pc = 0
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
                max_pc = max(int(parts[1], 16), max_pc)
                #print(instruction)
                instructions.append(instruction)
    print("############################################")
    print("# instrs:")
    print(len(instructions))
    print("Max PC:")
    print(max_pc)
    print("Max PC (Hex): ")
    print(hex(max_pc))
    # count the instructions and return only the top [num_instrs] common

    unique_instr = []
    instr_count = {}
    for instr in instructions: 
        if instr not in unique_instr:
            unique_instr.append(instr)
            instr_count[instr] = 0
        instr_count[instr] += 1

    print("# unique instrs:")
    print(len(unique_instr))

    instr_count = sort_entries(instr_count)
    
    print("############################################")
    return instr_count, len(instructions), max_pc

# Returns list of the top [num_instrs] in a program sorted by count based on the provided trace
def trim_instructions(instructions, instruction_count, num_instrs=-1):
    if num_instrs == -1:
        return instructions, len(instructions)

    trimmed_instr = {}

    trimmed_instr_count = 0
    num = 0
    for entry in instructions:
        num += 1
        trimmed_instr[entry] = instructions[entry]
        trimmed_instr_count += instructions[entry]
        if num == num_instrs:
            break

    print("\n############################################")
    print("Top ",num_instrs, " unique # trimmed instructions")
    print("# trimmmed instructions executed / # total executed instructions: ", trimmed_instr_count/instruction_count)
    print("############################################")
    trimmed_instr = sort_entries(trimmed_instr)
    return trimmed_instr

# Break apart functions
def get_bit_range(instruction, end, start):
    start_idx   = 32 - start
    end_idx     = 32 - end - 1
    opcode_bin = instruction[end_idx:start_idx]  # Extract last 7 bits as opcode
    return opcode_bin

def get_register(instr):
    rs2 = get_rs2(instr)
    rs1 = get_rs1(instr)
    rd  = get_rd(instr)
    bitfield = rs2 + rs1 + rd
    return bitfield

def get_opcode(instr):
    bitfield = get_bit_range(instr, 6, 0) 
    return bitfield

def get_funct7_funct3(instr):
    upper = get_funct7(instr)
    lower = get_funct3(instr)
    bitfield = upper + lower
    return bitfield

def get_imm_I_type(instr):
    bitfield = get_bit_range(instr, 31, 20) 
    return bitfield

def get_rs2(instr):
    bitfield = get_bit_range(instr, 24, 20) 
    return bitfield

def get_rs1(instr):
    bitfield = get_bit_range(instr, 19, 15) 
    return bitfield

def get_rd(instr):
    bitfield = get_bit_range(instr, 11, 7) 
    return bitfield

def get_funct3(instr):
    bitfield = get_bit_range(instr, 14, 12) 
    return bitfield

def get_funct7(instr):
    bitfield = get_bit_range(instr, 31, 25) 
    return bitfield

#######################################################3

def get_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if opcode not in unique_opcodes:
            unique_opcodes.append(opcode)
            opcodes[opcode] = 0
        opcodes[opcode] += instructions[instr]

    return opcodes

def get_RISB_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] != 'U' and riscv_opcode_to_format[opcode] != 'J':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += instructions[instr]

    return opcodes

def get_R_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'R':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += instructions[instr]

    return opcodes

def get_I_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'I':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += instructions[instr]

    return opcodes

def get_S_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'S':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += instructions[instr]

    return opcodes

def get_B_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'B':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += instructions[instr]

    return opcodes

def get_UJ_opcodes(instructions):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'U' or riscv_opcode_to_format[opcode] == 'J':
            if opcode not in unique_opcodes:
                unique_opcodes.append(opcode)
                opcodes[opcode] = 0
            opcodes[opcode] += instructions[instr]

    return opcodes

def get_opcodes(instructions, max_entries=None):
    unique_opcodes = []
    opcodes = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if opcode not in unique_opcodes:
            if max_entries is not None and len(unique_opcodes) >= max_entries:
                break
            unique_opcodes.append(opcode)
            opcodes[opcode] = 0
        opcodes[opcode] += instructions[instr]
    return opcodes
    
def parse_funct7_funct3(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        bitfield = get_funct7_funct3(instr)
        if bitfield not in unique_bitfields:
            if max_entries is not None and len(unique_bitfields) >= max_entries:
                break
            unique_bitfields.append(bitfield)
            bitfields[bitfield] = 0
        bitfields[bitfield] += instructions[instr]
    return bitfields

def parse_funct7_funct3_RISB(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] != 'U' and riscv_opcode_to_format[opcode] != 'J':
            bitfield = get_funct7_funct3(instr)
            if bitfield not in unique_bitfields:
                if max_entries is not None and len(unique_bitfields) >= max_entries:
                    break
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += instructions[instr]
    return bitfields

def parse_registers(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        bitfield = get_register(instr)
        if bitfield not in unique_bitfields:
            if max_entries is not None and len(unique_bitfields) >= max_entries:
                break
            unique_bitfields.append(bitfield)
            bitfields[bitfield] = 0
        bitfields[bitfield] += instructions[instr]
    return bitfields

def parse_registers_RISB(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] != 'U' and riscv_opcode_to_format[opcode] != 'J':
            bitfield = get_register(instr)
            if bitfield not in unique_bitfields:
                if max_entries is not None and len(unique_bitfields) >= max_entries:
                    break
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += instructions[instr]
    return bitfields

def parse_immediate_UJ(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'U' or riscv_opcode_to_format[opcode] == 'J':
            bitfield = get_bit_range(instr, 31, 12)
            if bitfield not in unique_bitfields:
                if max_entries is not None and len(unique_bitfields) >= max_entries:
                    break
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += instructions[instr]
    return bitfields

def parse_registers_UJ(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        opcode = get_opcode(instr)
        if riscv_opcode_to_format[opcode] == 'U' or riscv_opcode_to_format[opcode] == 'J':
            bitfield = get_bit_range(instr, 11, 7)
            if bitfield not in unique_bitfields:
                if max_entries is not None and len(unique_bitfields) >= max_entries:
                    break
                unique_bitfields.append(bitfield)
                bitfields[bitfield] = 0
            bitfields[bitfield] += instructions[instr]
    return bitfields

# NAIVE_I_TYPE
def parse_imm_I_type(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        bitfield = get_imm_I_type(instr)
        if bitfield not in unique_bitfields:
            if max_entries is not None and len(unique_bitfields) >= max_entries:
                break
            #print(upper, "        ", lower)
            unique_bitfields.append(bitfield)
            bitfields[bitfield] = 0
        bitfields[bitfield] += instructions[instr]

    return bitfields

def parse_rs1_funct3_rd(instructions, max_entries=None):
    unique_bitfields = []
    bitfields = {}
    for instr in instructions: 
        rs1 = get_rs1(instr)
        funct3 = get_funct3(instr)
        rd = get_rd(instr)
        bitfield = rs1 + funct3 + rd
        if bitfield not in unique_bitfields:
            if max_entries is not None and len(unique_bitfields) >= max_entries:
                break
            #print(upper, "        ", lower)
            unique_bitfields.append(bitfield)
            bitfields[bitfield] = 0
        bitfields[bitfield] += instructions[instr]

    return bitfields

#######################################################

def get_sum(entries):
    sum = 0
    for entry in entries:
        sum += entries[entry]
    
    return sum

def sort_entries(entries):
    sorted_entries = sorted(entries.items(), key=lambda x: x[1], reverse=True)
    sorted_entries_dict = dict(sorted_entries)
    return sorted_entries_dict

def print_entries(entries, limit=-1):
    num = 0
    for entry in entries:
        if num == limit:
            break
        num += 1
        print(entry, " ", entries[entry])
    print("\n\n")

def sort_and_print(entries, limit=-1):
    print_entries(sort_entries(entries), limit)

def print_instr_w_type(entries):
    for entry in entries:
        print(entry, " | ", riscv_opcode_to_format_extra[get_opcode(entry)], " | ", entries[entry])

def print_stats(entries, title, limit=-1):
    # Sort and Print
    sum = get_sum(entries)
    print("# unique " + title + ": ", len(entries))
    print("# " + title + ": ", sum)
    print("# bits in bitfield:", len(list(entries.keys())[0]))
    #print(len(entries))
    num_bits = 0
    if len(entries) >= 2:
        num_bits = math.ceil(math.log2(len(entries)))
    if num_bits > 0:
        print("# bits needed: ", num_bits)
        #print("#", title, "/ # bits: ", sum/num_bits)
    print("========================")
    print_entries(entries, limit)
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
    bitfields_register = parse_registers(instructions)

    # Sort and print
    print_stats(bitfields_register, "register bitfields")

    # Parse register bitfields (RISB)
    bitfields_register_RISB = parse_registers_RISB(instructions)

    # Sort and print
    register_RISB_bits = print_stats(bitfields_register_RISB, "register RISB bitfields")

    # Parse immediate bitfields (UJ)
    bitfields_immediate_UJ = parse_immediate_UJ(instructions)

    # Sort and print
    print_stats(bitfields_immediate_UJ, "immediate UJ bitfields")

    # Parse register bitfield (UJ)
    bitfields_register_UJ = parse_registers_UJ(instructions)

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

#######################################################

def get_instr_ratio(instructions):
    get_R_instr_ratio(instructions)
    get_I_instr_ratio(instructions)
    get_S_instr_ratio(instructions)
    get_B_instr_ratio(instructions)
    get_UJ_instr_ratio(instructions)

def get_R_instr_ratio(instructions):
    total_instr_count = get_sum(instructions)
    R_instr_count = get_sum(get_R_opcodes(instructions))
    print("# R Instrs / # Instrs: %.3f" % (R_instr_count/total_instr_count))

def get_I_instr_ratio(instructions):
    total_instr_count = get_sum(instructions)
    I_instr_count = get_sum(get_I_opcodes(instructions))
    print("# I Instrs / # Instrs: %.3f" % (I_instr_count/total_instr_count))

def get_S_instr_ratio(instructions):
    total_instr_count = get_sum(instructions)
    S_instr_count = get_sum(get_S_opcodes(instructions))
    print("# S Instrs / # Instrs: %.3f" % (S_instr_count/total_instr_count))

def get_B_instr_ratio(instructions):
    total_instr_count = get_sum(instructions)
    B_instr_count = get_sum(get_B_opcodes(instructions))
    print("# B Instrs / # Instrs: %.3f" % (B_instr_count/total_instr_count))

def get_UJ_instr_ratio(instructions):
    total_instr_count = get_sum(instructions)
    UJ_instr_count = get_sum(get_UJ_opcodes(instructions))
    print("# UJ Instrs / # Instrs: %.3f" % (UJ_instr_count/total_instr_count))

#######################################################

# NAIVE configuration (based on R-type instructions):
# Split instructions into 3 fields:
# 1. Opcodes [6:0]
# 2. funct7 + funct3 [31:25][14:2]
# 3. rs2 rs1 rd [24:15][11:7]
def profile_NAIVE_R_TYPE(instructions, instructions_all={}, write_out=False, filename="NAIVE_R_TYPE"):

    print("\nNAIVE_R_TYPE PROFILING\n")

    # Uncomment to print out all the instructions
    #print_instr_w_type(instructions)

    #####################
    ###### OPCODES ######
    #####################


    # Parse the opcodes
    field1 = get_opcodes(instructions)
    field1 = sort_entries(field1)
    field1_bits = print_stats(field1, "[FIELD 1] opcodes[6:0]", 0)

    #######################
    ###### FUNCT7/3 #######
    #######################
    # Parse the registers
    field2 = parse_funct7_funct3(instructions)
    field2 = sort_entries(field2)
    field2_bits = print_stats(field2, "[FIELD 2] funct7 + funct3 [31:25][14:2]", 0)

    #######################
    ###### REGISTERS ######
    #######################
    # Parse the registers
    field3 = parse_registers(instructions)
    field3 = sort_entries(field3)
    field3_bits = print_stats(field3, "[FIELD 3] rs2 rs1 rd [24:15][11:7]", 0)

    print("===================================================")
    print("[FIELD 1]:", field1_bits)
    print("[FIELD 2]:", field2_bits)
    print("[FIELD 3]:", field3_bits)
    print("[FIELD 1] + [FIELD 2] + [FIELD 3]: ", field1_bits + field2_bits + field3_bits)
    print("===================================================")

    field1_bits = 3
    field2_bits = 5
    field3_bits = 8
    # Get the max # compressible fields (from all instructions) to fill up luts
    field1_write = get_opcodes(instructions_all, 2**field1_bits)
    #field1_write = sort_entries(field1_write)

    field2_write = parse_funct7_funct3(instructions_all, 2**field2_bits)
    #field2_write = sort_entries(field2_write)

    field3_write = parse_registers(instructions_all, 2**field3_bits)
    #field3_write = sort_entries(field3_write)


    if(write_out):
        with open("profiling/field1_" + filename + ".mem", 'w') as file:
            for entry in field1_write:
                file.write(entry + "\n")
        with open("profiling/field2_" + filename + ".mem", 'w') as file:
            for entry in field2_write:
                file.write(entry + "\n")
        with open("profiling/field3_" + filename + ".mem", 'w') as file:
            for entry in field3_write:
                file.write(entry + "\n")

# Split instructions into 3 fields:
# 1. Opcodes [6:0]
# 2. imm[11:0] [31:20]
# 3. rs1 funct3 rd [19:7]
def profile_NAIVE_I_TYPE(instructions, instructions_all={}, write_out=False, filename="NAIVE_I_TYPE"):
    
    print("\nNAIVE_I_TYPE PROFILING\n")

    # Uncomment to print out all the instructions
    #print_instr_w_type(instructions)

    #####################
    ###### OPCODES ######
    #####################


    # Parse the opcodes
    field1 = get_opcodes(instructions)
    field1 = sort_entries(field1)
    field1_bits = print_stats(field1, "[FIELD 1] opcodes[6:0]", 0)

    #######################
    ######## IMM ##########
    #######################
    # Parse the registers
    field2 = parse_imm_I_type(instructions)
    field2 = sort_entries(field2)
    field2_bits = print_stats(field2, "[FIELD 2] imm[11:0] [31:20]", 0)

    #######################
    ###### REGISTERS ######
    #######################
    # Parse the registers
    field3 = parse_rs1_funct3_rd(instructions)
    field3 = sort_entries(field3)
    field3_bits = print_stats(field3, "[FIELD 3] rs1 funct3 rd [19:7]", 0)

    print("===================================================")
    print("[FIELD 1]:", field1_bits)
    print("[FIELD 2]:", field2_bits)
    print("[FIELD 3]:", field3_bits)
    print("[FIELD 1] + [FIELD 2] + [FIELD 3]: ", field1_bits + field2_bits + field3_bits)
    print("===================================================")

    field1_bits = 3
    field2_bits = 6
    field3_bits = 7

    # Get the max # compressible fields (from all instructions) to fill up luts
    field1_write = get_opcodes(instructions_all, 2**field1_bits)
    #field1_write = sort_entries(field1_write)

    field2_write = parse_imm_I_type(instructions_all, 2**field2_bits)
    #field2_write = sort_entries(field2_write)

    field3_write = parse_rs1_funct3_rd(instructions_all, 2**field3_bits)
    #field3_write = sort_entries(field3_write)


    if(write_out):
        with open("profiling/field1_" + filename + ".mem", 'w') as file:
            for entry in field1_write:
                file.write(entry + "\n")
        with open("profiling/field2_" + filename + ".mem", 'w') as file:
            for entry in field2_write:
                file.write(entry + "\n")
        with open("profiling/field3_" + filename + ".mem", 'w') as file:
            for entry in field3_write:
                file.write(entry + "\n")

def main():
    # Parse trace
    filename = sys.argv[1]

    # Remove prefix (everything before 'output/')
    prefix_removed = filename.split("output/")[-1]  # → "[program_name].out"

    # Remove suffix ('.out')
    program_name = prefix_removed.replace(".trace_dump", "")  # → "[program_name]"

    print(program_name)

    instructions_all, num_instructions, max_pc = parse_assembly_file(filename)
    get_instr_ratio(instructions_all)
    #profile_various(instructions_all)
    #profile_NAIVE_R_TYPE(instructions_all, instructions_all, True, "all")
    profile_NAIVE_R_TYPE(instructions_all)
    profile_NAIVE_I_TYPE(instructions_all)

    instructions_128 = trim_instructions(instructions_all, num_instructions, 128)
    get_instr_ratio(instructions_128)
    #profile_various(instructions_128)
    profile_NAIVE_R_TYPE(instructions_128)
    profile_NAIVE_I_TYPE(instructions_128)

    instructions_256 = trim_instructions(instructions_all, num_instructions, 256)
    get_instr_ratio(instructions_256)
    #profile_various(instructions_256)
    profile_NAIVE_R_TYPE(instructions_256, instructions_all, True, "R_" + program_name)
    profile_NAIVE_I_TYPE(instructions_256, instructions_all, True, "I_" + program_name)

    instructions_512 = trim_instructions(instructions_all, num_instructions, 512)
    get_instr_ratio(instructions_512)
    #profile_various(instructions_512)
    profile_NAIVE_R_TYPE(instructions_512)
    profile_NAIVE_I_TYPE(instructions_512)

if __name__ == "__main__":
    main()