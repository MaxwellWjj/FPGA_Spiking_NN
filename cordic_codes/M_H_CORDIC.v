//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/03/03 18:19:29
// Design Name: 
// Module Name: M_H_CORDIC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: This CORDIC is referred from M. Heidarpur et al., “CORDIC-SNN: On-FPGA STDP learning with Izhikevich neurons,”
//                       IEEE Tran. Circuits and Syst. I: Reg. Papers, vol. 66, no. 7, pp. 2651 - 2661, 2019.
// 
//////////////////////////////////////////////////////////////////////////////////



module M_H_CORDIC_exp_8(
    input clk,
    input rst,
    input init,
    input signed [8 : 0] value_in,//x
    output reg signed [9 : 0] value_out,//exp(x)
    output reg done
    );

    reg [3 : 0] cnt_iterations;//n
    reg [9 : 0] mul_result;//
    reg [18: 0] mul_tmp;
    reg  [9 : 0] value_reg;
    reg  [8 : 0] list_reg;
    reg signed [8 : 0] z;
    wire signed [8 : 0] z_abs;
    reg [8 : 0] poweroftwo;

    function [8 : 0] tanangle;
    input [3 : 0] i;
    begin
        case (i)
        4'd00: tanangle = 9'd78;   
        4'd01: tanangle = 9'd100;   
        4'd02: tanangle = 9'd113;    
        4'd03: tanangle = 9'd120;    
        4'd04: tanangle = 9'd124;    
        4'd05: tanangle = 9'd126;     
        4'd06: tanangle = 9'd127;      
        4'd07: tanangle = 9'd128;      
        default:tanangle = 9'd128;
        endcase
    end
    endfunction

    always@(posedge clk) begin
        if(rst) begin
            cnt_iterations <= 0;
            value_reg <= 9'b010000000;
            value_out <= 0;
//            list_reg <= 9'b010000000;//1
            z <= 0;
            poweroftwo <= 8'b01000000; 
            done<=0;
        end
        else if(init) begin
            
            z <= value_in;
            value_reg <= 9'b010000000;    // 1
            cnt_iterations <= 0;
            poweroftwo <= 8'b01000000;  // 0.5
        end
        else
        begin
            if(cnt_iterations == 4'd8) 
                begin
                    cnt_iterations <= 0;
                    done <= 1;
                    value_out <= mul_result;
                   
                end
            else 
            begin              
                if(poweroftwo < z_abs)
                    begin
                        cnt_iterations <= cnt_iterations + 1;
                        z <= z + poweroftwo;
                      
                        value_reg <= mul_result;
                        poweroftwo <= poweroftwo >> 1;
                        done <= 0;
                    end
                else
                    begin
                        poweroftwo <= poweroftwo >> 1;
                        cnt_iterations <= cnt_iterations + 1;
                      
                        done <= 0;
                    end
            end
        end
    end

    always @ *
        begin
            list_reg = tanangle(cnt_iterations);
            mul_tmp = list_reg * value_reg;
            mul_result = mul_tmp[18:7];
        end
    assign z_abs = z[8]? ~z+1'b1:z;


endmodule
