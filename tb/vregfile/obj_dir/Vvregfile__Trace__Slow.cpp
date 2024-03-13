// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vvregfile__Syms.h"


void Vvregfile___024root__traceInitSub0(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) VL_ATTR_COLD;

void Vvregfile___024root__traceInitTop(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    {
        Vvregfile___024root__traceInitSub0(vlSelf, tracep);
    }
}

void Vvregfile___024root__traceInitSub0(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    const int c = vlSymsp->__Vm_baseCode;
    if (false && tracep && c) {}  // Prevent unused
    // Body
    {
        tracep->declBit(c+129,"clk_i", false,-1);
        tracep->declBit(c+130,"rst_ni", false,-1);
        tracep->declBit(c+131,"we_i", false,-1);
        tracep->declBus(c+132,"addr_i", false,-1, 4,0);
        tracep->declArray(c+133,"wdata_i", false,-1, 127,0);
        tracep->declArray(c+137,"rdata_o", false,-1, 127,0);
        tracep->declBus(c+141,"vregfile DataWidth", false,-1, 31,0);
        tracep->declBus(c+142,"vregfile AddrWidth", false,-1, 31,0);
        tracep->declBit(c+129,"vregfile clk_i", false,-1);
        tracep->declBit(c+130,"vregfile rst_ni", false,-1);
        tracep->declBit(c+131,"vregfile we_i", false,-1);
        tracep->declBus(c+132,"vregfile addr_i", false,-1, 4,0);
        tracep->declArray(c+133,"vregfile wdata_i", false,-1, 127,0);
        tracep->declArray(c+137,"vregfile rdata_o", false,-1, 127,0);
        tracep->declBus(c+143,"vregfile NUM_WORDS", false,-1, 31,0);
        tracep->declArray(c+1,"vregfile mem", false,-1, 4095,0);
    }
}

void Vvregfile___024root__traceFullTop0(void* voidSelf, VerilatedVcd* tracep) VL_ATTR_COLD;
void Vvregfile___024root__traceChgTop0(void* voidSelf, VerilatedVcd* tracep);
void Vvregfile___024root__traceCleanup(void* voidSelf, VerilatedVcd* /*unused*/);

void Vvregfile___024root__traceRegister(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    {
        tracep->addFullCb(&Vvregfile___024root__traceFullTop0, vlSelf);
        tracep->addChgCb(&Vvregfile___024root__traceChgTop0, vlSelf);
        tracep->addCleanupCb(&Vvregfile___024root__traceCleanup, vlSelf);
    }
}

void Vvregfile___024root__traceFullSub0(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) VL_ATTR_COLD;

void Vvregfile___024root__traceFullTop0(void* voidSelf, VerilatedVcd* tracep) {
    Vvregfile___024root* const __restrict vlSelf = static_cast<Vvregfile___024root*>(voidSelf);
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    {
        Vvregfile___024root__traceFullSub0((&vlSymsp->TOP), tracep);
    }
}

void Vvregfile___024root__traceFullSub0(Vvregfile___024root* vlSelf, VerilatedVcd* tracep) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    vluint32_t* const oldp = tracep->oldp(vlSymsp->__Vm_baseCode);
    if (false && oldp) {}  // Prevent unused
    // Body
    {
        tracep->fullWData(oldp+1,(vlSelf->vregfile__DOT__mem),4096);
        tracep->fullBit(oldp+129,(vlSelf->clk_i));
        tracep->fullBit(oldp+130,(vlSelf->rst_ni));
        tracep->fullBit(oldp+131,(vlSelf->we_i));
        tracep->fullCData(oldp+132,(vlSelf->addr_i),5);
        tracep->fullWData(oldp+133,(vlSelf->wdata_i),128);
        tracep->fullWData(oldp+137,(vlSelf->rdata_o),128);
        tracep->fullIData(oldp+141,(0x80U),32);
        tracep->fullIData(oldp+142,(5U),32);
        tracep->fullIData(oldp+143,(0x20U),32);
    }
}
