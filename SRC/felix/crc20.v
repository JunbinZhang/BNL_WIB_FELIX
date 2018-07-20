
//-----------------------------------------------------------------------------
// Copyright (C) 2009 OutputLogic.com 
// This source file may be used and distributed without restriction 
// provided that this copyright statement is not removed from the file 
// and that any derivative work contains the original copyright notice 
// and the associated disclaimer. 
// 
// THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS 
// OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED	
// WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE. 
//-----------------------------------------------------------------------------
// CRC module for data[31:0] ,   crc[19:0]=1+x^1+x^2+x^3+x^6+x^7+x^9+x^11+x^12+x^18+x^19+x^20;
//-----------------------------------------------------------------------------
module crc20(
  input [31:0] data_in,
  input crc_en,
  output [19:0] crc_out,
  input rst,
  input clk);

  reg [19:0] lfsr_q,lfsr_c;

  

  always @(*) begin
    lfsr_c[0] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[3] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[14] ^ lfsr_q[16] ^ lfsr_q[18] ^ lfsr_q[19] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[12] ^ data_in[13] ^ data_in[15] ^ data_in[21] ^ data_in[22] ^ data_in[23] ^ data_in[24] ^ data_in[26] ^ data_in[28] ^ data_in[30] ^ data_in[31];
    lfsr_c[1] = lfsr_q[0] ^ lfsr_q[2] ^ lfsr_q[3] ^ lfsr_q[4] ^ lfsr_q[9] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ lfsr_q[16] ^ lfsr_q[17] ^ lfsr_q[18] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[9] ^ data_in[12] ^ data_in[14] ^ data_in[15] ^ data_in[16] ^ data_in[21] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30];
    lfsr_c[2] = lfsr_q[0] ^ lfsr_q[4] ^ lfsr_q[5] ^ lfsr_q[9] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[15] ^ lfsr_q[17] ^ data_in[0] ^ data_in[8] ^ data_in[10] ^ data_in[12] ^ data_in[16] ^ data_in[17] ^ data_in[21] ^ data_in[23] ^ data_in[24] ^ data_in[27] ^ data_in[29];
    lfsr_c[3] = lfsr_q[0] ^ lfsr_q[3] ^ lfsr_q[5] ^ lfsr_q[6] ^ lfsr_q[9] ^ lfsr_q[11] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[19] ^ data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[11] ^ data_in[12] ^ data_in[15] ^ data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[23] ^ data_in[25] ^ data_in[26] ^ data_in[31];
    lfsr_c[4] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[4] ^ lfsr_q[6] ^ lfsr_q[7] ^ lfsr_q[10] ^ lfsr_q[12] ^ lfsr_q[14] ^ lfsr_q[15] ^ data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[12] ^ data_in[13] ^ data_in[16] ^ data_in[18] ^ data_in[19] ^ data_in[22] ^ data_in[24] ^ data_in[26] ^ data_in[27];
    lfsr_c[5] = lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[5] ^ lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[11] ^ lfsr_q[13] ^ lfsr_q[15] ^ lfsr_q[16] ^ data_in[2] ^ data_in[5] ^ data_in[6] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[13] ^ data_in[14] ^ data_in[17] ^ data_in[19] ^ data_in[20] ^ data_in[23] ^ data_in[25] ^ data_in[27] ^ data_in[28];
    lfsr_c[6] = lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[6] ^ lfsr_q[8] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[17] ^ lfsr_q[18] ^ lfsr_q[19] ^ data_in[0] ^ data_in[1] ^ data_in[4] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[13] ^ data_in[14] ^ data_in[18] ^ data_in[20] ^ data_in[22] ^ data_in[23] ^ data_in[29] ^ data_in[30] ^ data_in[31];
    lfsr_c[7] = lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[7] ^ lfsr_q[10] ^ lfsr_q[14] ^ lfsr_q[16] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[13] ^ data_in[14] ^ data_in[19] ^ data_in[22] ^ data_in[26] ^ data_in[28];
    lfsr_c[8] = lfsr_q[0] ^ lfsr_q[2] ^ lfsr_q[3] ^ lfsr_q[8] ^ lfsr_q[11] ^ lfsr_q[15] ^ lfsr_q[17] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[8] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[14] ^ data_in[15] ^ data_in[20] ^ data_in[23] ^ data_in[27] ^ data_in[29];
    lfsr_c[9] = lfsr_q[4] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[14] ^ lfsr_q[19] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[9] ^ data_in[10] ^ data_in[11] ^ data_in[16] ^ data_in[22] ^ data_in[23] ^ data_in[26] ^ data_in[31];
    lfsr_c[10] = lfsr_q[0] ^ lfsr_q[5] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[15] ^ data_in[1] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6] ^ data_in[10] ^ data_in[11] ^ data_in[12] ^ data_in[17] ^ data_in[23] ^ data_in[24] ^ data_in[27];
    lfsr_c[11] = lfsr_q[3] ^ lfsr_q[6] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[18] ^ lfsr_q[19] ^ data_in[0] ^ data_in[1] ^ data_in[2] ^ data_in[5] ^ data_in[6] ^ data_in[8] ^ data_in[11] ^ data_in[15] ^ data_in[18] ^ data_in[21] ^ data_in[22] ^ data_in[23] ^ data_in[25] ^ data_in[26] ^ data_in[30] ^ data_in[31];
    lfsr_c[12] = lfsr_q[1] ^ lfsr_q[3] ^ lfsr_q[4] ^ lfsr_q[7] ^ lfsr_q[9] ^ lfsr_q[15] ^ lfsr_q[16] ^ lfsr_q[18] ^ data_in[0] ^ data_in[2] ^ data_in[4] ^ data_in[8] ^ data_in[9] ^ data_in[13] ^ data_in[15] ^ data_in[16] ^ data_in[19] ^ data_in[21] ^ data_in[27] ^ data_in[28] ^ data_in[30];
    lfsr_c[13] = lfsr_q[2] ^ lfsr_q[4] ^ lfsr_q[5] ^ lfsr_q[8] ^ lfsr_q[10] ^ lfsr_q[16] ^ lfsr_q[17] ^ lfsr_q[19] ^ data_in[1] ^ data_in[3] ^ data_in[5] ^ data_in[9] ^ data_in[10] ^ data_in[14] ^ data_in[16] ^ data_in[17] ^ data_in[20] ^ data_in[22] ^ data_in[28] ^ data_in[29] ^ data_in[31];
    lfsr_c[14] = lfsr_q[3] ^ lfsr_q[5] ^ lfsr_q[6] ^ lfsr_q[9] ^ lfsr_q[11] ^ lfsr_q[17] ^ lfsr_q[18] ^ data_in[2] ^ data_in[4] ^ data_in[6] ^ data_in[10] ^ data_in[11] ^ data_in[15] ^ data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[23] ^ data_in[29] ^ data_in[30];
    lfsr_c[15] = lfsr_q[0] ^ lfsr_q[4] ^ lfsr_q[6] ^ lfsr_q[7] ^ lfsr_q[10] ^ lfsr_q[12] ^ lfsr_q[18] ^ lfsr_q[19] ^ data_in[3] ^ data_in[5] ^ data_in[7] ^ data_in[11] ^ data_in[12] ^ data_in[16] ^ data_in[18] ^ data_in[19] ^ data_in[22] ^ data_in[24] ^ data_in[30] ^ data_in[31];
    lfsr_c[16] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[5] ^ lfsr_q[7] ^ lfsr_q[8] ^ lfsr_q[11] ^ lfsr_q[13] ^ lfsr_q[19] ^ data_in[4] ^ data_in[6] ^ data_in[8] ^ data_in[12] ^ data_in[13] ^ data_in[17] ^ data_in[19] ^ data_in[20] ^ data_in[23] ^ data_in[25] ^ data_in[31];
    lfsr_c[17] = lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[6] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[12] ^ lfsr_q[14] ^ data_in[5] ^ data_in[7] ^ data_in[9] ^ data_in[13] ^ data_in[14] ^ data_in[18] ^ data_in[20] ^ data_in[21] ^ data_in[24] ^ data_in[26];
    lfsr_c[18] = lfsr_q[0] ^ lfsr_q[1] ^ lfsr_q[2] ^ lfsr_q[7] ^ lfsr_q[11] ^ lfsr_q[12] ^ lfsr_q[13] ^ lfsr_q[14] ^ lfsr_q[15] ^ lfsr_q[16] ^ lfsr_q[18] ^ lfsr_q[19] ^ data_in[0] ^ data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[7] ^ data_in[10] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^ data_in[19] ^ data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^ data_in[27] ^ data_in[28] ^ data_in[30] ^ data_in[31];
    lfsr_c[19] = lfsr_q[0] ^ lfsr_q[2] ^ lfsr_q[8] ^ lfsr_q[9] ^ lfsr_q[10] ^ lfsr_q[11] ^ lfsr_q[13] ^ lfsr_q[15] ^ lfsr_q[17] ^ lfsr_q[18] ^ data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[5] ^ data_in[6] ^ data_in[7] ^ data_in[11] ^ data_in[12] ^ data_in[14] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^ data_in[23] ^ data_in[25] ^ data_in[27] ^ data_in[29] ^ data_in[30];

  end // always

  always @(posedge clk, posedge rst) begin
    if(rst) begin
      lfsr_q <= {20{1'b1}};
    end
    else begin
      lfsr_q <= crc_en ? lfsr_c : lfsr_q;
    end
  end // always
  
  
  
  reg [19:0] crc_temp;
  
  always @(posedge clk, posedge rst) begin
    if(rst) begin
      crc_temp <= {20{1'b1}};
    end
    else begin
      crc_temp <= lfsr_q;
    end
  end // always  
  assign crc_out = crc_temp;
endmodule // crc

