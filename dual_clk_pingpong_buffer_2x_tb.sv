module dual_clk_pingpong_buffer_2x_tb;
	reg wen;
	reg ren;
	reg rclk = 0;
	reg wclk = 0;
	reg reset_n;
	reg [7:0] data_in = 0;
	wire [7:0] data_out;
    wire full_o, empty_o;


dual_clk_pingpong_buffer_2x #(.WIDTH(8), .LOG2_NUM_DEPTH_FIFO(1)) DUT (.rclk(rclk), .ren(ren), .wclk(wclk), .wen(wen), .reset_n(reset_n), .data_in(data_in), .data_out(data_out), .full_o(full_o), .empty_o(empty_o));

	always 
    begin
		if($time<1000)	#5 wclk = ~wclk;
		else			#2.5 wclk = ~wclk;
	end
	always
	begin
		if($time<1000)  #2.5 rclk = ~rclk;
		else            #5 rclk = ~rclk;
	end

	always @(posedge wclk)
	begin
		if (reset_n) begin
			if(~full_o) begin 
				data_in <= data_in + 1;
				wen <= 1;
			end
			else begin 
				wen <= 0;
				$display("Time %d full", $time);
			end
		end
	end
	always @(posedge rclk)
	begin
		if (reset_n) begin
			if(~empty_o) ren <= 1;
			else begin
                ren <= 0;
                $display("Time %d empty", $time);
            end
		end
	end

initial begin
	#0 reset_n = 0;
	#5 reset_n = 1;
end


initial #3000 $stop;

endmodule