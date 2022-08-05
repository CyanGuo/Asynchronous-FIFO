module async_fifo_top (rclk, ren, wclk, wen, reset_n, data_in, data_out, full, empty);
    parameter WIDTH = 8;
    parameter LOG2DEPTH = 5;

    input rclk;
    input wclk;
    input ren;
    input wen;
    input reset_n;
    input [WIDTH-1:0] data_in;
    
    output [WIDTH-1:0] data_out;
    output full;
    output empty;

    wire renq;
    wire wenq;
    wire full;
    wire emtpy;
    wire [LOG2DEPTH:0] wr_depth, rd_depth;

    reg [LOG2DEPTH:0] wr_ptr_bin, rd_ptr_bin;
    wire [LOG2DEPTH:0] wr_ptr_gray, rd_ptr_gray; 
    reg [LOG2DEPTH:0] wr_ptr_s_gray, rd_ptr_s_gray;
    reg [LOG2DEPTH:0] wr_ptr_ss_gray, rd_ptr_ss_gray;
    wire [LOG2DEPTH:0] wr_ptr_ss_bin, rd_ptr_ss_bin;

    dual_clk_fifo_core #(.WIDTH(WIDTH), .LOG2DEPTH(LOG2DEPTH)) 
    dcfifocore0 (.rclk(rclk), .renq(renq), .wclk(wclk), .wenq(wenq), .data_in(data_in), .data_out(data_out), .wr_ptr(wr_ptr_bin[LOG2DEPTH-1:0]), .rd_ptr(rd_ptr_bin[LOG2DEPTH-1:0])); 

    assign wenq = wen & (!full);
    assign renq = ren & (!empty);

//----------------------------- RESET ------------------------------
    always @ (negedge reset_n)
    begin
        if (!reset_n) begin
            wr_ptr_bin <= 0; 
            rd_ptr_bin <= 0; 
            wr_ptr_s_gray <= 0; 
            rd_ptr_s_gray <= 0;
            wr_ptr_ss_gray <= 0;
            rd_ptr_ss_gray <= 0;
        end 
    end

//----------------------------- GRAY COUNTER -----------------------
    always @ (posedge wclk)
    begin
        if (wenq) wr_ptr_bin <= wr_ptr_bin + 1;
    end
    bin2gray #(.WIDTH(LOG2DEPTH+1)) bin2gray0 (.bin_i(wr_ptr_bin), .gray_o(wr_ptr_gray));

    always @ (posedge rclk or negedge reset_n)
    begin
        if (renq) rd_ptr_bin <= rd_ptr_bin + 1;  
    end
    bin2gray #(.WIDTH(LOG2DEPTH+1)) bin2gray1 (.bin_i(rd_ptr_bin), .gray_o(rd_ptr_gray));

//--------------------------- 2-SYNC ------------------------------
    always @ (posedge wclk) begin
        rd_ptr_s_gray <= rd_ptr_gray;
        rd_ptr_ss_gray <= rd_ptr_s_gray;
    end
    gray2bin #(.WIDTH(LOG2DEPTH+1)) gray2bin0 (.gray_i(rd_ptr_ss_gray), .bin_o(rd_ptr_ss_bin));

    always @ (posedge rclk) begin
        wr_ptr_s_gray <= wr_ptr_gray;
        wr_ptr_ss_gray <= wr_ptr_s_gray;
    end    
    gray2bin #(.WIDTH(LOG2DEPTH+1)) gray2bin1 (.gray_i(wr_ptr_ss_gray), .bin_o(wr_ptr_ss_bin));

//--------------------------- FULL or EMPTY -----------------------
    assign wr_depth = wr_ptr_bin - rd_ptr_ss_bin;
    assign full = (wr_depth == {1'b1, {LOG2DEPTH{1'b0}}});
    assign rd_depth = wr_ptr_ss_bin - rd_ptr_bin;
    assign empty = (rd_depth == {1'b0, {LOG2DEPTH{1'b0}}});

endmodule

module dual_clk_fifo_core (rclk, renq, wclk, wenq, data_in, data_out, wr_ptr, rd_ptr);
    parameter LOG2DEPTH = 5;
    parameter WIDTH = 8;

    input rclk, renq;
    input wclk, wenq;
    input [LOG2DEPTH-1:0] wr_ptr, rd_ptr;
    input [WIDTH-1:0] data_in;
    
    output [WIDTH-1:0] data_out;
    
    reg [WIDTH-1:0] memory [2**LOG2DEPTH-1:0];

    always @ (posedge wclk)
    begin
        if (wenq) begin
            memory[wr_ptr] <= data_in;
        end
    end
    
    assign data_out = (renq) ? memory[rd_ptr] : {WIDTH{1'bx}};

endmodule

module bin2gray (bin_i, gray_o);
    parameter WIDTH = 8;

    input [WIDTH-1:0] bin_i;
    output [WIDTH-1:0] gray_o;

    assign gray_o = (bin_i >> 1) ^ bin_i;

endmodule

module gray2bin (gray_i, bin_o);
    parameter WIDTH = 8;
    
    input [WIDTH-1:0] gray_i;
    output [WIDTH-1:0] bin_o;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin
            assign bin_o[i] = ^(gray_i >> i);
        end
    endgenerate

endmodule