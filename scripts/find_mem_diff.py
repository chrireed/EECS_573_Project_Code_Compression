import sys

def find_first_difference(file1_path, file2_path):
    """Find the first line where two files differ."""
    with open(file1_path, 'r') as file1, open(file2_path, 'r') as file2:
        line_number = 0
        for line1, line2 in zip(file1, file2):
            line_number += 1
            if line1 != line2:
                return line_number, line1.strip(), line2.strip()
        
        # Check if one file has more lines than the other
        remaining_file1 = file1.readline()
        remaining_file2 = file2.readline()
        
        if remaining_file1 or remaining_file2:
            line_number += 1
            return line_number, remaining_file1.strip() if remaining_file1 else "<EOF>", remaining_file2.strip() if remaining_file2 else "<EOF>"
        
        return None  # Files are identical

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python find_diff.py <file1> <file2>")
        sys.exit(1)
    
    file1_path = sys.argv[1]
    file2_path = sys.argv[2]
    
    result = find_first_difference(file1_path, file2_path)
    
    if result:
        line_num, line1, line2 = result
        print(f"First difference at line {line_num}:")
        print(f"File 1: {line1}")
        print(f"File 2: {line2}")
    else:
        print("Files are identical.")