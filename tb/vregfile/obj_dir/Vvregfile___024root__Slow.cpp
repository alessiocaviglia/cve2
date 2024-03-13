// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vvregfile.h for the primary calling header

#include "Vvregfile___024root.h"
#include "Vvregfile__Syms.h"

//==========


void Vvregfile___024root___ctor_var_reset(Vvregfile___024root* vlSelf);

Vvregfile___024root::Vvregfile___024root(const char* _vcname__)
    : VerilatedModule(_vcname__)
 {
    // Reset structure values
    Vvregfile___024root___ctor_var_reset(this);
}

void Vvregfile___024root::__Vconfigure(Vvregfile__Syms* _vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->vlSymsp = _vlSymsp;
}

Vvregfile___024root::~Vvregfile___024root() {
}

void Vvregfile___024root___eval_initial(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vclklast__TOP__clk_i = vlSelf->clk_i;
    vlSelf->__Vclklast__TOP__rst_ni = vlSelf->rst_ni;
}

void Vvregfile___024root___settle__TOP__2(Vvregfile___024root* vlSelf);

void Vvregfile___024root___eval_settle(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___eval_settle\n"); );
    // Body
    Vvregfile___024root___settle__TOP__2(vlSelf);
}

void Vvregfile___024root___final(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___final\n"); );
}

void Vvregfile___024root___ctor_var_reset(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk_i = VL_RAND_RESET_I(1);
    vlSelf->rst_ni = VL_RAND_RESET_I(1);
    vlSelf->we_i = VL_RAND_RESET_I(1);
    vlSelf->addr_i = VL_RAND_RESET_I(5);
    VL_RAND_RESET_W(128, vlSelf->wdata_i);
    VL_RAND_RESET_W(128, vlSelf->rdata_o);
    VL_RAND_RESET_W(4096, vlSelf->vregfile__DOT__mem);
    for (int __Vi0=0; __Vi0<2; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = VL_RAND_RESET_I(1);
    }
}
