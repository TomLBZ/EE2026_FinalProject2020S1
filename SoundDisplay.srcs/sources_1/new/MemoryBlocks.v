`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// 
// Create Date: 03/16/2020 08:58:28 AM
// Design Name: FGPA Project for EE2026
// Module Name: MemoryBlocks, fifo, RAM
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module provides data structures to store relatively large amount of data and interact with them
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MemoryBlocks(

    );
endmodule
module fifo #(parameter WSIZE = 16,parameter DSIZE = 32)
(
    input wr_clk, rst_n, wr_en, [WSIZE-1 : 0]din, rd_clk, rd_en,
    output [WSIZE-1 : 0]dout,
    output reg rempty,
    output reg wfull
);
//variables
    reg [WSIZE-1 :0] mem [DSIZE-1 : 0];
    reg [WSIZE-1 : 0] waddr,raddr;
    reg [WSIZE : 0] wbin,rbin,wbin_next,rbin_next;
    reg [WSIZE : 0] wgray_next,rgray_next;
    reg [WSIZE : 0] wp,rp;
    reg [WSIZE : 0] wr1_rp,wr2_rp,rd1_wp,rd2_wp;
    wire rempty_val,wfull_val;
    wire [WSIZE-1 : 0] _waddr,_raddr;
    wire [WSIZE : 0] _wgray_next,_rgray_next,_wbin_next,_rbin_next;
//output data
    assign dout = mem[raddr];
//input data
    always@(posedge wr_clk) if(wr_en && !wfull) mem[waddr] <= din;
//1.generate read address raddr; 2.convert binary to gray and assign to read pointer rp
    always@(posedge rd_clk or negedge rst_n) begin
        if(!rst_n) {rbin,rp} <= 0;
        else {rbin,rp} <= {rbin_next,rgray_next};
    end
    assign _raddr = rbin[WSIZE-1 : 0];
    assign _rbin_next = rbin + (rd_en & ~rempty);
    assign _rgray_next = rbin_next ^ (rbin_next >> 1);
    always @(_raddr) raddr = _raddr;
    always @(_rbin_next) rbin_next = _rbin_next;
    always @(_rgray_next) rgray_next = _rgray_next;
//1.generate read address waddr; 2.convert binary to gray and assign to write pointer wp
    always@(posedge wr_clk or negedge rst_n) begin
        if(!rst_n) {wbin,wp} <= 0;
        else {wbin,wp} <= {wbin_next,wgray_next};
    end
    assign _waddr = wbin[WSIZE-1 : 0];
    assign _wbin_next = wbin + (wr_en & ~wfull);
    assign _wgray_next = wbin_next ^ (wbin_next >> 1);
    always @(_waddr) waddr = _waddr;
    always @(_wbin_next) wbin_next = _wbin_next;
    always @(_wgray_next) wgray_next = _wgray_next;
//synchronize read pointer rp to read clock field
    always@(posedge wr_clk or negedge rst_n) begin
        if(!rst_n) {wr2_rp,wr1_rp} <= 0;
        else {wr2_rp,wr1_rp} <= {wr1_rp,rp};
    end
//synchronize write pointer wp to write clock field
    always@(posedge rd_clk or negedge rst_n) begin
        if(!rst_n) {rd2_wp,rd1_wp} <= 0;
        else {rd2_wp,rd1_wp} <= {rd1_wp,wp};
    end
//generate read empty signal rempty
    assign rempty_val = (rd2_wp == rgray_next);
    always@(posedge rd_clk or negedge rst_n) begin
        if(rst_n) rempty <= 1'b1;
        else rempty <= rempty_val;
    end
//generate write full signal wfull
    assign wfull_val = ((~(wr2_rp[WSIZE : WSIZE-1]) || wr2_rp[WSIZE-2 : 0]) == wgray_next);
    always@(posedge wr_clk or negedge rst_n) begin
        if(!rst_n) wfull <= 1'b0;
        else wfull <= wfull_val;
    end
endmodule
