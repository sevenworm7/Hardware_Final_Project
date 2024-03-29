module Screen (
    input rst,
    input div_2,
    input [2:0] state,
    input [0:899] map,
    input [8:0] charactor_h,
    input [8:0] charactor_v,
    input charactor_dir,
    output all_star_collect, //whether 3 stars are collected
    output reg star_countA,
    output reg star_countB,
    output reg star_countC,
    output [3:0] vgaRed,    
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,   
    output hsync,           
    output vsync       
);
    parameter INIT = 3'b000;
    parameter WAIT = 3'b001;
    parameter GAME = 3'b010;
    parameter WIN  = 3'b011;
    parameter LOSE = 3'b100;

    wire valid;
    wire [9:0] h_cnt, v_cnt; //640 480
    wire on_char,on_starA,on_starB,on_starC; //whether on charactor
    wire [11:0] pixel_char, pixel_map,pixel_starA,pixel_starB,pixel_starC;
    reg [4:0] map_h, map_v; //coordinate to map //20*15
    reg [3:0] pigeon_h, pigeon_v; //16*16
    reg [11:0] pixel;
    assign all_star_collect = star_countA & star_countB & star_countC;

    //vga control
    Vga_controller vga_controller(
        .div_2(div_2),
        .rst(rst),
        .hsync(hsync), //out
        .vsync(vsync), //out
        .valid(valid), //out
        .h_cnt(h_cnt), //out //640
        .v_cnt(v_cnt)  //out //480
    );

    //change the coordinate (h_cnt v_cnt) -> (map_h map_v pigeon_h pigeon_v)
    always @(*) map_h = (h_cnt>>5);
    always @(*) map_v = (v_cnt>>5);
    always @(*) pigeon_h = ((h_cnt>>1) - map_h*16);
    always @(*) pigeon_v = ((v_cnt>>1) - map_v*16);

    //根據座標換算之module
    Data_charactor data_charactor(
        .charactor_h(charactor_h),
        .charactor_v(charactor_v),
        .charactor_dir(charactor_dir),
        .h_cnt(h_cnt), //640 
        .v_cnt(v_cnt), //480 
        .on_char(on_char), //whether on charactor
        .pixel_char(pixel_char)
    );

    Data_star data_starA(//stars that you need to collect before reaching the door
        .star_h(1*16+7),
        .star_v(1*16+7),
        .h_cnt(h_cnt), //640 -> 320
        .v_cnt(v_cnt), //480 -> 240
        .on_star(on_starA), //whether on star
        .pixel_star(pixel_starA) 
    );
    Data_star data_starB(//stars that you need to collect before reaching the door
        .star_h(6*16+7),
        .star_v(6*16+7),
        .h_cnt(h_cnt), //640 -> 320
        .v_cnt(v_cnt), //480 -> 240
        .on_star(on_starB), //whether on star
        .pixel_star(pixel_starB) 
    );
    Data_star data_starC(//stars that you need to collect before reaching the door
        .star_h(14*16+7),
        .star_v(1*16+7),
        .h_cnt(h_cnt), //640 -> 320
        .v_cnt(v_cnt), //480 -> 240
        .on_star(on_starC), //whether on star
        .pixel_star(pixel_starC) 
    );

    Data_map data_map( 
        .map(map),
        .map_h(map_h),
        .map_v(map_v),
        .pigeon_h(pigeon_h),
        .pigeon_v(pigeon_v),
        .all_star_collect(all_star_collect),
        .pixel_map(pixel_map)
    );

    reg [5:0] disx,disy; // 計算pixel與角色之間的距離 以16*16為單位
    wire [3:0] char_distance,dis;
    always @(*) begin
        if((h_cnt>>1)>charactor_h) begin
            disx = ((h_cnt>>1)-charactor_h)>>4;
        end else begin
            disx = (charactor_h-(h_cnt>>1))>>4;
        end
    end
    always @(*) begin
        if((v_cnt>>1) > charactor_v) begin
            disy = ((v_cnt>>1)-charactor_v)>>4;
        end else begin
            disy = (charactor_v-(v_cnt>>1))>>4;
        end
    end
    
    assign char_distance = disx+disy > 7 ? 7 :disx+disy;


    //判斷pixel從哪個module拿 + 分配
    always @(*) begin
        case (state)
            INIT:begin
                pixel <= 0;
                star_countA <=0;
                star_countB <=0;
                star_countC <=0;
            end 
            WAIT: begin
                pixel <= 0;
                star_countA <=0;
                star_countB <=0;
                star_countC <=0;
            end
            GAME: begin
                if(on_char) begin
                    pixel <=pixel_char;
                    if(charactor_h >16 && charactor_h<32 && charactor_v>16 && charactor_v <32) 
                        star_countA <=1;
                    else if(charactor_h>96  && charactor_h < 112 && charactor_v >96 && charactor_v <112) 
                        star_countB <=1;
                    else if(charactor_h>224  && charactor_h < 240 && charactor_v >16 && charactor_v <32)
                        star_countC <=1;
                end
                else if(on_starA && star_countA ==0) pixel <= pixel_starA;
                else if(on_starB && star_countB ==0) pixel <= pixel_starB;
                else if(on_starC && star_countC ==0) pixel <= pixel_starC;
                else pixel <= pixel_map;
            end 
            WIN: begin
                pixel <= pixel_map;
            end
            LOSE: begin
                pixel <= pixel_map;
            end
            default: begin
                pixel <= 0;
                star_countA <=0;
                star_countB <=0;
                star_countC <=0;
            end
        endcase
    end

    wire [3:0] Redtem,Greentem,Bluetem;//vgaRed, vgaGreen, vgaBlue
    assign {Redtem,Greentem,Bluetem} = (valid ? pixel : 0);
    assign vgaRed   = (state==GAME) ? ((Redtem>2*char_distance) ? (Redtem   - 2*char_distance ) : 0) : Redtem;//離角色越遠 顏色會被設定的越暗
    assign vgaGreen = (state==GAME) ? ((Greentem>2*char_distance) ? (Greentem -2* char_distance ) : 0) : Greentem;
    assign vgaBlue  = (state==GAME) ? ((Bluetem > 2*char_distance) ? (Bluetem  - 2*char_distance) : 0) : Bluetem;

