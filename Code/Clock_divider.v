module Clock_divider #(parameter n = 27)(
    input wire clk,
    output wire div_2,
    output wire div_15  
);
    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) num <= next_num;
    assign next_num = num + 1;

    assign div_2 = num[1];
    assign div_15 = num[14];
endmodule