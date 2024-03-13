verilator -Wall --trace -cc ../../rtl/vregfile.sv --exe tb_vregfile.cpp
make -C obj_dir -f Vvregfile.mk Vvregfile
./obj_dir/Vvregfile
gtkwave waveform.vcd