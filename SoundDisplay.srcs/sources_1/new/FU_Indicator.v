`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module AVL_Indicator(
    input DCLK,   //100Mhz
    input RefSCLK,  //20k
    input SCLK,   //381Hz
    input [11:0] mic_in,
    output reg [3:0] an,
    output reg [6:0] seg,
    output [15:0] led,
    output reg [3:0] volume
    );
    reg [11:0] mic_max;
    reg [32:0] counter = 33'b000000000000000000000000000000000;
    wire [3:0] vol_mod_10 = (volume > 4'd9) ? volume - 4'd10 : volume;
    assign led = (16'b1111111111111111 >> (5'd16 - volume)); 

    //always@(posedge RefSCLK) 
    always @ (posedge DCLK) begin 
        counter <= counter + 1;
        if (counter[26]==1'b0) volume = (mic_max >> 7) - 5'd14;  //
        if (mic_max<mic_in) mic_max <= mic_in;  
        else if(counter[28]==1'b1) mic_max <= mic_max - 1'b1;   //mic_max decreases constantly at 
        if (counter[18]==1'b1) begin
            an = 4'b1101;
            if (volume <4'd10) seg = 7'b1111111;
            else seg = 7'b1111001;
        end
        else begin
            an = 4'b1110;
            case (vol_mod_10)
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
    end
endmodule
