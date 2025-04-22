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
    reg_miss_rate_re = re.compile(r"Icache Miss rate:\s+([\d.]+)")
    reg_occupancy_re = re.compile(r"Icache occupancy:\s+(\d+)")
    comp_miss_rate_re = re.compile(r"Compressed Icache Miss rate:\s+([\d.]+)")
    comp_occupancy_re = re.compile(r"Compressed Icache Occupancy:\s+(\d+)")
    cycles_re = re.compile(r"Cycle counter\s+\.+(\d+)")
    imem_re = re.compile(r"Imem Accesses:\s+(\d+)")
    combined_miss_re = re.compile(r"Combined cache Statistics:\s+Hits:\s+\d+,\s+Misses:\s+\d+\s+Miss rate:\s+([\d.]+)")

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
                
                # Extract all metrics
                metrics = {}
                
                # Regular Icache stats
                reg_miss_match = reg_miss_rate_re.search(content)
                reg_occ_match = reg_occupancy_re.search(content)
                
                # Compressed Icache stats
                comp_miss_match = comp_miss_rate_re.search(content)
                comp_occ_match = comp_occupancy_re.search(content)
                
                # Other metrics
                cycle_match = cycles_re.search(content)
                imem_match = imem_re.search(content)
                combined_miss_match = combined_miss_re.search(content)
                
                if reg_miss_match:
                    metrics['Reg Miss Rate'] = float(reg_miss_match.group(1))
                if reg_occ_match:
                    metrics['Reg Occupancy'] = int(reg_occ_match.group(1))
                if comp_miss_match:
                    metrics['Comp Miss Rate'] = float(comp_miss_match.group(1))
                if comp_occ_match:
                    metrics['Comp Occupancy'] = int(comp_occ_match.group(1))
                if cycle_match:
                    metrics['Cycles'] = int(cycle_match.group(1))
                if imem_match:
                    metrics['Imem Accesses'] = int(imem_match.group(1))
                if combined_miss_match:
                    metrics['Combined Miss Rate'] = float(combined_miss_match.group(1))
                
                if metrics:
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
              f"{'Reg Miss':<10}  "
              f"{'Reg Occ':<8}  "
              f"{'Comp Miss':<10}  "
              f"{'Comp Occ':<8}  "
              f"{'Comb Miss':<10}  "
              f"{'Cycles':<12}  "
              f"{'Imem Acc':<10}")
    print(header)
    print("-" * len(header))
    
    # Rows
    for program, data in sorted(results.items()):
        # Conditional formatting based on whether the value is a float or 'N/A'
        reg_miss_rate = f"{data.get('Reg Miss Rate', 'N/A'):<10}" if isinstance(data.get('Reg Miss Rate'), str) else f"{data.get('Reg Miss Rate', 0):<10.3f}"
        reg_occ = f"{data.get('Reg Occupancy', 'N/A'):<8}" if isinstance(data.get('Reg Occupancy'), str) else f"{data.get('Reg Occupancy', 0):<8}"
        comp_miss_rate = f"{data.get('Comp Miss Rate', 'N/A'):<10}" if isinstance(data.get('Comp Miss Rate'), str) else f"{data.get('Comp Miss Rate', 0):<10.3f}"
        comp_occ = f"{data.get('Comp Occupancy', 'N/A'):<8}" if isinstance(data.get('Comp Occupancy'), str) else f"{data.get('Comp Occupancy', 0):<8}"
        combined_miss_rate = f"{data.get('Combined Miss Rate', 'N/A'):<10}" if isinstance(data.get('Combined Miss Rate'), str) else f"{data.get('Combined Miss Rate', 0):<10.3f}"
        cycles = f"{data.get('Cycles', 'N/A'):<12}" if isinstance(data.get('Cycles'), str) else f"{data.get('Cycles', 0):<12}"
        imem_accesses = f"{data.get('Imem Accesses', 'N/A'):<10}" if isinstance(data.get('Imem Accesses'), str) else f"{data.get('Imem Accesses', 0):<10}"
        
        print(f"{program:<{max_program_len}}  "
              f"{reg_miss_rate}  "
              f"{reg_occ}  "
              f"{comp_miss_rate}  "
              f"{comp_occ}  "
              f"{combined_miss_rate}  "
              f"{cycles}  "
              f"{imem_accesses}")
    
    # Averages
    print("-" * len(header))
    if results:
        def safe_avg(values):
            vals = [v for v in values if v != 'N/A']
            return sum(vals) / len(vals) if vals else 'N/A'
        
        avg_reg_miss = safe_avg(d.get('Reg Miss Rate', 'N/A') for d in results.values())
        avg_reg_occ = safe_avg(d.get('Reg Occupancy', 'N/A') for d in results.values())
        avg_comp_miss = safe_avg(d.get('Comp Miss Rate', 'N/A') for d in results.values())
        avg_comp_occ = safe_avg(d.get('Comp Occupancy', 'N/A') for d in results.values())
        avg_comb_miss = safe_avg(d.get('Combined Miss Rate', 'N/A') for d in results.values())
        avg_cycles = safe_avg(d.get('Cycles', 'N/A') for d in results.values())
        avg_imem = safe_avg(d.get('Imem Accesses', 'N/A') for d in results.values())
        
        print(f"{'Average':<{max_program_len}}  "
              f"{avg_reg_miss if isinstance(avg_reg_miss, str) else avg_reg_miss:<10.3f}  "
              f"{avg_reg_occ if isinstance(avg_reg_occ, str) else avg_reg_occ:<8.1f}  "
              f"{avg_comp_miss if isinstance(avg_comp_miss, str) else avg_comp_miss:<10.3f}  "
              f"{avg_comp_occ if isinstance(avg_comp_occ, str) else avg_comp_occ:<8.1f}  "
              f"{avg_comb_miss if isinstance(avg_comb_miss, str) else avg_comb_miss:<10.3f}  "
              f"{avg_cycles if isinstance(avg_cycles, str) else avg_cycles:<12.1f}  "
              f"{avg_imem if isinstance(avg_imem, str) else avg_imem:<10.1f}")

def main():
    results = parse_output_files()
    print("\nCache Performance Metrics:")
    print_results(results)

if __name__ == "__main__":
    main()