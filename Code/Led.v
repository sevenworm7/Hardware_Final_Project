module Led (
    input rst,
	input clk,
    input div_hsec,
    input [2:0] state,
    input [2:0] curr_hp,
    input [2:0] volume,
    output reg [15:0] LED
);
    parameter INIT = 3'b000;
    parameter WAIT = 3'b001;
    parameter GAME = 3'b010;
    parameter WIN  = 3'b011;
    parameter LOSE = 3'b100;

    wire led_clk;

    assign led_clk = (((state == WAIT) || (state == LOSE)) ? div_hsec : clk);

    always @(posedge led_clk) begin
        case (state)
            INIT: begin 
                LED <= {
                    7'b1111111, 4'b0000,
                    (volume > 4), (volume > 3), (volume > 2), (volume > 1), (volume > 0)
                };
            end
            WAIT: begin 
                LED <= {
                    ((LED[15:9] == 7'b1111111) ? 7'b0000000 : 7'b1111111), 4'b0000,
                    (volume > 4), (volume > 3), (volume > 2), (volume > 1), (volume > 0)
                }; 
            end
            GAME: begin 
                LED <= {
                    (curr_hp > 0), (curr_hp > 1), (curr_hp > 1), (curr_hp > 3), 
                    (curr_hp > 4), (curr_hp > 5), (curr_hp > 6), 4'b0000,
                    (volume > 4), (volume > 3), (volume > 2), (volume > 1), (volume > 0)
                };
            end
            WIN: begin
                LED <= 16'b1111111111111111;
            end
            LOSE: begin
                LED <= 16'b0000000000000000;
            end
            default: LED <= 16'b0000000000000000;
        endcase
    end
    
endmodule