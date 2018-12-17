SetActiveLib -work
comp -include "$dsn\src\queue.vhd" 
comp -include "$dsn\src\TestBench\queue_TB.vhd" 
asim +access +r TESTBENCH_FOR_queue 
wave 
wave -noreg clk
wave -noreg rst
wave -noreg re
wave -noreg we
wave -noreg din
wave -noreg dout
wave -noreg empty
wave -noreg full
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\queue_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_queue 
