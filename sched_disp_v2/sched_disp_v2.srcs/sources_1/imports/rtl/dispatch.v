`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// dispatch.v  -  Dispatcher (parte "entregar") do scheduler/dispatcher v2
//
// Logica puramente combinacional (nao tem registradores, nao usa clock).
// Recebe QUAL unidade foi escolhida (sel) e QUANDO despachar (issue), e:
//   - liga o u_start somente da unidade escolhida;
//   - devolve o ready e o done somente da unidade escolhida;
//   - avisa se OUTRA unidade mandou done (other_done = comportamento errado).
//
// Unidades (proposta): 0 = LOAD, 1 = COMPUTE, 2 = STORE. sel = 3 nao existe.
// -----------------------------------------------------------------------------
module dispatch (
    input  wire [1:0] sel,         // unidade escolhida pelo scheduler
    input  wire       issue,       // 1 durante o ciclo de despacho (estado ISSUE)
    input  wire [2:0] u_ready,     // ready vindo das 3 unidades
    input  wire [2:0] u_done,      // done vindo das 3 unidades
    output wire [2:0] u_start,     // start para as 3 unidades
    output wire       sel_ready,   // a unidade escolhida esta livre?
    output wire       sel_done,    // a unidade escolhida terminou?
    output wire       other_done   // alguma unidade NAO escolhida mandou done?
);
    // "one-hot": um bit em 1 para cada unidade. Ex.: sel = 1 -> 3'b010
    wire [2:0] sel_onehot = (sel == 2'd0) ? 3'b001 :
                            (sel == 2'd1) ? 3'b010 :
                            (sel == 2'd2) ? 3'b100 :
                                            3'b000;   // sel = 3: nenhuma

    assign u_start    = issue ? sel_onehot : 3'b000;
    assign sel_ready  = |(u_ready & sel_onehot);
    assign sel_done   = |(u_done  & sel_onehot);
    assign other_done = |(u_done  & ~sel_onehot);
endmodule
