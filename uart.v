module UART_Top(
    input clk,
    input rst,

    input rx_in,
    output [7:0] rx_data,
    output rx_done,
    output parity_err,

    input start_tx,
    input [7:0] tx_data,
    output tx_out,
    output tx_done
);

UART_tx TX(
    .clk(clk),
    .rst(rst),
    .start_tx(start_tx),
    .data(tx_data),
    .tx_out(tx_out),
    .tx_done(tx_done)
);

UART_rx RX(
    .clk(clk),
    .rst(rst),
    .rx_in(rx_in),
    .rx_data(rx_data),
    .rx_done(rx_done),
    .parity_err(parity_err)
);

endmodule
module UART_tx(
    input clk,
    input rst,
    input start_tx,
    input [7:0] data,

    output reg tx_out,
    output reg tx_done
);

parameter IDLE   = 3'b000;
parameter START  = 3'b001;
parameter DATA   = 3'b010;
parameter PARITY = 3'b011;
parameter STOP   = 3'b100;

reg [2:0] state,next_state;
reg [2:0] bit_count;
reg parity_bit;

wire baud_tick;
wire baud_enable = (state != IDLE);
wire calc_parity = ^data;

baud_gen_tx BAUD(
    .clk(clk),
    .rst(rst),
    .enable(baud_enable),
    .baud_tick(baud_tick)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        bit_count <= 0;
        parity_bit <= 0;
    end
    else begin
        state <= next_state;

        if(state==IDLE && start_tx)
            parity_bit <= calc_parity;

        if(state==START)
            bit_count <= 0;
        else if(state==DATA && baud_tick)
            bit_count <= bit_count + 1'b1;
    end
end

always @(*) begin
    next_state = state;

    case(state)

        IDLE:
            if(start_tx)
                next_state = START;

        START:
            if(baud_tick)
                next_state = DATA;

        DATA:
            if(baud_tick && bit_count==3'd7)
                next_state = PARITY;

        PARITY:
            if(baud_tick)
                next_state = STOP;

        STOP:
            if(baud_tick)
                next_state = IDLE;

    endcase
end

always @(*) begin
    tx_out = 1'b1;
    tx_done = 1'b0;

    case(state)

        START:
            tx_out = 1'b0;

        DATA:
            tx_out = data[bit_count];

        PARITY:
            tx_out = parity_bit;

        STOP: begin
            tx_out = 1'b1;
            tx_done = 1'b1;
        end

    endcase
end

endmodule
module UART_rx(
    input clk,
    input rst,
    input rx_in,

    output reg [7:0] rx_data,
    output reg rx_done,
    output reg parity_err
);

parameter IDLE    = 3'b000;
parameter START   = 3'b001;
parameter RECEIVE = 3'b010;
parameter PARITY  = 3'b011;
parameter STOP    = 3'b100;
parameter DONE    = 3'b101;

reg [2:0] state,next_state;
reg [2:0] bit_count;

wire half_tick;
wire full_tick;
wire baud_enable = (state != IDLE);

wire expected_parity = ^rx_data;

baud_gen_rx BAUD(
    .clk(clk),
    .rst(rst),
    .enable(baud_enable),
    .half_tick(half_tick),
    .full_tick(full_tick)
);

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= IDLE;
        bit_count <= 0;
        rx_data <= 0;
        parity_err <= 0;
    end
    else begin
        state <= next_state;

        if(state==IDLE) begin
            bit_count <= 0;
            parity_err <= 0;
        end

        else if(state==RECEIVE && full_tick) begin
            rx_data[bit_count] <= rx_in;
            bit_count <= bit_count + 1'b1;
        end

        else if(state==PARITY && full_tick) begin
            parity_err <= (rx_in != expected_parity);
        end
    end
end

always @(*) begin
    next_state = state;

    case(state)

        IDLE:
            if(!rx_in)
                next_state = START;

        START:
            if(half_tick)
                next_state = rx_in ? IDLE : RECEIVE;

        RECEIVE:
            if(full_tick && bit_count==3'd7)
                next_state = PARITY;

        PARITY:
            if(full_tick)
                next_state = STOP;

        STOP:
            if(full_tick)
                next_state = DONE;

        DONE:
            next_state = IDLE;

        default:
            next_state = IDLE;

    endcase
end

always @(*) begin
    rx_done = (state == DONE);
end

endmodule
module baud_gen_tx(
    input clk,
    input rst,
    input enable,

    output reg baud_tick
);

parameter DIV = 434;

reg [8:0] count;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        count <= 0;
        baud_tick <= 0;
    end
    else if(!enable) begin
        count <= 0;
        baud_tick <= 0;
    end
    else begin
        if(count == DIV-1) begin
            count <= 0;
            baud_tick <= 1'b1;
        end
        else begin
            count <= count + 1'b1;
            baud_tick <= 1'b0;
        end
    end
end

endmodule
module baud_gen_rx(
    input clk,
    input rst,
    input enable,

    output reg half_tick,
    output reg full_tick
);

parameter FULL = 434;
parameter HALF = 217;

reg [8:0] count;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        count <= 0;
        half_tick <= 0;
        full_tick <= 0;
    end
    else if(!enable) begin
        count <= 0;
        half_tick <= 0;
        full_tick <= 0;
    end
    else begin
        half_tick <= 0;
        full_tick <= 0;

        if(count == FULL-1) begin
            count <= 0;
            full_tick <= 1'b1;
        end
        else begin
            count <= count + 1'b1;

            if(count == HALF-1)
                half_tick <= 1'b1;
        end
    end
end

endmodule
