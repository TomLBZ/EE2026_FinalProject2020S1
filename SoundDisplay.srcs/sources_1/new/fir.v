`timescale 1ns / 1ps

module fir(input CLK, reset_n,output [9:0] mic_in,output reg [9:0] fir_data);
reg    [31:0] clk_cnt;
reg    clk_div;

    rom_top u1(CLK,reset_n,0,0,mic_in);
    always @(posedge CLK or negedge reset_n)
        begin
            if(!reset_n)
                begin
                    clk_div<=1'b0;
                    clk_cnt<=32'd0;
                end
            else if(clk_cnt==32'd249) //100k
                begin
                    clk_div<=~clk_div;
                    clk_cnt<=32'd0;
                end
            else
                clk_cnt<=clk_cnt+1'b1;
        end
reg    [9:0] t1[7:0];
wire [31:0]data_reg [5:0];
wire [31:0]data_temp;

assign data_reg[0]=9*(t1[0]+t1[7]);
assign data_reg[1]=48*(t1[1]+t1[6]);
assign data_reg[2]=164*(t1[2]+t1[5]);
assign data_reg[3]=279*(t1[3]+t1[4]);
assign data_reg[4]=data_reg[0]+data_reg[1];
assign data_reg[5]=data_reg[2]+data_reg[3];   
assign data_temp  =(data_reg[4]+data_reg[5])/1000;

    always @(posedge clk_div or negedge reset_n)
    begin
        if(!reset_n)
        begin
            fir_data<=10'd0;
            t1[0]<=10'd0;
            t1[1]<=10'd0;
            t1[2]<=10'd0;
            t1[3]<=10'd0;
            t1[4]<=10'd0;
            t1[5]<=10'd0;
            t1[6]<=10'd0;
            t1[7]<=10'd0;
        end
        else
        begin
            fir_data<=data_temp[9:0];
            t1[1]<=t1[0];
            t1[2]<=t1[1];
            t1[3]<=t1[2];
            t1[4]<=t1[3];
            t1[5]<=t1[4];
            t1[6]<=t1[5];
            t1[7]<=t1[6];
            t1[0]<=mic_in;
        end
    end
endmodule


module rom_top(input CLK,reset_n, output  [8:0] q, output  [7:0] dds_tri_out,output  [9:0] data_temp);
    wire [31:0] f32_bus;
    wire [31:0] reg32_out;
    wire [31:0] reg32_in;
    assign f32_bus =32'd85899;
       adder_32 u1(f32_bus,reg32_out,reg32_in);
       reg32    u2(CLK,reset_n,reg32_in,reg32_out);
       sin1      u3(reg32_out[31:22],CLK,q);

    wire [31:0]      tri_f32_bus;                        
    wire [31:0]      tri_reg32_out;          
    wire [31:0]      tri_reg32_in;                 
    assign tri_f32_bus=32'd1803886;//21K
        adder_32 u5(tri_f32_bus,tri_reg32_out,tri_reg32_in);
        reg32    u6(CLK,reset_n,tri_reg32_in,tri_reg32_out);                                 
        sin2  u7(tri_reg32_out[31:22],CLK,dds_tri_out);
    assign data_temp = dds_tri_out + q;
endmodule 


module adder_32(input [31:0] data1,input [31:0]data2,output [31:0] sum);
    assign sum = data1+data2;
endmodule


module reg32(input CLK,reset_n,[31:0] data_in,output reg [31:0] data_out);
    always @(posedge CLK or negedge reset_n) begin
        if(!reset_n) data_out <= 32'h0000_0000;
        else data_out <= data_in;
    end 
endmodule