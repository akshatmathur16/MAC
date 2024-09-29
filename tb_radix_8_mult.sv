//Testbench: Multiply Accumulator block (MAC)
//Author: 2023EEN2223 AKshat Mathur

//Radix 8 Booth multiplier used
//as per spec input = 16 bit 
//output = 27 bits
//Refer to reg mult to check multiplication output
//Refer to wire out to check for final truncated output
//
module tb_radix_8_mult();

parameter N=5;

bit clk, rst;
bit signed [16-1:0] A;
bit signed [16-1:0] B; //A = multiplier, B=multiplicand
bit signed [26:0] out;

localparam o_SF = 2.0**-11.0;
localparam i_SF = 2.0**-12.0;

radix_8_mult #(.N(N)) inst_radix_8_mult 
(
    .clk(clk),
    .rst(rst),
    .A(A),
    .B(B), //A = multiplier, B=multiplicand
    //.mult(mult)
    .out(out)
);

bit signed [32:0] mult_rtl;
assign mult_rtl =  inst_radix_8_mult.mult;

initial begin

    
    rst = 1;
    //CORRECT
    #10 rst=0; A='d12; B='d34;
    #31 rst=0; A='d78; B='d56;
    #31 rst=0; A='d118; B='h228;
    
    for(int i=0; i<255; i++)
    begin
        rst=0; A={1'b0,$urandom_range(10,255)}; B={1'b0,$urandom_range(10,255)};
        #31 rst=0; A={1'b0,$urandom_range(10,255)}; B={1'b0, $urandom_range(10,255)};
        #31;
    end

    
    //-ve numbers - correct
    $display($time, "#AM Launching -ve Numbers");
    for(int i=0; i<5; i++)
    begin
        rst=0; A=$urandom_range(512, 256); B=$urandom_range(-1024, -512);
        //#31 rst=0; A=$urandom_range(-788, -255); B=$urandom_range(-788, -255);
        #31;
    end

    

    // trailing bits - CORRECT
    $display($time, "#AM Launching trailing bits");
    for(int i=0; i<5; i++)
    begin
        rst=0; A='hA0A0; B='h0A0A;
        #31 rst=0; A='hFFFF; B='h1111;
        #31;
    end


    ////16 bits - CORRECT
    for(int i=0; i<5; i++)
    begin
        $display($time, "#AM Launching 16 bits");
        rst=0; A=$urandom_range('h1111, 'hBBBB); B=$urandom_range('h2222, 'h5555);
        #31 rst=0; A=$urandom_range('hBBBBB, 'hEEEE); B=$urandom_range('h7777, 'h9999);
        #31;
    end

    $display($time, "#AM launching fractional values");
    `define FRAC
      for(int i=0; i<5; i++)
      begin
          rst=0; A=16'b0000_0000_0111_1101; B=16'b0000_0000_0111_1010; // a*b * 2^-24 = mult 
          #31 rst=0; A=16'b0000_0000_0001_1100; B=16'b0000_0000_0110_1100;
          #31;
      end

      rst =1;


end

initial
begin
    `ifdef FRAC
        $monitor($time, "A=%f B=%f,  mult = %f, accumulator = %f, out = %f",$itor(A*i_SF),$itor(B*i_SF),$itor(mult_rtl*i_SF*i_SF), $itor(inst_radix_8_mult.out_reg*i_SF*i_SF), $itor(out*o_SF));
    `else

        $monitor($time, "A=%d B=%d,  mult = %d, accumulator = %d, out = %d",A,B,inst_radix_8_mult.mult, inst_radix_8_mult.out_reg, out);
    `endif
end

initial
    #10000 $stop;

//clock generator
always
    #3.33 clk=~clk;

endmodule

