// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vvregfile.h for the primary calling header

#include "Vvregfile___024root.h"
#include "Vvregfile__Syms.h"

//==========

VL_INLINE_OPT void Vvregfile___024root___sequent__TOP__1(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___sequent__TOP__1\n"); );
    // Body
    if (vlSelf->rst_ni) {
        if (vlSelf->we_i) {
            VL_ASSIGNSEL_WIIW(4096,128,(0xfffU & ((IData)(vlSelf->addr_i) 
                                                  << 7U)), vlSelf->vregfile__DOT__mem, vlSelf->wdata_i);
        }
    } else {
        VL_CONST_W_1X(4096,vlSelf->vregfile__DOT__mem,0x00000000);
    }
}

VL_INLINE_OPT void Vvregfile___024root___settle__TOP__2(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___settle__TOP__2\n"); );
    // Body
    vlSelf->rdata_o[0U] = (((0U == (0x1fU & ((IData)(vlSelf->addr_i) 
                                             << 7U)))
                             ? 0U : (vlSelf->vregfile__DOT__mem[
                                     ((IData)(1U) + 
                                      (0x7cU & ((IData)(vlSelf->addr_i) 
                                                << 2U)))] 
                                     << ((IData)(0x20U) 
                                         - (0x1fU & 
                                            ((IData)(vlSelf->addr_i) 
                                             << 7U))))) 
                           | (vlSelf->vregfile__DOT__mem[
                              (0x7cU & ((IData)(vlSelf->addr_i) 
                                        << 2U))] >> 
                              (0x1fU & ((IData)(vlSelf->addr_i) 
                                        << 7U))));
    vlSelf->rdata_o[1U] = (((0U == (0x1fU & ((IData)(vlSelf->addr_i) 
                                             << 7U)))
                             ? 0U : (vlSelf->vregfile__DOT__mem[
                                     ((IData)(2U) + 
                                      (0x7cU & ((IData)(vlSelf->addr_i) 
                                                << 2U)))] 
                                     << ((IData)(0x20U) 
                                         - (0x1fU & 
                                            ((IData)(vlSelf->addr_i) 
                                             << 7U))))) 
                           | (vlSelf->vregfile__DOT__mem[
                              ((IData)(1U) + (0x7cU 
                                              & ((IData)(vlSelf->addr_i) 
                                                 << 2U)))] 
                              >> (0x1fU & ((IData)(vlSelf->addr_i) 
                                           << 7U))));
    vlSelf->rdata_o[2U] = (((0U == (0x1fU & ((IData)(vlSelf->addr_i) 
                                             << 7U)))
                             ? 0U : (vlSelf->vregfile__DOT__mem[
                                     ((IData)(3U) + 
                                      (0x7cU & ((IData)(vlSelf->addr_i) 
                                                << 2U)))] 
                                     << ((IData)(0x20U) 
                                         - (0x1fU & 
                                            ((IData)(vlSelf->addr_i) 
                                             << 7U))))) 
                           | (vlSelf->vregfile__DOT__mem[
                              ((IData)(2U) + (0x7cU 
                                              & ((IData)(vlSelf->addr_i) 
                                                 << 2U)))] 
                              >> (0x1fU & ((IData)(vlSelf->addr_i) 
                                           << 7U))));
    vlSelf->rdata_o[3U] = (((0U == (0x1fU & ((IData)(vlSelf->addr_i) 
                                             << 7U)))
                             ? 0U : (vlSelf->vregfile__DOT__mem[
                                     ((IData)(4U) + 
                                      (0x7cU & ((IData)(vlSelf->addr_i) 
                                                << 2U)))] 
                                     << ((IData)(0x20U) 
                                         - (0x1fU & 
                                            ((IData)(vlSelf->addr_i) 
                                             << 7U))))) 
                           | (vlSelf->vregfile__DOT__mem[
                              ((IData)(3U) + (0x7cU 
                                              & ((IData)(vlSelf->addr_i) 
                                                 << 2U)))] 
                              >> (0x1fU & ((IData)(vlSelf->addr_i) 
                                           << 7U))));
}

void Vvregfile___024root___eval(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___eval\n"); );
    // Body
    if ((((IData)(vlSelf->clk_i) & (~ (IData)(vlSelf->__Vclklast__TOP__clk_i))) 
         | ((IData)(vlSelf->rst_ni) & (~ (IData)(vlSelf->__Vclklast__TOP__rst_ni))))) {
        Vvregfile___024root___sequent__TOP__1(vlSelf);
        vlSelf->__Vm_traceActivity[1U] = 1U;
    }
    Vvregfile___024root___settle__TOP__2(vlSelf);
    // Final
    vlSelf->__Vclklast__TOP__clk_i = vlSelf->clk_i;
    vlSelf->__Vclklast__TOP__rst_ni = vlSelf->rst_ni;
}

QData Vvregfile___024root___change_request_1(Vvregfile___024root* vlSelf);

VL_INLINE_OPT QData Vvregfile___024root___change_request(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___change_request\n"); );
    // Body
    return (Vvregfile___024root___change_request_1(vlSelf));
}

VL_INLINE_OPT QData Vvregfile___024root___change_request_1(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___change_request_1\n"); );
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vvregfile___024root___eval_debug_assertions(Vvregfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vvregfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vvregfile___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk_i & 0xfeU))) {
        Verilated::overWidthError("clk_i");}
    if (VL_UNLIKELY((vlSelf->rst_ni & 0xfeU))) {
        Verilated::overWidthError("rst_ni");}
    if (VL_UNLIKELY((vlSelf->we_i & 0xfeU))) {
        Verilated::overWidthError("we_i");}
    if (VL_UNLIKELY((vlSelf->addr_i & 0xe0U))) {
        Verilated::overWidthError("addr_i");}
}
#endif  // VL_DEBUG
