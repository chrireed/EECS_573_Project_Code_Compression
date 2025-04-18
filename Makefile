##########################
# ---- Introduction ---- #
##########################

# default target
.DEFAULT_GOAL = helloworld.out
# ^ this overrides using the first listed target as the default

# ---- Program Execution ---- #
# these are your main commands for running programs and generating output
# make <my_program>.out      <- run a program on simv and generate .out, .trace, and .memaccess files in 'output/'
# make <my_program>.syn.out  <- run a program on syn_simv and do the same
# make simulate_all          <- run every program on simv at once (in parallel with -j)
# make simulate_all_syn      <- run every program on syn_simv at once (in parallel with -j)

# ---- Executable Compilation ---- #
# make simv      <- compiles simv from the TESTBENCH and SOURCES
# make syn_simv  <- compiles syn_simv from TESTBENCH and SYNTH_FILES
# make *.vg      <- synthesize modules in SOURCES for use in syn_simv
# make slack     <- grep the slack status of any synthesized modules

# ---- Program Memory Compilation ---- #
# NOTE: programs to run are in the programs/ directory
# make programs/<my_program>.mem  <- compiles a program to a RISC-V memory file for running on the processor
# make compile_all                <- compile every program at once (in parallel with -j)

# ---- Dump Files ---- #
# make <my_program>.dump  <- disassembles <my_program>.mem into .dump_x and .dump_abi RISC-V assembly files
# make *.debug.dump       <- for a .c program, creates dump files after compiling with a debug flag
# make programs/<my_program>.dump_x    <- numeric dump files use x0-x31 as register names
# make programs/<my_program>.dump_abi  <- abi dump files use the abi register names (sp, a0, etc.)
# make dump_all  <- create all dump files at once (in parallel with -j)

# ---- Verdi ---- #
# make <my_program>.verdi     <- run a program in verdi via simv
# make <my_program>.syn.verdi <- run a program in verdi via syn_simv

# ---- Visual Debugger ---- #
# make <my_program>.vis  <- run a program on the project 3 vtuber visual debugger!
# make vis_simv          <- compile the vtuber executable from VTUBER and SOURCES

# ---- Cleanup ---- #
# make clean            <- remove per-run files and compiled executable files
# make nuke             <- remove all files created from make rules
# make clean_run_files  <- remove per-run output files
# make clean_exe        <- remove compiled executable files
# make clean_synth      <- remove generated synthesis files
# make clean_output     <- remove the entire output/ directory
# make clean_programs   <- remove program memory and dump files

# Credits:
# Makefile is adapted from EECS470 project makefile

######################################################
# ---- Compilation Commands and Other Variables ---- #
######################################################

# this is a global clock period variable used in the tcl script and referenced in testbenches
export CLOCK_PERIOD = 2.0

# the Verilog Compiler command and arguments
# VCS = SW_VCS=2020.12-SP2-1 vcs +vc -Mupdate -line -full64 -kdb -lca \
#       -debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
# VCS = SW_VCS=2020.12-SP2-1 vcs +vc -Mupdate -line -full64 -kdb -lca +define+DEBUG_CACHE +define+USE_1WA_ICACHE \
# 	-debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
VCS = SW_VCS=2020.12-SP2-1 vcs +vc -Mupdate -line -full64 -kdb -lca +define+DEBUG_CACHE +define+USE_XWA_ICACHE \
	-debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
# VCS = SW_VCS=2020.12-SP2-1 vcs +vcs+dumpvars+test.vcd +vc -Mupdate -line -full64 -kdb -lca \
#       -debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
# VCS = SW_VCS=2023.12-SP2-1 vcs +vc -Mupdate -line -full64 -kdb -lca \
#        -debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
# VCS = SW_VCS=2022.06 vcs +vc -Mupdate -line -full64 -kdb -lca \
#       -debug_access+all+reverse $(VCS_BAD_WARNINGS) +define+CLOCK_PERIOD=$(CLOCK_PERIOD)
# a SYNTH define is added when compiling for synthesis that can be used in testbenches

# remove certain warnings that generate MB of text but can be safely ignored
VCS_BAD_WARNINGS = +warn=noTFIPC +warn=noDEBUG_DEP +warn=noENUMASSIGN

# a reference library of standard structural cells that we link against when synthesizing
LIB = /afs/umich.edu/class/eecs470/lib/verilog/lec25dscc25.v

