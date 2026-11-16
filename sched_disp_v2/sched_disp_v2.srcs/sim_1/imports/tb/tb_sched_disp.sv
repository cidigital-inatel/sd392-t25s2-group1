`timescale 1ns / 1ps
// -----------------------------------------------------------------------------
// tb_sched_disp.sv  -  Testbench autoverificavel do sched_disp (versao 2)
//
// Monta: mock_fetch (programa) -> sched_disp -> 3 x mock_unit (LOAD/COMPUTE/STORE)
// Entradas mudam na borda de DESCIDA do clock; o DUT reage na SUBIDA.
// Resultado final: "RESULTADO: PASS" ou "RESULTADO: FAIL (N erros)".
// -----------------------------------------------------------------------------
module tb_sched_disp;

    localparam [15:0] TIMEOUT = 16'd50;
    localparam CLK_PERIOD = 10;   // 100 MHz

    // Codigos de erro (iguais aos do DUT)
    localparam [3:0] E_NONE = 4'd0, E_ZERO_TASKS = 4'd1, E_BAD_UNIT = 4'd2,
                     E_RSVD_BITS = 4'd3, E_BAD_OPCODE = 4'd4, E_TIMEOUT_DONE = 4'd5,
                     E_SPURIOUS_DONE = 4'd6, E_TIMEOUT_READY = 4'd7,
                     E_TIMEOUT_INSTR = 4'd8, E_WRONG_UNIT_DONE = 4'd9;

    // Unidades e opcodes (proposta)
    localparam [1:0] LOAD = 2'd0, COMPUTE = 2'd1, STORE = 2'd2;
    localparam [3:0] LD_PESOS = 4'd1, LD_ENTRADA = 4'd2;
    localparam [3:0] OP_CONV = 4'd1, OP_POOL = 4'd2, OP_FC = 4'd3, OP_ARGMAX = 4'd4;
    localparam [3:0] ST_RESULT = 4'd1;

    // ---------------- Sinais ----------------
    reg         clk = 1'b0;
    reg         rst_n = 1'b0;
    reg         start = 1'b0;
    reg  [7:0]  num_tasks = 8'd0;
    wire        busy, done, error;
    wire [3:0]  err_code;
    wire        instr_valid, instr_ready;
    wire [15:0] instr_data;
    wire [2:0]  u_ready, u_start, u_done;
    wire [3:0]  u_op;
    wire [7:0]  u_arg;

    // Controles do ambiente de teste
    reg  [7:0]  fetch_gap = 8'd0;
    reg         fetch_stall = 1'b0;
    reg  [7:0]  lat_load = 8'd3, lat_comp = 8'd3, lat_store = 8'd3;
    reg  [1:0]  mode_load = 2'd0, mode_comp = 2'd0, mode_store = 2'd0;
    reg  [2:0]  ready_block = 3'b000;  // forca u_ready[i] = 0
    reg  [2:0]  inj_done = 3'b000;     // injeta done falso na unidade i
    wire [2:0]  mock_ready, mock_done;

    assign u_ready = mock_ready & ~ready_block;
    assign u_done  = mock_done | inj_done;

    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------- DUT ----------------
    sched_disp #(.TIMEOUT_CYCLES(TIMEOUT)) dut (
        .clk(clk), .rst_n(rst_n),
        .start(start), .num_tasks(num_tasks),
        .busy(busy), .done(done), .error(error), .err_code(err_code),
        .instr_valid(instr_valid), .instr_ready(instr_ready), .instr_data(instr_data),
        .u_ready(u_ready), .u_start(u_start), .u_op(u_op), .u_arg(u_arg), .u_done(u_done)
    );

    // ---------------- Modelos (somente simulacao) ----------------
    // O fetch reinicia quando o start sera aceito (DUT parado: IDLE ou ERROR)
    wire fetch_restart = start & ~busy & ~done;

    mock_fetch fetch0 (
        .clk(clk), .rst_n(rst_n), .restart(fetch_restart),
        .instr_ready(instr_ready), .instr_valid(instr_valid), .instr_data(instr_data),
        .cfg_gap(fetch_gap), .cfg_stall(fetch_stall)
    );

    mock_unit unit_load (
        .clk(clk), .rst_n(rst_n), .start(u_start[0]), .op(u_op), .arg(u_arg),
        .ready(mock_ready[0]), .done(mock_done[0]),
        .cfg_latency(lat_load), .cfg_mode(mode_load)
    );
    mock_unit unit_comp (
        .clk(clk), .rst_n(rst_n), .start(u_start[1]), .op(u_op), .arg(u_arg),
        .ready(mock_ready[1]), .done(mock_done[1]),
        .cfg_latency(lat_comp), .cfg_mode(mode_comp)
    );
    mock_unit unit_store (
        .clk(clk), .rst_n(rst_n), .start(u_start[2]), .op(u_op), .arg(u_arg),
        .ready(mock_ready[2]), .done(mock_done[2]),
        .cfg_latency(lat_store), .cfg_mode(mode_store)
    );

    // ---------------- Monitores (rodam o tempo todo) ----------------
    integer errors = 0;
    integer n_dispatch = 0;
    integer n_done_pulses = 0;
    integer n_accept = 0;
    reg [1:0] log_unit [0:255];
    reg [3:0] log_op   [0:255];
    reg [7:0] log_arg  [0:255];
    reg [2:0] u_start_prev = 3'b000;

    function [1:0] onehot_to_idx(input [2:0] v);
        onehot_to_idx = v[0] ? 2'd0 : v[1] ? 2'd1 : v[2] ? 2'd2 : 2'd3;
    endfunction

    always @(posedge clk) begin
        if (rst_n) begin
            if (u_start != 3'b000) begin
                // Regra 1: no maximo uma unidade recebe start por vez
                if (u_start != 3'b001 && u_start != 3'b010 && u_start != 3'b100) begin
                    errors = errors + 1;
                    $display("[%0t] FALHA: u_start em mais de uma unidade (%b)", $time, u_start);
                end
                // Regra 2: so despacha para unidade pronta
                if ((u_start & ~u_ready) != 3'b000) begin
                    errors = errors + 1;
                    $display("[%0t] FALHA: u_start para unidade ocupada", $time);
                end
                // Regra 3: u_start nunca dura 2 ciclos
                if (u_start_prev != 3'b000) begin
                    errors = errors + 1;
                    $display("[%0t] FALHA: u_start ativo por 2 ciclos seguidos", $time);
                end
                if (n_dispatch < 256) begin
                    log_unit[n_dispatch] = onehot_to_idx(u_start);
                    log_op[n_dispatch]   = u_op;
                    log_arg[n_dispatch]  = u_arg;
                end
                n_dispatch = n_dispatch + 1;
            end
            // Regra 4: done e error nunca juntos
            if (done && error) begin
                errors = errors + 1;
                $display("[%0t] FALHA: done e error ao mesmo tempo", $time);
            end
            if (done) n_done_pulses = n_done_pulses + 1;
            if (instr_valid && instr_ready) n_accept = n_accept + 1;
        end
        u_start_prev <= u_start;
    end

    // ---------------- Tarefas auxiliares ----------------
    function [15:0] mk(input [1:0] unit, input [1:0] rsvd, input [3:0] op, input [7:0] arg);
        mk = {unit, rsvd, op, arg};
    endfunction

    task check(input cond, input [8*64-1:0] msg);
        begin
            if (!cond) begin
                errors = errors + 1;
                $display("[%0t] FALHA: %0s", $time, msg);
            end
        end
    endtask

    task clear_counters;
        begin
            n_dispatch = 0; n_done_pulses = 0; n_accept = 0;
        end
    endtask

    task do_reset;
        begin
            @(negedge clk); rst_n = 1'b0;
            repeat (3) @(negedge clk);
            rst_n = 1'b1;
            @(negedge clk);
        end
    endtask

    task pulse_start(input [7:0] n);
        begin
            @(negedge clk); num_tasks = n; start = 1'b1;
            @(negedge clk); start = 1'b0;
        end
    endtask

    reg got_done, got_error;
    task wait_end(input integer max_cycles);
        integer c;
        begin
            got_done = 1'b0; got_error = 1'b0; c = 0;
            while (!done && !error && c < max_cycles) begin
                @(negedge clk); c = c + 1;
            end
            got_done = done; got_error = error;
            if (!got_done && !got_error) begin
                errors = errors + 1;
                $display("[%0t] FALHA: nem done nem error apos %0d ciclos", $time, max_cycles);
            end
        end
    endtask

    // Executa o programa esperando sucesso; confere ordem, unidade, op e arg
    task run_ok(input [7:0] n, input [8*40-1:0] name);
        integer k;
        begin
            clear_counters();
            pulse_start(n);
            check(busy == 1'b1, "busy deveria subir apos start");
            wait_end(20000);
            check(got_done == 1'b1, "esperava done");
            check(got_error == 1'b0, "nao esperava error");
            @(negedge clk);
            check(done == 1'b0, "done deveria durar 1 ciclo");
            check(busy == 1'b0, "busy deveria cair apos done");
            check(n_dispatch == n, "numero de despachos diferente de num_tasks");
            check(n_accept == n, "numero de instrucoes aceitas diferente de num_tasks");
            check(n_done_pulses == 1, "done deveria pulsar 1 vez");
            for (k = 0; k < n; k = k + 1) begin
                check(log_unit[k] == fetch0.prog[k][15:14], "instrucao foi para a unidade errada");
                check(log_op[k]   == fetch0.prog[k][11:8],  "opcode despachado errado");
                check(log_arg[k]  == fetch0.prog[k][7:0],   "arg despachado errado");
            end
            $display("[%0t] %0s: %0d instrucoes executadas", $time, name, n_dispatch);
        end
    endtask

    task run_err(input [7:0] n, input [3:0] exp_code, input integer exp_dispatch,
                 input [8*40-1:0] name);
        begin
            clear_counters();
            pulse_start(n);
            wait_end(20000);
            check(got_error == 1'b1, "esperava error");
            check(err_code == exp_code, "err_code inesperado");
            check(busy == 1'b0, "busy deveria ser 0 em ERROR");
            check(n_dispatch == exp_dispatch, "numero de despachos antes do erro");
            check(n_done_pulses == 0, "done nao deveria pulsar em erro");
            $display("[%0t] %0s: error=1 err_code=%0d despachos=%0d", $time, name, err_code, n_dispatch);
        end
    endtask

    // Programa ilustrativo da CNN MNIST (11 instrucoes)
    task load_mnist_program;
        begin
            fetch0.prog[0]  = mk(LOAD,    2'd0, LD_PESOS,   8'd1);  // pesos conv1
            fetch0.prog[1]  = mk(LOAD,    2'd0, LD_ENTRADA, 8'd0);  // imagem 28x28
            fetch0.prog[2]  = mk(COMPUTE, 2'd0, OP_CONV,    8'd1);  // conv camada 1
            fetch0.prog[3]  = mk(COMPUTE, 2'd0, OP_POOL,    8'd1);  // pool+ReLU camada 1
            fetch0.prog[4]  = mk(LOAD,    2'd0, LD_PESOS,   8'd2);  // pesos conv2
            fetch0.prog[5]  = mk(COMPUTE, 2'd0, OP_CONV,    8'd2);  // conv camada 2
            fetch0.prog[6]  = mk(COMPUTE, 2'd0, OP_POOL,    8'd2);  // pool+ReLU camada 2
            fetch0.prog[7]  = mk(LOAD,    2'd0, LD_PESOS,   8'd3);  // pesos fc
            fetch0.prog[8]  = mk(COMPUTE, 2'd0, OP_FC,      8'd3);  // fully connected
            fetch0.prog[9]  = mk(COMPUTE, 2'd0, OP_ARGMAX,  8'd3);  // escolhe a classe
            fetch0.prog[10] = mk(STORE,   2'd0, ST_RESULT,  8'd0);  // devolve resultado
        end
    endtask

    // ---------------- Sequencia de testes ----------------
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) fetch0.prog[i] = 16'h0000;

        // T1 - Reset
        $display("\n== T1: reset ==");
        do_reset();
        check(busy == 0 && done == 0 && error == 0 && u_start == 0, "saidas apos reset");
        check(instr_ready == 0, "instr_ready deveria ser 0 em IDLE");
        check(err_code == E_NONE, "err_code apos reset");

        // T2 - Uma instrucao (COMPUTE)
        $display("\n== T2: uma instrucao COMPUTE ==");
        fetch0.prog[0] = mk(COMPUTE, 2'd0, OP_CONV, 8'h2A);
        run_ok(1, "T2");

        // T3 - LOAD, COMPUTE, STORE: cada uma vai para a sua unidade
        $display("\n== T3: uma instrucao para cada unidade ==");
        fetch0.prog[0] = mk(LOAD,    2'd0, LD_PESOS,  8'h01);
        fetch0.prog[1] = mk(COMPUTE, 2'd0, OP_CONV,   8'h02);
        fetch0.prog[2] = mk(STORE,   2'd0, ST_RESULT, 8'h03);
        run_ok(3, "T3");

        // T4 - Programa MNIST completo, latencias diferentes por unidade
        $display("\n== T4: programa MNIST (11 instrucoes) ==");
        load_mnist_program();
        lat_load = 8'd10; lat_comp = 8'd25; lat_store = 8'd5;
        run_ok(11, "T4 MNIST");
        lat_load = 8'd3; lat_comp = 8'd3; lat_store = 8'd3;

        // T5 - Fetch lento (pausas entre instrucoes)
        $display("\n== T5: fetch com pausas ==");
        load_mnist_program();
        fetch_gap = 8'd4;
        run_ok(11, "T5 fetch lento");
        fetch_gap = 8'd0;

        // T6 - Espera a unidade CERTA: COMPUTE ocupado, as outras livres
        $display("\n== T6: espera a unidade escolhida ==");
        fetch0.prog[0] = mk(COMPUTE, 2'd0, OP_FC, 8'h05);
        clear_counters();
        ready_block = 3'b010;
        pulse_start(1);
        repeat (15) begin
            @(negedge clk);
            check(n_dispatch == 0, "despachou com a unidade escolhida ocupada");
            check(busy == 1'b1, "busy deveria ficar 1 enquanto espera");
        end
        ready_block = 3'b000;
        wait_end(5000);
        check(got_done == 1'b1, "T6 deveria terminar com done");
        check(n_dispatch == 1 && log_unit[0] == COMPUTE, "T6 deveria despachar para COMPUTE");
        $display("[%0t] T6: esperou o COMPUTE e despachou", $time);

        // T7 - start durante a execucao e ignorado
        $display("\n== T7: start com busy=1 e ignorado ==");
        load_mnist_program();
        lat_comp = 8'd10;
        clear_counters();
        pulse_start(11);
        repeat (20) @(negedge clk);
        pulse_start(3);
        wait_end(20000);
        check(got_done == 1'b1, "T7 deveria terminar com done");
        check(n_dispatch == 11, "T7: segundo start nao pode mudar o programa");
        @(negedge clk);
        lat_comp = 8'd3;
        $display("[%0t] T7: %0d despachos (esperado 11)", $time, n_dispatch);

        // T8 - Instrucoes invalidas
        $display("\n== T8: instrucoes invalidas ==");
        run_err(0, E_ZERO_TASKS, 0, "T8a num_tasks=0");
        fetch0.prog[0] = mk(2'd3, 2'd0, 4'd1, 8'h00);
        run_err(1, E_BAD_UNIT, 0, "T8b unidade 3");
        fetch0.prog[0] = mk(LOAD, 2'd1, LD_PESOS, 8'h00);
        run_err(1, E_RSVD_BITS, 0, "T8c bits reservados");
        fetch0.prog[0] = mk(LOAD, 2'd0, 4'd3, 8'h00);
        run_err(1, E_BAD_OPCODE, 0, "T8d LOAD com opcode 3");
        fetch0.prog[0] = mk(STORE, 2'd0, 4'd2, 8'h00);
        run_err(1, E_BAD_OPCODE, 0, "T8e STORE com opcode 2");
        fetch0.prog[0] = mk(COMPUTE, 2'd0, 4'd0, 8'h00);
        run_err(1, E_BAD_OPCODE, 0, "T8f COMPUTE com opcode 0");
        fetch0.prog[0] = mk(LOAD,  2'd0, LD_PESOS, 8'hAA);
        fetch0.prog[1] = mk(STORE, 2'd0, 4'd5,     8'hBB);
        run_err(2, E_BAD_OPCODE, 1, "T8g invalida na posicao 1");

        // T9 - Recuperacao com novo start
        $display("\n== T9: recuperacao apos erro ==");
        load_mnist_program();
        run_ok(11, "T9");
        check(err_code == E_NONE, "err_code deveria limpar no novo start");

        // T10 - done falso com o sistema parado
        $display("\n== T10: done espurio em IDLE ==");
        @(negedge clk); inj_done = 3'b100;
        @(negedge clk); inj_done = 3'b000;
        @(negedge clk);
        check(error == 1'b1 && err_code == E_SPURIOUS_DONE, "done espurio deveria gerar erro 6");
        $display("[%0t] T10: error=%0d err_code=%0d", $time, error, err_code);
        load_mnist_program();
        run_ok(11, "T10 recuperacao");

        // T11 - done de unidade errada durante a espera
        $display("\n== T11: done da unidade errada ==");
        fetch0.prog[0] = mk(COMPUTE, 2'd0, OP_CONV, 8'h01);
        lat_comp = 8'd30;
        clear_counters();
        pulse_start(1);
        repeat (10) @(negedge clk);
        inj_done = 3'b001;              // LOAD diz "terminei" sem ter recebido nada
        @(negedge clk); inj_done = 3'b000;
        @(negedge clk);
        check(error == 1'b1 && err_code == E_WRONG_UNIT_DONE, "deveria gerar erro 9");
        $display("[%0t] T11: error=%0d err_code=%0d", $time, error, err_code);
        repeat (40) @(negedge clk);     // deixa o COMPUTE terminar (fica em ERROR)
        lat_comp = 8'd3;

        // T12 - Unidade responde done duas vezes
        $display("\n== T12: done duplicado ==");
        fetch0.prog[0] = mk(STORE, 2'd0, ST_RESULT, 8'h00);
        mode_store = 2'd2;
        run_err(1, E_SPURIOUS_DONE, 1, "T12 done duplicado");
        mode_store = 2'd0;
        repeat (3) @(negedge clk);

        // T13 - Unidade nunca termina
        $display("\n== T13: timeout esperando done ==");
        fetch0.prog[0] = mk(COMPUTE, 2'd0, OP_CONV, 8'h00);
        mode_comp = 2'd1;
        run_err(1, E_TIMEOUT_DONE, 1, "T13 timeout done");
        mode_comp = 2'd0;
        do_reset();
        check(busy == 0 && error == 0 && err_code == E_NONE, "estado apos reset");

        // T14 - Unidade nunca fica livre
        $display("\n== T14: timeout esperando ready ==");
        fetch0.prog[0] = mk(LOAD, 2'd0, LD_ENTRADA, 8'h00);
        ready_block = 3'b001;
        run_err(1, E_TIMEOUT_READY, 0, "T14 timeout ready");
        ready_block = 3'b000;

        // T15 - Fetch nunca entrega
        $display("\n== T15: timeout esperando instrucao ==");
        fetch_stall = 1'b1;
        run_err(3, E_TIMEOUT_INSTR, 0, "T15 timeout instrucao");
        fetch_stall = 1'b0;

        // T16 - Reset no meio do programa
        $display("\n== T16: reset durante execucao ==");
        load_mnist_program();
        lat_comp = 8'd20;
        clear_counters();
        pulse_start(11);
        repeat (60) @(negedge clk);
        check(busy == 1'b1, "deveria estar executando antes do reset");
        do_reset();
        check(busy == 0 && done == 0 && error == 0 && u_start == 0, "saidas apos reset");
        lat_comp = 8'd3;
        run_ok(11, "T16 apos reset");

        // T17 - Nenhuma unidade recebeu start estando ocupada
        check(unit_load.violations == 0 && unit_comp.violations == 0 &&
              unit_store.violations == 0, "alguma unidade recebeu start ocupada");

        $display("\n========================================");
        if (errors == 0) $display("RESULTADO: PASS");
        else             $display("RESULTADO: FAIL (%0d erros)", errors);
        $display("========================================\n");
        $finish;
    end

    initial begin
        #5_000_000;
        $display("RESULTADO: FAIL (watchdog: simulacao nao terminou)");
        $finish;
    end

endmodule
