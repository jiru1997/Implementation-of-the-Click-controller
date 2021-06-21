`timescale 1ns/1ps

module celement (a, b, c);
  parameter delay = 0;
  parameter ff_width = 1;
  input [ff_width - 1:0] a;
  input [ff_width - 1:0] b;
  output reg [ff_width - 1:0] c;

  always @ (a or b) begin
      if(a == 1 && b == 1) begin
        c <= 1;
      end
      else if(a == 0 && b == 0) begin
        c <= 0;
      end
      else begin
        c <= c;
      end
  end

  initial begin
      c <= 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module ff(d, clk, reset, q);
  parameter clk_to_Q = 3;
  parameter ff_width = 12;

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

//-----------------------------------------------------------------------------------------
module clickcontrol(reset, aReq, bAck, aAck, bReq, clk);

  parameter ff_width = 1;
  parameter gate_delay = 0;
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
  delay_element #(.d_delay(1)) de3(aReq, aReq_wire);

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

//-----------------------------------------------------------------------------------------
module delay_element(din, dout);
  input din;
  output dout;
  parameter d_delay = 1;
  assign #d_delay dout = din;
endmodule

//-----------------------------------------------------------------------------------------
module shift (data_in, data_out);
  parameter WIDTH = 12;

  input [WIDTH-1 : 0] data_in;
  output reg [WIDTH-1 : 0] data_out;

  reg [WIDTH-1 : 0] temp;

  always begin
    # 2;
    data_out = {data_in[WIDTH-2 : 0], temp[WIDTH-1]}; 
  end

  initial begin
    data_out <= 0;
    temp <= 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module upperbranch (data_in, reset, aReq, bAck, aAck, bReq, data_out);
  parameter WIDTH = 12;
  parameter ff_width = 1;
  parameter DELAY = 10;
  input reset;
  input aReq;
  input bAck;
  input [WIDTH - 1 : 0] data_in;
  output reg [WIDTH - 1 : 0] data_out;
  output reg [ff_width - 1 : 0] aAck;
  output reg [ff_width - 1 : 0] bReq;
  
  wire clk, aAck_wire, bReq_wire, data_read_wire;
  wire [WIDTH - 1 : 0] data_read;
  wire [WIDTH - 1 : 0] data_temp1;
  wire [WIDTH - 1 : 0] data_temp2;
  wire [WIDTH - 1 : 0] data_temp3;
  reg [ff_width - 1 : 0] bAckinput;

  clickcontrol cl(reset, aReq, bAckinput, aAck_wire, bReq_wire, clk);
  ff flipflop(data_in, clk, reset, data_read);

  shift sh1(data_read, data_temp1);
  shift sh2(data_temp1, data_temp2);
  shift sh3(data_temp2, data_temp3);

  always @(bAck) begin
    bAckinput <= bAck;
  end

  always @(data_temp3) begin
    data_out = data_temp3;
  end

  always @(aAck_wire) begin
    #DELAY;
    aAck <= aAck_wire;
  end

  always @(bReq_wire) begin
    #DELAY;
    bReq = bReq_wire;
  end

  always @(negedge reset) begin
    aAck <= 0;
    bReq <= 0;
    data_out <= 0;
    bAckinput <= 0;
  end
  
  initial begin
    aAck <= 0;
    bReq <= 0;
    data_out <= 0;
    bAckinput <= 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module lowerbranch (data_in, reset, aReq, bAck, aAck, bReq, data_out);
  parameter WIDTH = 12;
  parameter DELAY = 3;
  parameter ff_width = 1;
  input reset;
  input aReq;
  input bAck;
  input [WIDTH - 1 : 0] data_in;
  output reg [WIDTH - 1 : 0] data_out;
  output reg [ff_width - 1 : 0] aAck;
  output reg [ff_width - 1 : 0] bReq;
  
  wire clk, aAck_wire, bReq_wire;
  wire [WIDTH - 1 : 0] data_read;
  wire [WIDTH - 1 : 0] data_temp1;
  reg [ff_width - 1 : 0] bAckinput;

  clickcontrol cl(reset, aReq, bAckinput, aAck_wire, bReq_wire, clk);
  ff flipflop(data_in, clk, reset, data_read);

  shift sh1(data_read, data_temp1);

  always @(data_temp1) begin
    data_out = data_temp1;
  end

  always @(bAck) begin
    bAckinput <= bAck;
  end

  always @(aAck_wire) begin
    #DELAY;
    aAck <= aAck_wire;
  end

  always @(bReq_wire) begin
    #DELAY;
    bReq <= bReq_wire;
  end

  always @(negedge reset) begin
    aAck <= 0;
    bReq <= 0;
    data_out <= 0;
    bAckinput <= 0;
  end
  
  initial begin
    aAck <= 0;
    bReq <= 0;
    data_out <= 0;
    bAckinput <= 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module subtractor (a1Req, a2Req, data_in1, data_in2, bAck, reset, bReq, data_out, colAck, random_delay_time);
  parameter WIDTH = 12;
  parameter ff_width = 1;
  input a1Req;
  input a2Req;
  input [WIDTH - 1 : 0] data_in1;
  input [WIDTH - 1 : 0] data_in2;
  input bAck;
  input reset;
  input random_delay_time;
  output reg [WIDTH - 1 : 0] data_out;
  output reg [ff_width - 1 : 0] colAck;
  output reg [ff_width - 1 : 0] bReq;

  wire clk, colAck_wire, bReq_wire;
  wire [WIDTH - 1 : 0] data_read1;
  wire [WIDTH - 1 : 0] data_read2;
  wire [ff_width - 1 : 0] data_ready_wire;
  reg [ff_width - 1 : 0] data_ready;
  reg [ff_width - 1 : 0] bAckinput;

  celement c(a1Req, a2Req, data_ready_wire);
  clickcontrol cl(reset, data_ready, bAckinput, colAck_wire, bReq_wire, clk);
  ff flipflop1(data_in1, clk, reset, data_read1);
  ff flipflop2(data_in2, clk, reset, data_read2);

  always @(data_ready_wire) begin
    data_ready = data_ready_wire;
  end

  always @(bAck) begin
    bAckinput <= bAck;
  end

  always @(data_read1 or data_read2) begin
    #random_delay_time
    data_out <= data_read1 - data_read2;
  end

  always @(colAck_wire) begin
    colAck <= colAck_wire;
  end

  always @(bReq_wire) begin
    bReq <= bReq_wire;
  end

  always @(negedge reset) begin
    colAck <= 0;
    bReq <= 0;
    data_out <= 0;
    bAckinput <= 0;
    data_ready <= 0;
  end
  
  initial begin
    colAck <= 0;
    bReq <= 0;
    data_out <= 0;
    bAckinput <= 0;
    data_ready <= 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module data_bucket (data_in, reset, aReq, aAck, data_out);
  parameter WIDTH = 12;
  parameter ff_width = 1;
  input reset;
  input aReq;
  input [WIDTH - 1 : 0] data_in;
  output reg [WIDTH - 1 : 0] data_out;
  output reg [ff_width - 1 : 0] aAck;
  
  always @(posedge aReq or negedge aReq) begin
    data_out = data_in;
    if(data_out != 0) begin
      $display("current result is %d", data_out);
    end
    aAck <= aReq;
  end

  always @(negedge reset) begin
    aAck <= 0;
    data_out <= 0;
  end

  initial begin
    aAck <= 0;
    data_out <= 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module copy (aReq, data_in, reset, b1Ack, b2Ack, aAck, bReq, data_out);
  parameter WIDTH = 12;
  parameter DELAY = 0;
  parameter ff_width = 1;
  input reset;
  input aReq;
  input b1Ack;
  input b2Ack;
  input [WIDTH - 1 : 0] data_in;
  output reg [WIDTH - 1 : 0] data_out;
  output reg [ff_width - 1 : 0] aAck;
  output reg [ff_width - 1 : 0] bReq;
  
  wire clk, totAck_wire, aAck_wire, bReq_wire;
  wire [WIDTH - 1 : 0] data_wire;
  reg [ff_width - 1 : 0] totAck;

  celement c(b1Ack, b2Ack, totAck_wire);
  clickcontrol cl(reset, aReq, totAck, aAck_wire, bReq_wire, clk);
  ff flipflop(data_in, clk, reset, data_wire);

  always @(totAck_wire) begin
    totAck <= totAck_wire;
  end

  always @(data_wire) begin
    data_out <= data_wire;
  end

  always @(aAck_wire) begin
    #DELAY;
    aAck <= aAck_wire;
  end

  always @(bReq_wire) begin
    #DELAY;
    bReq <= bReq_wire;
  end

  always @(negedge reset) begin
    aAck <= 0;
    bReq <= 0;
    data_out <= 0;
    totAck = 0;
  end
  
  initial begin
    aAck <= 0;
    bReq <= 0;
    data_out <= 0;
    totAck = 0;
  end
endmodule

//-----------------------------------------------------------------------------------------
module data_generator (reset, bAck, bReq, data_out);
  parameter WIDTH = 12;
  parameter DELAY = 4;
  parameter ff_width = 1;
  input reset;
  input bAck;
  output reg [WIDTH - 1 : 0] data_out;
  output reg [ff_width - 1 : 0] bReq;

  reg [7:0] data_out1;
  reg [ff_width - 1 : 0] req;

  always @(posedge bAck or negedge bAck) begin 
    #DELAY;
    data_out1 = $random() % (2**8); 
    data_out = data_out1;
    $display("current data is %d", data_out1);
    req = ~ req;
    bReq = req;
  end

  always @(negedge reset) begin
    req = 1;
    bReq = req;
    data_out1 = $random() % (2**8); 
    $display("After reset new data is %d", data_out1);
    data_out = data_out1;
  end

  initial begin
    req = 1;
    bReq = req;
    data_out1 = $random() % (2**8); 
    $display("current data is %d", data_out1);
    data_out = data_out1;
  end
endmodule
