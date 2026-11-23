// -----------------------------------------------------------------------------
// i2c_master.v - I2C Master (передавач / Tx-частина протоколу)
// Лабораторна робота №3, варіант 14 (I2C, Verilog). КІ-402, Погорєлов О.І.
//
// Виконує одну транзакцію на один байт:
//   запис:  START | ADDR[6:0] W | ACK | DATA[7:0] | ACK  | STOP
//   читання: START | ADDR[6:0] R | ACK | DATA[7:0] | NACK | STOP
//
// SCL генерується з системного тактового сигналу clk. Кожен біт на шині
// розбито на 4 фази (чверті періоду SCL):
//   фаза 0: SCL = 0, майстер виставляє SDA
//   фаза 1: SCL відпускається (=1)
//   фаза 2: SCL = 1, майстер зчитує SDA (ACK або біт даних від slave)
//   фаза 3: SCL = 0
// Лінії шини - відкритий стік: вихід *_oe = 1 тягне лінію в 0, *_oe = 0
// відпускає її (рівень 1 дає підтягувальний резистор).
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module i2c_master #(
    parameter integer CLK_HZ = 50_000_000,   // частота системного такту clk
    parameter integer SCL_HZ = 100_000       // частота SCL (Standard-mode 100 кГц)
) (
    input  wire       clk,      // системний такт
    input  wire       rst,      // синхронне скидання, активний рівень 1
    // --- інтерфейс користувача ---
    input  wire       start,    // імпульс запуску транзакції (1 такт)
    input  wire       rw,       // 0 - запис, 1 - читання
    input  wire [6:0] addr,     // 7-бітна адреса slave
    input  wire [7:0] wdata,    // байт для запису
    output reg  [7:0] rdata,    // прочитаний байт
    output reg        busy,     // 1 - транзакція триває
    output reg        done,     // імпульс 1 такт: транзакцію завершено
    output reg        ack_err,  // 1 - slave не підтвердив (NACK)
    // --- шина I2C (відкритий стік) ---
    output reg        scl_oe,   // 1 - тягнути SCL у 0
    output reg        sda_oe,   // 1 - тягнути SDA у 0
    input  wire       sda_i     // поточний рівень лінії SDA
);

    // Дільник: один тик на чверть періоду SCL
    localparam integer DIV = CLK_HZ / (SCL_HZ * 4);

    // Стани автомата
    localparam [3:0] S_IDLE     = 4'd0,
                     S_START    = 4'd1,
                     S_ADDR     = 4'd2,
                     S_ADDR_ACK = 4'd3,
                     S_WR       = 4'd4,
                     S_WR_ACK   = 4'd5,
                     S_RD       = 4'd6,
                     S_RD_NACK  = 4'd7,
                     S_STOP     = 4'd8;

    reg [3:0]  state;
    reg [15:0] div_cnt;   // лічильник дільника частоти
    reg [1:0]  phase;     // фаза біта 0..3
    reg [2:0]  bit_cnt;   // номер біта у байті (7..0)
    reg [7:0]  shreg;     // зсувний регістр передачі / прийому
    reg        rw_r;      // збережений напрям транзакції
    reg [7:0]  wdata_r;   // збережений байт для запису

    wire tick = (div_cnt == DIV - 1);   // кінець чверті періоду SCL

    // Дільник частоти працює лише під час транзакції
    always @(posedge clk) begin
        if (rst || state == S_IDLE)
            div_cnt <= 16'd0;
        else if (tick)
            div_cnt <= 16'd0;
        else
            div_cnt <= div_cnt + 16'd1;
    end

    always @(posedge clk) begin
        if (rst) begin
            state   <= S_IDLE;
            phase   <= 2'd0;
            bit_cnt <= 3'd7;
            shreg   <= 8'd0;
            rw_r    <= 1'b0;
            wdata_r <= 8'd0;
            rdata   <= 8'd0;
            busy    <= 1'b0;
            done    <= 1'b0;
            ack_err <= 1'b0;
            scl_oe  <= 1'b0;   // шина відпущена
            sda_oe  <= 1'b0;
        end else begin
            done <= 1'b0;

            if (state == S_IDLE) begin
                scl_oe <= 1'b0;
                sda_oe <= 1'b0;
                phase  <= 2'd0;
                if (start) begin
                    shreg   <= {addr, rw};   // перший байт: адреса + R/W
                    rw_r    <= rw;
                    wdata_r <= wdata;
                    bit_cnt <= 3'd7;
                    busy    <= 1'b1;
                    ack_err <= 1'b0;
                    state   <= S_START;
                end
            end else if (tick) begin
                phase <= phase + 2'd1;

                case (state)
                // START: SDA 1->0 при SCL = 1
                S_START: case (phase)
                    2'd0: begin scl_oe <= 1'b0; sda_oe <= 1'b0; end
                    2'd1: sda_oe <= 1'b1;
                    2'd3: begin scl_oe <= 1'b1; state <= S_ADDR; end
                    default: ;
                endcase

                // Передача байта (адреса або дані), старший біт першим
                S_ADDR, S_WR: case (phase)
                    2'd0: sda_oe <= ~shreg[7];
                    2'd1: scl_oe <= 1'b0;
                    2'd3: begin
                        scl_oe <= 1'b1;
                        shreg  <= {shreg[6:0], 1'b0};
                        if (bit_cnt == 3'd0) begin
                            bit_cnt <= 3'd7;
                            state   <= (state == S_ADDR) ? S_ADDR_ACK : S_WR_ACK;
                        end else
                            bit_cnt <= bit_cnt - 3'd1;
                    end
                    default: ;
                endcase

                // Прийом ACK від slave: SDA відпущена, читаємо в фазі 2
                S_ADDR_ACK, S_WR_ACK: case (phase)
                    2'd0: sda_oe <= 1'b0;
                    2'd1: scl_oe <= 1'b0;
                    2'd2: if (sda_i) ack_err <= 1'b1;   // NACK
                    2'd3: begin
                        scl_oe <= 1'b1;
                        if (ack_err)
                            state <= S_STOP;
                        else if (state == S_ADDR_ACK) begin
                            shreg <= wdata_r;
                            state <= rw_r ? S_RD : S_WR;
                        end else
                            state <= S_STOP;
                    end
                endcase

                // Прийом байта від slave
                S_RD: case (phase)
                    2'd0: sda_oe <= 1'b0;
                    2'd1: scl_oe <= 1'b0;
                    2'd2: shreg <= {shreg[6:0], sda_i};
                    2'd3: begin
                        scl_oe <= 1'b1;
                        if (bit_cnt == 3'd0) begin
                            bit_cnt <= 3'd7;
                            state   <= S_RD_NACK;
                        end else
                            bit_cnt <= bit_cnt - 3'd1;
                    end
                endcase

                // Майстер відповідає NACK: читаємо лише один байт
                S_RD_NACK: case (phase)
                    2'd0: begin sda_oe <= 1'b0; rdata <= shreg; end
                    2'd1: scl_oe <= 1'b0;
                    2'd3: begin scl_oe <= 1'b1; state <= S_STOP; end
                    default: ;
                endcase

                // STOP: SDA 0->1 при SCL = 1
                S_STOP: case (phase)
                    2'd0: begin scl_oe <= 1'b1; sda_oe <= 1'b1; end
                    2'd1: scl_oe <= 1'b0;
                    2'd2: sda_oe <= 1'b0;
                    2'd3: begin
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= S_IDLE;
                    end
                endcase

                default: state <= S_IDLE;
                endcase
            end
        end
    end

endmodule
