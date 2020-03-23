`timescale 1ns / 1ps

module screen_test(
    input CLK100MHZ, [4:0] btn,[15:0] sw,
    input JAI,
    output [1:0] JAO,
    output [7:0] JB, [15:0] led, [6:0] seg, [3:0] an
    );
    
    reg taskMode = 1;//for lab tasks use 1, for project use 0.
    reg [2:0] clkrst = 0;//reset clock
    wire [15:0] oled_data; //= 16'h07E0;//pixel data to be sent
    reg [4:0] sbit = 0;//slow clock's reading bit. Freq(sclk) = Freq(CLK) / 2^(sbit + 1).
    wire [3:0] graphicsState;//determines state of graphics
    wire [11:0] mic_in;//mic sample input from the mic
    wire [4:0] btnPulses;
    wire [3:0] CLK;//[100M, 6.25M, 20k, _flexible_]
    wire [15:0] mic_mapped;//processed data for led display
    wire [12:0] currentPixel;//current pixel being updated, goes from 0 to 6143.
    wire [4:0] testState;
    wire reset = taskMode ? btnPulses[0] : (clkrst ? 1 : 0);
    wire clk6p25m = CLK[2];
    wire onRefresh;//asserted for 1 clk cycle when drawing new frame on the screen
    wire sendingPixels;
    wire samplePixel;
    wire led_MUX_toggle;
    
    
        Peripherals peripherals(CLK100MHZ,clkrst,sbit,btn,sw,CLK,btnPulses,led_MUX_toggle, graphicsState);
        Audio_Capture ac(CLK[3],CLK[1],JAI, JAO[0], JAO[1], mic_in);
        B16_MUX led_mux(mic_mapped,{4'b0,mic_in},led_MUX_toggle,led[15:0]);
        //Oled_Display(clk, reset, frame_begin, sending_pixels,sample_pixel, pixel_index, pixel_data, cs, sdin, sclk, d_cn, resn, vccen,pmoden,teststate);
        Oled_Display oled(clk6p25m,reset,onRefresh,sendingPixels,samplePixel,currentPixel,oled_data,JB[0],JB[1],JB[3],JB[4],JB[5],JB[6],JB[7], testState);
        //Graphics_test g(graphicsState, onRefresh, CLK[3], currentPixel, oled_data);
        //pixel f0(CLK[3], currentPixel);
        flappy_bird(CLK[0], currentPixel, oled_data);
        //
        AV_Indicator volind(mic_in,CLK[0],CLK100MHZ,mic_mapped,seg,an);
endmodule

module Graphics_test(input [3:0] swState, input onRefresh, input WCLK, input [12:0] Pix, output [15:0] STREAM);
    reg [63:0] Cmd;
    wire [63:0] PTcmd;
    wire [63:0] LNcmd;
    wire [63:0] CHRcmd;
    wire [63:0] RECTcmd;
    wire [63:0] CIRCcmd;
    wire [63:0] CIRCcmd1;
    wire [63:0] FRECTcmd;
    wire [63:0] FCIRCcmd;
    wire [6:0] CmdX;
    wire [5:0] CmdY;
    wire [15:0] CmdCol;
    wire pixSet;
    wire CmdBusy;
    wire [6:0] psX;
    wire [5:0] psY;
    wire [15:0] psC;
    wire write;
    wire CMD_ON = swState > 0;
    wire CommandDone;//add command queue later, this will be useful.
    DisplayCommandCore DCMD(Cmd, CMD_ON, WCLK, pixSet, CmdX, CmdY, CmdCol, CmdBusy,CommandDone);
    PixelSetter PSET(WCLK,pixSet,CmdX,CmdY,CmdCol,psX,psY,psC,write);
    DisplayRAM DRAM(Pix, WCLK, write, psX, psY, psC, STREAM);
    DrawPoint DPT(7'd48, 6'd32, {5'd31, 6'd63, 5'd31}, PTcmd); // white point R,G,B
    DrawLine DLN(7'd16, 6'd48, 7'd80, 6'd48, {5'd31,6'd32,5'd0}, LNcmd); // orange line R,0.5G,0
    DrawChar DCHR(7'd46, 6'd29, 30'd0, {5'd0, 6'd0, 5'd31}, CHRcmd); // blue char 0,0,B
    DrawRect DRECT(7'd32, 6'd16, 7'd64, 6'd48, {5'd31,6'd0,5'd0}, RECTcmd); // red rect R,0,0
    DrawCirc DCIRC(7'd48, 6'd32, 5'd31, {5'd0, 6'd63, 5'd0}, CIRCcmd); // green circle 0,G,0
    DrawCirc DCIRC1(7'd20, 6'd22, 5'd20, {5'd31, 6'd63, 5'd0}, CIRCcmd1);
    FillRect FRECT(7'd40, 6'd24, 7'd56, 6'd40, {5'd31,6'd63,5'd0}, FRECTcmd); // yellow frect R,G,0
    FillCirc FCIRC(7'd48, 6'd32, 5'd16, {5'd31, 6'd0, 5'd31}, FCIRCcmd); // magenta fcircle R,0,B
    always @ (*) begin//redraw onto the DRAM as a new frame
        if(~CmdBusy) begin
            case (swState)
                4'd1: begin Cmd = PTcmd; end // 1 - point
                4'd2: begin Cmd = LNcmd; end // 2 - line
                4'd3: begin Cmd = CHRcmd; end // 3 - char
                4'd4: begin Cmd = RECTcmd; end // 4 - rectangle
                4'd5: begin Cmd = CIRCcmd; end // 5 - circle
                4'd6: begin Cmd = CIRCcmd1; end //
                4'd7: begin Cmd = FRECTcmd; end // 7 - fill rectangle
                4'd8: begin Cmd = FCIRCcmd; end //8 - fill circle
                default: begin Cmd = 0; end // 0 - idle
            endcase
        end
    end
endmodule







module flappy_bird(input CLK, input [12:0] Pix, output reg [15:0] STREAM);
    //reg [29:0] counter = 30'b000000000000000000000000000000;
    reg [12:0] xvalue;
    reg [12:0] yvalue;
    //reg [7:0] xleft = 8'b00000000;
    
    always @ (posedge CLK) begin
        //map Pix value to x and y
        //counter <= counter + 1'b1;
        yvalue = Pix / 8'd96;   //0~64
        xvalue = Pix - yvalue * 8'd96;  //0~96
        
        if ((xvalue > 7'd0) && (xvalue<7'd18) && (yvalue > 7'd56) && (yvalue < 7'd64)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd12) && (xvalue<7'd18) && (yvalue > 7'd32) && (yvalue < 7'd56)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd6) && (xvalue<7'd12) && (yvalue > 7'd8) && (yvalue < 7'd40)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd12) && (xvalue<7'd30) && (yvalue > 7'd8) && (yvalue < 7'd16)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd24) && (xvalue<7'd54) && (yvalue > 7'd16) && (yvalue < 7'd24)) STREAM <= 16'b1111100000000000;
        else if ((xvalue > 7'd36) && (xvalue<7'd42) && (yvalue > 7'd0) && (yvalue < 7'd16)) STREAM <= 16'b1111100000000000;
        else STREAM <= 16'b0000000000111111;
        
    end
    
endmodule
    





