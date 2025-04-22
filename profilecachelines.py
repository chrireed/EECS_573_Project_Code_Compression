import math
from profilebitfields import *


# Check instruction for bitfield
def has_bitfield(end, start, instruction, bitfield):
    instr_bitfield = get_bit_range(instruction, end, start)
    if instr_bitfield == bitfield:
        return True
    return False

def parse_mem_NAIVE_R_TYPE(filename, max_pc):
    with open(filename, 'r') as file:
        lines = file.readlines()

    mem = {}
    mem["instr"] = []
    mem["field1"] = []
    mem["field2"] = []
    mem["field3"] = []
    last_line = int(max_pc/4)
    i = 0
    for line in lines:
        instr = bin(int(line, 16))[2:].zfill(32)
        mem["instr"].append(instr)
        mem["field1"].append(get_opcode(instr))
        mem["field2"].append(get_funct7_funct3(instr))
        mem["field3"].append(get_register(instr))
        if i == last_line:
            break
        i += 1
    
    last_line += 1
    print("############################################")
    print("Parsed mem file")
    print("# instrs:")
    print(len(mem["instr"]))
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

def analyze_num_occurences(top_instructions, mem, compressible, block_size):
    print("############################################")
    
    # Count how many times out top [num] instruction appear in memory
    unique_instrs = []
    instr_count = {}
    for instr in mem["instr"]: 
        if instr in top_instructions:
            if instr not in unique_instrs:
                unique_instrs.append(instr)
                instr_count[instr] = 0
            instr_count[instr] += 1
    print("BLOCK SIZE: " + str(block_size))
    print("Top " + str(len(top_instructions)) + " instructions memory occurences")
    # for instr in instr_count:
    #     print(instr + " | # in mem: " + str(instr_count[instr]) + " | # in mem/ # executed " + str(instr_count[instr] / top_instructions[instr]))
    
    # For our top [num] instructions, find out how many of them are in compressible cache lines
    total_num_top_compressible_instructions = 0
    for instr_base_idx in range(0, len(mem["instr"]), block_size):
            num_compressible = 0
            num_instructions_in_top = 0
            for idx in range(instr_base_idx, instr_base_idx + block_size, 1):
                if idx < len(mem["instr"]):
                    if compressible[idx]:
                        num_compressible += 1
                    if mem["instr"][idx] in top_instructions:
                        num_instructions_in_top += 1
                    if(num_compressible == block_size):
                        total_num_top_compressible_instructions += num_instructions_in_top

    print("# occurences of top " + str(len(top_instructions)) + " instructions in mem: " + str(get_sum(instr_count)))
    print("# occurences that are in compressible cache lines: " + str(total_num_top_compressible_instructions))
    print("ratio: " + str(total_num_top_compressible_instructions / get_sum(instr_count)))
            
    print("############################################")

    

