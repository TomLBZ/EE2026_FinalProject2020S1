`timescale 1ns / 1ps


module Audio_Volume_Indicator(
    input mic_in,
    input [3:0] CLK,
    output reg [15:0] led,
    output reg [6:0] seg,
    output reg [3:0] an
    );
    
    reg segdisplay = 15'd0;
    
    always @ (CLK[1]) begin
        segdisplay = (mic_in * 5'd15) / 12'b111111111111;
        
        if (segdisplay <4'd10) an = 4'b1110;
        
        case (segdisplay)
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
    
endmodule
