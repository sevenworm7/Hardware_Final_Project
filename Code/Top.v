module Top (
    input clk,
    input rst,         //btn_c
    input volUP_btn,   //btn_up
    input volDOWN_btn, //btn_down
    inout wire PS2_DATA, //keyboard
    inout wire PS2_CLK,  //keyboard
    output [15:0] LED, 
    output [6:0] DISPLAY, //7 seg
    output [3:0] DIGIT,   //7 seg
    output [3:0] vgaRed,    //screen
    output [3:0] vgaGreen,  //screen
    output [3:0] vgaBlue,   //screen
    output hsync,           //screen
    output vsync,           //screen
    output audio_mclk, //voice
    output audio_lrck, //voice
    output audio_sck,  //voice
    output audio_sdin  //voice
);
    //parameter
    parameter INIT = 3'b000;
    parameter WAIT = 3'b001;
    parameter GAME = 3'b010;
    parameter WIN  = 3'b011;
    parameter LOSE = 3'b100;
    parameter [2:0] UP    = 3'd0; 
	parameter [2:0] LEFT  = 3'd1; 
	parameter [2:0] DOWN  = 3'd2; 
	parameter [2:0] RIGHT = 3'd3; 
	parameter [2:0] ENTER = 3'd4; 

    //declaration
    wire div_2, div_15, div_22, div_hsec; //半秒clk
    wire volUP, volDOWN;
    wire [2:0] key_num;
    wire key; //按鍵按下會持續為1
    wire [2:0] volume; //1~5 和 靜音0
    wire [8:0] charactor_h, charactor_v;
    wire charactor_dir; 
    wire [0:899] map; //320*240 -> 20*15 //(h+20*v)*3 (每格有3bit可使用) //跟screen同方向
    reg [3:0] three_sec_cnt;
    reg time_left_cnt;
    reg [3:0] time_left [0:2]; //time_left[2]: min //time_left[1]: sec //time_left[0]: sec
    reg [2:0] curr_hp; //max: 7
    reg [2:0] state;
    reg [15:0] num;

    //state control
    always @(posedge div_hsec) 
        three_sec_cnt <= ((state == WAIT) ? (three_sec_cnt + 1) : 1'b0);
    always @(posedge clk or posedge rst) begin
        if(rst) state <= INIT;
        else begin
            case (state)
                INIT: begin
                    if(key && (key_num == ENTER)) state <= WAIT;
                    else state <= state;
                end
                WAIT: begin
                    if(three_sec_cnt >= 6) state <= GAME;
                    else state <= state;
                end
                GAME: begin
                    if(0) state <= WIN; //do
                    else if((!time_left[0] && !time_left[1] && !time_left[2]) 
                    || (curr_hp == 1'b0)) 
                        state <= LOSE;
                    else state <= state;
                end
                WIN: begin
                    if(key && (key_num == ENTER)) state <= WAIT;
                    else state <= state;
                end
                LOSE: begin
                    if(key && (key_num == ENTER)) state <= WAIT;
                    else state <= state;
                end
                default: state <= state;
            endcase
        end
    end

    //clk div
    Clock_divider clock_divider(
        .clk(clk),
        .div_2(div_2),
        .div_15(div_15),
        .div_22(div_22),
        .div_hsec(div_hsec)
        //add more div_ behind
    );

    //button
    Button button(
        .div_15(div_15),
        .volUP_btn(volUP_btn),
        .volDOWN_btn(volDOWN_btn),
        .volUP(volUP), //after debounce + one pulse
        .volDOWN(volDOWN)
    );

    //curr_hp
    always @(posedge clk) begin
        curr_hp <= 3'd7;
    end

    //led 
    Led led(
        .rst(rst),
		.clk(clk),
        .div_hsec(div_hsec),
        .state(state),
        .curr_hp(curr_hp),
        .volume(volume), 
        .LED(LED)
    );

    //time_left control //min sec sec //2 1 0 
    always @(posedge div_hsec) time_left_cnt <= !time_left_cnt;
    always @(posedge time_left_cnt) begin
        if(state == WIN || state == LOSE) begin //維持剩餘時間
            time_left[2] <= time_left[2];
            time_left[1] <= time_left[1];
            time_left[0] <= time_left[0];
        end
        else if(state != GAME) begin //4 min 44 sec
            time_left[2] <= 4'd4;
            time_left[1] <= 4'd4;
            time_left[0] <= 4'd4;
        end
        else begin
            time_left[2] <= (((time_left[1]==1'b0) && (time_left[0]==1'b0)) ? (time_left[2]-1) : time_left[2]);
            time_left[1] <= ((time_left[0]==1'b0) ? (((time_left[1]>0) ? (time_left[1]-1) : 4'd5)) : time_left[1]);
            time_left[0] <= ((time_left[0]>0) ? (time_left[0]-1) : 4'd9);
        end
    end

    //7 segment //main for showing time_left 
    always @(posedge clk) begin
        case (state)
            INIT: begin
                num <= {4'd10, 4'd10, 4'd10, 4'd10}; //"----"
            end
            WAIT: begin
                num <= {4'd10, 4'd10, 4'd10, ((4'd7 - three_sec_cnt)>>1)};
            end
            GAME: begin
                num <= {4'd0, time_left[2], time_left[1], time_left[0]};
            end
            WIN: begin
                num <= {4'd0, time_left[2], time_left[1], time_left[0]};
            end
            LOSE: begin
                num <= {4'd10, 4'd10, 4'd10, 4'd10}; //"----"
            end
            default: num <= {4'd10, 4'd10, 4'd10, 4'd10}; //"----"
        endcase
    end
    Seven_segment seven_segment(
        .rst(rst),
		.div_15(div_15),
        .num(num), //16bits, 4 bits a group
        .DISPLAY(DISPLAY),
        .DIGIT(DIGIT)
    );

    //keyboard //使用時用 key && key_num 就好
    Keyboard keyboard(
        .rst(rst),
		.clk(clk),
        .PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
        .key_num(key_num),
        .key(key) //按鍵按下會持續為1
    );

    //map
    Map m(
        .rst(rst),
        .clk(clk),
        .state(state),
        .map(map) //20*15 //(h+20*v)*3 (每格有3bit可使用)
    );

    //charactor
    Charactor charactor(
        .rst(rst),
        .clk(clk),
        .state(state),
        .key_num(key_num),
        .key(key),
        .map(map),
        .charactor_h(charactor_h), //max for 320
        .charactor_v(charactor_v), //max for 240
        .charactor_dir(charactor_dir) //0:left, 1:right
    );

    //screen 
    Screen screen(
        .rst(rst),
		.div_2(div_2), 
        .state(state),
        .map(map),
        .charactor_h(charactor_h), //max for 320
        .charactor_v(charactor_v), //max for 240
        .charactor_dir(charactor_dir), //0:left, 1:right
        .vgaRed(vgaRed),    
        .vgaGreen(vgaGreen),  
        .vgaBlue(vgaBlue),   
        .hsync(hsync),           
        .vsync(vsync)
    );

    //voice
    Voice voice(
        .rst(rst),
        .clk(clk),
        .div_15(div_15), //音量按鈕用
        .div_22(div_22), //音樂播放速度
        .state(state),
        .volUP(volUP),
        .volDOWN(volDOWN),
        .volume(volume),
        .audio_mclk(audio_mclk), 
        .audio_lrck(audio_lrck), 
        .audio_sck(audio_sck),  
        .audio_sdin(audio_sdin)
    );

endmodule