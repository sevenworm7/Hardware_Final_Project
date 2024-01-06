`define sil 32'd50000000 

module Voice (
    input rst,
    input clk,
    input div_15,
    input div_22, //may have to change
    input [2:0] state,
    input volUP,
    input volDOWN,
    input sound_effect, //音效 //拉起一個clk posedge後播放
    output reg [2:0] volume,
    output audio_mclk, 
    output audio_lrck, 
    output audio_sck,  
    output audio_sdin 
);
    //declaration
    wire [11:0] ibeat, ibeat_s;
    wire [31:0] toneL, toneR, toneL_s;
    wire [21:0] note_div_left, note_div_right;
    wire [15:0] audio_in_left, audio_in_right;

    //volume control
    always @(posedge div_15 or posedge rst) begin
        if(rst) volume <= 3'd2;
        else if(volUP) volume <= ((volume < 3'd5) ? (volume + 1) : volume);
        else if(volDOWN) volume <= ((volume > 3'd0) ? (volume - 1) : volume);
        else volume <= volume;
    end

    //Player Control
    Player_control player_control( 
        .clk(clk),
        .div_22(div_22),
        .rst(rst),
        .state(state),
        .sound_effect(sound_effect),
        .ibeat(ibeat),    //output
        .ibeat_s(ibeat_s) //output
    );

    //Music module
    Music music(
        .ibeat(ibeat),
        .toneL(toneL), //output
        .toneR(toneR) //output
    );

    //Sound effect
    Sound_effect se(
        .ibeat_s(ibeat_s),
        .toneL_s(toneL_s) //output //切掉鋼琴左手
    );

    //Note generation
    assign note_div_left = ((ibeat_s != 0) ? (50000000 / toneL_s) : (50000000 / toneL));
    assign note_div_right = (50000000 / toneR);
    Note_gen note_gen(
        .clk(clk), 
        .rst(rst), 
        .volume(volume),
        .note_div_left(note_div_left), 
        .note_div_right(note_div_right), 
        .audio_left(audio_in_left),     // left sound audio  //output
        .audio_right(audio_in_right)    // right sound audio //output
    );

    // Speaker controller
    Speaker_control speaker_control(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );
endmodule

module Player_control (
    input clk,
	input div_22, 
	input rst, 
	input [2:0] state, 
    input sound_effect,
	output reg [11:0] ibeat,
    output reg [11:0] ibeat_s
);
    parameter INIT = 3'b000;
    parameter WAIT = 3'b001;
    parameter GAME = 3'b010;
    parameter WIN  = 3'b011;
    parameter LOSE = 3'b100;

	parameter LEN = 864; //16 * 3 * 18
    parameter LEN_s = 64; //16 * 4 * 1

    reg mode;

	always @(posedge div_22 or posedge rst) begin
        if(rst) ibeat <= 0;
        else begin
            case (state)
                INIT: ibeat <= ((ibeat < LEN) ? (ibeat + 1) : 0);
                WAIT: ibeat <= 0;
                GAME: ibeat <= ((ibeat < LEN) ? (ibeat + 1) : 0);
                WIN: ibeat <= 0;
                LOSE: ibeat <= 0;
                default: ibeat <= ibeat;
            endcase
        end
	end

    //sound effect control
    always @(posedge clk) begin
        if(sound_effect) mode <= 1'b1;
        else if(ibeat_s != 0) mode <= 1'b0;
        else mode <= mode;
    end
    always @(posedge div_22 or posedge rst) begin
        if(rst) ibeat_s <= 0;
        else if(mode) ibeat_s <= 1;
        else if(ibeat_s != 0) ibeat_s <= ((ibeat_s < LEN_s) ? (ibeat_s + 1) : 0);
        else ibeat_s <= 0;
    end

endmodule

module Music(
	input [11:0] ibeat,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);
    always @* begin
        case(ibeat)
            //1 1
            12'd0   : toneR =    `sil;  12'd1   : toneR =    `sil;
            12'd2   : toneR =    `sil;  12'd3   : toneR =    `sil;
            12'd4   : toneR =    `sil;  12'd5   : toneR =    `sil;
            12'd6   : toneR =    `sil;  12'd7   : toneR =    `sil;
            12'd8   : toneR =    `sil;  12'd9   : toneR =    `sil;
            12'd10  : toneR =    `sil;  12'd11  : toneR =    `sil;
            12'd12  : toneR =    `sil;  12'd13  : toneR =    `sil;
            12'd14  : toneR =    `sil;  12'd15  : toneR =    `sil;
            //1 2
            12'd16  : toneR = 32'd440;  12'd17  : toneR = 32'd440;
            12'd18  : toneR = 32'd440;  12'd19  : toneR = 32'd440;
            12'd20  : toneR = 32'd440;  12'd21  : toneR = 32'd440;
            12'd22  : toneR = 32'd440;  12'd23  : toneR =    `sil;
            12'd24  : toneR = 32'd494;  12'd25  : toneR = 32'd494;
            12'd26  : toneR = 32'd494;  12'd27  : toneR = 32'd494;
            12'd28  : toneR = 32'd494;  12'd29  : toneR = 32'd494;
            12'd30  : toneR = 32'd494;  12'd31  : toneR =    `sil;
            //1 3
            12'd32  : toneR = 32'd523;  12'd33  : toneR = 32'd523;
            12'd34  : toneR = 32'd523;  12'd35  : toneR = 32'd523;
            12'd36  : toneR = 32'd523;  12'd37  : toneR = 32'd523;
            12'd38  : toneR = 32'd523;  12'd39  : toneR =    `sil;
            12'd40  : toneR = 32'd587;  12'd41  : toneR = 32'd587;
            12'd42  : toneR = 32'd587;  12'd43  : toneR = 32'd587;
            12'd44  : toneR = 32'd587;  12'd45  : toneR = 32'd587;
            12'd46  : toneR = 32'd587;  12'd47  : toneR =    `sil;
            //2 1
            12'd48  : toneR = 32'd659;  12'd49  : toneR = 32'd659;
            12'd50  : toneR = 32'd659;  12'd51  : toneR = 32'd659;
            12'd52  : toneR = 32'd659;  12'd53  : toneR = 32'd659;
            12'd54  : toneR = 32'd659;  12'd55  : toneR = 32'd659;
            12'd56  : toneR = 32'd659;  12'd57  : toneR = 32'd659;
            12'd58  : toneR = 32'd659;  12'd59  : toneR = 32'd659;
            12'd60  : toneR = 32'd659;  12'd61  : toneR = 32'd659;
            12'd62  : toneR = 32'd659;  12'd63  : toneR =    `sil;
            //2 2
            12'd64  : toneR = 32'd415;  12'd65  : toneR = 32'd415;
            12'd66  : toneR = 32'd415;  12'd67  : toneR = 32'd415;
            12'd68  : toneR = 32'd415;  12'd69  : toneR = 32'd415;
            12'd70  : toneR = 32'd415;  12'd71  : toneR =    `sil;
            12'd72  : toneR = 32'd494;  12'd73  : toneR = 32'd494;
            12'd74  : toneR = 32'd494;  12'd75  : toneR = 32'd494;
            12'd76  : toneR = 32'd494;  12'd77  : toneR = 32'd494;
            12'd78  : toneR = 32'd494;  12'd79  : toneR =    `sil;
            //2 3
            12'd80  : toneR = 32'd659;  12'd81  : toneR = 32'd659;
            12'd82  : toneR = 32'd659;  12'd83  : toneR = 32'd659;
            12'd84  : toneR = 32'd659;  12'd85  : toneR = 32'd659;
            12'd86  : toneR = 32'd659;  12'd87  : toneR = 32'd659;
            12'd88  : toneR = 32'd659;  12'd89  : toneR = 32'd659;
            12'd90  : toneR = 32'd659;  12'd91  : toneR = 32'd659;
            12'd92  : toneR = 32'd659;  12'd93  : toneR = 32'd659;
            12'd94  : toneR = 32'd659;  12'd95  : toneR =    `sil;
            //3 1
            12'd96  : toneR = 32'd659;  12'd97  : toneR = 32'd659;
            12'd98  : toneR = 32'd659;  12'd99  : toneR = 32'd659;
            12'd100 : toneR = 32'd659;  12'd101 : toneR = 32'd659;
            12'd102 : toneR = 32'd659;  12'd103 : toneR = 32'd659;
            12'd104 : toneR = 32'd659;  12'd105 : toneR = 32'd659;
            12'd106 : toneR = 32'd659;  12'd107 : toneR = 32'd659;
            12'd108 : toneR = 32'd659;  12'd109 : toneR = 32'd659;
            12'd110 : toneR = 32'd659;  12'd111 : toneR =    `sil;
            //3 2
            12'd112 : toneR = 32'd440;  12'd113 : toneR = 32'd440;
            12'd114 : toneR = 32'd440;  12'd115 : toneR = 32'd440;
            12'd116 : toneR = 32'd440;  12'd117 : toneR = 32'd440;
            12'd118 : toneR = 32'd440;  12'd119 : toneR =    `sil;
            12'd120 : toneR = 32'd494;  12'd121 : toneR = 32'd494;
            12'd122 : toneR = 32'd494;  12'd123 : toneR = 32'd494;
            12'd124 : toneR = 32'd494;  12'd125 : toneR = 32'd494;
            12'd126 : toneR = 32'd494;  12'd127 : toneR =    `sil;
            //3 3
            12'd128 : toneR = 32'd523;  12'd129 : toneR = 32'd523;
            12'd130 : toneR = 32'd523;  12'd131 : toneR = 32'd523;
            12'd132 : toneR = 32'd523;  12'd133 : toneR = 32'd523;
            12'd134 : toneR = 32'd523;  12'd135 : toneR =    `sil;
            12'd136 : toneR = 32'd659;  12'd137 : toneR = 32'd659;
            12'd138 : toneR = 32'd659;  12'd139 : toneR = 32'd659;
            12'd140 : toneR = 32'd659;  12'd141 : toneR = 32'd659;
            12'd142 : toneR = 32'd659;  12'd143 : toneR =    `sil;
            //4 1
            12'd144 : toneR = 32'd587;  12'd145 : toneR = 32'd587;
            12'd146 : toneR = 32'd587;  12'd147 : toneR = 32'd587;
            12'd148 : toneR = 32'd587;  12'd149 : toneR = 32'd587;
            12'd150 : toneR = 32'd587;  12'd151 : toneR = 32'd587;
            12'd152 : toneR = 32'd587;  12'd153 : toneR = 32'd587;
            12'd154 : toneR = 32'd587;  12'd155 : toneR = 32'd587;
            12'd156 : toneR = 32'd587;  12'd157 : toneR = 32'd587;
            12'd158 : toneR = 32'd587;  12'd159 : toneR =    `sil;
            //4 2
            12'd160 : toneR = 32'd370;  12'd161 : toneR = 32'd370;
            12'd162 : toneR = 32'd370;  12'd163 : toneR = 32'd370;
            12'd164 : toneR = 32'd370;  12'd165 : toneR = 32'd370;
            12'd166 : toneR = 32'd370;  12'd167 : toneR =    `sil;
            12'd168 : toneR = 32'd440;  12'd169 : toneR = 32'd440;
            12'd170 : toneR = 32'd440;  12'd171 : toneR = 32'd440;
            12'd172 : toneR = 32'd440;  12'd173 : toneR = 32'd440;
            12'd174 : toneR = 32'd440;  12'd175 : toneR =    `sil;
            //4 3
            12'd176 : toneR = 32'd587;  12'd177 : toneR = 32'd587;
            12'd178 : toneR = 32'd587;  12'd179 : toneR = 32'd587;
            12'd180 : toneR = 32'd587;  12'd181 : toneR = 32'd587;
            12'd182 : toneR = 32'd587;  12'd183 : toneR = 32'd587;
            12'd184 : toneR = 32'd587;  12'd185 : toneR = 32'd587;
            12'd186 : toneR = 32'd587;  12'd187 : toneR = 32'd587;
            12'd188 : toneR = 32'd587;  12'd189 : toneR = 32'd587;
            12'd190 : toneR = 32'd587;  12'd191 : toneR =    `sil;
            //5 1
            12'd192 : toneR =    `sil;  12'd193 : toneR =    `sil;
            12'd194 : toneR =    `sil;  12'd195 : toneR =    `sil;
            12'd196 : toneR =    `sil;  12'd197 : toneR =    `sil;
            12'd198 : toneR =    `sil;  12'd199 : toneR =    `sil;
            12'd200 : toneR =    `sil;  12'd201 : toneR =    `sil;
            12'd202 : toneR =    `sil;  12'd203 : toneR =    `sil;
            12'd204 : toneR =    `sil;  12'd205 : toneR =    `sil;
            12'd206 : toneR =    `sil;  12'd207 : toneR =    `sil;
            //5 2
            12'd208 : toneR = 32'd440;  12'd209 : toneR = 32'd440;
            12'd210 : toneR = 32'd440;  12'd211 : toneR = 32'd440;
            12'd212 : toneR = 32'd440;  12'd213 : toneR = 32'd440;
            12'd214 : toneR = 32'd440;  12'd215 : toneR =    `sil;
            12'd216 : toneR = 32'd494;  12'd217 : toneR = 32'd494;
            12'd218 : toneR = 32'd494;  12'd219 : toneR = 32'd494;
            12'd220 : toneR = 32'd494;  12'd221 : toneR = 32'd494;
            12'd222 : toneR = 32'd494;  12'd223 : toneR =    `sil;
            //5 3
            12'd224 : toneR = 32'd523;  12'd225 : toneR = 32'd523;
            12'd226 : toneR = 32'd523;  12'd227 : toneR = 32'd523;
            12'd228 : toneR = 32'd523;  12'd229 : toneR = 32'd523;
            12'd230 : toneR = 32'd523;  12'd231 : toneR =    `sil;
            12'd232 : toneR = 32'd587;  12'd233 : toneR = 32'd587;
            12'd234 : toneR = 32'd587;  12'd235 : toneR = 32'd587;
            12'd236 : toneR = 32'd587;  12'd237 : toneR = 32'd587;
            12'd238 : toneR = 32'd587;  12'd239 : toneR =    `sil;
            //6 1
            12'd240 : toneR = 32'd523;  12'd241 : toneR = 32'd523;
            12'd242 : toneR = 32'd523;  12'd243 : toneR = 32'd523;
            12'd244 : toneR = 32'd523;  12'd245 : toneR = 32'd523;
            12'd246 : toneR = 32'd523;  12'd247 : toneR = 32'd523;
            12'd248 : toneR = 32'd523;  12'd249 : toneR = 32'd523;
            12'd250 : toneR = 32'd523;  12'd251 : toneR = 32'd523;
            12'd252 : toneR = 32'd523;  12'd253 : toneR = 32'd523;
            12'd254 : toneR = 32'd523;  12'd255 : toneR =    `sil;
            //6 2
            12'd256 : toneR = 32'd330;  12'd257 : toneR = 32'd330;
            12'd258 : toneR = 32'd330;  12'd259 : toneR = 32'd330;
            12'd260 : toneR = 32'd330;  12'd261 : toneR = 32'd330;
            12'd262 : toneR = 32'd330;  12'd263 : toneR =    `sil;
            12'd264 : toneR = 32'd440;  12'd265 : toneR = 32'd440;
            12'd266 : toneR = 32'd440;  12'd267 : toneR = 32'd440;
            12'd268 : toneR = 32'd440;  12'd269 : toneR = 32'd440;
            12'd270 : toneR = 32'd440;  12'd271 : toneR =    `sil;
            //6 3
            12'd272 : toneR = 32'd523;  12'd273 : toneR = 32'd523;
            12'd274 : toneR = 32'd523;  12'd275 : toneR = 32'd523;
            12'd276 : toneR = 32'd523;  12'd277 : toneR = 32'd523;
            12'd278 : toneR = 32'd523;  12'd279 : toneR = 32'd523;
            12'd280 : toneR = 32'd523;  12'd281 : toneR = 32'd523;
            12'd282 : toneR = 32'd523;  12'd283 : toneR = 32'd523;
            12'd284 : toneR = 32'd523;  12'd285 : toneR = 32'd523;
            12'd286 : toneR = 32'd523;  12'd287 : toneR =    `sil;
            //7 1
            12'd288 : toneR = 32'd440;  12'd289 : toneR = 32'd440;
            12'd290 : toneR = 32'd440;  12'd291 : toneR = 32'd440;
            12'd292 : toneR = 32'd440;  12'd293 : toneR = 32'd440;
            12'd294 : toneR = 32'd440;  12'd295 : toneR = 32'd440;
            12'd296 : toneR = 32'd440;  12'd297 : toneR = 32'd440;
            12'd298 : toneR = 32'd440;  12'd299 : toneR = 32'd440;
            12'd300 : toneR = 32'd440;  12'd301 : toneR = 32'd440;
            12'd302 : toneR = 32'd440;  12'd303 : toneR =    `sil;
            //7 2
            12'd304 : toneR = 32'd311;  12'd305 : toneR = 32'd311;
            12'd306 : toneR = 32'd311;  12'd307 : toneR = 32'd311;
            12'd308 : toneR = 32'd311;  12'd309 : toneR = 32'd311;
            12'd310 : toneR = 32'd311;  12'd311 : toneR =    `sil;
            12'd312 : toneR = 32'd370;  12'd313 : toneR = 32'd370;
            12'd314 : toneR = 32'd370;  12'd315 : toneR = 32'd370;
            12'd316 : toneR = 32'd370;  12'd317 : toneR = 32'd370;
            12'd318 : toneR = 32'd370;  12'd319 : toneR =    `sil;
            //7 3
            12'd320 : toneR = 32'd440;  12'd321 : toneR = 32'd440;
            12'd322 : toneR = 32'd440;  12'd323 : toneR = 32'd440;
            12'd324 : toneR = 32'd440;  12'd325 : toneR = 32'd440;
            12'd326 : toneR = 32'd440;  12'd327 : toneR =    `sil;
            12'd328 : toneR = 32'd523;  12'd329 : toneR = 32'd523;
            12'd330 : toneR = 32'd523;  12'd331 : toneR = 32'd523;
            12'd332 : toneR = 32'd523;  12'd333 : toneR = 32'd523;
            12'd334 : toneR = 32'd523;  12'd335 : toneR =    `sil;
            //8 1
            12'd336 : toneR = 32'd494;  12'd337 : toneR = 32'd494;
            12'd338 : toneR = 32'd494;  12'd339 : toneR = 32'd494;
            12'd340 : toneR = 32'd494;  12'd341 : toneR = 32'd494;
            12'd342 : toneR = 32'd494;  12'd343 : toneR = 32'd494;
            12'd344 : toneR = 32'd494;  12'd345 : toneR = 32'd494;
            12'd346 : toneR = 32'd494;  12'd347 : toneR = 32'd494;
            12'd348 : toneR = 32'd494;  12'd349 : toneR = 32'd494;
            12'd350 : toneR = 32'd494;  12'd351 : toneR = 32'd494;
            //8 2
            12'd352 : toneR = 32'd494;  12'd353 : toneR = 32'd494;
            12'd354 : toneR = 32'd494;  12'd355 : toneR = 32'd494;
            12'd356 : toneR = 32'd494;  12'd357 : toneR = 32'd494;
            12'd358 : toneR = 32'd494;  12'd359 : toneR = 32'd494;
            12'd360 : toneR = 32'd494;  12'd361 : toneR = 32'd494;
            12'd362 : toneR = 32'd494;  12'd363 : toneR = 32'd494;
            12'd364 : toneR = 32'd494;  12'd365 : toneR = 32'd494;
            12'd366 : toneR = 32'd494;  12'd367 : toneR =    `sil;
            //8 3
            12'd368 : toneR = 32'd659;  12'd369 : toneR = 32'd659;
            12'd370 : toneR = 32'd659;  12'd371 : toneR = 32'd659;
            12'd372 : toneR = 32'd659;  12'd373 : toneR = 32'd659;
            12'd374 : toneR = 32'd659;  12'd375 : toneR = 32'd659;
            12'd376 : toneR = 32'd659;  12'd377 : toneR = 32'd659;
            12'd378 : toneR = 32'd659;  12'd379 : toneR = 32'd659;
            12'd380 : toneR = 32'd659;  12'd381 : toneR = 32'd659;
            12'd382 : toneR = 32'd659;  12'd383 : toneR =    `sil;
            //9 1
            12'd384 : toneR =    `sil;  12'd385 : toneR =    `sil;
            12'd386 : toneR =    `sil;  12'd387 : toneR =    `sil;
            12'd388 : toneR =    `sil;  12'd389 : toneR =    `sil;
            12'd390 : toneR =    `sil;  12'd391 : toneR =    `sil;
            12'd392 : toneR =    `sil;  12'd393 : toneR =    `sil;
            12'd394 : toneR =    `sil;  12'd395 : toneR =    `sil;
            12'd396 : toneR =    `sil;  12'd397 : toneR =    `sil;
            12'd398 : toneR =    `sil;  12'd399 : toneR =    `sil;
            //9 2
            12'd400 : toneR = 32'd440;  12'd401 : toneR = 32'd440;
            12'd402 : toneR = 32'd440;  12'd403 : toneR = 32'd440;
            12'd404 : toneR = 32'd440;  12'd405 : toneR = 32'd440;
            12'd406 : toneR = 32'd440;  12'd407 : toneR =    `sil;
            12'd408 : toneR = 32'd494;  12'd409 : toneR = 32'd494;
            12'd410 : toneR = 32'd494;  12'd411 : toneR = 32'd494;
            12'd412 : toneR = 32'd494;  12'd413 : toneR = 32'd494;
            12'd414 : toneR = 32'd494;  12'd415 : toneR =    `sil;
            //9 3
            12'd416 : toneR = 32'd523;  12'd417 : toneR = 32'd523;
            12'd418 : toneR = 32'd523;  12'd419 : toneR = 32'd523;
            12'd420 : toneR = 32'd523;  12'd421 : toneR = 32'd523;
            12'd422 : toneR = 32'd523;  12'd423 : toneR =    `sil;
            12'd424 : toneR = 32'd587;  12'd425 : toneR = 32'd587;
            12'd426 : toneR = 32'd587;  12'd427 : toneR = 32'd587;
            12'd428 : toneR = 32'd587;  12'd429 : toneR = 32'd587;
            12'd430 : toneR = 32'd587;  12'd431 : toneR =    `sil;
            //10 1
            12'd432 : toneR = 32'd659;  12'd433 : toneR = 32'd659;
            12'd434 : toneR = 32'd659;  12'd435 : toneR = 32'd659;
            12'd436 : toneR = 32'd659;  12'd437 : toneR = 32'd659;
            12'd438 : toneR = 32'd659;  12'd439 : toneR = 32'd659;
            12'd440 : toneR = 32'd659;  12'd441 : toneR = 32'd659;
            12'd442 : toneR = 32'd659;  12'd443 : toneR = 32'd659;
            12'd444 : toneR = 32'd659;  12'd445 : toneR = 32'd659;
            12'd446 : toneR = 32'd659;  12'd447 : toneR = 32'd659;
            //10 2
            12'd448 : toneR = 32'd659;  12'd449 : toneR = 32'd659;
            12'd450 : toneR = 32'd659;  12'd451 : toneR = 32'd659;
            12'd452 : toneR = 32'd659;  12'd453 : toneR = 32'd659;
            12'd454 : toneR = 32'd659;  12'd455 : toneR =    `sil;
            12'd456 : toneR = 32'd330;  12'd457 : toneR = 32'd330;
            12'd458 : toneR = 32'd330;  12'd459 : toneR = 32'd330;
            12'd460 : toneR = 32'd330;  12'd461 : toneR = 32'd330;
            12'd462 : toneR = 32'd330;  12'd463 : toneR =    `sil;
            //10 3
            12'd464 : toneR = 32'd415;  12'd465 : toneR = 32'd415;
            12'd466 : toneR = 32'd415;  12'd467 : toneR = 32'd415;
            12'd468 : toneR = 32'd415;  12'd469 : toneR = 32'd415;
            12'd470 : toneR = 32'd415;  12'd471 : toneR =    `sil;
            12'd472 : toneR = 32'd494;  12'd473 : toneR = 32'd494;
            12'd474 : toneR = 32'd494;  12'd475 : toneR = 32'd494;
            12'd476 : toneR = 32'd494;  12'd477 : toneR = 32'd494;
            12'd478 : toneR = 32'd494;  12'd479 : toneR =    `sil;
            //11 1
            12'd480 : toneR = 32'd659;  12'd481 : toneR = 32'd659;
            12'd482 : toneR = 32'd659;  12'd483 : toneR = 32'd659;
            12'd484 : toneR = 32'd659;  12'd485 : toneR = 32'd659;
            12'd486 : toneR = 32'd659;  12'd487 : toneR = 32'd659;
            12'd488 : toneR = 32'd659;  12'd489 : toneR = 32'd659;
            12'd490 : toneR = 32'd659;  12'd491 : toneR = 32'd659;
            12'd492 : toneR = 32'd659;  12'd493 : toneR = 32'd659;
            12'd494 : toneR = 32'd659;  12'd495 : toneR = 32'd659;
            //11 2
            12'd496 : toneR = 32'd659;  12'd497 : toneR = 32'd659;
            12'd498 : toneR = 32'd659;  12'd499 : toneR = 32'd659;
            12'd500 : toneR = 32'd659;  12'd501 : toneR = 32'd659;
            12'd502 : toneR = 32'd659;  12'd503 : toneR =    `sil;
            12'd504 : toneR = 32'd330;  12'd505 : toneR = 32'd330;
            12'd506 : toneR = 32'd330;  12'd507 : toneR = 32'd330;
            12'd508 : toneR = 32'd330;  12'd509 : toneR = 32'd330;
            12'd510 : toneR = 32'd330;  12'd511 : toneR =    `sil;
            //11 3
            12'd512 : toneR = 32'd440;  12'd513 : toneR = 32'd440;
            12'd514 : toneR = 32'd440;  12'd515 : toneR = 32'd440;
            12'd516 : toneR = 32'd440;  12'd517 : toneR = 32'd440;
            12'd518 : toneR = 32'd440;  12'd519 : toneR =    `sil;
            12'd520 : toneR = 32'd659;  12'd521 : toneR = 32'd659;
            12'd522 : toneR = 32'd659;  12'd523 : toneR = 32'd659;
            12'd524 : toneR = 32'd659;  12'd525 : toneR = 32'd659;
            12'd526 : toneR = 32'd659;  12'd527 : toneR =    `sil;
            //12 1
            12'd528 : toneR = 32'd587;  12'd529 : toneR = 32'd587;
            12'd530 : toneR = 32'd587;  12'd531 : toneR = 32'd587;
            12'd532 : toneR = 32'd587;  12'd533 : toneR = 32'd587;
            12'd534 : toneR = 32'd587;  12'd535 : toneR = 32'd587;
            12'd536 : toneR = 32'd587;  12'd537 : toneR = 32'd587;
            12'd538 : toneR = 32'd587;  12'd539 : toneR = 32'd587;
            12'd540 : toneR = 32'd587;  12'd541 : toneR = 32'd587;
            12'd542 : toneR = 32'd587;  12'd543 : toneR = 32'd587;
            //12 2
            12'd544 : toneR = 32'd587;  12'd545 : toneR = 32'd587;
            12'd546 : toneR = 32'd587;  12'd547 : toneR = 32'd587;
            12'd548 : toneR = 32'd587;  12'd549 : toneR = 32'd587;
            12'd550 : toneR = 32'd587;  12'd551 : toneR = 32'd587;
            12'd552 : toneR = 32'd587;  12'd553 : toneR = 32'd587;
            12'd554 : toneR = 32'd587;  12'd555 : toneR = 32'd587;
            12'd556 : toneR = 32'd587;  12'd557 : toneR = 32'd587;
            12'd558 : toneR = 32'd587;  12'd559 : toneR =    `sil;
            //12 3
            12'd560 : toneR =    `sil;  12'd561 : toneR =    `sil;
            12'd562 : toneR =    `sil;  12'd563 : toneR =    `sil;
            12'd564 : toneR =    `sil;  12'd565 : toneR =    `sil;
            12'd566 : toneR =    `sil;  12'd567 : toneR =    `sil;
            12'd568 : toneR =    `sil;  12'd569 : toneR =    `sil;
            12'd570 : toneR =    `sil;  12'd571 : toneR =    `sil;
            12'd572 : toneR =    `sil;  12'd573 : toneR =    `sil;
            12'd574 : toneR =    `sil;  12'd575 : toneR =    `sil;
            //13 1
            12'd576 : toneR =    `sil;  12'd577 : toneR =    `sil;
            12'd578 : toneR =    `sil;  12'd579 : toneR =    `sil;
            12'd580 : toneR =    `sil;  12'd581 : toneR =    `sil;
            12'd582 : toneR =    `sil;  12'd583 : toneR =    `sil;
            12'd584 : toneR =    `sil;  12'd585 : toneR =    `sil;
            12'd586 : toneR =    `sil;  12'd587 : toneR =    `sil;
            12'd588 : toneR =    `sil;  12'd589 : toneR =    `sil;
            12'd590 : toneR =    `sil;  12'd591 : toneR =    `sil;
            //13 2
            12'd592 : toneR = 32'd294;  12'd593 : toneR = 32'd294;
            12'd594 : toneR = 32'd294;  12'd595 : toneR = 32'd294;
            12'd596 : toneR = 32'd294;  12'd597 : toneR = 32'd294;
            12'd598 : toneR = 32'd294;  12'd599 : toneR =    `sil;
            12'd600 : toneR = 32'd349;  12'd601 : toneR = 32'd349;
            12'd602 : toneR = 32'd349;  12'd603 : toneR = 32'd349;
            12'd604 : toneR = 32'd349;  12'd605 : toneR = 32'd349;
            12'd606 : toneR = 32'd349;  12'd607 : toneR =    `sil;
            //13 3
            12'd608 : toneR = 32'd440;  12'd609 : toneR = 32'd440;
            12'd610 : toneR = 32'd440;  12'd611 : toneR = 32'd440;
            12'd612 : toneR = 32'd440;  12'd613 : toneR = 32'd440;
            12'd614 : toneR = 32'd440;  12'd615 : toneR =    `sil;
            12'd616 : toneR = 32'd587;  12'd617 : toneR = 32'd587;
            12'd618 : toneR = 32'd587;  12'd619 : toneR = 32'd587;
            12'd620 : toneR = 32'd587;  12'd621 : toneR = 32'd587;
            12'd622 : toneR = 32'd587;  12'd623 : toneR =    `sil;
            //14 1
            12'd624 : toneR = 32'd523;  12'd625 : toneR = 32'd523;
            12'd626 : toneR = 32'd523;  12'd627 : toneR = 32'd523;
            12'd628 : toneR = 32'd523;  12'd629 : toneR = 32'd523;
            12'd630 : toneR = 32'd523;  12'd631 : toneR = 32'd523;
            12'd632 : toneR = 32'd523;  12'd633 : toneR = 32'd523;
            12'd634 : toneR = 32'd523;  12'd635 : toneR = 32'd523;
            12'd636 : toneR = 32'd523;  12'd637 : toneR = 32'd523;
            12'd638 : toneR = 32'd523;  12'd639 : toneR = 32'd523;
            //14 2
            12'd640 : toneR = 32'd523;  12'd641 : toneR = 32'd523;
            12'd642 : toneR = 32'd523;  12'd643 : toneR = 32'd523;
            12'd644 : toneR = 32'd523;  12'd645 : toneR = 32'd523;
            12'd646 : toneR = 32'd523;  12'd647 : toneR = 32'd523;
            12'd648 : toneR = 32'd523;  12'd649 : toneR = 32'd523;
            12'd650 : toneR = 32'd523;  12'd651 : toneR = 32'd523;
            12'd652 : toneR = 32'd523;  12'd653 : toneR = 32'd523;
            12'd654 : toneR = 32'd523;  12'd655 : toneR =     `sil;
            //14 3
            12'd656 : toneR = 32'd494;  12'd657 : toneR = 32'd494;
            12'd658 : toneR = 32'd494;  12'd659 : toneR = 32'd494;
            12'd660 : toneR = 32'd494;  12'd661 : toneR = 32'd494;
            12'd662 : toneR = 32'd494;  12'd663 : toneR =     `sil;
            12'd664 : toneR = 32'd440;  12'd665 : toneR = 32'd440;
            12'd666 : toneR = 32'd440;  12'd667 : toneR = 32'd440;
            12'd668 : toneR = 32'd440;  12'd669 : toneR = 32'd440;
            12'd670 : toneR = 32'd440;  12'd671 : toneR =     `sil;
            //15 1
            12'd672 : toneR = 32'd415;  12'd673 : toneR = 32'd415;
            12'd674 : toneR = 32'd415;  12'd675 : toneR = 32'd415;
            12'd676 : toneR = 32'd415;  12'd677 : toneR = 32'd415;
            12'd678 : toneR = 32'd415;  12'd679 : toneR = 32'd415;
            12'd680 : toneR = 32'd415;  12'd681 : toneR = 32'd415;
            12'd682 : toneR = 32'd415;  12'd683 : toneR = 32'd415;
            12'd684 : toneR = 32'd415;  12'd685 : toneR = 32'd415;
            12'd686 : toneR = 32'd415;  12'd687 : toneR = 32'd415;
            //15 2
            12'd688 : toneR = 32'd415;  12'd689 : toneR = 32'd415;
            12'd690 : toneR = 32'd415;  12'd691 : toneR = 32'd415;
            12'd692 : toneR = 32'd415;  12'd693 : toneR = 32'd415;
            12'd694 : toneR = 32'd415;  12'd695 : toneR = 32'd415;
            12'd696 : toneR = 32'd415;  12'd697 : toneR = 32'd415;
            12'd698 : toneR = 32'd415;  12'd699 : toneR = 32'd415;
            12'd700 : toneR = 32'd415;  12'd701 : toneR = 32'd415;
            12'd702 : toneR = 32'd415;  12'd703 : toneR =    `sil;
            //15 3
            12'd704 : toneR = 32'd659;  12'd705 : toneR = 32'd659;
            12'd706 : toneR = 32'd659;  12'd707 : toneR = 32'd659;
            12'd708 : toneR = 32'd659;  12'd709 : toneR = 32'd659;
            12'd710 : toneR = 32'd659;  12'd711 : toneR = 32'd659;
            12'd712 : toneR = 32'd659;  12'd713 : toneR = 32'd659;
            12'd714 : toneR = 32'd659;  12'd715 : toneR = 32'd659;
            12'd716 : toneR = 32'd659;  12'd717 : toneR = 32'd659;
            12'd718 : toneR = 32'd659;  12'd719 : toneR =    `sil;
            //16 1
            12'd720 : toneR = 32'd440;  12'd721 : toneR = 32'd440;
            12'd722 : toneR = 32'd440;  12'd723 : toneR = 32'd440;
            12'd724 : toneR = 32'd440;  12'd725 : toneR = 32'd440;
            12'd726 : toneR = 32'd440;  12'd727 : toneR = 32'd440;
            12'd728 : toneR = 32'd440;  12'd729 : toneR = 32'd440;
            12'd730 : toneR = 32'd440;  12'd731 : toneR = 32'd440;
            12'd732 : toneR = 32'd440;  12'd733 : toneR = 32'd440;
            12'd734 : toneR = 32'd440;  12'd735 : toneR = 32'd440;
            //16 2
            12'd736 : toneR = 32'd440;  12'd737 : toneR = 32'd440;
            12'd738 : toneR = 32'd440;  12'd739 : toneR = 32'd440;
            12'd740 : toneR = 32'd440;  12'd741 : toneR = 32'd440;
            12'd742 : toneR = 32'd440;  12'd743 : toneR = 32'd440;
            12'd744 : toneR = 32'd440;  12'd745 : toneR = 32'd440;
            12'd746 : toneR = 32'd440;  12'd747 : toneR = 32'd440;
            12'd748 : toneR = 32'd440;  12'd749 : toneR = 32'd440;
            12'd750 : toneR = 32'd440;  12'd751 : toneR = 32'd440;
            //16 3
            12'd752 : toneR = 32'd440;  12'd753 : toneR = 32'd440;
            12'd754 : toneR = 32'd440;  12'd755 : toneR = 32'd440;
            12'd756 : toneR = 32'd440;  12'd757 : toneR = 32'd440;
            12'd758 : toneR = 32'd440;  12'd759 : toneR = 32'd440;
            12'd760 : toneR = 32'd440;  12'd761 : toneR = 32'd440;
            12'd762 : toneR = 32'd440;  12'd763 : toneR = 32'd440;
            12'd764 : toneR = 32'd440;  12'd765 : toneR = 32'd440;
            12'd766 : toneR = 32'd440;  12'd767 : toneR =    `sil;
            //17 1
            12'd768 : toneR =    `sil;  12'd771 : toneR =    `sil;
            12'd772 : toneR =    `sil;  12'd773 : toneR =    `sil;
            12'd774 : toneR =    `sil;  12'd775 : toneR =    `sil;
            12'd776 : toneR =    `sil;  12'd777 : toneR =    `sil;
            12'd778 : toneR =    `sil;  12'd779 : toneR =    `sil;
            12'd780 : toneR =    `sil;  12'd781 : toneR =    `sil;
            12'd782 : toneR =    `sil;  12'd783 : toneR =    `sil;
            //17 2
            12'd784 : toneR =    `sil;  12'd785 : toneR =    `sil;
            12'd786 : toneR =    `sil;  12'd787 : toneR =    `sil;
            12'd788 : toneR =    `sil;  12'd789 : toneR =    `sil;
            12'd790 : toneR =    `sil;  12'd791 : toneR =    `sil;
            12'd792 : toneR =    `sil;  12'd793 : toneR =    `sil;
            12'd794 : toneR =    `sil;  12'd795 : toneR =    `sil;
            12'd796 : toneR =    `sil;  12'd797 : toneR =    `sil;
            12'd798 : toneR =    `sil;  12'd799 : toneR =    `sil;
            //17 3
            12'd800 : toneR =    `sil;  12'd801 : toneR =    `sil;
            12'd802 : toneR =    `sil;  12'd803 : toneR =    `sil;
            12'd804 : toneR =    `sil;  12'd805 : toneR =    `sil;
            12'd806 : toneR =    `sil;  12'd807 : toneR =    `sil;
            12'd808 : toneR =    `sil;  12'd809 : toneR =    `sil;
            12'd810 : toneR =    `sil;  12'd811 : toneR =    `sil;
            12'd812 : toneR =    `sil;  12'd813 : toneR =    `sil;
            12'd814 : toneR =    `sil;  12'd815 : toneR =    `sil;
            //18 1
            12'd816 : toneR =    `sil;  12'd817 : toneR =    `sil;
            12'd818 : toneR =    `sil;  12'd819 : toneR =    `sil;
            12'd820 : toneR =    `sil;  12'd821 : toneR =    `sil;
            12'd822 : toneR =    `sil;  12'd823 : toneR =    `sil;
            12'd824 : toneR =    `sil;  12'd825 : toneR =    `sil;
            12'd826 : toneR =    `sil;  12'd827 : toneR =    `sil;
            12'd828 : toneR =    `sil;  12'd829 : toneR =    `sil;
            12'd830 : toneR =    `sil;  12'd831 : toneR =    `sil;
            //18 2
            12'd832 : toneR =    `sil;  12'd833 : toneR =    `sil;
            12'd834 : toneR =    `sil;  12'd835 : toneR =    `sil;
            12'd836 : toneR =    `sil;  12'd837 : toneR =    `sil;
            12'd838 : toneR =    `sil;  12'd839 : toneR =    `sil;
            12'd840 : toneR =    `sil;  12'd841 : toneR =    `sil;
            12'd842 : toneR =    `sil;  12'd843 : toneR =    `sil;
            12'd844 : toneR =    `sil;  12'd845 : toneR =    `sil;
            12'd846 : toneR =    `sil;  12'd847 : toneR =    `sil;
            //18 3
            12'd848 : toneR =    `sil;  12'd849 : toneR =    `sil;
            12'd850 : toneR =    `sil;  12'd851 : toneR =    `sil;
            12'd852 : toneR =    `sil;  12'd853 : toneR =    `sil;
            12'd854 : toneR =    `sil;  12'd855 : toneR =    `sil;
            12'd856 : toneR =    `sil;  12'd857 : toneR =    `sil;
            12'd858 : toneR =    `sil;  12'd859 : toneR =    `sil;
            12'd860 : toneR =    `sil;  12'd861 : toneR =    `sil;
            12'd862 : toneR =    `sil;  12'd863 : toneR =    `sil;
            default : toneR =    `sil;
        endcase
    end

    always @* begin
        case(ibeat)
            //1 1
            12'd0   : toneL =    `sil;  12'd1   : toneL = 32'd440; 
            12'd2   : toneL = 32'd440;  12'd3   : toneL = 32'd440;
            12'd4   : toneL = 32'd440;  12'd5   : toneL = 32'd440;
            12'd6   : toneL = 32'd440;  12'd7   : toneL =    `sil;
            12'd8   : toneL = 32'd659;  12'd9   : toneL = 32'd659;
            12'd10  : toneL = 32'd659;  12'd11  : toneL = 32'd659;
            12'd12  : toneL = 32'd659;  12'd13  : toneL = 32'd659;
            12'd14  : toneL = 32'd659;  12'd15  : toneL = 32'd659;
            //1 2
            12'd16  : toneL = 32'd659;  12'd17  : toneL = 32'd659;
            12'd18  : toneL = 32'd659;  12'd19  : toneL = 32'd659;
            12'd20  : toneL = 32'd659;  12'd21  : toneL = 32'd659;
            12'd22  : toneL = 32'd659;  12'd23  : toneL = 32'd659;
            12'd24  : toneL = 32'd659;  12'd25  : toneL = 32'd659;
            12'd26  : toneL = 32'd659;  12'd27  : toneL = 32'd659;
            12'd28  : toneL = 32'd659;  12'd29  : toneL = 32'd659;
            12'd30  : toneL = 32'd659;  12'd31  : toneL = 32'd659;
            //1 3
            12'd32  : toneL = 32'd659;  12'd33  : toneL = 32'd659;
            12'd34  : toneL = 32'd659;  12'd35  : toneL = 32'd659;
            12'd36  : toneL = 32'd659;  12'd37  : toneL = 32'd659;
            12'd38  : toneL = 32'd659;  12'd39  : toneL = 32'd659;
            12'd40  : toneL = 32'd659;  12'd41  : toneL = 32'd659;
            12'd42  : toneL = 32'd659;  12'd43  : toneL = 32'd659;
            12'd44  : toneL = 32'd659;  12'd45  : toneL = 32'd659;
            12'd46  : toneL = 32'd659;  12'd47  : toneL =    `sil;
            //2 1
            12'd48  : toneL = 32'd415;  12'd49  : toneL = 32'd415;
            12'd50  : toneL = 32'd415;  12'd51  : toneL = 32'd415;
            12'd52  : toneL = 32'd415;  12'd53  : toneL = 32'd415;
            12'd54  : toneL = 32'd415;  12'd55  : toneL =    `sil;
            12'd56  : toneL = 32'd659;  12'd57  : toneL = 32'd659;
            12'd58  : toneL = 32'd659;  12'd59  : toneL = 32'd659;
            12'd60  : toneL = 32'd659;  12'd61  : toneL = 32'd659;
            12'd62  : toneL = 32'd659;  12'd63  : toneL = 32'd659;
            //2 2
            12'd64  : toneL = 32'd659;  12'd65  : toneL = 32'd659;
            12'd66  : toneL = 32'd659;  12'd67  : toneL = 32'd659;
            12'd68  : toneL = 32'd659;  12'd69  : toneL = 32'd659;
            12'd70  : toneL = 32'd659;  12'd71  : toneL = 32'd659;
            12'd72  : toneL = 32'd659;  12'd73  : toneL = 32'd659;
            12'd74  : toneL = 32'd659;  12'd75  : toneL = 32'd659;
            12'd76  : toneL = 32'd659;  12'd77  : toneL = 32'd659;
            12'd78  : toneL = 32'd659;  12'd79  : toneL = 32'd659;
            //2 3
            12'd80  : toneL = 32'd659;  12'd81  : toneL = 32'd659;
            12'd82  : toneL = 32'd659;  12'd83  : toneL = 32'd659;
            12'd84  : toneL = 32'd659;  12'd85  : toneL = 32'd659;
            12'd86  : toneL = 32'd659;  12'd87  : toneL = 32'd659;
            12'd88  : toneL = 32'd659;  12'd89  : toneL = 32'd659;
            12'd90  : toneL = 32'd659;  12'd91  : toneL = 32'd659;
            12'd92  : toneL = 32'd659;  12'd93  : toneL = 32'd659;
            12'd94  : toneL = 32'd659;  12'd95  : toneL =    `sil;
            //3 1
            12'd96  : toneL = 32'd392;  12'd97  : toneL = 32'd392;
            12'd98  : toneL = 32'd392;  12'd99  : toneL = 32'd392;
            12'd100 : toneL = 32'd392;  12'd101 : toneL = 32'd392;
            12'd102 : toneL = 32'd392;  12'd103 : toneL =    `sil;
            12'd104 : toneL = 32'd659;  12'd105 : toneL = 32'd659;
            12'd106 : toneL = 32'd659;  12'd107 : toneL = 32'd659;
            12'd108 : toneL = 32'd659;  12'd109 : toneL = 32'd659;
            12'd110 : toneL = 32'd659;  12'd111 : toneL = 32'd659;
            //3 2
            12'd112 : toneL = 32'd659;  12'd113 : toneL = 32'd659;
            12'd114 : toneL = 32'd659;  12'd115 : toneL = 32'd659;
            12'd116 : toneL = 32'd659;  12'd117 : toneL = 32'd659;
            12'd118 : toneL = 32'd659;  12'd119 : toneL = 32'd659;
            12'd120 : toneL = 32'd659;  12'd121 : toneL = 32'd659;
            12'd122 : toneL = 32'd659;  12'd123 : toneL = 32'd659;
            12'd124 : toneL = 32'd659;  12'd125 : toneL = 32'd659;
            12'd126 : toneL = 32'd659;  12'd127 : toneL = 32'd659;
            //3 3
            12'd128 : toneL = 32'd659;  12'd129 : toneL = 32'd659;
            12'd130 : toneL = 32'd659;  12'd131 : toneL = 32'd659;
            12'd132 : toneL = 32'd659;  12'd133 : toneL = 32'd659;
            12'd134 : toneL = 32'd659;  12'd135 : toneL = 32'd659;
            12'd136 : toneL = 32'd659;  12'd137 : toneL = 32'd659;
            12'd138 : toneL = 32'd659;  12'd139 : toneL = 32'd659;
            12'd140 : toneL = 32'd659;  12'd141 : toneL = 32'd659;
            12'd142 : toneL = 32'd659;  12'd143 : toneL =    `sil;
            //4 1
            12'd144 : toneL = 32'd370;  12'd145 : toneL = 32'd370;
            12'd146 : toneL = 32'd370;  12'd147 : toneL = 32'd370;
            12'd148 : toneL = 32'd370;  12'd149 : toneL = 32'd370;
            12'd150 : toneL = 32'd370;  12'd151 : toneL =    `sil;
            12'd152 : toneL = 32'd587;  12'd153 : toneL = 32'd587;
            12'd154 : toneL = 32'd587;  12'd155 : toneL = 32'd587;
            12'd156 : toneL = 32'd587;  12'd157 : toneL = 32'd587;
            12'd158 : toneL = 32'd587;  12'd159 : toneL = 32'd587;
            //4 2
            12'd160 : toneL = 32'd587;  12'd161 : toneL = 32'd587;
            12'd162 : toneL = 32'd587;  12'd163 : toneL = 32'd587;
            12'd164 : toneL = 32'd587;  12'd165 : toneL = 32'd587;
            12'd166 : toneL = 32'd587;  12'd167 : toneL = 32'd587;
            12'd168 : toneL = 32'd587;  12'd169 : toneL = 32'd587;
            12'd170 : toneL = 32'd587;  12'd171 : toneL = 32'd587;
            12'd172 : toneL = 32'd587;  12'd173 : toneL = 32'd587;
            12'd174 : toneL = 32'd587;  12'd175 : toneL = 32'd587;
            //4 3
            12'd176 : toneL = 32'd587;  12'd177 : toneL = 32'd587;
            12'd178 : toneL = 32'd587;  12'd179 : toneL = 32'd587;
            12'd180 : toneL = 32'd587;  12'd181 : toneL = 32'd587;
            12'd182 : toneL = 32'd587;  12'd183 : toneL = 32'd587;
            12'd184 : toneL = 32'd587;  12'd185 : toneL = 32'd587;
            12'd186 : toneL = 32'd587;  12'd187 : toneL = 32'd587;
            12'd188 : toneL = 32'd587;  12'd189 : toneL = 32'd587;
            12'd190 : toneL = 32'd587;  12'd191 : toneL =    `sil;
            //5 1
            12'd192 : toneL = 32'd349;  12'd193 : toneL = 32'd349;
            12'd194 : toneL = 32'd349;  12'd195 : toneL = 32'd349;
            12'd196 : toneL = 32'd349;  12'd197 : toneL = 32'd349;
            12'd198 : toneL = 32'd349;  12'd199 : toneL =    `sil;
            12'd200 : toneL = 32'd587;  12'd201 : toneL = 32'd587;
            12'd202 : toneL = 32'd587;  12'd203 : toneL = 32'd587;
            12'd204 : toneL = 32'd587;  12'd205 : toneL = 32'd587;
            12'd206 : toneL = 32'd587;  12'd207 : toneL = 32'd587;
            //5 2
            12'd208 : toneL = 32'd587;  12'd209 : toneL = 32'd587;
            12'd210 : toneL = 32'd587;  12'd211 : toneL = 32'd587;
            12'd212 : toneL = 32'd587;  12'd213 : toneL = 32'd587;
            12'd214 : toneL = 32'd587;  12'd215 : toneL = 32'd587;
            12'd216 : toneL = 32'd587;  12'd217 : toneL = 32'd587;
            12'd218 : toneL = 32'd587;  12'd219 : toneL = 32'd587;
            12'd220 : toneL = 32'd587;  12'd221 : toneL = 32'd587;
            12'd222 : toneL = 32'd587;  12'd223 : toneL = 32'd587;
            //5 3
            12'd224 : toneL = 32'd587;  12'd225 : toneL = 32'd587;
            12'd226 : toneL = 32'd587;  12'd227 : toneL = 32'd587;
            12'd228 : toneL = 32'd587;  12'd229 : toneL = 32'd587;
            12'd230 : toneL = 32'd587;  12'd231 : toneL = 32'd587;
            12'd232 : toneL = 32'd587;  12'd233 : toneL = 32'd587;
            12'd234 : toneL = 32'd587;  12'd235 : toneL = 32'd587;
            12'd236 : toneL = 32'd587;  12'd237 : toneL = 32'd587;
            12'd238 : toneL = 32'd587;  12'd239 : toneL =    `sil;
            //6 1
            12'd240 : toneL = 32'd330;  12'd241 : toneL = 32'd330;
            12'd242 : toneL = 32'd330;  12'd243 : toneL = 32'd330;
            12'd244 : toneL = 32'd330;  12'd245 : toneL = 32'd330;
            12'd246 : toneL = 32'd330;  12'd247 : toneL =    `sil;
            12'd248 : toneL = 32'd523;  12'd249 : toneL = 32'd523;
            12'd250 : toneL = 32'd523;  12'd251 : toneL = 32'd523;
            12'd252 : toneL = 32'd523;  12'd253 : toneL = 32'd523;
            12'd254 : toneL = 32'd523;  12'd255 : toneL = 32'd523;
            //6 2
            12'd256 : toneL = 32'd523;  12'd257 : toneL = 32'd523;
            12'd258 : toneL = 32'd523;  12'd259 : toneL = 32'd523;
            12'd260 : toneL = 32'd523;  12'd261 : toneL = 32'd523;
            12'd262 : toneL = 32'd523;  12'd263 : toneL = 32'd523;
            12'd264 : toneL = 32'd523;  12'd265 : toneL = 32'd523;
            12'd266 : toneL = 32'd523;  12'd267 : toneL = 32'd523;
            12'd268 : toneL = 32'd523;  12'd269 : toneL = 32'd523;
            12'd270 : toneL = 32'd523;  12'd271 : toneL = 32'd523;
            //6 3
            12'd272 : toneL = 32'd523;  12'd273 : toneL = 32'd523;
            12'd274 : toneL = 32'd523;  12'd275 : toneL = 32'd523;
            12'd276 : toneL = 32'd523;  12'd277 : toneL = 32'd523;
            12'd278 : toneL = 32'd523;  12'd279 : toneL = 32'd523;
            12'd280 : toneL = 32'd523;  12'd281 : toneL = 32'd523;
            12'd282 : toneL = 32'd523;  12'd283 : toneL = 32'd523;
            12'd284 : toneL = 32'd523;  12'd285 : toneL = 32'd523;
            12'd286 : toneL = 32'd523;  12'd287 : toneL =    `sil;
            //7 1
            12'd288 : toneL = 32'd311;  12'd289 : toneL = 32'd311;
            12'd290 : toneL = 32'd311;  12'd291 : toneL = 32'd311;
            12'd292 : toneL = 32'd311;  12'd293 : toneL = 32'd311;
            12'd294 : toneL = 32'd311;  12'd295 : toneL =    `sil;
            12'd296 : toneL = 32'd523;  12'd297 : toneL = 32'd523;
            12'd298 : toneL = 32'd523;  12'd299 : toneL = 32'd523;
            12'd300 : toneL = 32'd523;  12'd301 : toneL = 32'd523;
            12'd302 : toneL = 32'd523;  12'd303 : toneL = 32'd523;
            //7 2
            12'd304 : toneL = 32'd523;  12'd305 : toneL = 32'd523;
            12'd306 : toneL = 32'd523;  12'd307 : toneL = 32'd523;
            12'd308 : toneL = 32'd523;  12'd309 : toneL = 32'd523;
            12'd310 : toneL = 32'd523;  12'd311 : toneL = 32'd523;
            12'd312 : toneL = 32'd523;  12'd313 : toneL = 32'd523;
            12'd314 : toneL = 32'd523;  12'd315 : toneL = 32'd523;
            12'd316 : toneL = 32'd523;  12'd317 : toneL = 32'd523;
            12'd318 : toneL = 32'd523;  12'd319 : toneL = 32'd523;
            //7 3
            12'd320 : toneL = 32'd523;  12'd321 : toneL = 32'd523;
            12'd322 : toneL = 32'd523;  12'd323 : toneL = 32'd523;
            12'd324 : toneL = 32'd523;  12'd325 : toneL = 32'd523;
            12'd326 : toneL = 32'd523;  12'd327 : toneL = 32'd523;
            12'd328 : toneL = 32'd523;  12'd329 : toneL = 32'd523;
            12'd330 : toneL = 32'd523;  12'd331 : toneL = 32'd523;
            12'd332 : toneL = 32'd523;  12'd333 : toneL = 32'd523;
            12'd334 : toneL = 32'd523;  12'd335 : toneL =    `sil;
            //8 1
            12'd336 : toneL = 32'd330;  12'd337 : toneL = 32'd330;
            12'd338 : toneL = 32'd330;  12'd339 : toneL = 32'd330;
            12'd340 : toneL = 32'd330;  12'd341 : toneL = 32'd330;
            12'd342 : toneL = 32'd330;  12'd343 : toneL =    `sil;
            12'd344 : toneL = 32'd494;  12'd345 : toneL = 32'd494;
            12'd346 : toneL = 32'd494;  12'd347 : toneL = 32'd494;
            12'd348 : toneL = 32'd494;  12'd349 : toneL = 32'd494;
            12'd350 : toneL = 32'd494;  12'd351 : toneL =    `sil;
            //8 2
            12'd352 : toneL = 32'd659;  12'd353 : toneL = 32'd659;
            12'd354 : toneL = 32'd659;  12'd355 : toneL = 32'd659;
            12'd356 : toneL = 32'd659;  12'd357 : toneL = 32'd659;
            12'd358 : toneL = 32'd659;  12'd359 : toneL =    `sil;
            12'd360 : toneL = 32'd831;  12'd361 : toneL = 32'd831;
            12'd362 : toneL = 32'd831;  12'd363 : toneL = 32'd831;
            12'd364 : toneL = 32'd831;  12'd365 : toneL = 32'd831;
            12'd366 : toneL = 32'd831;  12'd367 : toneL =    `sil;
            //8 3
            12'd368 : toneL =    `sil;  12'd369 : toneL =    `sil;
            12'd370 : toneL =    `sil;  12'd371 : toneL =    `sil;
            12'd372 : toneL =    `sil;  12'd373 : toneL =    `sil;
            12'd374 : toneL =    `sil;  12'd375 : toneL =    `sil;
            12'd376 : toneL =    `sil;  12'd377 : toneL =    `sil;
            12'd378 : toneL =    `sil;  12'd379 : toneL =    `sil;
            12'd380 : toneL =    `sil;  12'd381 : toneL =    `sil;
            12'd382 : toneL =    `sil;  12'd383 : toneL =    `sil;
            //9 1
            12'd384 : toneL = 32'd440;  12'd385 : toneL = 32'd440;
            12'd386 : toneL = 32'd440;  12'd387 : toneL = 32'd440;
            12'd388 : toneL = 32'd440;  12'd389 : toneL = 32'd440;
            12'd390 : toneL = 32'd440;  12'd391 : toneL =    `sil;
            12'd392 : toneL = 32'd659;  12'd393 : toneL = 32'd659;
            12'd394 : toneL = 32'd659;  12'd395 : toneL = 32'd659;
            12'd396 : toneL = 32'd659;  12'd397 : toneL = 32'd659;
            12'd398 : toneL = 32'd659;  12'd399 : toneL =    `sil;
            //9 2
            12'd400 : toneL = 32'd880;  12'd401 : toneL = 32'd880;
            12'd402 : toneL = 32'd880;  12'd403 : toneL = 32'd880;
            12'd404 : toneL = 32'd880;  12'd405 : toneL = 32'd880;
            12'd406 : toneL = 32'd880;  12'd407 : toneL = 32'd880;
            12'd408 : toneL = 32'd880;  12'd409 : toneL = 32'd880;
            12'd410 : toneL = 32'd880;  12'd411 : toneL = 32'd880;
            12'd412 : toneL = 32'd880;  12'd413 : toneL = 32'd880;
            12'd414 : toneL = 32'd880;  12'd415 : toneL = 32'd880;
            //9 3
            12'd416 : toneL = 32'd880;  12'd417 : toneL = 32'd880;
            12'd418 : toneL = 32'd880;  12'd419 : toneL = 32'd880;
            12'd420 : toneL = 32'd880;  12'd421 : toneL = 32'd880;
            12'd422 : toneL = 32'd880;  12'd423 : toneL = 32'd880;
            12'd424 : toneL = 32'd880;  12'd425 : toneL = 32'd880;
            12'd426 : toneL = 32'd880;  12'd427 : toneL = 32'd880;
            12'd428 : toneL = 32'd880;  12'd429 : toneL = 32'd880;
            12'd430 : toneL = 32'd880;  12'd431 : toneL =    `sil;
            //10 1
            12'd432 : toneL = 32'd415;  12'd433 : toneL = 32'd415;
            12'd434 : toneL = 32'd415;  12'd435 : toneL = 32'd415;
            12'd436 : toneL = 32'd415;  12'd437 : toneL = 32'd415;
            12'd438 : toneL = 32'd415;  12'd439 : toneL =    `sil;
            12'd440 : toneL = 32'd659;  12'd441 : toneL = 32'd659;
            12'd442 : toneL = 32'd659;  12'd443 : toneL = 32'd659;
            12'd444 : toneL = 32'd659;  12'd445 : toneL = 32'd659;
            12'd446 : toneL = 32'd659;  12'd447 : toneL =    `sil;
            //10 2
            12'd448 : toneL = 32'd831;  12'd449 : toneL = 32'd831;
            12'd450 : toneL = 32'd831;  12'd451 : toneL = 32'd831;
            12'd452 : toneL = 32'd831;  12'd453 : toneL = 32'd831;
            12'd454 : toneL = 32'd831;  12'd455 : toneL = 32'd831;
            12'd456 : toneL = 32'd831;  12'd457 : toneL = 32'd831;
            12'd458 : toneL = 32'd831;  12'd459 : toneL = 32'd831;
            12'd460 : toneL = 32'd831;  12'd461 : toneL = 32'd831;
            12'd462 : toneL = 32'd831;  12'd463 : toneL = 32'd831;
            //10 3
            12'd464 : toneL = 32'd831;  12'd465 : toneL = 32'd831;
            12'd466 : toneL = 32'd831;  12'd467 : toneL = 32'd831;
            12'd468 : toneL = 32'd831;  12'd469 : toneL = 32'd831;
            12'd470 : toneL = 32'd831;  12'd471 : toneL = 32'd831;
            12'd472 : toneL = 32'd831;  12'd473 : toneL = 32'd831;
            12'd474 : toneL = 32'd831;  12'd475 : toneL = 32'd831;
            12'd476 : toneL = 32'd831;  12'd477 : toneL = 32'd831;
            12'd478 : toneL = 32'd831;  12'd479 : toneL =    `sil;
            //11 1
            12'd480 : toneL = 32'd392;  12'd481 : toneL = 32'd392;
            12'd482 : toneL = 32'd392;  12'd483 : toneL = 32'd392;
            12'd484 : toneL = 32'd392;  12'd485 : toneL = 32'd392;
            12'd486 : toneL = 32'd392;  12'd487 : toneL =    `sil;
            12'd488 : toneL = 32'd659;  12'd489 : toneL = 32'd659;
            12'd490 : toneL = 32'd659;  12'd491 : toneL = 32'd659;
            12'd492 : toneL = 32'd659;  12'd493 : toneL = 32'd659;
            12'd494 : toneL = 32'd659;  12'd495 : toneL =    `sil;
            //11 2
            12'd496 : toneL = 32'd880;  12'd497 : toneL = 32'd880;
            12'd498 : toneL = 32'd880;  12'd499 : toneL = 32'd880;
            12'd500 : toneL = 32'd880;  12'd501 : toneL = 32'd880;
            12'd502 : toneL = 32'd880;  12'd503 : toneL = 32'd880;
            12'd504 : toneL = 32'd880;  12'd505 : toneL = 32'd880;
            12'd506 : toneL = 32'd880;  12'd507 : toneL = 32'd880;
            12'd508 : toneL = 32'd880;  12'd509 : toneL = 32'd880;
            12'd510 : toneL = 32'd880;  12'd511 : toneL = 32'd880;
            //11 3
            12'd512 : toneL = 32'd880;  12'd513 : toneL = 32'd880;
            12'd514 : toneL = 32'd880;  12'd515 : toneL = 32'd880;
            12'd516 : toneL = 32'd880;  12'd517 : toneL = 32'd880;
            12'd518 : toneL = 32'd880;  12'd519 : toneL = 32'd880;
            12'd520 : toneL = 32'd880;  12'd521 : toneL = 32'd880;
            12'd522 : toneL = 32'd880;  12'd523 : toneL = 32'd880;
            12'd524 : toneL = 32'd880;  12'd525 : toneL = 32'd880;
            12'd526 : toneL = 32'd880;  12'd527 : toneL =    `sil;
            //12 1
            12'd528 : toneL = 32'd370;  12'd529 : toneL = 32'd370;
            12'd530 : toneL = 32'd370;  12'd531 : toneL = 32'd370;
            12'd532 : toneL = 32'd370;  12'd533 : toneL = 32'd370;
            12'd534 : toneL = 32'd370;  12'd535 : toneL =    `sil;
            12'd536 : toneL = 32'd587;  12'd537 : toneL = 32'd587;
            12'd538 : toneL = 32'd587;  12'd539 : toneL = 32'd587;
            12'd540 : toneL = 32'd587;  12'd541 : toneL = 32'd587;
            12'd542 : toneL = 32'd587;  12'd543 : toneL =    `sil;
            //12 2
            12'd544 : toneL = 32'd740;  12'd545 : toneL = 32'd740;
            12'd546 : toneL = 32'd740;  12'd547 : toneL = 32'd740;
            12'd548 : toneL = 32'd740;  12'd549 : toneL = 32'd740;
            12'd550 : toneL = 32'd740;  12'd551 : toneL =    `sil;
            12'd552 : toneL = 32'd880;  12'd553 : toneL = 32'd880;
            12'd554 : toneL = 32'd880;  12'd555 : toneL = 32'd880;
            12'd556 : toneL = 32'd880;  12'd557 : toneL = 32'd880;
            12'd558 : toneL = 32'd880;  12'd559 : toneL =    `sil;
            //12 3
            12'd560 : toneL = 32'd1175;  12'd561 : toneL = 32'd1175;
            12'd562 : toneL = 32'd1175;  12'd563 : toneL = 32'd1175;
            12'd564 : toneL = 32'd1175;  12'd565 : toneL = 32'd1175;
            12'd566 : toneL = 32'd1175;  12'd567 : toneL = 32'd1175;
            12'd568 : toneL = 32'd1175;  12'd569 : toneL = 32'd1175;
            12'd570 : toneL = 32'd1175;  12'd571 : toneL = 32'd1175;
            12'd572 : toneL = 32'd1175;  12'd573 : toneL = 32'd1175;
            12'd574 : toneL = 32'd1175;  12'd575 : toneL =     `sil;
            //13 1
            12'd576 : toneL = 32'd349;  12'd577 : toneL = 32'd349;
            12'd578 : toneL = 32'd349;  12'd579 : toneL = 32'd349;
            12'd580 : toneL = 32'd349;  12'd581 : toneL = 32'd349;
            12'd582 : toneL = 32'd349;  12'd583 : toneL =    `sil;
            12'd584 : toneL = 32'd587;  12'd585 : toneL = 32'd587;
            12'd586 : toneL = 32'd587;  12'd587 : toneL = 32'd587;
            12'd588 : toneL = 32'd587;  12'd589 : toneL = 32'd587;
            12'd590 : toneL = 32'd587;  12'd591 : toneL =    `sil;
            //13 2
            12'd592 : toneL = 32'd880;  12'd593 : toneL = 32'd880;
            12'd594 : toneL = 32'd880;  12'd595 : toneL = 32'd880;
            12'd596 : toneL = 32'd880;  12'd597 : toneL = 32'd880;
            12'd598 : toneL = 32'd880;  12'd599 : toneL = 32'd880;
            12'd600 : toneL = 32'd880;  12'd601 : toneL = 32'd880;
            12'd602 : toneL = 32'd880;  12'd603 : toneL = 32'd880;
            12'd604 : toneL = 32'd880;  12'd605 : toneL = 32'd880;
            12'd606 : toneL = 32'd880;  12'd607 : toneL = 32'd880;
            //13 3
            12'd608 : toneL = 32'd880;  12'd609 : toneL = 32'd880;
            12'd610 : toneL = 32'd880;  12'd611 : toneL = 32'd880;
            12'd612 : toneL = 32'd880;  12'd613 : toneL = 32'd880;
            12'd614 : toneL = 32'd880;  12'd615 : toneL = 32'd880;
            12'd616 : toneL = 32'd880;  12'd617 : toneL = 32'd880;
            12'd618 : toneL = 32'd880;  12'd619 : toneL = 32'd880;
            12'd620 : toneL = 32'd880;  12'd621 : toneL = 32'd880;
            12'd622 : toneL = 32'd880;  12'd623 : toneL =    `sil;
            //14 1
            12'd624 : toneL = 32'd330;  12'd625 : toneL = 32'd330;
            12'd626 : toneL = 32'd330;  12'd627 : toneL = 32'd330;
            12'd628 : toneL = 32'd330;  12'd629 : toneL = 32'd330;
            12'd630 : toneL = 32'd330;  12'd631 : toneL =    `sil;
            12'd632 : toneL = 32'd523;  12'd633 : toneL = 32'd523;
            12'd634 : toneL = 32'd523;  12'd635 : toneL = 32'd523;
            12'd636 : toneL = 32'd523;  12'd637 : toneL = 32'd523;
            12'd638 : toneL = 32'd523;  12'd639 : toneL =    `sil;
            //14 2
            12'd640 : toneL = 32'd659;  12'd641 : toneL = 32'd659;
            12'd642 : toneL = 32'd659;  12'd643 : toneL = 32'd659;
            12'd644 : toneL = 32'd659;  12'd645 : toneL = 32'd659;
            12'd646 : toneL = 32'd659;  12'd647 : toneL =    `sil;
            12'd648 : toneL = 32'd880;  12'd649 : toneL = 32'd880;
            12'd650 : toneL = 32'd880;  12'd651 : toneL = 32'd880;
            12'd652 : toneL = 32'd880;  12'd653 : toneL = 32'd880;
            12'd654 : toneL = 32'd880;  12'd655 : toneL = 32'd880;
            //14 3
            12'd656 : toneL = 32'd880;  12'd657 : toneL = 32'd880;
            12'd658 : toneL = 32'd880;  12'd659 : toneL = 32'd880;
            12'd660 : toneL = 32'd880;  12'd661 : toneL = 32'd880;
            12'd662 : toneL = 32'd880;  12'd663 : toneL = 32'd880;
            12'd664 : toneL = 32'd880;  12'd665 : toneL = 32'd880;
            12'd666 : toneL = 32'd880;  12'd667 : toneL = 32'd880;
            12'd668 : toneL = 32'd880;  12'd669 : toneL = 32'd880;
            12'd670 : toneL = 32'd880;  12'd671 : toneL =    `sil;
            //15 1
            12'd672 : toneL = 32'd330;  12'd673 : toneL = 32'd330;
            12'd674 : toneL = 32'd330;  12'd675 : toneL = 32'd330;
            12'd676 : toneL = 32'd330;  12'd677 : toneL = 32'd330;
            12'd678 : toneL = 32'd330;  12'd679 : toneL =    `sil;
            12'd680 : toneL = 32'd494;  12'd681 : toneL = 32'd494;
            12'd682 : toneL = 32'd494;  12'd683 : toneL = 32'd494;
            12'd684 : toneL = 32'd494;  12'd685 : toneL = 32'd494;
            12'd686 : toneL = 32'd494;  12'd687 : toneL =    `sil;
            //15 2
            12'd688 : toneL = 32'd659;  12'd689 : toneL = 32'd659;
            12'd690 : toneL = 32'd659;  12'd691 : toneL = 32'd659;
            12'd692 : toneL = 32'd659;  12'd693 : toneL = 32'd659;
            12'd694 : toneL = 32'd659;  12'd695 : toneL =    `sil;
            12'd696 : toneL = 32'd740;  12'd697 : toneL = 32'd740;
            12'd698 : toneL = 32'd740;  12'd699 : toneL = 32'd740;
            12'd700 : toneL = 32'd740;  12'd701 : toneL = 32'd740;
            12'd702 : toneL = 32'd740;  12'd703 : toneL =    `sil;
            //15 3
            12'd704 : toneL = 32'd330;  12'd705 : toneL = 32'd330;
            12'd706 : toneL = 32'd330;  12'd707 : toneL = 32'd330;
            12'd708 : toneL = 32'd330;  12'd709 : toneL = 32'd330;
            12'd710 : toneL = 32'd330;  12'd711 : toneL = 32'd330;
            12'd712 : toneL = 32'd330;  12'd713 : toneL = 32'd330;
            12'd714 : toneL = 32'd330;  12'd715 : toneL = 32'd330;
            12'd716 : toneL = 32'd330;  12'd717 : toneL = 32'd330;
            12'd718 : toneL = 32'd330;  12'd719 : toneL =    `sil;
            //16 1
            12'd720 : toneL = 32'd220;  12'd721 : toneL = 32'd220;
            12'd722 : toneL = 32'd220;  12'd723 : toneL = 32'd220;
            12'd724 : toneL = 32'd220;  12'd725 : toneL = 32'd220;
            12'd726 : toneL = 32'd220;  12'd727 : toneL =    `sil;
            12'd728 : toneL = 32'd330;  12'd729 : toneL = 32'd330;
            12'd730 : toneL = 32'd330;  12'd731 : toneL = 32'd330;
            12'd732 : toneL = 32'd330;  12'd733 : toneL = 32'd330;
            12'd734 : toneL = 32'd330;  12'd735 : toneL =    `sil;
            //16 2
            12'd736 : toneL = 32'd440;  12'd737 : toneL = 32'd440;
            12'd738 : toneL = 32'd440;  12'd739 : toneL = 32'd440;
            12'd740 : toneL = 32'd440;  12'd741 : toneL = 32'd440;
            12'd742 : toneL = 32'd440;  12'd743 : toneL =    `sil;
            12'd744 : toneL = 32'd494;  12'd745 : toneL = 32'd494;
            12'd746 : toneL = 32'd494;  12'd747 : toneL = 32'd494;
            12'd748 : toneL = 32'd494;  12'd749 : toneL = 32'd494;
            12'd750 : toneL = 32'd494;  12'd751 : toneL =    `sil;
            //16 3
            12'd752 : toneL = 32'd523;  12'd753 : toneL = 32'd523;
            12'd754 : toneL = 32'd523;  12'd755 : toneL = 32'd523;
            12'd756 : toneL = 32'd523;  12'd757 : toneL = 32'd523;
            12'd758 : toneL = 32'd523;  12'd759 : toneL =    `sil;
            12'd760 : toneL = 32'd659;  12'd761 : toneL = 32'd659;
            12'd762 : toneL = 32'd659;  12'd763 : toneL = 32'd659;
            12'd764 : toneL = 32'd659;  12'd765 : toneL = 32'd659;
            12'd766 : toneL = 32'd659;  12'd767 : toneL =    `sil;
            //17 1
            12'd768 : toneL = 32'd880;  12'd769 : toneL = 32'd880;
            12'd770 : toneL = 32'd880;  12'd771 : toneL = 32'd880;
            12'd772 : toneL = 32'd880;  12'd773 : toneL = 32'd880;
            12'd774 : toneL = 32'd880;  12'd775 : toneL = 32'd880;
            12'd776 : toneL = 32'd880;  12'd777 : toneL = 32'd880;
            12'd778 : toneL = 32'd880;  12'd779 : toneL = 32'd880;
            12'd780 : toneL = 32'd880;  12'd781 : toneL = 32'd880;
            12'd782 : toneL = 32'd880;  12'd783 : toneL = 32'd880;
            //17 2
            12'd784 : toneL = 32'd880;  12'd785 : toneL = 32'd880;
            12'd786 : toneL = 32'd880;  12'd787 : toneL = 32'd880;
            12'd788 : toneL = 32'd880;  12'd789 : toneL = 32'd880;
            12'd790 : toneL = 32'd880;  12'd791 : toneL = 32'd880;
            12'd792 : toneL = 32'd880;  12'd793 : toneL = 32'd880;
            12'd794 : toneL = 32'd880;  12'd795 : toneL = 32'd880;
            12'd796 : toneL = 32'd880;  12'd797 : toneL = 32'd880;
            12'd798 : toneL = 32'd880;  12'd799 : toneL = 32'd880;
            //17 3
            12'd800 : toneL = 32'd880;  12'd801 : toneL = 32'd880;
            12'd802 : toneL = 32'd880;  12'd803 : toneL = 32'd880;
            12'd804 : toneL = 32'd880;  12'd805 : toneL = 32'd880;
            12'd806 : toneL = 32'd880;  12'd807 : toneL = 32'd880;
            12'd808 : toneL = 32'd880;  12'd809 : toneL = 32'd880;
            12'd810 : toneL = 32'd880;  12'd811 : toneL = 32'd880;
            12'd812 : toneL = 32'd880;  12'd813 : toneL = 32'd880;
            12'd814 : toneL = 32'd880;  12'd815 : toneL =    `sil;
            //18 1
            12'd816 : toneL =    `sil;  12'd817 : toneL =    `sil;
            12'd818 : toneL =    `sil;  12'd819 : toneL =    `sil;
            12'd820 : toneL =    `sil;  12'd821 : toneL =    `sil;
            12'd822 : toneL =    `sil;  12'd823 : toneL =    `sil;
            12'd824 : toneL =    `sil;  12'd825 : toneL =    `sil;
            12'd826 : toneL =    `sil;  12'd827 : toneL =    `sil;
            12'd828 : toneL =    `sil;  12'd829 : toneL =    `sil;
            12'd830 : toneL =    `sil;  12'd831 : toneL =    `sil;
            //18 2
            12'd832 : toneL =    `sil;  12'd833 : toneL =    `sil;
            12'd834 : toneL =    `sil;  12'd835 : toneL =    `sil;
            12'd836 : toneL =    `sil;  12'd837 : toneL =    `sil;
            12'd838 : toneL =    `sil;  12'd839 : toneL =    `sil;
            12'd840 : toneL =    `sil;  12'd841 : toneL =    `sil;
            12'd842 : toneL =    `sil;  12'd843 : toneL =    `sil;
            12'd844 : toneL =    `sil;  12'd845 : toneL =    `sil;
            12'd846 : toneL =    `sil;  12'd847 : toneL =    `sil;
            //18 3
            12'd848 : toneL =    `sil;  12'd849 : toneL =    `sil;
            12'd850 : toneL =    `sil;  12'd851 : toneL =    `sil;
            12'd852 : toneL =    `sil;  12'd853 : toneL =    `sil;
            12'd854 : toneL =    `sil;  12'd855 : toneL =    `sil;
            12'd856 : toneL =    `sil;  12'd857 : toneL =    `sil;
            12'd858 : toneL =    `sil;  12'd859 : toneL =    `sil;
            12'd860 : toneL =    `sil;  12'd861 : toneL =    `sil;
            12'd862 : toneL =    `sil;  12'd863 : toneL =    `sil;
            default : toneL =    `sil;
        endcase
    end

endmodule

module Sound_effect (
    input [11:0] ibeat_s,
    output reg [31:0] toneL_s
);
    always @* begin
        case(ibeat_s)
            //1 1
            12'd0   : toneL_s = 32'd988;  12'd1   : toneL_s = 32'd988;
            12'd2   : toneL_s = 32'd988;  12'd3   : toneL_s =    `sil;
            12'd4   : toneL_s = 32'd1319;  12'd5   : toneL_s = 32'd1319;
            12'd6   : toneL_s = 32'd1319;  12'd7   : toneL_s = 32'd1319;
            12'd8   : toneL_s = 32'd1319;  12'd9   : toneL_s = 32'd1319;
            12'd10  : toneL_s = 32'd1319;  12'd11  : toneL_s = 32'd1319;
            12'd12  : toneL_s = 32'd1319;  12'd13  : toneL_s = 32'd1319;
            12'd14  : toneL_s = 32'd1319;  12'd15  : toneL_s = 32'd1319;
            //1 2
            12'd16  : toneL_s = 32'd1319;  12'd17  : toneL_s = 32'd1319;
            12'd18  : toneL_s = 32'd1319;  12'd19  : toneL_s = 32'd1319;
            12'd20  : toneL_s = 32'd1319;  12'd21  : toneL_s = 32'd1319;
            12'd22  : toneL_s = 32'd1319;  12'd23  : toneL_s = 32'd1319;
            12'd24  : toneL_s = 32'd1319;  12'd25  : toneL_s = 32'd1319;
            12'd26  : toneL_s = 32'd1319;  12'd27  : toneL_s = 32'd1319;
            12'd28  : toneL_s = 32'd1319;  12'd29  : toneL_s = 32'd1319;
            12'd30  : toneL_s = 32'd1319;  12'd31  : toneL_s =    `sil;
            //1 3
            12'd32  : toneL_s = 32'd1319;  12'd33  : toneL_s = 32'd1319;
            12'd34  : toneL_s = 32'd1319;  12'd35  : toneL_s = 32'd1319;
            12'd36  : toneL_s = 32'd1319;  12'd37  : toneL_s = 32'd1319;
            12'd38  : toneL_s = 32'd1319;  12'd39  : toneL_s =    `sil;
            12'd40  : toneL_s =    `sil;  12'd41  : toneL_s =    `sil;
            12'd42  : toneL_s =    `sil;  12'd43  : toneL_s =    `sil;
            12'd44  : toneL_s =    `sil;  12'd45  : toneL_s =    `sil;
            12'd46  : toneL_s =    `sil;  12'd47  : toneL_s =    `sil;
            //1 4
            12'd48  : toneL_s =    `sil;  12'd49  : toneL_s =    `sil;
            12'd50  : toneL_s =    `sil;  12'd51  : toneL_s =    `sil;
            12'd52  : toneL_s =    `sil;  12'd53  : toneL_s =    `sil;
            12'd54  : toneL_s =    `sil;  12'd55  : toneL_s =    `sil;
            12'd56  : toneL_s =    `sil;  12'd57  : toneL_s =    `sil;
            12'd58  : toneL_s =    `sil;  12'd59  : toneL_s =    `sil;
            12'd60  : toneL_s =    `sil;  12'd61  : toneL_s =    `sil;
            12'd62  : toneL_s =    `sil;  12'd63  : toneL_s =    `sil;
        endcase
    end

