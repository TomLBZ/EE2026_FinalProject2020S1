`timescale 1ns / 1ps
// clock signals needed: 6Hz, 190Hz, 381Hz

module Audio_Volume_Indicator(
    input [11:0] mic_in,
    input CLK,
    input CLK100MHZ,
    output reg [15:0] led,
    output reg [6:0] seg,
    output reg [3:0] an
    );
    reg [30:0] counter = 31'b00000000000000000000000000000;
    reg [21:0] segdisplaymax = 20'd0;
    reg [4:0] segdisplay = 5'b0;
    reg [11:0] mic_max;
    reg tmp = 0;
    //assign led = (16'b1111111111111111 >> (5'd15-segdisplay));
    
    always @ (posedge CLK100MHZ) begin
        counter <= counter + 1;
    end
    
    always @ (CLK) begin
        //led <= (16'b1111111111111111 >> (5'd15-segdisplay));
        
        if(counter[24]==1'b1) begin
            if (mic_max<mic_in) mic_max <= mic_in;   
            
        end
        if(counter[27]==1'b0) mic_max <= mic_max - 1'b1;
        
        segdisplaymax = (mic_max * 5'd15) / 12'b111111111111;
        //segdisplaymax = (mic_max - 20'd1911) * 10'd273;
        segdisplay <= segdisplaymax;
        
        case(segdisplay) 
            4'd0: led = 16'b0000000000000000;
            4'd1: led = 16'b0000000000000001;
            4'd2: led = 16'b0000000000000011;
            4'd3: led = 16'b0000000000000111;
            4'd4: led = 16'b0000000000001111;
            4'd5: led = 16'b0000000000011111;
            4'd6: led = 16'b0000000000111111;
            4'd7: led = 16'b0000000001111111;
            4'd8: led = 16'b0000000011111111;
            4'd9: led = 16'b0000000111111111;
        endcase
        
        if (segdisplay <4'd10) begin 
                an = 4'b1110;
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
        
        else if (segdisplay >4'd9) begin
            if (counter[18]==1'b0) begin
                an = 4'b1101;
                seg = 7'b1111001;
            end
            else if (counter[18]==1'b1) begin
                an = 4'b1110;
                case (segdisplay)
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
endmodule
