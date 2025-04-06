#!/bin/bash

# Assign arguments to variables
pass_keyword="PASSED"
fail_keyword="FAILED"
output_pattern="output/*.syn.out"

files=($output_pattern)

for file in "${files[@]}"; do
    if grep -q "$pass_keyword" "$file"; then
        echo "$file: '$pass_keyword'"
        ((pass_count++))
    fi
done

fail_count=$(expr 22 - $pass_count)
echo "Total passing files: $pass_count"

echo "Failing benchmarks: $fail_count"