endmodule

module Vga_controller (
    input wire div_2, rst,
    output wire hsync, vsync, valid,
    output wire [9:0] h_cnt,
    output wire [9:0] v_cnt
    );

    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;

    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800; 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;

    always @(posedge div_2)
        if (rst)
            pixel_cnt <= 0;
        else
            if (pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;

    always @(posedge div_2)
        if (rst)
            hsync_i <= hsync_default;
        else
            if ((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default; 

    always @(posedge div_2)
        if (rst)
            line_cnt <= 0;
        else
            if (pixel_cnt == (HT -1))
                if (line_cnt < (VT - 1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;

    always @(posedge div_2)
        if (rst)
            vsync_i <= vsync_default; 
        else if ((line_cnt >= (VD + VF - 1)) && (line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default; 
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;
endmodule

//https://www.peko-step.com/zhtw/tool/tfcolor.html
module Data_charactor (
    input [8:0] charactor_h, //320
    input [8:0] charactor_v, //240
    input charactor_dir, //0:left, 1:right
    input [9:0] h_cnt, //640 -> 320
    input [9:0] v_cnt, //480 -> 240
    output reg on_char, //whether on charactor
    output reg [11:0] pixel_char //rgb //用hex表示剛好各一位數
);
    parameter [11:0] DATA [0:255] = { //16*16 //https://www.pinterest.com/pin/255931191311981988/
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'h09F, 12'h09F, 12'h09F, 12'h09F, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hF00, 12'hFFF, 12'hF00, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFF0, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h09F, 12'h09F, 12'h09F, 12'hFFF, 12'hFFF, 12'hFF0, 12'hFF0, 12'hFF0, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h09F, 12'h09F, 12'h000, 
        12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 
        12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'hFFF, 12'hFFF, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'h09F, 12'hFFF, 12'hFFF, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'h09F, 12'h09F, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h09F, 12'h09F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000
    }; //take 7+7*16 as center

    wire [8:0] h, v;

    assign h = h_cnt[9:1]; //320
    assign v = v_cnt[9:1]; //240

    always @(*) begin
        if((h-8 < charactor_h && charactor_h < h+9) 
        && (v-8 < charactor_v && charactor_v < v+9)) begin
            pixel_char = (charactor_dir ? 
                DATA[ (15-((h-charactor_h)+7)) + ((v-charactor_v)+7)*16 ] : 
                DATA[ ((h-charactor_h)+7) + ((v-charactor_v)+7)*16 ]);
            on_char = (pixel_char != 12'h000);
        end
        else begin
            pixel_char = 12'h000;
            on_char = 1'b0;
        end
    end

endmodule

module Data_map (
    input [0:899] map, //20*15 //(h+20*v)*3 (每格有3bit可使用)
    input [4:0] map_h, //coordinate to map //20*15
    input [4:0] map_v,
    input [3:0] pigeon_h, //16*16
    input [3:0] pigeon_v,
    input all_star_collect,
    output reg [11:0] pixel_map //rgb
);  
    parameter NONE = 3'd0;
    parameter LINE = 3'd1;
    parameter TERMINAL = 3'd2;
    parameter STAR = 3'd3;
    parameter [11:0] DATA_LINE [0:255] = { //16*16 //from up to down
        12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'hA00, 12'h800, 
        12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800, 12'h800
    };

    wire [2:0] target_pigeon, left, right, up, down;

    assign target_pigeon = {
        map[(map_h + map_v*20)*3], map[(map_h + map_v*20)*3 + 1], map[(map_h + map_v*20)*3 + 2]
    };
    assign left = {
        map[((map_h-1) + map_v*20)*3], map[((map_h-1) + map_v*20)*3 + 1], map[((map_h-1) + map_v*20)*3 + 2]
    };
    assign right = {
        map[((map_h+1) + map_v*20)*3], map[((map_h+1) + map_v*20)*3 + 1], map[((map_h+1) + map_v*20)*3 + 2]
    };
    assign up = {
        map[(map_h + (map_v-1)*20)*3], map[(map_h + (map_v-1)*20)*3 + 1], map[(map_h + (map_v-1)*20)*3 + 2]
    };
    assign down = {
        map[(map_h + (map_v+1)*20)*3], map[(map_h + (map_v+1)*20)*3 + 1], map[(map_h + (map_v+1)*20)*3 + 2]
    };

    always @(*) begin
        case (target_pigeon)
            NONE: begin
                pixel_map = 12'h000; //black
            end
            LINE: begin
                pixel_map = DATA_LINE[ pigeon_h + pigeon_v*16 ]; //red
            end
            TERMINAL: begin
                pixel_map = all_star_collect ? 12'hA0A : 12'h622; //purple/brown
            end
            default: begin
                pixel_map = 12'h000; //black 
            end
        endcase
    end

endmodule


module Data_star(
    input [8:0] star_h,
    input [8:0] star_v,
    input [9:0] h_cnt, //640 -> 320
    input [9:0] v_cnt, //480 -> 240
    output reg on_star, //whether on charactor
    output reg [11:0] pixel_star //rgb //用hex表示剛好各一位數
);
    wire [8:0] h,v;
    assign h = h_cnt[9:1]; //320
    assign v = v_cnt[9:1]; //240
    parameter [11:0] DATA [0:255] = { //16*16 //https://www.pinterest.com/pin/star-silhouette-pixel-art-in-2023--8233211825325023/
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 
        12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000
    }; //take 7+7*16 as center


    always @(*) begin
        if((h-8 < star_h && star_h < h+9) 
        && (v-8 < star_v && star_v < v+9)) begin
            pixel_star = DATA[ ((h-star_h)+8) + ((v-star_v)+8)*16 ];
            on_star = (pixel_star != 12'h000);
        end
        else begin
            pixel_star = 12'h000;
            on_star = 1'b0;
        end
    end
endmodule

module Data_trap(
    input [8:0] trap_h,
    input [8:0] trap_v,
    input [9:0] h_cnt, //640 -> 320
    input [9:0] v_cnt, //480 -> 240
    output reg on_trap, //whether on charactor
    output reg [11:0] pixel_trap //rgb //用hex表示剛好各一位數
);
    wire [8:0] h,v;
    assign h = h_cnt[9:1]; //320
    assign v = v_cnt[9:1]; //240
    parameter [11:0] DATA [0:255] = { //16*16 //https://www.pinterest.com/pin/star-silhouette-pixel-art-in-2023--8233211825325023/
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'hF00, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'hF00, 12'hF00, 12'hF00, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'hF00, 12'hF00, 12'hF00, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'hF00, 12'hF00, 12'hF00, 12'hF00, 12'hF00, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'hF00, 12'hF00, 12'hF00, 12'hF00, 12'hF00, 12'hF00, 
        12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h00F, 12'h00F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000, 12'h000, 
        12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h000, 12'h00F, 12'h00F, 12'h000
    }; //take 7+7*16 as center
endmodule