def main():
    # Parse trace
    program_name = sys.argv[1]
    mem_file     = sys.argv[2]

    trace_dump_file = "output/" + program_name + ".trace_dump"
    instructions_all, num_instructions, max_pc = parse_assembly_file(trace_dump_file)

    profiling_type = "NAIVE_R_TYPE_"
    field1_mem_filepath = "profiling/field1_" + profiling_type + program_name + ".mem"
    field2_mem_filepath = "profiling/field2_" + profiling_type + program_name + ".mem"
    field3_mem_filepath = "profiling/field3_" + profiling_type + program_name + ".mem"

    field1 = {}
    field2 = {}
    field3 = {}

    with open(field1_mem_filepath, 'r') as file:
        lines = file.readlines()
        for line in lines:
            field1[line.strip()] = 0

    with open(field2_mem_filepath, 'r') as file:
        lines = file.readlines()
        for line in lines:
            field2[line.strip()] = 0

    with open(field3_mem_filepath, 'r') as file:
        lines = file.readlines()
        for line in lines:
            field3[line.strip()] = 0

    print(field1)
    print(field2)
    print(field3)

    # Parse mem file
    mem_parsed, last_line = parse_mem_NAIVE_R_TYPE(mem_file, max_pc)

    # Count how any bitfield matches each instruction has
    num_fields = 3
    line_matches = [0] * last_line
    line_num = 0
    for entry in mem_parsed["field1"]:
        if entry in field1:
            line_matches[line_num] += 1
        line_num += 1
    line_num = 0
    for entry in mem_parsed["field2"]:
        if entry in field2:
            line_matches[line_num] += 1
        line_num += 1
    line_num = 0
    for entry in mem_parsed["field3"]:
        if entry in field3:
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
        print("NM: " + num_matches + " M?: " + match + " Instr: " + instr + " Opcode " + field1 + " f73: " + field2 + " reg: " + field3)

    # Analyze various cache configurations

    # analyze_cache(1024, 1, 1, 16, compressible, max_pc)
    # analyze_cache(1024, 1, 2, 16, compressible, max_pc)
    # analyze_cache(1024, 1, 4, 16, compressible, max_pc)
    # analyze_cache(1024, 1, 8, 16, compressible, max_pc)
    # analyze_cache(1024, 2, 1, 16, compressible, max_pc)
    # analyze_cache(1024, 2, 2, 16, compressible, max_pc)
    # analyze_cache(1024, 2, 4, 16, compressible, max_pc)
    # analyze_cache(1024, 2, 8, 16, compressible, max_pc)
    # analyze_cache(1024, 4, 1, 16, compressible, max_pc)
    # analyze_cache(1024, 4, 2, 16, compressible, max_pc)
    # analyze_cache(1024, 4, 4, 16, compressible, max_pc)
    # analyze_cache(1024, 4, 8, 16, compressible, max_pc)
    # analyze_cache(1024, 8, 1, 16, compressible, max_pc)
    # analyze_cache(1024, 8, 2, 16, compressible, max_pc)
    # analyze_cache(1024, 8, 4, 16, compressible, max_pc)
    # analyze_cache(1024, 8, 8, 16, compressible, max_pc)

    # analyze_cache(512, 1, 1, 16, compressible, max_pc)
    # analyze_cache(512, 1, 2, 16, compressible, max_pc)
    # analyze_cache(512, 1, 4, 16, compressible, max_pc)
    # analyze_cache(512, 1, 8, 16, compressible, max_pc)
    # analyze_cache(512, 2, 1, 16, compressible, max_pc)
    # analyze_cache(512, 2, 2, 16, compressible, max_pc)
    # analyze_cache(512, 2, 4, 16, compressible, max_pc)
    # analyze_cache(512, 2, 8, 16, compressible, max_pc)
    # analyze_cache(512, 4, 1, 16, compressible, max_pc)
    # analyze_cache(512, 4, 2, 16, compressible, max_pc)
    # analyze_cache(512, 4, 4, 16, compressible, max_pc)
    # analyze_cache(512, 4, 8, 16, compressible, max_pc)
    # analyze_cache(512, 8, 1, 16, compressible, max_pc)
    # analyze_cache(512, 8, 2, 16, compressible, max_pc)
    # analyze_cache(512, 8, 4, 16, compressible, max_pc)
    # analyze_cache(512, 8, 8, 16, compressible, max_pc)

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

    instructions_128 = trim_instructions(instructions_all, num_instructions, 128)
    instructions_256 = trim_instructions(instructions_all, num_instructions, 256)
    instructions_512 = trim_instructions(instructions_all, num_instructions, 512)

    # Get info regarding how often our top instructions actually fit into cache lines

    analyze_num_occurences(instructions_128, mem_parsed, compressible, 2)
    analyze_num_occurences(instructions_128, mem_parsed, compressible, 4)
    analyze_num_occurences(instructions_256, mem_parsed, compressible, 2)
    analyze_num_occurences(instructions_256, mem_parsed, compressible, 4)
    analyze_num_occurences(instructions_512, mem_parsed, compressible, 2)
    analyze_num_occurences(instructions_512, mem_parsed, compressible, 4)
    
    



if __name__ == "__main__":
    main()

