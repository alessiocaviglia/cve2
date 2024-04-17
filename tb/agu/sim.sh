rm -r obj_dir
verilator -Wall --trace -cc ../../rtl/vce2_agu.sv --exe tb_agu.cpp
make -C obj_dir -f Vvce2_agu.mk Vvce2_agu
./obj_dir/Vvce2_agu
gtkwave wave.vcd
