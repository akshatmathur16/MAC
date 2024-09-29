//Multiply Accumulator block (MAC)
//Author: 2023EEN2223 AKshat Mathur

//Radix 8 Booth multiplier used
//as per spec input = 16 bit 
//output = 27 bits
//Refer to reg mult to check multiplication output
//Refer to wire out to check for final truncated output
//



`define synth 1

module radix_8_mult #(parameter N=5)
(
    input bit clk, rst,
    input bit signed [16-1:0] A, // as per spec 16 bit Inputs
    input bit signed [16-1:0] B, //A = multiplier, B=multiplicand
    output bit signed [26:0] out // as per spec truncated bits = 26 bits
);

bit signed [16:0] temp_A; // A concat with Q0
bit signed [17:0] temp_B; // B extened to 2 sign bits
bit signed [3:0]op_code[5:0]; // memory to hold op codes extracted from  temp_A
bit signed [17:0] pp_mem[5:0]; // memory to hold partial products calcualted through op codes
bit signed [32:0] mult; //  multiplication output
bit signed [32:0] mult_d; // delayed mult reg
bit signed [39:0] out_reg; // Accumulator register 
bit [8:0] count; // count upto 0-256
bit signed [26:0] out_temp; // as per spec truncated bits = 26 bits

//bit signed [31:0] out_am; 

//flags to prevent the IDLE cycle test scenario
assign flag = A^temp_A || B^temp_B ? 1'b1:1'b0;
assign flag_pp = op_code[0] ^ temp_A[3:0] || op_code[1]^temp_A[6:3] || op_code[2] ^ temp_A[9:6] || op_code[3] ^temp_A[12:9] || op_code[4] ^ temp_A[15:12] || op_code[5] ^ {{3{temp_A[16]}},temp_A[15]} ? 1'b0: 1'b1;


// assigning truncated output
assign out_temp = (mult_d !=mult) ? {out_reg[39],out_reg[39:14]}: out_temp;
//assigning final rounded off output
assign out = (mult_d !=mult) ? {out_temp,1'b0}: out; // left shift by 1 => mult by 2

//assign out_am = A*B;


//assigning the accoumulator value while maintaining a counter of 256 at accumulator
always@(mult)
begin
    if(~rst)
    begin
        if(count == 256)
        begin
            out_reg = 'b0; 
            count = 'b0;
            //count will rollover to 0 here
        end
        else
        begin
            if(mult_d != mult)
            begin
                out_reg = out_reg + mult;
                count = count+1;
            end
            else
            begin
                out_reg = out_reg;
            end
        end
    end
    else // resetting Accumulator and counter on reset
    begin
        out_reg = 'b0;
        count = 'b0;
    end
end
           
always @(posedge clk)
begin
    if(rst)
    begin
        mult<='b0;
        temp_A <= 'b0;
        temp_B <= 'b0;
        mult_d <= 'b0;
        //out_reg <= 'b0;
    end

    else
    begin
        // Bit padding of A, B as per ALgorithm
        temp_A <= {A,1'b0};
        temp_B <={{2{B[15]}},B};

        if(flag)
        begin
            //op_code generator
            op_code[0] <= temp_A[3:0];
            op_code[1] <= temp_A[6:3];
            op_code[2] <= temp_A[9:6];
            op_code[3] <= temp_A[12:9];
            op_code[4] <= temp_A[15:12];
            op_code[5] <= {{3{temp_A[16]}},temp_A[15]};
        end

        `ifndef synth
            for(int i=0;i<6;i++)
            begin
                $display($time,"pp_mem[%d]=%b",i,pp_mem[i]);
            end
        `endif

        if(flag_pp)
        begin
            //PP generator
            for(int i=0; i<6; i++)
            begin
                case(op_code[i])
                    4'b0001, 4'b0010: pp_mem[i] <= temp_B;  // +1a
                    4'b0011, 4'b0100: pp_mem[i] <= 2*temp_B;  // +2a
                    4'b0101, 4'b0110: pp_mem[i] <= 3*temp_B;  // +3a
                    4'b0111:          pp_mem[i] <= 4*temp_B;  // +4a
                    4'b1000:          pp_mem[i] <= ~(4*temp_B)+1;  // -4a
                    4'b1001, 4'b1010: pp_mem[i] <= ~(3*temp_B)+1;  // -3a
                    4'b1011, 4'b1100: pp_mem[i] <= ~(2*temp_B)+1;  // -2a
                    4'b1101, 4'b1110: pp_mem[i] <= ~(temp_B)+1;  // -1a
                    default:          pp_mem[i] <= 'b0; //0 
                endcase
                //$display($time,"AKSHAT pp_mem[%d]=%d",i,pp_mem[i]);
            end


            // Adding Partial products to form mult 
            mult <= {{(33-18-0){pp_mem[0][17]}}, pp_mem[0]} + {{(33-18-3){pp_mem[1][17]}}, pp_mem[1], 3'b0}
            + {{(33-18-6){pp_mem[2][17]}}, pp_mem[2], 6'b0}
            + {{(33-18-9){pp_mem[3][17]}}, pp_mem[3], 9'b0}
            + {{(33-18-12){pp_mem[4][17]}}, pp_mem[4], 12'b0}
            + {{(33-18-15){pp_mem[5][17]}}, pp_mem[5], 15'b0};

            mult_d <= mult;

        end

    end

end

endmodule
