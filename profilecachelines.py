import math
from profilebitfields import *


# Check instruction for bitfield
def has_bitfield(end, start, instruction, bitfield):
    instr_bitfield = get_bit_range(instruction, end, start)
    if instr_bitfield == bitfield:
        return True
    return False

# Break apart functions
def get_register(instr):
    upper = get_bit_range(instr, 24, 15) #rs2 rs1
    lower = get_bit_range(instr, 11, 7) #rd
    bitfield = upper + lower
    return bitfield

def get_opcode(instr):
    bitfield = get_bit_range(instr, 6, 0) 
    return bitfield

def get_funct7_funct3(instr):
    upper = get_bit_range(instr, 31, 25) #funct7 or immediate
    lower = get_bit_range(instr, 14, 12) #funct3
    bitfield = upper + lower
    return bitfield

def parse_mem_basic(filename, max_pc):
    with open(filename, 'r') as file:
        lines = file.readlines()

    mem = {}
    mem["instr"] = []
    mem["opcode"] = []
    mem["f37"] = []
    mem["reg"] = []
    last_line = int(max_pc/4)
    i = 0
    for line in lines:
        instr = bin(int(line, 16))[2:].zfill(32)
        mem["instr"].append(instr)
        mem["opcode"].append(get_opcode(instr))
        mem["f37"].append(get_funct7_funct3(instr))
        mem["reg"].append(get_register(instr))
        if i == last_line:
            break
        i += 1
    
    last_line += 1
    print("############################################")
    print("Parsed mem file")
    print("# instrs:")
    print(len(mem["opcode"]))
    print("last line:")
    print(last_line)
    print("############################################")

    return mem, last_line

# [cache_size] in bytes
# [cache_ways] number of ways
# [cache_blocks] number of instructions per cache line
# [instr_size] size of each instruction in bits
# [compressible] whether or not an instruction is compressible
def analyze_cache(cache_size, cache_ways, cache_blocks, instr_size, compressible, max_pc):
    print("############################################")
    print("Cache Size: ", cache_size, "B")
    print("Cache Ways: ", cache_ways)
    print("Cache Blocks: ", cache_blocks)
    print("Instr Size (bits): ", instr_size)
    print("Max PC: ", max_pc)

    cache_line_size = int(cache_blocks*int(instr_size/8))
    cache_lines = int(cache_size/cache_line_size)
    number_sets = int(cache_lines/cache_ways)
    print("Cache line size: ", cache_line_size, "B")
    print("Cache lines: ", cache_lines)
    print("Cache sets: ", number_sets)

    if cache_blocks < 2:
        block_offset_bit_start = 1
        block_offset_bit_end = 1
    else:
        block_offset_bit_start = 2
        block_offset_bit_end = block_offset_bit_start + math.ceil(math.log2(cache_blocks)) - 1
        print("Block offset bits: [", block_offset_bit_end, "-", block_offset_bit_start, "]")

    index_bit_start = block_offset_bit_end + 1
    index_bit_end = index_bit_start + math.ceil(math.log2(cache_lines/cache_ways)) - 1
    tag_bit_start = index_bit_end + 1
    tag_bit_end = 31
    print("Set index bits: [", index_bit_end, "-", index_bit_start, "]")
    print("Tag bits: [", tag_bit_end, "-", tag_bit_start, "]")

    cache = [[0] * cache_ways] * cache_lines 

    # find number of compressible cache lines
    # evaluate occupancy
    num_compressible_instr = 0
    num_compressible_cache_lines = 0
    num_cache_lines = 0

    set_counts = [0] * number_sets
    num_matches_needed = cache_blocks
    for address in range(0, max_pc + 4, 4*cache_blocks):
        idx = int(address / 4)
        num_matches = 0
        num_cache_lines += 1
        for val in range(0, cache_blocks):
            if idx + val <= max_pc/4:
                num_matches += compressible[idx + val]
        num_compressible_instr += num_matches
        if num_matches == num_matches_needed:
            #print(str(1), " ", address, "-", address + 4*cache_blocks - 1)
            num_compressible_cache_lines += 1
            address_bin = bin(address)[2:].zfill(32)
            index = get_bit_range(address_bin, index_bit_end, index_bit_start)
            #print(int(index, 2))
            set_counts[int(index, 2) - 1] += 1 #increase number of cache lines that map to this set
        # else:
        #     #print(str(0), " ", address, "-", address + 4*cache_blocks - 1)

    print("num instructions: ", len(compressible))
    print("num compressible instr: ", num_compressible_instr)
    print("num cache lines: ", num_cache_lines)
    print("num compressible cache lines: ", num_compressible_cache_lines)
    print("compressible lines/total lines", num_compressible_cache_lines/num_cache_lines)
    print("num compr. instructions in cache lines/num compressible instrs", (num_compressible_cache_lines * cache_blocks)/num_compressible_instr)
    count = set_counts.count(0)
    print("# sets: ", len(set_counts))
    print("# sets that aren't used:", count)
    print("# sets that are used/#sets:", (len(set_counts) - count)/len(set_counts))
    
    for address in range(0, max_pc + 4, 4):
        address_bin = bin(address)[2:].zfill(32)
        tag = get_bit_range(address_bin, tag_bit_end, tag_bit_start)
        index = get_bit_range(address_bin, index_bit_end, index_bit_start)
        block_offset = get_bit_range(address_bin, block_offset_bit_end, block_offset_bit_start)
        #print("addr: ", address_bin, "tag: ", tag, "index: ", index, "block_offset: ", block_offset)

    print("############################################")


    

