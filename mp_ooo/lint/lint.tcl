read_file -type verilog $env(PKG_SRCS) $env(HDL_SRCS)
<<<<<<< HEAD
read_file -type gateslibdb $env(SRAM_LIB)
=======
if {$env(SRAM_LIB) != ""} {
    read_file -type gateslibdb $env(SRAM_LIB)
}
>>>>>>> 53cde64 (mp_ooo patch3)
read_file -type awl lint.awl

set_option top cpu
set_option enable_gateslib_autocompile yes
set_option language_mode verilog
set_option enableSV09 yes
set_option enable_save_restore no
<<<<<<< HEAD
set_option mthresh 65536
=======
set_option mthresh 2000000000
>>>>>>> 53cde64 (mp_ooo patch3)

current_goal Design_Read -top cpu

current_goal lint/lint_turbo_rtl -top cpu

set_parameter checkfullstruct true

run_goal

# help -rules STARC05-2.11.3.1
