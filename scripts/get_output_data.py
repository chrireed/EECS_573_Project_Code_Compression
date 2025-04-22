import os
import re
from pathlib import Path

EXCLUDED_PROGRAMS = {
    "basic", 
    "hello",
    "helloworld",
    "multest",
    "sieve"
}

def parse_output_files(directory="../output"):  # Changed to look in parent/output
    # Dictionary to store results for each program
    results = {}
    
    # Regular expressions to extract the information we need
    program_name_re = re.compile(r"output/([^/]+)\.out")
    miss_rate_re = re.compile(r"Miss rate:\s+([\d.]+)")
    occupancy_re = re.compile(r"Icache occupancy:\s+(\d+)")
    
    # Walk through the directory
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(".out"):
                filepath = os.path.join(root, file)
                # Extract program name from filename (without the .out extension)
                program_name = os.path.splitext(file)[0]
                
                if program_name in EXCLUDED_PROGRAMS:
                    continue
                    
                # Read the file
                try:
                    with open(filepath, 'r') as f:
                        content = f.read()
                except FileNotFoundError:
                    print(f"Warning: Could not read file {filepath}")
                    continue
                
                # Find miss rate and occupancy
                miss_rate_match = miss_rate_re.search(content)
                occupancy_match = occupancy_re.search(content)
                
                if miss_rate_match and occupancy_match:
                    miss_rate = float(miss_rate_match.group(1))
                    occupancy = int(occupancy_match.group(1))
                    results[program_name] = {
                        'miss_rate': miss_rate,
                        'occupancy': occupancy
                    }
                else:
                    print(f"Warning: Could not find metrics in {filepath}")
    
    return results

def calculate_averages(results):
    if not results:
        return None, None
    
    total_miss_rate = 0
    total_occupancy = 0
    count = len(results)
    
    for program in results.values():
        total_miss_rate += program['miss_rate']
        total_occupancy += program['occupancy']
    
    avg_miss_rate = total_miss_rate / count
    avg_occupancy = total_occupancy / count
    
    return avg_miss_rate, avg_occupancy

def print_results(results, avg_miss_rate, avg_occupancy):
    print("{:<20} {:<15} {:<15}".format("Program", "Miss Rate", "Occupancy"))
    print("-" * 50)
    
    for program, data in sorted(results.items()):
        print("{:<20} {:<15.6f} {:<15}".format(
            program, data['miss_rate'], data['occupancy']
        ))
    
    if avg_miss_rate is not None and avg_occupancy is not None:
        print("\n{:<20} {:<15.6f} {:<15.2f}".format(
            "Averages:", avg_miss_rate, avg_occupancy
        ))

def main():
    # Parse the files
    results = parse_output_files()
    
    if not results:
        print("No valid output files found in the '../output' directory.")
        return
    
    # Calculate averages
    avg_miss_rate, avg_occupancy = calculate_averages(results)
    
    # Print results
    print_results(results, avg_miss_rate, avg_occupancy)

if __name__ == "__main__":
    main()