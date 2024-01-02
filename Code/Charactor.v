module Charactor (
    input rst,
    input clk,
    input key_num,
    input key,
    output  [19:0] charactor_posi
);
    wire left,right,up,down;
    path_check p1(clk,rst,charactor_posi,left,right,up,down);
    always @(*) begin
        
    end
endmodule

module path_check( // check if 4 directions are paths that the character can walk through
    input clk,
    input rst,
    input  [19:0] charactor_posi,
    output left,
    output right,
    output up,
    output down
);
    always @(*) begin
         
    end



endmodule