# the EECS 470 synthesis script
TCL_SCRIPT = synth/470synth.tcl

# build flags
ISA    = -march=rv32im
CFLAGS = -mno-relax $(ISA) -mabi=ilp32 -nostartfiles -mstrict-align

# adjust the optimization if you want programs to run faster; this may obfuscate/change their instructions
OFLAGS     = -O3
OBJFLAGS   = -SD -M no-aliases
OBJCFLAGS  = --set-section-flags .bss=contents,alloc,readonly
OBJDFLAGS  = -SD -M numeric,no-aliases
DEBUG_FLAG = -g

# this is our RISC-V compiler toolchain
# NOTE: you can use a local riscv install to compile programs by setting CAEN to 0
CAEN = 1
ifeq (1, $(CAEN))
    GCC     = riscv gcc
    OBJCOPY = riscv objcopy
    OBJDUMP = riscv objdump
    AS      = riscv as
    ELF2HEX = riscv elf2hex
	STRIP	= riscv strip
else
    GCC     = riscv64-unknown-elf-gcc
    OBJCOPY = riscv64-unknown-elf-objcopy
    OBJDUMP = riscv64-unknown-elf-objdump
    AS      = riscv64-unknown-elf-as
    ELF2HEX = elf2hex
	STRIP	= 
endif

####################################
# ---- Executable Compilation ---- #
####################################

# NOTE: the executables are not the only things you need to compile
# you must also create a programs/*.mem file for each program you run
# which will be loaded into mem by the testbench on startup
# To run a program on simv or syn_simv, see the program execution section
# This is done automatically with 'make <my_program>.out'

HEADERS = 

TESTBENCH_BASE = tests/testbench_base.v

TESTBENCH = tests/testbench.v

MEM 	  = verilog/imem.v \
			verilog/dmem.v

SOURCES = 	verilog/picorv32.v \
			verilog/icache_1wa.v \
			verilog/icache_Xwa.v

SYNTH_FILES = 	synth/picorv32.vg \
				synth/icache_1wa.vg \
				synth/icache_Xwa.vg

# the normal simulation executable will run your testbench on the original modules
simv: $(TESTBENCH) $(SOURCES) $(MEM) $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $(filter-out $(HEADERS),$^) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

simv_base: $(TESTBENCH_BASE) $(SOURCES) $(DMEM) $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the simulation executable $@)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	$(VCS) $(filter-out $(HEADERS),$^) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

# this also generates many other files, see the tcl script's introduction for info on each of them
synth/%.vg: $(SOURCES) $(TCL_SCRIPT) $(HEADERS)
	@$(call PRINT_COLOR, 5, synthesizing the $* module)
	@$(call PRINT_COLOR, 3, this might take a while...)
	@$(call PRINT_COLOR, 3, NOTE: if this is slow to startup: run '"module load vcs verdi synopsys-synth"')
	# pipefail causes the command to exit on failure even though it's piping to tee
	set -o pipefail; cd synth && MODULE=$* SOURCES="$(SOURCES)" dc_shell-t -f $(notdir $(TCL_SCRIPT)) | tee $*_synth.out
	@$(call PRINT_COLOR, 6, finished synthesizing $@)

# the synthesis executable runs your testbench on the synthesized versions of your modules
syn_simv: $(TESTBENCH) $(SYNTH_FILES) $(MEM) $(HEADERS)
	@$(call PRINT_COLOR, 5, compiling the synthesis executable $@)
	$(VCS) +define+SYNTH $(filter-out $(HEADERS),$^) $(LIB) -o $@
	@$(call PRINT_COLOR, 6, finished compiling $@)

testbench.saif:
	vcd2saif -input testbench.vcd -o synth/testbench.saif
