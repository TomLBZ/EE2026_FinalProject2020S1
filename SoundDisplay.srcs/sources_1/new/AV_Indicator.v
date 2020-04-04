`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
// Engineer: Li Bozhao
// Engineer: Liu Jingjing
// 
// Create Date: 03/19/2020 10:53:20 AM
// Design Name: FGPA Project for EE2026
// Module Name: AV_Indicator
// Project Name: FGPA Project for EE2026
// Target Devices: Basys3
// Tool Versions: Vivado 2018.2
// Description: This module operates 7-seg display based on mic input.
// 
// Dependencies: NULL
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////
    
module AV_Indicator(
    input DCLK,   //6.25M
    input RefSCLK,  //20k
    input SCLK,   //
    input [11:0] mic_in,
    output [3:0] an,
    output reg [6:0] SEG,
    output [15:0] led,
    output reg [3:0] volume
    );
    reg [11:0] mic_max;
    reg [3:0] mask = 4'b0001;
    reg digit = 1'b0;
    reg [6:0] seg;
    wire [3:0] vol_mod_10 = volume > 4'd9 ? volume - 4'd10 : volume;
    wire maxstin = mic_max < mic_in;
    
    assign an = ~(mask << digit);     //shift 1/0 bit
    assign led = (16'b1111111111111111 >> (5'd15 - volume));  
    reg [11:0] baseline = 12'b011111111111;
    wire [11:0] mic_minus = mic_max > baseline ? mic_max - baseline : 12'b0;
    reg [15:0] cnt = 16'b0000000000000000;
    always @ (posedge RefSCLK) begin
            volume <= (mic_minus >> 7);
            digit = ~digit;
    end
    always @ (posedge SCLK) begin
        mic_max <= maxstin ? mic_in : mic_max - 1;
        seg = SEG; 
    end 
    always@(*)begin
        if (digit) begin//10th
            //an = 4'b1101;
            if(volume < 4'd10) SEG = 7'b1111111;
            else SEG = 7'b1111001;
        end else begin//1st
            //an = 4'b1110;
            case (vol_mod_10)
                4'd0: SEG = 7'b1000000;
                4'd1: SEG = 7'b1111001;
                4'd2: SEG = 7'b0100100;
                4'd3: SEG = 7'b0110000;
                4'd4: SEG = 7'b0011001;
                4'd5: SEG = 7'b0010010;
                4'd6: SEG = 7'b0000010 ;
                4'd7: SEG = 7'b1111000;
                4'd8: SEG = 7'b0000000;
                4'd9: SEG = 7'b0010000;
            endcase
        end
    end

endmodule