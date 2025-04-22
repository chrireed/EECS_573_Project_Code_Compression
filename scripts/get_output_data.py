import os
import re
from pathlib import Path

EXCLUDED_PROGRAMS = {
    "basic", 
    "hello",
    "helloworld",
    "multest",
    "sieve",
    "crc32",
    "edn",
    "huffbench",
    "matmult-int",
    "mont64",
    "md5sum",
    "primecount",
    "sglib-combined",
    "slre",
    "tarfind",
    "ud",
    "qrduino"
}

def parse_output_files(directory="../output"):
    results = {}
    
    # Regular expressions for all metrics
    miss_rate_re = re.compile(r"Miss rate:\s+([\d.]+)")
    occupancy_re = re.compile(r"Icache occupancy:\s+(\d+)")
    cycles_re = re.compile(r"Cycle counter\s+\.+(\d+)")
    imem_re = re.compile(r"Imem Accesses:\s+([\d.]+)")

    for file in os.listdir(directory):
        if file.endswith(".out"):
            program_name = os.path.splitext(file)[0]
            
            if program_name in EXCLUDED_PROGRAMS:
                print(f"Skipping excluded program: {program_name}")
                continue
            
            filepath = os.path.join(directory, file)
            
            try:
                with open(filepath, 'r') as f:
                    content = f.read()
                
                # Extract all metrics (without walrus operator)
                metrics = {}
                miss_match = miss_rate_re.search(content)
                occ_match = occupancy_re.search(content)
                cycle_match = cycles_re.search(content)
                imem_match = imem_re.search(content)
                
                if miss_match:
                    metrics['Miss Rate'] = float(miss_match.group(1))
                if occ_match:
                    metrics['Occupancy'] = int(occ_match.group(1))
                if cycle_match:
                    metrics['Cycles'] = int(cycle_match.group(1))
                if imem_match:
                    metrics['Imem Accesses'] = float(imem_match.group(1))
                
                if metrics:  # Only add if we found at least one metric
                    results[program_name] = metrics
                    
            except Exception as e:
                print(f"Error processing {filepath}: {e}")
    
    return results

def print_results(results):
    if not results:
        print("No results found!")
        return
    
    # Determine column widths
    max_program_len = max(len(prog) for prog in results.keys())
    max_program_len = max(max_program_len, len("Program"))
    
    # Header
    header = (f"{'Program':<{max_program_len}}  "
              f"{'Miss Rate':<12}  "
              f"{'Occupancy':<10}  "
              f"{'Cycles':<12}  "
              f"{'Imem Accesses':<15}")
    print(header)
    print("-" * len(header))
    
    # Rows
    for program, data in sorted(results.items()):
        print(f"{program:<{max_program_len}}  "
              f"{data.get('Miss Rate', 'N/A'):<12.3f}  "
              f"{data.get('Occupancy', 'N/A'):<10}  "
              f"{data.get('Cycles', 'N/A'):<12}  "
              f"{data.get('Imem Accesses', 'N/A'):<15.2f}")
    
    # Averages
    print("-" * len(header))
    if results:
        avg_miss = sum(d.get('Miss Rate', 0) for d in results.values()) / len(results)
        avg_occ = sum(d.get('Occupancy', 0) for d in results.values()) / len(results)
        avg_cycles = sum(d.get('Cycles', 0) for d in results.values()) / len(results)
        avg_imem = sum(d.get('Imem Accesses', 0) for d in results.values()) / len(results)
        
        print(f"{'Average':<{max_program_len}}  "
              f"{avg_miss:<12.3f}  "
              f"{avg_occ:<10.1f}  "
              f"{avg_cycles:<12.1f}  "
              f"{avg_imem:<15.2f}")

def main():
    results = parse_output_files()
    print("\nPerformance Metrics (Excluded: {EXCLUDED_PROGRAMS}):")
    print_results(results)

if __name__ == "__main__":
    main()