// -----------------------------------------------------------------------------
// i2c_slave.v - I2C Slave (приймач / Rx-частина протоколу)
// Лабораторна робота №3, варіант 14 (I2C, Verilog). КІ-402, Погорєлов О.І.
//
// Приймає байти, які пише майстер, і віддає байт tx_data при читанні.
// SCL і SDA синхронізуються з системним тактом clk (2 тригери) і
// аналізуються за фронтами:
//   START  - спад SDA при SCL = 1
//   STOP   - фронт SDA при SCL = 1
//   біт    - зчитується за фронтом SCL
//   вихід  - SDA змінюється лише після спаду SCL (коли SCL = 0)
// Розтягування такту (clock stretching) не використовується.
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module i2c_slave #(
    parameter [6:0] ADDR = 7'h42            // власна 7-бітна адреса
) (
    input  wire       clk,       // системний такт (>= 8 x SCL)
    input  wire       rst,       // синхронне скидання, активний рівень 1
    // --- інтерфейс користувача ---
    input  wire [7:0] tx_data,   // байт, що віддається майстру при читанні
    output reg  [7:0] rx_data,   // останній прийнятий байт
    output reg        rx_valid,  // імпульс 1 такт: прийнято новий байт
    output reg        addr_hit,  // імпульс 1 такт: розпізнано свою адресу
    // --- шина I2C (відкритий стік) ---
    input  wire       scl_i,     // рівень лінії SCL
    input  wire       sda_i,     // рівень лінії SDA
    output reg        sda_oe     // 1 - тягнути SDA у 0
);

    localparam [2:0] S_IDLE    = 3'd0,
                     S_ADDR    = 3'd1,
                     S_ADDR_ACK = 3'd2,
                     S_RX      = 3'd3,
                     S_RX_ACK  = 3'd4,
                     S_TX      = 3'd5,
                     S_TX_ACK  = 3'd6;

    // Синхронізатори та детектори фронтів
    reg [2:0] scl_s, sda_s;
    always @(posedge clk) begin
        scl_s <= {scl_s[1:0], scl_i};
        sda_s <= {sda_s[1:0], sda_i};
    end
    wire scl      = scl_s[1];
    wire sda      = sda_s[1];
    wire scl_rise = (scl_s[2:1] == 2'b01);
    wire scl_fall = (scl_s[2:1] == 2'b10);
    wire start_c  = scl && (sda_s[2:1] == 2'b10);   // START
    wire stop_c   = scl && (sda_s[2:1] == 2'b01);   // STOP

    reg [2:0] state;
    reg [3:0] bit_cnt;   // кількість прийнятих/переданих бітів 0..8
    reg [7:0] shreg;     // зсувний регістр
    reg       rw;        // напрям поточної транзакції (1 - читання)
    reg       m_ack;     // ACK майстра після байта читання

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_IDLE;
            bit_cnt  <= 4'd0;
            shreg    <= 8'd0;
            rw       <= 1'b0;
            m_ack    <= 1'b0;
            rx_data  <= 8'd0;
            rx_valid <= 1'b0;
            addr_hit <= 1'b0;
            sda_oe   <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            addr_hit <= 1'b0;

            if (start_c) begin                 // START (або повторний START)
                state   <= S_ADDR;
                bit_cnt <= 4'd0;
                sda_oe  <= 1'b0;
            end else if (stop_c) begin         // STOP - звільнити шину
                state  <= S_IDLE;
                sda_oe <= 1'b0;
            end else case (state)
            S_IDLE: sda_oe <= 1'b0;

            // Прийом адреси і біта R/W
            S_ADDR: begin
                if (scl_rise) begin
                    shreg   <= {shreg[6:0], sda};
                    bit_cnt <= bit_cnt + 4'd1;
                end else if (scl_fall && bit_cnt == 4'd8) begin
                    if (shreg[7:1] == ADDR) begin
                        sda_oe   <= 1'b1;      // ACK
                        rw       <= shreg[0];
                        addr_hit <= 1'b1;
                        state    <= S_ADDR_ACK;
                    end else
                        state <= S_IDLE;       // чужа адреса - мовчимо (NACK)
                end
            end

            // Кінець такту ACK адреси
            S_ADDR_ACK: if (scl_fall) begin
                bit_cnt <= 4'd0;
                if (rw) begin
                    shreg  <= tx_data;
                    sda_oe <= ~tx_data[7];     // перший біт для читання
                    state  <= S_TX;
                end else begin
                    sda_oe <= 1'b0;
                    state  <= S_RX;
                end
            end

            // Прийом байта даних від майстра
            S_RX: begin
                if (scl_rise) begin
                    shreg   <= {shreg[6:0], sda};
                    bit_cnt <= bit_cnt + 4'd1;
                end else if (scl_fall && bit_cnt == 4'd8) begin
                    rx_data  <= shreg;
                    rx_valid <= 1'b1;
                    sda_oe   <= 1'b1;          // ACK
                    state    <= S_RX_ACK;
                end
            end

            S_RX_ACK: if (scl_fall) begin
                sda_oe  <= 1'b0;
                bit_cnt <= 4'd0;
                state   <= S_RX;               // можливий наступний байт
            end

            // Передача байта майстру
            S_TX: begin
                if (scl_rise)
                    bit_cnt <= bit_cnt + 4'd1;
                else if (scl_fall) begin
                    if (bit_cnt == 4'd8) begin
                        sda_oe <= 1'b0;        // відпустити SDA для ACK/NACK майстра
                        state  <= S_TX_ACK;
                    end else begin
                        sda_oe <= ~shreg[6];
                        shreg  <= {shreg[6:0], 1'b0};
                    end
                end
            end

            S_TX_ACK: begin
                if (scl_rise)
                    m_ack <= ~sda;
                else if (scl_fall) begin
                    if (m_ack) begin           // майстер хоче ще байт
                        shreg   <= tx_data;
                        sda_oe  <= ~tx_data[7];
                        bit_cnt <= 4'd0;
                        state   <= S_TX;
                    end else
                        state <= S_IDLE;       // NACK - кінець читання
                end
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule
