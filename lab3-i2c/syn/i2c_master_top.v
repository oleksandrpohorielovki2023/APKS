// Обгортка для синтезу майстра: двонаправлені виводи SCL/SDA з відкритим стоком.
module i2c_master_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire       rw,
    input  wire [6:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata,
    output wire       busy,
    output wire       done,
    output wire       ack_err,
    inout  wire       scl,
    inout  wire       sda
);
    wire scl_oe, sda_oe;

    i2c_master #(.CLK_HZ(50_000_000), .SCL_HZ(100_000)) u_master (
        .clk(clk), .rst(rst), .start(start), .rw(rw), .addr(addr), .wdata(wdata),
        .rdata(rdata), .busy(busy), .done(done), .ack_err(ack_err),
        .scl_oe(scl_oe), .sda_oe(sda_oe), .sda_i(sda)
    );

    assign scl = scl_oe ? 1'b0 : 1'bz;
    assign sda = sda_oe ? 1'b0 : 1'bz;
endmodule
