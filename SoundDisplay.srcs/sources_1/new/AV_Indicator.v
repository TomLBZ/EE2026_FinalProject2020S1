`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: EE2026
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
    input [11:0] mic_in,
    input CLK,      //use 20kHz
    input CLK100MHZ,
    output [15:0] led,
    output reg [6:0] seg,
    output reg [3:0] an
    );
    
    reg [4:0] volume = 5'b00000;
    reg [29:0] counter = 30'b0;
    reg [29:0] tmp = 30'd0;
    reg [11:0] mic_max;
    
    always @ (posedge CLK100MHZ) begin
            counter <= counter + 1;
    end
    
    assign led = (16'b1111111111111111 >> (5'd15 - volume));
    
    always @ (CLK) begin
        if (counter[20]==1'b0) begin
            tmp = (mic_in *5'd15 / 12'b111111111111 - 5'd7) * 2'd2;   
        end
        volume <= tmp;
        
        if(counter[24]==1'b1) begin
                if (mic_max<mic_in) mic_max <= mic_in;   
        end
        if(counter[27]==1'b0) mic_max <= mic_max - 1'b1;
        
        //Controls the 7-segment display according to volume
        if (counter[22]==1'b0) begin
        if (volume <4'd10) begin 
                an = 4'b1110;
                case (volume)
                    4'd0: seg = 7'b1000000;
                    4'd1: seg = 7'b1111001;
                    4'd2: seg = 7'b0100100;
                    4'd3: seg = 7'b0110000;
                    4'd4: seg = 7'b0011001;
                    4'd5: seg = 7'b0010010;
                    4'd6: seg = 7'b0000010 ;
                    4'd7: seg = 7'b1111000;
                    4'd8: seg = 7'b0000000;
                    4'd9: seg = 7'b0010000;
                endcase
        end
        
        else if (volume >4'd9) begin
            if (counter[18]==1'b0) begin
                an = 4'b1101;
                seg = 7'b1111001;
            end
            else if (counter[18]==1'b1) begin
                an = 4'b1110;
                case (volume)
                            4'd10: seg = 7'b1000000;
                            4'd11: seg = 7'b1111001;
                            4'd12: seg = 7'b0100100;
                            4'd13: seg = 7'b0110000;
                            4'd14: seg = 7'b0011001;
                            4'd15: seg = 7'b0010010;
                endcase
            end
    end
   end
end    
endmodule
