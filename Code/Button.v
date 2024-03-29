module Button (
    input div_15,
    input volUP_btn,
    input volDOWN_btn,
    output volUP,
    output volDOWN
);
	wire volUP_t, volDOWN_t;

	debounce d_volup(.clk(div_15), .pb(volUP_btn), .pb_debounced(volUP_t));
	one_pulse op_volup(.clk(div_15), .pb_in(volUP_t), .pb_out(volUP));

	debounce d_voldown(.clk(div_15), .pb(volDOWN_btn), .pb_debounced(volDOWN_t));
	one_pulse op_voldown(.clk(div_15), .pb_in(volDOWN_t), .pb_out(volDOWN));
endmodule

module debounce (
	input wire clk,
	input wire pb, 
	output wire pb_debounced 
);
	reg [3:0] shift_reg; 

	always @(posedge clk) begin
		shift_reg[3:1] <= shift_reg[2:0];
		shift_reg[0] <= pb;
	end

	assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);
endmodule

module one_pulse (
    input wire clk,
    input wire pb_in,
    output reg pb_out
);
	reg pb_in_delay;

	always @(posedge clk) begin
		if (pb_in == 1'b1 && pb_in_delay == 1'b0) begin
			pb_out <= 1'b1;
		end else begin
			pb_out <= 1'b0;
		end
	end
	
	always @(posedge clk) begin
		pb_in_delay <= pb_in;
	end
endmodule
