// Taken from picorv32 firmware/

#include "firmware.h"

int main() {
    int x = 2 + 1;
    int y = 2*x;
    int z = x*x;
    print_hex(x,1);
    print_chr('\n');
    print_hex(y,1);
    print_chr('\n');
    print_hex(z,1);
    print_chr('\n');
    print_str("Hello World!\n");
    stats();
}