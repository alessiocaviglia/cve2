rm -r obj_dir
verilator -Wall --trace -cc ../../rtl/vcve2_fracturable_adder.sv --exe tb_adder.cpp
make -C obj_dir -f Vvcve2_fracturable_adder.mk Vvcve2_fracturable_adder
./obj_dir/Vvcve2_fracturable_adder
gtkwave wave.vcd
