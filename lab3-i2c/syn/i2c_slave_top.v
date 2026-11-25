// Обгортка для синтезу slave: SDA - двонаправлений вивід з відкритим стоком.
module i2c_slave_top (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] tx_data,
    output wire [7:0] rx_data,
    output wire       rx_valid,
    output wire       addr_hit,
    input  wire       scl,
    inout  wire       sda
);
    wire sda_oe;

    i2c_slave #(.ADDR(7'h42)) u_slave (
        .clk(clk), .rst(rst), .tx_data(tx_data), .rx_data(rx_data),
        .rx_valid(rx_valid), .addr_hit(addr_hit),
        .scl_i(scl), .sda_i(sda), .sda_oe(sda_oe)
    );

    assign sda = sda_oe ? 1'b0 : 1'bz;
endmodule
