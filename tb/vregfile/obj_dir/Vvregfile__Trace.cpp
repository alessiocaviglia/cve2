// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vvregfile__Syms.h"


void Vvregfile___024root__traceChgSub0(Vvregfile___024root* vlSelf, VerilatedVcd* tracep);

void Vvregfile___024root__traceChgTop0(void* voidSelf, VerilatedVcd* tracep) {
    Vvregfile___024root* const __restrict vlSelf = static_cast<Vvregfile___024root*>(voidSelf);
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    {
        Vvregfile___024root__traceChgSub0((&vlSymsp->TOP), tracep);
    }
}

void Vvregfile___024root__traceChgSub0(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    vluint32_t* const oldp = tracep->oldp(vlSymsp->__Vm_baseCode + 1);
    if (false && oldp) {}  // Prevent unused
    // Body
    {
        if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[1U])) {
            tracep->chgWData(oldp+0,(vlSelf->vregfile__DOT__mem),4096);
        }
        tracep->chgBit(oldp+128,(vlSelf->clk_i));
        tracep->chgBit(oldp+129,(vlSelf->rst_ni));
        tracep->chgBit(oldp+130,(vlSelf->we_i));
        tracep->chgCData(oldp+131,(vlSelf->addr_i),5);
        tracep->chgWData(oldp+132,(vlSelf->wdata_i),128);
        tracep->chgWData(oldp+136,(vlSelf->rdata_o),128);
    }
}

void Vvregfile___024root__traceCleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    Vvregfile___024root* const __restrict vlSelf = static_cast<Vvregfile___024root*>(voidSelf);
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    {
        vlSymsp->__Vm_activity = false;
        vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
        vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
    }
}
