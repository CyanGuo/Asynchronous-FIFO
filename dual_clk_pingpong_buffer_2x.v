// Copyright @ 2022 Yuqing Guo

// dual-clk ping-pong buffer
// depth-expansion
// consist of 2 FIFOs
// aspect ratio is same

module dual_clk_pingpong_buffer_2x (
        reset_n,
        wclk,
        rclk,
        wen,
        ren,
        data_in,
        data_out,
        full_o,
        empty_o
        );
parameter LOG2_NUM_DEPTH_FIFO = 1;
parameter WIDTH = 8;

input rclk;
input wclk;
input ren;
input wen;
input reset_n;
input [WIDTH-1:0] data_in;

output [WIDTH-1:0] data_out;
output full_o;
output empty_o;

reg [LOG2_NUM_DEPTH_FIFO-1:0] WFP;
reg [LOG2_NUM_DEPTH_FIFO-1:0] RFP;
wire wenq0;
wire wenq1;
wire renq0;
wire renq1;
wire full_o;
wire empty_o;
wire full0;
wire full1;
wire empty0;
wire empty1;
wire [WIDTH-1:0] data_out0;
wire [WIDTH-1:0] data_out1;

// decode
assign wenq0 = (WFP == 0) & (!full_o & wen);
assign wenq1 = (WFP == 1) & (!full_o & wen);
assign renq0 = (RFP == 0) & (!empty_o & ren);
assign renq1 = (RFP == 1) & (!empty_o & ren);

// full empty
assign empty_o = RFP ? empty1 : empty0;
assign full_o = WFP ? full1 : full0;

// data out
assign data_out = RFP ? data_out1 : data_out0;

async_fifo_top #(.WIDTH(WIDTH), .LOG2DEPTH(5)) 
asyncfifo0 (.rclk(rclk), .ren(renq0), .wclk(wclk), .wen(wenq0), .reset_n(reset_n),
            .data_in(data_in), .data_out(data_out0), .full(full0), .empty(empty0));

async_fifo_top #(.WIDTH(WIDTH), .LOG2DEPTH(5)) 
asyncfifo1 (.rclk(rclk), .ren(renq1), .wclk(wclk), .wen(wenq1), .reset_n(reset_n),
            .data_in(data_in), .data_out(data_out1), .full(full1), .empty(empty1));

always @ (posedge wclk or negedge reset_n) begin
    if (reset_n) begin
        WFP <= 0;
    end
    else if (WFP == LOG2_NUM_DEPTH_FIFO) begin
        WFP <= 0;
    end
    else if (!full_o && wen) begin
        WFP <= WFP + 1;
    end
end

always @ (posedge rclk or negedge reset_n) begin
    if (reset_n) begin
        RFP <= 0;
    end
    else if (RFP == LOG2_NUM_DEPTH_FIFO) begin
        RFP <= 0;
    end
    else if (!empty_o && ren) begin
        RFP <= RFP + 1;
    end
end

endmodule