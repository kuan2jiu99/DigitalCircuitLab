module keyboard_buffer(key_out, ps2d, ps2c, clk_50mhz, reset);
    input ps2d, ps2c, clk_50mhz, reset;
    output [7:0] key_out;
	
    wire ps2d, ps2c, clk_50mhz;
    reg [7:0] key_out;
    reg [7:0] last_key;
    wire [7:0] key_code;
	
    ps2key ps2(clk_50mhz, ps2d, ps2c, key_code);
    reg key_down;

    always @(posedge clk_50mhz) begin
	if(reset) begin
	    key_out <= 8'h00;
	    key_down <= 1'b0;
	    last_key <= key_code;
	end
	else begin
	    if (last_key == key_code) 
	    key_out <= key_code;
	    key_down <= 1'b1;
	    last_key <= key_code;
	end

    end

endmodule
