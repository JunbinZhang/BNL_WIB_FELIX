module countertest_WIB
(
    input clk120,
    input clk240,
    input rst,
    output reg [127:0] data,
    output reg [15:0] k_data
);
////////////////////////////////
wire [127:0] link_data;
wire [15:0]  link_k_data;

wire fifo_rclk_1;
wire fifo_re_1;
wire busy_1;
wire fifo_empty_1;
wire [31:0] fifo_data_1;
wire [1:0] fifo_dtype_1;

FMchannelTXctrl_WIB link1
(
    .clk120(clk120),
    .clk240(clk240),
    .rst(rst),
    .data(link_data[63:0]),
    .k_data(link_k_data[7:0]),
	 
    .fifo_data(fifo_data_1),  
	 .fifo_dtype(fifo_dtype_1),
    .fifo_empty(fifo_empty_1),
    .busy(1'b0),
    .fifo_rclk(fifo_rclk_1),
    .fifo_re(fifo_re_1)
);

FullModeUserLogic_WIB user1
(
    .clk240(clk240),
    .rst(rst),
  //-------FMchannelTXctrl_WIB interface-----//
    .fifo_rclk(fifo_rclk_1),
    .fifo_re(fifo_re_1),
    .busy(busy_1),
    .empty(fifo_empty_1),
    .fifo_data(fifo_data_1),
    .fifo_dtype(fifo_dtype_1)
);


/////////////////////////////////
wire fifo_rclk_2;
wire fifo_re_2;
wire busy_2;
wire fifo_empty_2;
wire [31:0] fifo_data_2;
wire [1:0] fifo_dtype_2;

FMchannelTXctrl_WIB link2
(
    .clk120(clk120),
    .clk240(clk240),
    .rst(rst),
    .data(link_data[127:64]),
    .k_data(link_k_data[15:8]),
	 
	 .fifo_data(fifo_data_2),  
	 .fifo_dtype(fifo_dtype_2),
    .fifo_empty(fifo_empty_2),
    .busy(1'b0),//disable busy
    .fifo_rclk(fifo_rclk_2),
    .fifo_re(fifo_re_2)
);
FullModeUserLogic_WIB user2
(
    .clk240(clk240),
    .rst(rst),
  //-------FMchannelTXctrl_WIB interface-----//
    .fifo_rclk(fifo_rclk_2),
    .fifo_re(fifo_re_2),
    .busy(busy_2),
    .empty(fifo_empty_2),
    .fifo_data(fifo_data_2),
    .fifo_dtype(fifo_dtype_2)
);

//rebuid data for FELIX_PCS
always @ (posedge clk120) begin
    if(rst) begin
        data <= 128'b0;
        k_data <= 16'b0;
    end
    else begin
        data <= link_data;
        k_data <= link_k_data;
    end
end
endmodule
