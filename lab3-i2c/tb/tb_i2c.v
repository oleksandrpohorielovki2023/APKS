// -----------------------------------------------------------------------------
// tb_i2c.v - тестбенч для i2c_master + i2c_slave
// Лабораторна робота №3, варіант 14 (I2C, Verilog). КІ-402, Погорєлов О.І.
//
// Імітує зовнішнє середовище:
//   - генерує clk 50 МГц і сигнал скидання rst;
//   - шина I2C з підтягувальними резисторами (tri1), обидва пристрої
//     керують лініями як відкритий стік;
//   - подає дані на вхід передавача (майстра) і перевіряє, що slave їх прийняв;
//   - slave передає байт майстру (перевірка прийому майстром);
//   - звертання до неіснуючої адреси має дати NACK.
// Результат: повідомлення PASS/FAIL та файл осцилограм i2c.vcd.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_i2c;

    localparam integer CLK_HZ = 50_000_000;
    localparam integer SCL_HZ = 100_000;
    localparam [6:0]   SLAVE_ADDR = 7'h42;

    // --- такт і скидання ---
    reg clk = 1'b0;
    always #10 clk = ~clk;            // 50 МГц (період 20 нс)
    reg rst = 1'b1;

    // --- шина I2C: tri1 = лінія з підтягуванням до 1 ---
    tri1 scl, sda;
    wire m_scl_oe, m_sda_oe, s_sda_oe;
    assign scl = m_scl_oe ? 1'b0 : 1'bz;
    assign sda = m_sda_oe ? 1'b0 : 1'bz;
    assign sda = s_sda_oe ? 1'b0 : 1'bz;

    // --- майстер (Tx) ---
    reg        start = 1'b0;
    reg        rw    = 1'b0;
    reg  [6:0] addr  = 7'h00;
    reg  [7:0] wdata = 8'h00;
    wire [7:0] rdata;
    wire       busy, done, ack_err;

    i2c_master #(.CLK_HZ(CLK_HZ), .SCL_HZ(SCL_HZ)) u_master (
        .clk(clk), .rst(rst),
        .start(start), .rw(rw), .addr(addr), .wdata(wdata),
        .rdata(rdata), .busy(busy), .done(done), .ack_err(ack_err),
        .scl_oe(m_scl_oe), .sda_oe(m_sda_oe), .sda_i(sda)
    );

    // --- slave (Rx) ---
    reg  [7:0] s_tx_data = 8'h5A;
    wire [7:0] s_rx_data;
    wire       s_rx_valid, s_addr_hit;

    i2c_slave #(.ADDR(SLAVE_ADDR)) u_slave (
        .clk(clk), .rst(rst),
        .tx_data(s_tx_data), .rx_data(s_rx_data),
        .rx_valid(s_rx_valid), .addr_hit(s_addr_hit),
        .scl_i(scl), .sda_i(sda), .sda_oe(s_sda_oe)
    );

    integer errors = 0;

    // Запуск однієї транзакції та очікування її завершення
    task i2c_xfer(input [6:0] a, input r, input [7:0] d);
        begin
            @(posedge clk);
            addr <= a; rw <= r; wdata <= d; start <= 1'b1;
            @(posedge clk);
            start <= 1'b0;
            @(posedge done);
            @(posedge clk);
        end
    endtask

    task check(input cond, input [8*48-1:0] what);
        begin
            if (cond) $display("[%t] PASS: %0s", $time, what);
            else begin $display("[%t] FAIL: %0s", $time, what); errors = errors + 1; end
        end
    endtask

    initial begin
        $timeformat(-6, 2, " us", 10);
        $dumpfile("i2c.vcd");
        $dumpvars(0, tb_i2c);

        repeat (5) @(posedge clk);
        rst <= 1'b0;
        repeat (5) @(posedge clk);

        // Тест 1: запис 0xA5 у slave 0x42
        i2c_xfer(SLAVE_ADDR, 1'b0, 8'hA5);
        check(!ack_err,             "write 0xA5: slave ACK");
        check(s_rx_data == 8'hA5,   "write 0xA5: slave received 0xA5");

        // Тест 2: запис 0x3C
        i2c_xfer(SLAVE_ADDR, 1'b0, 8'h3C);
        check(!ack_err,             "write 0x3C: slave ACK");
        check(s_rx_data == 8'h3C,   "write 0x3C: slave received 0x3C");

        // Тест 3: читання - slave передає 0x5A
        s_tx_data = 8'h5A;
        i2c_xfer(SLAVE_ADDR, 1'b1, 8'h00);
        check(!ack_err,             "read: slave ACK");
        check(rdata == 8'h5A,       "read: master received 0x5A");

        // Тест 4: читання 0xC3
        s_tx_data = 8'hC3;
        i2c_xfer(SLAVE_ADDR, 1'b1, 8'h00);
        check(rdata == 8'hC3,       "read: master received 0xC3");

        // Тест 5: неіснуюча адреса 0x21 -> NACK
        i2c_xfer(7'h21, 1'b0, 8'hFF);
        check(ack_err,              "wrong address 0x21: NACK detected");
        check(s_rx_data == 8'h3C,   "wrong address: slave data unchanged");

        if (errors == 0) $display("RESULT: ALL TESTS PASSED");
        else             $display("RESULT: %0d TEST(S) FAILED", errors);
        #2000 $finish;
    end

    // Захист від зависання
    initial begin
        #10_000_000 $display("RESULT: TIMEOUT"); $finish;
    end

endmodule