endmodule

module Note_gen(
    input clk, // clock from crystal
    input rst, // active high reset
    input [2:0] volume, 
    input [21:0] note_div_left, // div for note generation
    input [21:0] note_div_right,
    output reg [15:0] audio_left,
    output reg [15:0] audio_right
    );

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    // note_div_left == 22'd1 when silent
    always @(*) begin
        if(note_div_left == 22'd1) audio_left = 16'h0000;
        else begin
            if(b_clk == 1'b0) begin
                case (volume)
                    3'd0: audio_left = 16'h2000;
                    3'd1: audio_left = 16'h3000;
                    3'd2: audio_left = 16'h4000;
                    3'd3: audio_left = 16'h5000;
                    3'd4: audio_left = 16'h6000;
                    3'd5: audio_left = 16'h7000;
                    default: audio_left = 16'h2000;
                endcase
            end
            else audio_left = 16'h2000;
        end
    end
    always @(*) begin
        if(note_div_right == 22'd1) audio_right = 16'h0000;
        else begin
            if(c_clk == 1'b0) begin
                case (volume)
                    3'd0: audio_right = 16'h2000;
                    3'd1: audio_right = 16'h3000;
                    3'd2: audio_right = 16'h4000;
                    3'd3: audio_right = 16'h5000;
                    3'd4: audio_right = 16'h6000;
                    3'd5: audio_right = 16'h7000;
                    default: audio_right = 16'h2000;
                endcase
            end
            else audio_right = 16'h2000;
        end
    end
endmodule

module Speaker_control(
    input clk,  // clock from the crystal
    input rst,  // active high reset
    input [15:0] audio_in_left, // left channel audio data input
    input [15:0] audio_in_right, // right channel audio data input
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    output audio_sck, // serial clock
    output reg audio_sdin // serial audio data input
    ); 

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule