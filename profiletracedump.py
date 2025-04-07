import sys
import math
filename = sys.argv[1]


def parse_assembly_file(filename):
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

            instruction = {
                "memory": parts[0],
                "PC": parts[1],
                "hex": parts[2],
                "assembly": parts[3].split(" ")[0] + " " + parts[3].split(" ")[1]
            }
            instructions.append(instruction)
    return instructions

def count_instruction_frequency(instructions):
    frequency = {}
    for instr in instructions:
        asm = instr["assembly"]
        frequency[asm] = frequency.get(asm, 0) + 1
    return frequency

def freq_of_components(sort_frequency_dict):
    immFreq = {}
    regFreq = {}
    opFreq = {}


    pleep = 0
    for asm, count in sorted_frequency:
        if (pleep == 100):
            break
        op = asm.split(" ")[0]
        opFreq[op] = opFreq.get(op, 0) + 1
        print(asm)
        if "(" in asm.split(" ")[1]:
  
            reg1 = asm.split(" ")[1].split(",")[0]
            imm = asm.split(" ")[1].split(",")[1].split("(")[0]
            reg2 = asm.split(" ")[1].split(",")[1].split("(")[1].split(")")[0]

            regFreq[reg1] = regFreq.get(reg1, 0) + 1
            regFreq[reg2] = regFreq.get(reg2, 0) + 1
            immFreq[imm] = immFreq.get(imm, 0) + 1
        elif ("i" in asm.split(" ")[0] or "e" in asm.split(" ")[0]) and not "lui" in asm.split(" ")[0] and not "auipc" in asm.split(" ")[0]:
            imm = asm.split(" ")[1].split(",")[2]
            reg1 = asm.split(" ")[1].split(",")[0]
            reg2 = asm.split(" ")[1].split(",")[1]

            regFreq[reg1] = regFreq.get(reg1, 0) + 1
            regFreq[reg2] = regFreq.get(reg2, 0) + 1
            immFreq[imm] = immFreq.get(imm, 0) + 1

        elif "jal" in asm.split(" ")[0] or "lui" in asm.split(" ")[0] or "auipc" in asm.split(" ")[0]:
            imm = asm.split(" ")[1].split(",")[1]
            reg1 = asm.split(" ")[1].split(",")[0]

            regFreq[reg1] = regFreq.get(reg1, 0) + 1
            immFreq[imm] = immFreq.get(imm, 0) + 1
        else:
            reg1 = asm.split(" ")[1].split(",")[0]
            reg2 = asm.split(" ")[1].split(",")[1]
            reg3 = asm.split(" ")[1].split(",")[2]

            regFreq[reg1] = regFreq.get(reg1, 0) + 1
            regFreq[reg2] = regFreq.get(reg2, 0) + 1
            regFreq[reg3] = regFreq.get(reg3, 0) + 1
        pleep = pleep + 1
    return (immFreq,regFreq,opFreq)


def adjust_frequencies(freq_dict):
    # Halve the frequency of instructions that start with 'lw' or 'sw'
    adjusted = {}
    for asm, count in freq_dict.items():
        if asm.startswith("lw") or asm.startswith("sw") or asm.startswith("lbu") or asm.startswith("sb") or asm.startswith("lb") or asm.startswith("lh") or asm.startswith("lhu") or asm.startswith("sh"):
            adjusted[asm] = count // 2  # using integer division
        else:
            adjusted[asm] = count
    return adjusted

def sort_frequency_dict(freq_dict):
    # Returns a list of tuples sorted by frequency in descending order.
    return sorted(freq_dict.items(), key=lambda x: x[1], reverse=True)

if __name__ == "__main__":
    filename = "output/" + filename  # Update with the correct file path
    assembly_instructions = parse_assembly_file(filename)
    frequency_dict = count_instruction_frequency(assembly_instructions)
    
    # Adjust frequencies: halve those starting with 'lw' or 'sw'
    adjusted_frequency = adjust_frequencies(frequency_dict)
    
    sorted_frequency = sort_frequency_dict(adjusted_frequency)

    comp_freq = freq_of_components(sorted_frequency)

    imm_freq = comp_freq[0]
    reg_freq = comp_freq[1]
    op_freq = comp_freq[2]
    
    print("Sorted Assembly Instruction Frequencies (adjusted):")
    counter = 0
    first_hundred = 0
    for asm, count in sorted_frequency:
        if (counter < 101):
            first_hundred = first_hundred + count
            counter = counter + 1
        print(f"{asm}: {count}")

    print("first_hundred", first_hundred)
    print("reg  Frequencies (adjusted):")
    print(reg_freq)
    print(len(reg_freq))
    print(math.log2(len(reg_freq)))

    print("imm  Frequencies (adjusted):")
    print(imm_freq)
    print(len(imm_freq))
    print(math.log2(len(imm_freq)))

    print("op  Frequencies (adjusted):")
    print(op_freq)
    print(len(op_freq))
    print(math.log2(len(op_freq)))