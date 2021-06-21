`timescale 1ns/1ps

module ff(d, clk, reset, q);
	parameter clk_to_Q = 0;
    parameter ff_width = 1;

    input [ff_width - 1:0] d;
    input clk;
    input reset;
    output reg [ff_width - 1:0] q;

    always @ (posedge clk or negedge reset) begin
        if(reset == 0) begin
        	#clk_to_Q q <= 0;
        end
        else if(clk == 1) begin
            #clk_to_Q q <= d;
        end
        else begin
            #clk_to_Q q <= q;
        end 
    end
endmodule

module clickcontrol(reset, aReq, bAck, aAck, bReq, clk);

    parameter ff_width = 1;
    parameter gate_delay = 2;
	input reset;
	input aReq;
	input bAck;
	output reg [ff_width - 1 : 0] aAck;
	output reg [ff_width - 1 : 0] bReq;
	output reg clk;

    wire temp1, temp2, clk_wire, aAck_wire, bReq_wire, aReq_wire;
    wire [ff_width - 1 : 0] ffout;
    reg [ff_width - 1 : 0] data;
    reg [ff_width - 1 : 0] ffinput;

    ff #(.clk_to_Q(1), .ff_width(1)) flip(ffinput, clk, reset, ffout);
    delay_element #(.d_delay(1)) de1(ffout, aAck_wire);
    delay_element #(.d_delay(1)) de2(ffout, bReq_wire);
    delay_element #(.d_delay(8)) de3(aReq, aReq_wire);

    assign #gate_delay temp1 = (~aReq_wire) && data && bAck;
    assign #gate_delay temp2 = aReq_wire && (~data) && (~bAck);
    assign #gate_delay clk_wire = temp1 || temp2;

    always @(ffout) begin
    	data = ffout;
        ffinput = ~ffout;
    end

    always @(aAck_wire) begin
    	aAck <= aAck_wire;
    end

    always @(bReq_wire) begin
    	bReq <= bReq_wire;
    end

    always @(clk_wire) begin
    	clk <= clk_wire;
    end

    always @(negedge reset) begin
    	ffinput <= 1;
    	data <= 0;
	    aAck <= 0;
	    bReq <= 0;
	    clk <= 0;
	end

    initial begin
    	ffinput <= 1;
    	data <= 0;
	    aAck <= 0;
	    bReq <= 0;
	    clk <= 0;
    end
endmodule

module delay_element(din, dout);
	input din;
	output dout;
	parameter d_delay = 1;
	assign #d_delay dout = din;
endmodule