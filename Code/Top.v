module Top (
    input clk,
    input rst,
    input volUP_btn,
    input volDOWN_btn,
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

    //declaration
    wire div_2, div_15; //for screen //for 7-seg, btn 
    wire volUP, volDOWN;
    reg [15:0] num;

    //clk div
    Clock_divider clock_divider(
        .clk(clk),
        .div_2(div_2),
        .div_15(div_15)
        //add more clk_div behind
    );

    //button
    Button button(
        .div_15(div_15), //not origin clk
        .volUP_btn(volUP_btn),
        .volDOWN_btn(volDOWN_btn),
        .volUP(volUP), //after debounce + one pulse
        .volDOWN(volDOWN)
    );

    //led
    Led led(
        .rst(rst),
		.clk(clk),
        .led(LED)
    );

    //7 segment
    Seven_segment seven_segment(
        .rst(rst),
		.div_15(div_15), //not origin clk
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

    //screen
    Screen screen(
        .rst(rst),
		.div_2(div_2), //not origin clk
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
        .audio_mclk(audio_mclk), 
        .audio_lrck(audio_lrck), 
        .audio_sck(audio_sck),  
        .audio_sdin(audio_sdin)
    );

endmodule