`timescale 1ns / 1ps

module maze_display(

    );
endmodule

module maze_display_start_builder (input CLK,output [63:0] CMD);
    reg [63:0] MazeScene [31:0];//32 commands
    reg [5:0] count = 0;
    reg [63:0] cmd;
    `include "CommandFunctions.v"
    //assign MazeScene[0] = DrawChar(7'd55, 6'd53, 20'd11, LEVEL >= 4'd0 ? LT[THEME] : BGT[THEME],1'd0); //L, original size
    assign MazeScene[0] = DrawChar(7'd46, 6'd29, 20'd5, {5'd0, 6'd0, 5'd31},1'd1); end // 3 - char // blue char 0,0,B
    always @(posedge CLK) begin
        cmd = MazeScene[count];
        count = count + 6'd1;
    end
    assign CMD = cmd;
endmodule