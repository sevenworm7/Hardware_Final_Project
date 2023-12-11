//Code盡量寫簡潔一點，一方面方便看，一方面減少記憶體消耗之類
/*
整體流程:
    state == INIT: (按enter後等3秒進入GAME state)
        led: 全暗，等三秒時每秒: 全亮->全暗
        screen: 顯示press start之類?? (遊戲比較偏黑暗風，配色以紅黑為主?)，等三秒時全黑?
        7_seg: 顯示 "----"，等三秒時顯示3->2->1
        voice: 播放主題曲，可以考慮雙耳都播鋼琴右手，進遊戲在切成雙耳不同旋律，等三秒時把音樂關掉
    state == GAME:
        led: 顯示角色血量，初始7點
        screen: 
            地圖:
                開個陣列之類存簡化版地圖，後用一小段線條重複複製貼上來做迷宮
                沿著線走的迷宮應該就可以了(可能黑底走紅線之類?隨意)(垂直跟水平線就好)
                先將遊戲控制在一個螢幕的畫面就好
                只要顯示角色四周一定範圍的地圖就好，旁邊慢慢變黑之類?
                先把地圖架構弄出來就好，其他東西可以之後再弄
            角色:
                我覺得現在先做單張圖的就好，要做任何換圖的之後再弄比較好
                那兩張圖要裁背景感覺挺難，可以考慮弄個圓形大頭貼之類(picture有放試圖)
                應該用上下左右操控就好(所以地圖用直線橫線就好)
                備案: 圖片可以考慮一顆頭就好(看上看下看左看右之類)(找外部圖丟進去用)
        7_seg: 顯示倒數計時
        voice: 從頭播放主題曲，音效可以之後再弄
*/

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
    parameter INIT = 1'b0;
    parameter GAME = 1'b1;

    //declaration
    wire div_2, div_15, div_hsec; //半秒clk
    wire volUP, volDOWN;
    wire [15:0] num;
    wire [2:0] key_num;
    wire key; //been_ready && key_down[last_change] == 1'b1
    reg [3:0] time_left [0:2]; //time_left[2]: min //time_left[1]: sec //time_left[0]: sec
    reg [2:0] curr_hp; //max: 7
    reg state; //0:wait to start, 1:play
    reg [2:0] map [0:300]; //320*240 -> 20*15 //h+20*v //跟screen同方向

    //state control
    always @(posedge clk or posedge rst) begin
        if(rst) state <= INIT;
        else begin
            case (state)
                INIT: begin
                    //do
                end
                GAME: begin
                    //do
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

    //led 
    Led led(
        .rst(rst),
		.clk(clk),
        .div_hsec(div_hsec),
        .state(state),
        .curr_hp(curr_hp), //showing hp by led
        .LED(LED)
    );

    //7 segment //main for showing time_left 
    assign num = {4'd0, time_left[2], time_left[1], time_left[0]};
    Seven_segment seven_segment(
        .rst(rst),
		.div_15(div_15),
        .div_hsec(div_hsec), 
        .state(state),
        .num(num), //16bits, 4 bits a group
        .DISPLAY(DISPLAY),
        .DIGIT(DISPLAY)
    );

    //keyboard
    Keyboard keyboard(
        .rst(rst),
		.clk(clk),
        .PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
        .key_num(key_num),
        .key(key) //been_ready && key_down[last_change] == 1'b1
    );

    //map
    /*
    map有個問題就是如果使用陣列會無法當變數丟到其他module?
    我目前是考慮把map直接寫在top裡，screen或是charactor要使用map時再用局部的方式傳資訊
    */
    //output: map char_movable?

    //charactor
    /*
    角色移動前要設計一個預計移動點的參數，把它丟到map裡確定可否移動後再移動角色
    角色可以先考慮一張圖就好，之後要做變化時再把變化資訊丟給screen
    */
    Charactor charactor(
        .rst(rst),
        .clk(clk),
        .key_num(key_num),
        .key(key),
        .charactor_posi(charactor_posi)
    );

    //screen 
    /*
    這邊我考慮把screen裡面正在掃描的點當ouput送到top，再用一個always block把
    map跟charactor的資訊整理成一個參數丟到screen裡，screen再根據那個參數判斷顯示什麼??
    另外有個問題，角色在Screen的移動要精細點，不能照map做很粗略的螢幕切割。。。怎處理?
    */
    Screen screen(
        .rst(rst),
		.div_2(div_2), 
        .state(state),
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
        .div_22(div_22), //一拍16個posedge
        .state(state),
        .audio_mclk(audio_mclk), 
        .audio_lrck(audio_lrck), 
        .audio_sck(audio_sck),  
        .audio_sdin(audio_sdin)
    );

endmodule