`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: liaozinmdxintaibengle
// 
// Create Date: 2020/03/27 00:33:54
// Design Name: 
// Module Name: FU_Indicator
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


module FU_Indicator(
    input DCLK,   //100Mhz
    input RefSCLK,  //20k
    input SCLK,   //381Hz
    input [11:0] mic_in,
    output [3:0] an,
    output reg [6:0] seg,
    output [15:0] led,
    output reg [3:0] volume
    );
    
    reg [11:0] mic_max;
    reg [29:0] counter = 30'b0;
    wire [3:0] vol_mod_10 = volume > 4'd9 ? volume - 4'd10 : volume;
    reg [3:0] mask = 4'b0001;
    reg digit = 1'b0;
    reg [6:0] SEG;
    reg [29:0] tmp = 30'd0;
    assign an = ~(mask << digit);     //shift 1/0 
    always @ (posedge DCLK) counter <= counter + 1;
    
    assign led = (16'b1111111111111111 >> (5'd15 - volume));  
    always @ (posedge RefSCLK) begin  //20kHz
            tmp = (mic_max *5'd15 / 12'b111111111111 - 5'd7) * 2'd2;   
            volume <= tmp;
            digit = ~digit;
            if ((mic_max<mic_in)&&(counter[24]==1'b1)) mic_max <= mic_in;  //update mic_max value at 6Hz
            if(counter[28]==1'b1) mic_max <= mic_max - 1'b1;   //mic_max decreases constantly at 0.74Hz
    end

    always@(posedge SCLK) seg = SEG;   //6Hz

    always@(negedge DCLK)begin
        if (digit) begin
            if (volume <4'd10) SEG = 7'b1111111;
            else SEG = 7'b1111001;
        end
        else begin
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
