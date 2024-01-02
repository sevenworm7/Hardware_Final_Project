module Seven_segment (
    input rst,
    input div_15,
    input [15:0] num,
    output reg [6:0] DISPLAY,
    output reg [3:0] DIGIT
);
    reg [3:0] display_num;

    always @(posedge div_15 or posedge rst) begin
        if(rst) DIGIT <= 4'b1111;
        else begin
            case (DIGIT)
                4'b1110: DIGIT <= 4'b1101;
                4'b1101: DIGIT <= 4'b1011;
                4'b1011: DIGIT <= 4'b0111;
                4'b0111: DIGIT <= 4'b1110;
                default: DIGIT <= 4'b1110;
            endcase
        end
    end

    always @(*) begin
        case (DIGIT)
            4'b1110: display_num = num[3:0];
            4'b1101: display_num = num[7:4];
            4'b1011: display_num = num[11:8];
            4'b0111: display_num = num[15:12];
            default: display_num = 4'd10;
        endcase
    end

    always @(*) begin
        case (display_num)
            4'd0:    DISPLAY = 7'b1000000;
			4'd1:    DISPLAY = 7'b1111001;
			4'd2:    DISPLAY = 7'b0100100;
			4'd3:    DISPLAY = 7'b0110000;
			4'd4:    DISPLAY = 7'b0011001;
			4'd5:    DISPLAY = 7'b0010010;
			4'd6:    DISPLAY = 7'b0000010;
			4'd7:    DISPLAY = 7'b1111000;
			4'd8:    DISPLAY = 7'b0000000;
			4'd9:    DISPLAY = 7'b0010000;
			4'd10:   DISPLAY = 7'b0111111; //'-'
            default: DISPLAY = 7'b0111111;
        endcase
    end
    
endmodule