`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// sched_disp.v  -  Scheduler/Dispatcher (versao 2)
//
// Recebe instrucoes do fetch/decoder (handshake valid/ready), uma por vez,
// confere se sao validas e despacha cada uma para a unidade certa:
//   unidade 0 = LOAD    (futuro: data mover - traz dados/pesos da memoria)
//   unidade 1 = COMPUTE (futuro: PEs - fazem as contas da CNN)
//   unidade 2 = STORE   (futuro: data mover - devolve o resultado)
// So aceita a proxima instrucao depois que a anterior terminou (em ordem).
//
// Formato da instrucao (PROPOSTA, a confirmar com a equipe), 16 bits:
//   [15:14] unit_id   0=LOAD 1=COMPUTE 2=STORE (3 = invalido)
//   [13:12] reservado (deve ser 0)
//   [11:8]  opcode    LOAD: 1=pesos 2=entrada
//                     COMPUTE: 1=CONV 2=POOL+ReLU 3=FC 4=ARGMAX
//                     STORE: 1=resultado
//   [7:0]   arg       identificador da camada/buffer
//
// Parte "scheduler" : WAIT_INSTR, CHECK, NEXT  (decide)
// Parte "dispatcher": ISSUE, WAIT_DONE + modulo dispatch.v  (entrega)
//
// Convencoes: clock unico; reset sincrono ativo em 0 (rst_n).
// start, done e u_start sao pulsos de 1 ciclo. start so e aceito em IDLE/ERROR.
// -----------------------------------------------------------------------------
module sched_disp #(
    parameter [15:0] TIMEOUT_CYCLES = 16'd1000
)(
    input  wire        clk,
    input  wire        rst_n,

    // Controle (futuramente: registradores AXI4-Lite)
    input  wire        start,
    input  wire [7:0]  num_tasks,     // quantas instrucoes o programa tem
    output wire        busy,
    output wire        done,
    output wire        error,
    output reg  [3:0]  err_code,

    // Entrada de instrucoes (vindo do fetch/decoder)
    input  wire        instr_valid,   // "tenho uma instrucao para voce"
    output wire        instr_ready,   // "pode mandar, estou esperando"
    input  wire [15:0] instr_data,

    // Unidades de execucao (bit 0 = LOAD, bit 1 = COMPUTE, bit 2 = STORE)
    input  wire [2:0]  u_ready,
    output wire [2:0]  u_start,
    output wire [3:0]  u_op,          // compartilhado: so a unidade com start le
    output wire [7:0]  u_arg,         // compartilhado
    input  wire [2:0]  u_done
);

    // ---------------- Estados ----------------
    localparam [2:0] S_IDLE       = 3'd0,
                     S_WAIT_INSTR = 3'd1,
                     S_CHECK      = 3'd2,
                     S_ISSUE      = 3'd3,
                     S_WAIT_DONE  = 3'd4,
                     S_NEXT       = 3'd5,
                     S_DONE       = 3'd6,
                     S_ERROR      = 3'd7;

    // ---------------- Codigos de erro ----------------
    localparam [3:0] E_NONE            = 4'd0,
                     E_ZERO_TASKS      = 4'd1,  // start com num_tasks == 0
                     E_BAD_UNIT        = 4'd2,  // unit_id == 3
                     E_RSVD_BITS       = 4'd3,  // bits reservados != 0
                     E_BAD_OPCODE      = 4'd4,  // opcode invalido para a unidade
                     E_TIMEOUT_DONE    = 4'd5,  // unidade nao terminou
                     E_SPURIOUS_DONE   = 4'd6,  // done sem ninguem esperar
                     E_TIMEOUT_READY   = 4'd7,  // unidade nunca ficou livre
                     E_TIMEOUT_INSTR   = 4'd8,  // fetch nao entregou instrucao
                     E_WRONG_UNIT_DONE = 4'd9;  // done de unidade nao despachada

    localparam [1:0] U_LOAD = 2'd0, U_COMPUTE = 2'd1, U_STORE = 2'd2;

    reg [2:0]  state;
    reg [7:0]  idx;        // quantas instrucoes ja terminaram
    reg [7:0]  n_tasks;    // copia de num_tasks feita no start
    reg [15:0] instr_reg;  // instrucao atual (guardada)
    reg [15:0] timer;      // contador de espera (timeout)

    // Campos da instrucao atual
    wire [1:0] i_unit = instr_reg[15:14];
    wire [1:0] i_rsvd = instr_reg[13:12];
    wire [3:0] i_op   = instr_reg[11:8];

    // Opcode valido para a unidade escolhida?
    reg i_op_ok;
    always @(*) begin
        case (i_unit)
            U_LOAD:    i_op_ok = (i_op == 4'd1) || (i_op == 4'd2);
            U_COMPUTE: i_op_ok = (i_op >= 4'd1) && (i_op <= 4'd4);
            U_STORE:   i_op_ok = (i_op == 4'd1);
            default:   i_op_ok = 1'b0;
        endcase
    end

    // ---------------- Dispatcher (entrega) ----------------
    wire sel_ready, sel_done, other_done;
    dispatch u_dispatch (
        .sel(i_unit),
        .issue(state == S_ISSUE),
        .u_ready(u_ready),
        .u_done(u_done),
        .u_start(u_start),
        .sel_ready(sel_ready),
        .sel_done(sel_done),
        .other_done(other_done)
    );

    // ---------------- Saidas (dependem so do estado: maquina de Moore) ----------------
    assign busy        = (state == S_WAIT_INSTR) || (state == S_CHECK) ||
                         (state == S_ISSUE)      || (state == S_WAIT_DONE) ||
                         (state == S_NEXT);
    assign done        = (state == S_DONE);
    assign error       = (state == S_ERROR);
    assign instr_ready = (state == S_WAIT_INSTR);
    assign u_op        = instr_reg[11:8];
    assign u_arg       = instr_reg[7:0];

    wire any_done = |u_done;

    // ---------------- Logica sequencial ----------------
    always @(posedge clk) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            idx       <= 8'd0;
            n_tasks   <= 8'd0;
            instr_reg <= 16'd0;
            timer     <= 16'd0;
            err_code  <= E_NONE;
        end else if (any_done && (state != S_WAIT_DONE) && (state != S_ERROR)) begin
            // Prioridade maxima: done que ninguem pediu (inclui done duplicado)
            state    <= S_ERROR;
            err_code <= E_SPURIOUS_DONE;
        end else begin
            case (state)
                // Parado; ERROR tambem aceita novo start (recuperacao)
                S_IDLE, S_ERROR: begin
                    if (start) begin
                        if (num_tasks == 8'd0) begin
                            state    <= S_ERROR;
                            err_code <= E_ZERO_TASKS;
                        end else begin
                            n_tasks  <= num_tasks;
                            idx      <= 8'd0;
                            timer    <= 16'd0;
                            err_code <= E_NONE;
                            state    <= S_WAIT_INSTR;
                        end
                    end
                end

                // ---- scheduler: recebe a instrucao ----
                S_WAIT_INSTR: begin
                    if (instr_valid) begin          // instr_ready = 1 aqui
                        instr_reg <= instr_data;
                        timer     <= 16'd0;
                        state     <= S_CHECK;
                    end else if (timer == TIMEOUT_CYCLES - 1) begin
                        state <= S_ERROR;  err_code <= E_TIMEOUT_INSTR;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                // ---- scheduler: confere e espera a unidade certa ----
                S_CHECK: begin
                    if (i_unit == 2'd3) begin
                        state <= S_ERROR;  err_code <= E_BAD_UNIT;
                    end else if (i_rsvd != 2'd0) begin
                        state <= S_ERROR;  err_code <= E_RSVD_BITS;
                    end else if (!i_op_ok) begin
                        state <= S_ERROR;  err_code <= E_BAD_OPCODE;
                    end else if (sel_ready) begin
                        state <= S_ISSUE;
                    end else if (timer == TIMEOUT_CYCLES - 1) begin
                        state <= S_ERROR;  err_code <= E_TIMEOUT_READY;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                // ---- dispatcher: entrega (u_start da unidade escolhida = 1) ----
                S_ISSUE: begin
                    timer <= 16'd0;
                    state <= S_WAIT_DONE;
                end

                // ---- dispatcher: espera a unidade escolhida terminar ----
                S_WAIT_DONE: begin
                    if (other_done) begin
                        state <= S_ERROR;  err_code <= E_WRONG_UNIT_DONE;
                    end else if (sel_done) begin
                        state <= S_NEXT;
                    end else if (timer == TIMEOUT_CYCLES - 1) begin
                        state <= S_ERROR;  err_code <= E_TIMEOUT_DONE;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                // ---- scheduler: proxima instrucao ou fim ----
                S_NEXT: begin
                    if (idx == n_tasks - 1'b1) begin
                        state <= S_DONE;
                    end else begin
                        idx   <= idx + 1'b1;
                        timer <= 16'd0;
                        state <= S_WAIT_INSTR;
                    end
                end

                S_DONE: state <= S_IDLE;   // done = 1 neste ciclo

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
