module UART_Top_tb;


reg clk, rst, start_tx;
reg [7:0] tx_data;

wire tx_out, tx_done;
wire [7:0] rx_data;
wire rx_done, parity_err;

wire rx_in = tx_out;

UART_Top dut (
    .clk(clk),
    .rst(rst),
    .rx_in(rx_in),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .parity_err(parity_err),
    .start_tx(start_tx),
    .tx_data(tx_data),
    .tx_out(tx_out),
    .tx_done(tx_done)
);

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    start_tx = 0;
    tx_data = 0;

    #100 rst = 0;

    // Test 1
    #100;
    tx_data = 8'hA5;
    start_tx = 1;
    #20 start_tx = 0;

    @(posedge rx_done);

    // Test 2
    #50000;
    tx_data = 8'h71;
    start_tx = 1;
    #20 start_tx = 0;

    @(posedge rx_done);

    #50000;
    $stop;
end


endmodule
module UART_tx_tb;


reg clk, rst, start_tx;
reg [7:0] data;

wire tx_out, tx_done;

UART_tx dut (
    .clk(clk),
    .rst(rst),
    .start_tx(start_tx),
    .data(data),
    .tx_out(tx_out),
    .tx_done(tx_done)
);

always #10 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    start_tx = 0;
    data = 0;

    #100 rst = 0;

    data = 8'h69;
    start_tx = 1;
    #20 start_tx = 0;

    @(posedge tx_done);

    #1000;

    data = 8'hC2;
    start_tx = 1;
    #20 start_tx = 0;

    @(posedge tx_done);

    #1000;
    $stop;
end


endmodule
module UART_rx_tb;

reg clk, rst, rx_in;

wire [7:0] rx_data;
wire rx_done;
wire parity_err;

parameter BIT_TIME = 8680;

UART_rx dut (
.clk(clk),
.rst(rst),
.rx_in(rx_in),
.rx_data(rx_data),
.rx_done(rx_done),
.parity_err(parity_err)
);

always #10 clk = ~clk;

initial begin


clk = 0;
rst = 1;
rx_in = 1;

#100 rst = 0;

// Frame 1 : 0x69

rx_in = 0; #(BIT_TIME); // start

rx_in = 1; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);

rx_in = 0; #(BIT_TIME); // parity
rx_in = 1; #(BIT_TIME); // stop

#50000;

// Frame 2 : 0x96

rx_in = 0; #(BIT_TIME);

rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);

rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);

#50000;

// Frame 3 : 0xF0 (Wrong Parity)

rx_in = 0; #(BIT_TIME);

rx_in = 0; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 0; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);
rx_in = 1; #(BIT_TIME);

rx_in = 1; #(BIT_TIME); // wrong parity
rx_in = 1; #(BIT_TIME); // stop

#50000;

$stop;


end

initial begin
$monitor("time=%0t data=%h done=%b err=%b",
$time, rx_data, rx_done, parity_err);
end

endmodule

