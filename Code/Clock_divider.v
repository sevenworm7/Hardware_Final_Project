module Clock_divider #(parameter n = 27)(
    input wire clk,
    output wire div_2,
    output wire div_15, 
    output wire div_22,
    output wire div_hsec
);
    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) num <= next_num;
    assign next_num = num + 1;

    assign div_2 = num[1];
    assign div_15 = num[14];
    assign div_22 = num[21];

    second_divider sd(.clk(clk), .div_hsec(div_hsec));
endmodule

module second_divider (
    input wire clk,
    output reg div_hsec
);
    reg [25:0] counter;
    always @(posedge clk) begin
        if(counter < 25000000) begin
            counter <= counter + 1'b1;
            div_hsec <= div_hsec;
        end
        else begin
            counter <= 1'b0;
            div_hsec <= !div_hsec;
        end
    end
endmodule