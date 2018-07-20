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


module FullModeUserLogic_WIB(
  input clk240,
  input rst,
  //-------FMchannelTXctrl_WIB interface-----//
  input fifo_rclk,
  input fifo_re,
  output busy,
  output empty,
  output [31:0] fifo_data,
  output [1:0]  fifo_dtype
  //----------observe signals-------//
  //output o_wrreq,
  //output o_full,
  //output [31:0] o_data,
  //output [1:0] o_dtype
);

assign busy = 1'b0;
// Build a 16-bit counter
reg [31:0] counter; //WIB frame has 464 bytes
reg [31:0] data;
reg [1:0]  dtype;
//---------------fifo write process------------------//
wire [35:0] data_in;
wire [35:0] data_out;
wire wrfull;
reg wrreq;
assign data_in = {2'b00,dtype,data};


// Build a state machine sending sop/eop/data
//-------FELIX K-code definition-------------//
////---------State Machine-------------//
//localparam INIT = 3'd0,
//           SOP  = 3'd1,
//           DATA = 3'd2,
//           EOP  = 3'd3,
//           IDLE  = 3'd4;
////localparam CHUNK_SIZE = 116;
//---------State Machine-------05112018------//
localparam START = 3'd0,
           SOP  = 3'd1,
           DATA = 3'd2,
           EOP  = 3'd3,
			  IDLE = 3'd4;
reg[2:0] State;
always @ (posedge clk240) begin
    if(rst) begin
        State <= START;
        data <= 32'hDEADBEEF;
        dtype<= 2'b11;
        counter <= 32'b0;
    end
    else begin
        case(State)
		  
				START:begin
              data <= 32'b0;
              dtype <= 2'b01; //01 -> sop
				  State <= SOP;	
				end

            SOP: begin
                data <= data + 1'b1;
                counter <= counter + 1'b1;
                dtype <= 2'b00; // 00 -> normal data
                State <= DATA;
            end 
            DATA:begin    
                if(counter < 32'd114) begin
                    counter <= counter + 1'b1;
                    data <= data + 1'b1;
                    State <= DATA;
                end
                else begin
                  counter <= counter + 1'b1;
                  State<= EOP;
                  data <= data + 1'b1;
                  dtype <= 2'b10; //10->eop
                end                
            end
            EOP:begin
                counter <= 32'b0;
                State <= IDLE;
                dtype <= 2'b11; //11 -> ignored
                data <= 32'hDEADBEEF;			 
            end
				IDLE:begin
					if(counter < 32'd3) begin
						counter <= counter + 1'b1;
						State <= IDLE;
					end
					else begin
						counter <= 32'b0;
						dtype <= 2'b01;
						data <= 32'b0;
						State <= SOP;
					end
				end
				default:State <= START;
        endcase
    end
end
//Generate 
always @ (State) begin
	if(((State == SOP) || (State == DATA) || (State == EOP)) && !wrfull)
		wrreq = 1'b1;
	else
		wrreq = 1'b0;
end



felix_user_fifo user_fifo
(
    .aclr(rst),
    .data(data_in), //36 bits
    .wrreq(wrreq),
    .wrclk(clk240),
    .wrfull(wrfull),

    .rdreq(fifo_re),//read fifo if not empty
    .rdclk(fifo_rclk),
    .rdempty(empty),
    .q(data_out) //36 bits
);

assign fifo_data = data_out[31:0];
assign fifo_dtype = data_out[33:32];

//assign o_full = wrfull;
//assign o_wrreq = wrreq;
//assign o_data = data;
//assign o_dtype = dtype;


endmodule