# a phony target to view the slack in the *.rep synthesis report file
slack:
	grep --color=auto "slack" synth/*.rep
.PHONY: slack

########################################
# ---- Program Memory Compilation ---- #
########################################

# this section will compile programs into .mem files to be loaded into memory
# you start with either a C program in the programs/ directory
# those compile into a .elf link file via the riscv assembler or compiler
# then that link file is converted to a .mem hex file

# find the test program files and separate them based on suffix of .s or .c
# filter out files that aren't themselves programs
NON_PROGRAMS = $(ENTRY)
C_CODE   = $(filter-out $(NON_PROGRAMS),$(wildcard programs/*.c))

# concatenate ASSEMBLY and C_CODE to list every program
#PROGRAMS = $(ASSEMBLY:%.s=%) $(C_CODE:%.c=%)
EMB_PROGRAMS = programs/mont64 programs/crc32 programs/cubic programs/edn \
               programs/huffbench programs/matmult-int programs/md5sum \
               programs/minver programs/nbody programs/nettle-aes \
               programs/nettle-sha256 programs/nsichneu programs/picojpeg \
               programs/primecount programs/qrduino programs/sglib-combined \
               programs/slre programs/st programs/statemate programs/tarfind \
               programs/ud programs/wikisort
PROGRAMS = $(C_CODE:%.c=%) $(EMB_PROGRAMS)

PROGRAMS_STRIP = $(PROGRAMS:programs/%=%)
# NOTE: this is Make's pattern substitution syntax
# see: https://www.gnu.org/software/make/manual/html_node/Text-Functions.html#Text-Functions
# this reads as: $(var:pattern=replacement)
# a percent sign '%' in pattern is as a wildcard, and can be reused in the replacement
# if you don't include the percent it automatically attempts to replace just the suffix of the input

# C and assembly compilation files. These link and setup the runtime for the programs
ENTRY     		= firmware/entry.S
LINKERS    		= firmware/linker.lds
FIRMWARE   		= firmware/print.c firmware/stats.c firmware/firmware.h
FIRMWARE_DIR	= firmware/

# make elf files from C source code and strip debug info
%.elf: %.c $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(ISA) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) $< -T $(LINKERS) -o $@
	$(STRIP) --strip-debug $@
	

# C programs can also be compiled in debug mode, this is solely meant for use in the .dump files below
%.debug.elf: %.c $(ENTRY) $(LINKERS)
	@$(call PRINT_COLOR, 5, compiling debug C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) $< -T $(LINKERS) -o $@
	$(GCC) $(DEBUG_FLAG) $(CFLAGS) $(OFLAGS) $(ENTRY) $< -T $(LINKERS) -o $@

# turn any elf file into a hex memory file ready for the testbench
# each line of mem corresponds to 1 word (4B/32b) in memory
%.mem: %.elf
	$(ELF2HEX) 4 32768 $< > $@
	@$(call PRINT_COLOR, 6, created memory file $@)
	@$(call PRINT_COLOR, 3, NOTE: to see RISC-V assembly run: '"make $*.dump"')
	@$(call PRINT_COLOR, 3, for \*.c sources also try: '"make $*.debug.dump"')

# compile all programs in one command (use 'make -j' to run multithreaded)
compile_all: $(PROGRAMS:=.mem)
.PHONY: compile_all

./%.elf: programs/%.elf;
./%.mem: programs/%.mem;
.PRECIOUS: ./%.elf

########################
# ---- Dump Files ---- #
########################

# when debugging a program, the dump files will show you the disassembled RISC-V
# assembly code that your processor is actually running

# this creates the <my_program>.debug.elf targets, which can be used in: 'make <my_program>.debug.dump_*'
# these are useful for the C sources because the debug flag makes the assembly more understandable
# because it includes some of the original C operations and function/variable names

#DUMP_PROGRAMS = $(C_CODE:.c=.debug)
DUMP_PROGRAMS = $(PROGRAMS)

# 'make <my_program>.dump' will create both files at once!
./%.dump: programs/%.dump_x programs/%.dump_abi ;
.PHONY: ./%.dump
# Tell tell Make to treat the .dump_* files as "precious" and not to rm them as intermediaries to %.dump
.PRECIOUS: %.dump_x %.dump_abi

# use the numberic x0-x31 register names
%.dump_x: %.elf
	@$(call PRINT_COLOR, 5, disassembling $<)
	$(OBJDUMP) $(OBJDFLAGS) $< > $@
	@$(call PRINT_COLOR, 6, created numeric dump file $@)

# use the Application Binary Interface register names (sp, a0, etc.)
%.dump_abi: %.elf
	@$(call PRINT_COLOR, 5, disassembling $<)
	$(OBJDUMP) $(OBJFLAGS) $< > $@
	@$(call PRINT_COLOR, 6, created abi dump file $@)

# create all dump files in one command (use 'make -j' to run multithreaded)
#dump_all: $(DUMP_PROGRAMS:=.dump_x) $(DUMP_PROGRAMS:=.dump_abi)
dump_all: $(DUMP_PROGRAMS:=.dump_abi)
.PHONY: dump_all

# consume the output trace
%.trace_dump: programs/%.dump_abi output/%.out
	@$(call PRINT_COLOR, 5, consuming trace for $*)
	python3 scripts/showtrace.py output/$*.trace programs/$*.dump_abi > output/$@

%.syn.trace_dump: programs/%.dump_abi output/%.out scripts/showtrace.py 
	@$(call PRINT_COLOR, 5, consuming trace for $*)
	python3 scripts/showtrace.py output/$*.trace programs/$*.dump_abi > output/$@

profiling:
	mkdir -p profiling

%.trace.prof: %.trace_dump profiling
	python3 profiletracedump.py $< > profiling/$@

%.bitf: %.trace_dump profiling
	python3 profilebitfields.py output/$< > profiling/$@

%.cache: %.trace_dump profiling
	python3 profilecachelines.py output/$*.trace_dump programs/$*.mem > profiling/$@

./programs/%.trace_dump: %.trace_dump;
trace_dump_all: $(DUMP_PROGRAMS:=.trace_dump)
bitf_all: $(PROGRAMS_STRIP:=.bitf)
cache_all: $(PROGRAMS_STRIP:=.cache)
###############################
# ---- Program Execution ---- #
###############################

# run one of the executables (simv/syn_simv) using the chosen program
# e.g. 'make sampler.out' does the following from a clean directory:
#   1. compiles simv
#   2. compiles programs/sampler.s into its .elf and then .mem files (in programs/)
#   3. runs ./simv +MEMORY=programs/sampler.mem +WRITEBACK=output/sampler.wb +PIPELINE=output/sampler.ppln > output/sampler.out
#   4. which creates the sampler.out, sampler.wb, and sampler.ppln files in output/
# the same can be done for synthesis by doing 'make sampler.syn.out'
# which will also create .syn.wb and .syn.ppln files in output/

# targets built in the 'output/' directory should create output/ if it doesn't exist
# (it's deleted entirely by 'make nuke')
# NOTE: place it after the pipe "|" as an order-only pre-requisite
output:
	mkdir -p output

OUTPUTS = $(PROGRAMS:programs/%=output/%)

# run a program and produce output files
$(OUTPUTS:=.out): output/%.out: programs/%.mem simv | output
	@$(call PRINT_COLOR, 5, running simv on $<)
	./simv +MEMORY=$< +TRACE=$(@D)/$*.trace +MEMACCESS=$(@D)/$*.memacc > $@
	@$(call PRINT_COLOR, 6, finished running simv on $<)
	@$(call PRINT_COLOR, 2, output is in $@, $(@D)/$*.memaccess, and $(@D)/$*.trace)

$(OUTPUTS:=.base.out): output/%.base.out: programs/%.mem simv_base | output
	@$(call PRINT_COLOR, 5, running simv on $<)
	./simv_base +MEMORY=$< +TRACE=$(@D)/$*.base.trace +MEMACCESS=$(@D)/$*.base.memacc > $@
	@$(call PRINT_COLOR, 6, finished running simv on $<)
	@$(call PRINT_COLOR, 2, output is in $@, $(@D)/$*.memaccess, and $(@D)/$*.trace)
# NOTE: this uses a 'static pattern rule' to match a list of known targets to a pattern
# and then generates the correct rule based on the pattern, where % and $* match
# so for the target 'output/sampler.out' the % matches 'sampler' and depends on programs/sampler.mem
# see: https://www.gnu.org/software/make/manual/html_node/Static-Usage.html
# $(@D) is an automatic variable for the directory of the target, in this case, 'output'

# this does the same as simv, but adds .syn to the output files and compiles syn_simv instead
# run synthesis with: 'make <my_program>.syn.out'
$(OUTPUTS:=.syn.out): output/%.syn.out: programs/%.mem syn_simv | output
	@$(call PRINT_COLOR, 5, running syn_simv on $<)
	@$(call PRINT_COLOR, 3, this might take a while...)
	./syn_simv +MEMORY=$< +TRACE=$(@D)/$*.syn.trace +MEMACCESS=$(@D)/$*.syn.memacc > $@
	@$(call PRINT_COLOR, 6, finished running syn_simv on $<)
	@$(call PRINT_COLOR, 2, output is in $@ $(@D)/$*.syn.memaccess, and $(@D)/$*.syn.trace)

# Allow us to type 'make <my_program>.out' instead of 'make output/<my_program>.out'
./%.out: output/%.out ;
.PHONY: ./%.out

# Declare that creating a %.out file also creates both %.wb and %.ppln files
%.wb %.ppln: %.out ;

# run all programs in one command (use 'make -j' to run multithreaded)
simulate_all: simv compile_all $(OUTPUTS:=.out)
simulate_all_base: simv compile_all $(OUTPUTS:=.base.out)
simulate_all_syn: syn_simv compile_all $(OUTPUTS:=.syn.out)
.PHONY: simulate_all simulate_all_syn

#######################
# ---- Module TB ---- #
#######################
icache_1wa_simv: tests/icache_1wa_tb.v verilog/icache_1wa.v verilog/imem.v
	$(VCS) +define+DEBUG_CACHE tests/icache_1wa_tb.v verilog/picorv32.v verilog/icache_1wa.v verilog/imem.v -o icache_1wa_simv

%.icache_1wa_simv.out: programs/%.mem icache_1wa_simv output
	./icache_1wa_simv +MEMORY=$< > output/$@

%.icache_1wa_simv.verdi: programs/%.mem simv novas.rc verdi_dir icache_1wa_simv
	./icache_1wa_simv -gui=verdi +MEMORY=$<

icache_2wa_simv: tests/icache_2wa_tb.v verilog/icache_Xwa.v verilog/imem.v
	$(VCS) +define+DEBUG_CACHE tests/icache_2wa_tb.v verilog/picorv32.v verilog/icache_Xwa.v verilog/imem.v -o icache_2wa_simv

%.icache_2wa_simv.out: programs/%.mem icache_2wa_simv output
	./icache_2wa_simv +MEMORY=$< > output/$@

%.icache_2wa_simv.verdi: programs/%.mem simv novas.rc verdi_dir icache_2wa_simv
	./icache_2wa_simv -gui=verdi +MEMORY=$<

icache_4wa_simv: tests/icache_4wa_tb.v verilog/icache_Xwa.v verilog/imem.v
	$(VCS) +define+DEBUG_CACHE tests/icache_4wa_tb.v verilog/picorv32.v verilog/icache_Xwa.v verilog/imem.v -o icache_4wa_simv

%.icache_4wa_simv.out: programs/%.mem icache_4wa_simv output
	./icache_4wa_simv +MEMORY=$< > output/$@

%.icache_4wa_simv.verdi: programs/%.mem simv novas.rc verdi_dir icache_4wa_simv
	./icache_4wa_simv -gui=verdi +MEMORY=$<

###################
# ---- Verdi ---- #
###################

# run verdi on a program with: 'make <my_program>.verdi' or 'make <my_program>.syn.verdi'

# this creates a directory verdi will use if it doesn't exist yet
verdi_dir:
	mkdir -p /tmp/$${USER}470
.PHONY: verdi_dir

novas.rc: initialnovas.rc
	sed s/UNIQNAME/$$USER/ initialnovas.rc > novas.rc

%.verdi: programs/%.mem simv novas.rc verdi_dir
	./simv -gui=verdi +MEMORY=$< +WRITEBACK=/dev/null +PIPELINE=/dev/null

%.syn.verdi: programs/%.mem syn_simv novas.rc verdi_dir
	./syn_simv -gui=verdi +MEMORY=$< +WRITEBACK=/dev/null +PIPELINE=/dev/null

.PHONY: %.verdi

#####################
# ---- Cleanup ---- #
#####################

clean: clean_exe clean_run_files clean_output clean_programs clean_prof

nuke: clean clean_synth
	@$(call PRINT_COLOR, 6, note: nuke is split into multiple commands you can call separately: $^)

clean_exe:
	@$(call PRINT_COLOR, 3, removing compiled executable files)
	rm -rf *simv simv_base *.daidir csrc *.key   # created by simv/syn_simv/vis_simv <-- linux is tweaking THE FILES ARE THERE WDYM THEYRE NOT BUT ARE AT THE SAME TIME
	rm -rf vcdplus.vpd vc_hdrs.h       # created by simv/syn_simv/vis_simv <-- linux is tweaking
	rm -rf verdi* novas* *fsdb*        # verdi files <-- linux is tweaking
	rm -rf dve* inter.vpd DVEfiles     # old DVE debugger

clean_run_files:
	@$(call PRINT_COLOR, 3, removing per-run outputs)
	rm -rf output/*.out output/*.wb output/*.ppln

clean_synth:
	@$(call PRINT_COLOR, 1, removing synthesis files)
	cd synth && rm -rf *.vg *_svsim.sv *.res *.rep *.ddc *.chk *.syn *.out *.db *.svf *.mr *.pvl command.log

clean_output:
	@$(call PRINT_COLOR, 1, removing entire output directory)
	rm -rf output/
	rm -f testbench.vcd

clean_programs:
	@$(call PRINT_COLOR, 3, removing program memory files)
	rm -rf programs/*.mem
	@$(call PRINT_COLOR, 3, removing dump files)
	rm -rf programs/*.dump*
	@$(call PRINT_COLOR, 3, removing elf files)
	rm -rf programs/*.elf

clean_prof:
	rm -rf profiling/
	
.PHONY: clean nuke clean_%

######################
# ---- Printing ---- #
######################

# this is a GNU Make function with two arguments: PRINT_COLOR(color: number, msg: string)
# it does all the color printing throughout the makefile
PRINT_COLOR = if [ -t 0 ]; then tput setaf $(1) ; fi; echo $(2); if [ -t 0 ]; then tput sgr0; fi
# colors: 0:black, 1:red, 2:green, 3:yellow, 4:blue, 5:magenta, 6:cyan, 7:white
# other numbers are valid, but aren't specified in the tput man page

# Make functions are called like this:
# $(call PRINT_COLOR,3,Hello World!)
# NOTE: adding '@' to the start of a line avoids printing the command itself, only the output

#####################
# ---- Embench ---- #
#####################
EMB_SUPPORT_DIR	= ./programs/emb_support/
EMB_SUPPORT 	= $(wildcard programs/emb_support/*.c)

EMB_SRC_MONT64 			= $(wildcard programs/emb_src/aha-mont64/*.c)
EMB_SRC_CRC32 			= $(wildcard programs/emb_src/crc32/*.c)
EMB_SRC_CUBIC 			= $(wildcard programs/emb_src/cubic/*.c)
EMB_SRC_EDN 			= $(wildcard programs/emb_src/edn/*.c)
EMB_SRC_HUFFBENCH 		= $(wildcard programs/emb_src/huffbench/*.c)
EMB_SRC_MATMULT 		= $(wildcard programs/emb_src/matmult-int/*.c)
EMB_SRC_MD5SUM 			= $(wildcard programs/emb_src/md5sum/*.c)
EMB_SRC_MINVER 			= $(wildcard programs/emb_src/minver/*.c)
EMB_SRC_NBODY 			= $(wildcard programs/emb_src/nbody/*.c)
EMB_SRC_NETTLE_AES 		= $(wildcard programs/emb_src/nettle-aes/*.c)
EMB_SRC_NETTLE_SHA256 	= $(wildcard programs/emb_src/nettle-sha256/*.c)
EMB_SRC_NSICHNEU 		= $(wildcard programs/emb_src/nsichneu/*.c)
EMB_SRC_PICOJPEG 		= $(wildcard programs/emb_src/picojpeg/*.c)
EMB_SRC_PRIMECOUNT 		= $(wildcard programs/emb_src/primecount/*.c)
EMB_SRC_QRDUINO 		= $(wildcard programs/emb_src/qrduino/*.c)
EMB_SRC_SGLIB 			= $(wildcard programs/emb_src/sglib-combined/*.c)
EMB_SRC_SLRE 			= $(wildcard programs/emb_src/slre/*.c)
EMB_SRC_ST 				= $(wildcard programs/emb_src/st/*.c)
EMB_SRC_STATEMATE 		= $(wildcard programs/emb_src/statemate/*.c)
EMB_SRC_TARFIND 		= $(wildcard programs/emb_src/tarfind/*.c)
EMB_SRC_UD 				= $(wildcard programs/emb_src/ud/*.c)
EMB_SRC_WIKISORT 		= $(wildcard programs/emb_src/wikisort/*.c)

EMB_LIB_FLAGS	= -lm

# make elf files from C source code
programs/mont64.elf: $(EMB_SUPPORT) $(EMB_SRC_MONT64) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_MONT64) -T $(LINKERS) -o programs/mont64.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/crc32.elf: $(EMB_SUPPORT) $(EMB_SRC_CRC32) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_CRC32) -T $(LINKERS) -o programs/crc32.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/cubic.elf: $(EMB_SUPPORT) $(EMB_SRC_CUBIC) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_CUBIC) -T $(LINKERS) -o programs/cubic.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/edn.elf: $(EMB_SUPPORT) $(EMB_SRC_EDN) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_EDN) -T $(LINKERS) -o programs/edn.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/huffbench.elf: $(EMB_SUPPORT) $(EMB_SRC_HUFFBENCH) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_HUFFBENCH) -T $(LINKERS) -o programs/huffbench.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/matmult-int.elf: $(EMB_SUPPORT) $(EMB_SRC_MATMULT) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_MATMULT) -T $(LINKERS) -o programs/matmult-int.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/md5sum.elf: $(EMB_SUPPORT) $(EMB_SRC_MD5SUM) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_MD5SUM) -T $(LINKERS) -o programs/md5sum.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/minver.elf: $(EMB_SUPPORT) $(EMB_SRC_MINVER) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_MINVER) -T $(LINKERS) -o programs/minver.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/nbody.elf: $(EMB_SUPPORT) $(EMB_SRC_NBODY) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_NBODY) -T $(LINKERS) -o programs/nbody.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/nettle-aes.elf: $(EMB_SUPPORT) $(EMB_SRC_NETTLE_AES) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_NETTLE_AES) -T $(LINKERS) -o programs/nettle-aes.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/nettle-sha256.elf: $(EMB_SUPPORT) $(EMB_SRC_NETTLE_SHA256) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_NETTLE_SHA256) -T $(LINKERS) -o programs/nettle-sha256.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/nsichneu.elf: $(EMB_SUPPORT) $(EMB_SRC_NSICHNEU) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_NSICHNEU) -T $(LINKERS) -o programs/nsichneu.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/picojpeg.elf: $(EMB_SUPPORT) $(EMB_SRC_PICOJPEG) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_PICOJPEG) -T $(LINKERS) -o programs/picojpeg.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/primecount.elf: $(EMB_SUPPORT) $(EMB_SRC_PRIMECOUNT) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_PRIMECOUNT) -T $(LINKERS) -o programs/primecount.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/qrduino.elf: $(EMB_SUPPORT) $(EMB_SRC_QRDUINO) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_QRDUINO) -T $(LINKERS) -o programs/qrduino.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/sglib-combined.elf: $(EMB_SUPPORT) $(EMB_SRC_SGLIB) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_SGLIB) -T $(LINKERS) -o programs/sglib-combined.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/slre.elf: $(EMB_SUPPORT) $(EMB_SRC_SLRE) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_SLRE) -T $(LINKERS) -o programs/slre.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/st.elf: $(EMB_SUPPORT) $(EMB_SRC_ST) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_ST) -T $(LINKERS) -o programs/st.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/statemate.elf: $(EMB_SUPPORT) $(EMB_SRC_STATEMATE) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_STATEMATE) -T $(LINKERS) -o programs/statemate.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/tarfind.elf: $(EMB_SUPPORT) $(EMB_SRC_TARFIND) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_TARFIND) -T $(LINKERS) -o programs/tarfind.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/ud.elf: $(EMB_SUPPORT) $(EMB_SRC_UD) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_UD) -T $(LINKERS) -o programs/ud.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@

programs/wikisort.elf: $(EMB_SUPPORT) $(EMB_SRC_WIKISORT) $(ENTRY) $(LINKERS) $(FIRMWARE)
	@$(call PRINT_COLOR, 5, compiling C code file $<)
	$(GCC) $(CFLAGS) $(OFLAGS) $(ENTRY) -I$(FIRMWARE_DIR) $(FIRMWARE) -I$(EMB_SUPPORT_DIR) $(EMB_SUPPORT) $(EMB_SRC_WIKISORT) -T $(LINKERS) -o programs/wikisort.elf $(EMB_LIB_FLAGS)
	$(STRIP) --strip-debug $@