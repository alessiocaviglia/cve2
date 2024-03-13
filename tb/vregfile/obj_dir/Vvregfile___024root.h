// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vvregfile.h for the primary calling header

#ifndef VERILATED_VVREGFILE___024ROOT_H_
#define VERILATED_VVREGFILE___024ROOT_H_  // guard

#include "verilated_heavy.h"

//==========

class Vvregfile__Syms;
class Vvregfile_VerilatedVcd;


//----------

VL_MODULE(Vvregfile___024root) {
  public:

    // PORTS
    VL_IN8(clk_i,0,0);
    VL_IN8(rst_ni,0,0);
    VL_IN8(we_i,0,0);
    VL_IN8(addr_i,4,0);
    VL_INW(wdata_i,127,0,4);
    VL_OUTW(rdata_o,127,0,4);

    // LOCAL SIGNALS
    VlWide<128>/*4095:0*/ vregfile__DOT__mem;

    // LOCAL VARIABLES
    CData/*0:0*/ __Vclklast__TOP__clk_i;
    CData/*0:0*/ __Vclklast__TOP__rst_ni;
    VlUnpacked<CData/*0:0*/, 2> __Vm_traceActivity;

    // INTERNAL VARIABLES
    Vvregfile__Syms* vlSymsp;  // Symbol table

    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vvregfile___024root);  ///< Copying not allowed
  public:
    Vvregfile___024root(const char* name);
    ~Vvregfile___024root();

    // INTERNAL METHODS
    void __Vconfigure(Vvregfile__Syms* symsp, bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
