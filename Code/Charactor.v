module Charactor (
    input rst,
    input clk,
    input [2:0] state,
    input [2:0] key_num,
    input key,
    input [0:899] map, //20*15 //(h+20*v)*3 (每格有3bit可使用)
    output reg [8:0] charactor_h, //max for 320
    output reg [8:0] charactor_v, //max for 240
    output reg charactor_dir //0:left, 1:right
);  
    parameter INIT = 3'b000;
    parameter WAIT = 3'b001;
    parameter GAME = 3'b010;
    parameter WIN  = 3'b011;
    parameter LOSE = 3'b100;

    parameter [2:0] UP    = 3'd0; //correspond to key_num
	parameter [2:0] LEFT  = 3'd1; 
	parameter [2:0] DOWN  = 3'd2; 
	parameter [2:0] RIGHT = 3'd3; 

    parameter NONE = 3'd0;
    parameter LINE = 3'd1;
    parameter TERMINAL = 3'd2;

    parameter MAX_CNT = 32'd3000000; //for charactor speed //越小速度越快

    reg [2:0] target_key;
    reg [31:0] cnt;
    reg [8:0] nxt_charactor_h, nxt_charactor_v;
    reg [4:0] nxt_map_h, nxt_map_v;
    
    //speed control
    always @(posedge clk) begin
        if(key && (cnt == 1'b0)) target_key <= key_num;
        else target_key <= target_key;
    end
    always @(posedge clk) begin
        if(key && ((cnt == 1'b0) || (target_key == key_num))) 
            cnt <= ((cnt < MAX_CNT) ? (cnt + 1'b1) : 1'b0);
        else cnt <= 1'b0;
    end

    //nxt_charactor_h nxt_charactor_v 
    always @(*) begin
        case (target_key)
            UP: begin
                nxt_charactor_h <= charactor_h;
                nxt_charactor_v <= charactor_v - 1;
            end
            LEFT: begin
                nxt_charactor_h <= charactor_h - 1;
                nxt_charactor_v <= charactor_v;
            end
            DOWN: begin
                nxt_charactor_h <= charactor_h;
                nxt_charactor_v <= charactor_v + 1;
            end
            RIGHT: begin
                nxt_charactor_h <= charactor_h + 1;
                nxt_charactor_v <= charactor_v;
            end
            default: begin
                nxt_charactor_h <= charactor_h;
                nxt_charactor_v <= charactor_v;
            end
        endcase
    end
    
    //calculate charactor nxt pigeon in map //只能在(cnt == MAX_CNT)時取值
    always @(posedge clk) begin
        if(cnt == 1'b0) nxt_map_h <= 1'b0;
        else if(((nxt_map_h + 1) * 16) < nxt_charactor_h) 
            nxt_map_h <= nxt_map_h + 1'b1;
        else nxt_map_h <= nxt_map_h;
    end
    always @(posedge clk) begin
        if(cnt == 1'b0) nxt_map_v <= 1'b0;
        else if(((nxt_map_v + 1) * 16) < nxt_charactor_v) 
            nxt_map_v <= nxt_map_v + 1'b1;
        else nxt_map_v <= nxt_map_v;
    end

    //charactor move
    always @(posedge clk) begin
        case (state)
            INIT: begin
                charactor_h <= 4*16 + 8;
                charactor_v <= 4*16 + 8;
            end
            WAIT: begin
                charactor_h <= 4*16 + 8;
                charactor_v <= 4*16 + 8;
            end
            GAME: begin
                if((cnt == MAX_CNT) && ( 
                    {map[(nxt_map_h + nxt_map_v*20)*3], 
                    map[(nxt_map_h + nxt_map_v*20)*3 + 1], 
                    map[(nxt_map_h + nxt_map_v*20)*3 + 2]} != NONE
                )) begin 
                    charactor_h <= nxt_charactor_h;
                    charactor_v <= nxt_charactor_v;
                end
                else begin
                    charactor_h <= charactor_h;
                    charactor_v <= charactor_v;
                end
            end
            WIN: begin
                charactor_h <= charactor_h;
                charactor_v <= charactor_v;
            end
            LOSE: begin
                charactor_h <= charactor_h;
                charactor_v <= charactor_v;
            end 
            default: begin
                charactor_h <= charactor_h;
                charactor_v <= charactor_v;
            end
        endcase
    end

    //direction control
    always @(*) begin
        case (target_key)
            UP:      charactor_dir = 1'b0;
            LEFT:    charactor_dir = 1'b0;
            DOWN:    charactor_dir = 1'b1;
            RIGHT:   charactor_dir = 1'b1;
            default: charactor_dir = charactor_dir;
        endcase
    end
    
endmodule