def main():
    # Parse trace
    trace_dump_file = sys.argv[1]
    mem_file    = sys.argv[2]


    cache_size = [256] # in bytes
    cache_instr_per_line = [1]
    cache_ways = [1]

    instructions_all, num_instructions, max_pc = parse_assembly_file(trace_dump_file)
    instructions_256 = trim_instructions(instructions_all, num_instructions, 256)


    opcodes = get_opcodes(instructions_256)
    bitfields_funct7_funct3 = parse_funct7_funct3(instructions_256)
    bitfields_register = parse_register(instructions_256)

    print_stats(opcodes, "opcodes[6:0]")
    print_stats(bitfields_register, "registers[24:15][11:7]")
    print_stats(bitfields_funct7_funct3, "funct7_funct3[31:25][14:12]")
    # print("Opcodes")
    # sort_and_print(opcodes)
    # print("f37")
    # sort_and_print(bitfields_funct7_funct3)
    # print("reg")
    # sort_and_print(bitfields_register)

    # Parse mem file
    mem_parsed, last_line = parse_mem_basic(mem_file, max_pc)

    # Count how any bitfield matches each instruction has
    num_fields = 3
    line_matches = [0] * last_line
    line_num = 0
    for entry in mem_parsed["opcode"]:
        if entry in opcodes:
            line_matches[line_num] += 1
        line_num += 1
    line_num = 0
    for entry in mem_parsed["f37"]:
        if entry in bitfields_funct7_funct3:
            line_matches[line_num] += 1
        line_num += 1
    line_num = 0
    for entry in mem_parsed["reg"]:
        if entry in bitfields_register:
            line_matches[line_num] += 1
        line_num += 1
    
    # Determine whether a line is compressible based on the matches
    compressible = []
    for entry in line_matches:
        if entry == 3:
            compressible.append(1)
        else:
            compressible.append(0)

    count = compressible.count(1)
    print("# compressible instructions:", count)  # Output: 5

    # Print out everything for sanity's sake to check
    line = 0
    for instr in mem_parsed["instr"]:
        num_matches = str(line_matches[line])
        match = str(compressible[line])
        field1 = get_opcode(instr)
        field2 = get_funct7_funct3(instr)
        field3 = get_register(instr)
        line +=1
        # print("NM: " + num_matches + " M?: " + match + " Instr: " + instr + " Opcode " + field1 + " f73: " + field2 + " reg: " + field3)

    analyze_cache(1024, 1, 1, 16, compressible, max_pc)
    analyze_cache(1024, 1, 2, 16, compressible, max_pc)
    analyze_cache(1024, 1, 4, 16, compressible, max_pc)
    analyze_cache(1024, 1, 8, 16, compressible, max_pc)
    analyze_cache(1024, 2, 1, 16, compressible, max_pc)
    analyze_cache(1024, 2, 2, 16, compressible, max_pc)
    analyze_cache(1024, 2, 4, 16, compressible, max_pc)
    analyze_cache(1024, 2, 8, 16, compressible, max_pc)
    analyze_cache(1024, 4, 1, 16, compressible, max_pc)
    analyze_cache(1024, 4, 2, 16, compressible, max_pc)
    analyze_cache(1024, 4, 4, 16, compressible, max_pc)
    analyze_cache(1024, 4, 8, 16, compressible, max_pc)
    analyze_cache(1024, 8, 1, 16, compressible, max_pc)
    analyze_cache(1024, 8, 2, 16, compressible, max_pc)
    analyze_cache(1024, 8, 4, 16, compressible, max_pc)
    analyze_cache(1024, 8, 8, 16, compressible, max_pc)

    analyze_cache(512, 1, 1, 16, compressible, max_pc)
    analyze_cache(512, 1, 2, 16, compressible, max_pc)
    analyze_cache(512, 1, 4, 16, compressible, max_pc)
    analyze_cache(512, 1, 8, 16, compressible, max_pc)
    analyze_cache(512, 2, 1, 16, compressible, max_pc)
    analyze_cache(512, 2, 2, 16, compressible, max_pc)
    analyze_cache(512, 2, 4, 16, compressible, max_pc)
    analyze_cache(512, 2, 8, 16, compressible, max_pc)
    analyze_cache(512, 4, 1, 16, compressible, max_pc)
    analyze_cache(512, 4, 2, 16, compressible, max_pc)
    analyze_cache(512, 4, 4, 16, compressible, max_pc)
    analyze_cache(512, 4, 8, 16, compressible, max_pc)
    analyze_cache(512, 8, 1, 16, compressible, max_pc)
    analyze_cache(512, 8, 2, 16, compressible, max_pc)
    analyze_cache(512, 8, 4, 16, compressible, max_pc)
    analyze_cache(512, 8, 8, 16, compressible, max_pc)

    analyze_cache(256, 1, 1, 16, compressible, max_pc)
    analyze_cache(256, 1, 2, 16, compressible, max_pc)
    analyze_cache(256, 1, 4, 16, compressible, max_pc)
    analyze_cache(256, 1, 8, 16, compressible, max_pc)
    analyze_cache(256, 2, 1, 16, compressible, max_pc)
    analyze_cache(256, 2, 2, 16, compressible, max_pc)
    analyze_cache(256, 2, 4, 16, compressible, max_pc)
    analyze_cache(256, 2, 8, 16, compressible, max_pc)
    analyze_cache(256, 4, 1, 16, compressible, max_pc)
    analyze_cache(256, 4, 2, 16, compressible, max_pc)
    analyze_cache(256, 4, 4, 16, compressible, max_pc)
    analyze_cache(256, 4, 8, 16, compressible, max_pc)
    analyze_cache(256, 8, 1, 16, compressible, max_pc)
    analyze_cache(256, 8, 2, 16, compressible, max_pc)
    analyze_cache(256, 8, 4, 16, compressible, max_pc)
    analyze_cache(256, 8, 8, 16, compressible, max_pc)
    
    



if __name__ == "__main__":
    main()

