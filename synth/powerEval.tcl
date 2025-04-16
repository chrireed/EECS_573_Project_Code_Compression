set target_library lec25dscc25_TT.db

set link_library "* $target_library"

set search_path [list "./" "../" "/afs/umich.edu/class/eecs470/lib/synopsys/"]

read_ddc icache_1wa.ddc

read_saif -input testbench.saif -instance_name testbench/icache -verbose

report_power -analysis_effort high > icache_power.rep

read_ddc picorv32.ddc

read_saif -input testbench.saif -instance_name testbench/proc -verbose

report_power -analysis_effort high > proc_power.rep

exit 0 ;