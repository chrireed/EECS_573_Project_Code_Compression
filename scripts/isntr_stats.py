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

def adjust_frequencies(freq_dict):
    # Halve the frequency of instructions that start with 'lw' or 'sw'
    adjusted = {}
    for asm, count in freq_dict.items():
        if asm.startswith("lw") or asm.startswith("sw"):
            adjusted[asm] = count // 2  # using integer division
        else:
            adjusted[asm] = count
    return adjusted

def sort_frequency_dict(freq_dict):
    # Returns a list of tuples sorted by frequency in descending order.
    return sorted(freq_dict.items(), key=lambda x: x[1], reverse=True)

if __name__ == "__main__":
    filename = "trace.dump"  # Update with the correct file path
    assembly_instructions = parse_assembly_file(filename)
    frequency_dict = count_instruction_frequency(assembly_instructions)
    
    # Adjust frequencies: halve those starting with 'lw' or 'sw'
    adjusted_frequency = adjust_frequencies(frequency_dict)
    
    sorted_frequency = sort_frequency_dict(adjusted_frequency)
    
    print("Sorted Assembly Instruction Frequencies (adjusted):")
    for asm, count in sorted_frequency:
        print(f"{asm}: {count}")
