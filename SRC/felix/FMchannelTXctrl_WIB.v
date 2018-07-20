`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2016/12/12 20:46:30
// Design Name: 
// Module Name: test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module FMchannelTXctrl_WIB(
  input clk120,
  input clk240,
  input rst,
  //--------user logic interface-----//
  input [31:0] fifo_data,  
  input [1:0]  fifo_dtype,
  input fifo_empty,
  input busy,
  output fifo_rclk,
  output fifo_re,
  //--------FELIX PCS interface------//
  output reg [63:0] data,  //output to FELIX_PCS
  output reg [7:0] k_data //output to FELIX_PCS
);

//--------link1-----------//
wire [39:0] link_fifo_data_in; //40-bit inputs
assign link_fifo_data_in[39:36] = 4'b0000;

FMchannelTXctrl link
(
    .clk240(clk240),
    .rst(rst),//high level active
    .busy(busy),  //coming from user logic
    .fifo_rclk(fifo_rclk), //240MHz output to user logic
    .fifo_re(fifo_re),     //output to user logic
    .fifo_dout(fifo_data), //coming from user logic
    .fifo_dtype(fifo_dtype),//coming from user logic
    .fifo_empty(fifo_empty),//coming from user logic
    .dout(link_fifo_data_in[31:0]), //32-bit
    .kout(link_fifo_data_in[35:32])  //4-bit
);



//40-bit wide, 128 word depth
wire [79:0] link_fifo_dout;
wire link_fifo_empty;
wire link_fifo_rdreq;
assign link_fifo_rdreq = !link_fifo_empty;
wire link_fifo_full;
wire link_fifo_wrreq;
assign link_fifo_wrreq = !link_fifo_full;

felix_fifo data_fifo
(
    .aclr(rst),
    .data(link_fifo_data_in), //40bit
    .wrreq(link_fifo_wrreq),
    .wrclk(clk240),
    .wrfull(link_fifo_full),

    .rdreq(link_fifo_rdreq),//read fifo if not empty
    .rdclk(clk120),
    .rdempty(link_fifo_empty),
    .q(link_fifo_dout) //80 bits
);


always @ (posedge clk120) begin
    if(rst) begin
        data <= 64'b0;
        k_data <= 8'b0;
    end
    else begin
        data <= {link_fifo_dout[71:40],link_fifo_dout[31:0]};    
        k_data <= {link_fifo_dout[75:72],link_fifo_dout[35:32]};
    end
end
//------------------------------//
endmodule
