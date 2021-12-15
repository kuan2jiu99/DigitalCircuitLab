module pac_man_move (
	input        i_clk,
	input        i_rst,
	input [3:0] command,
	output [2:0] p_x,
	output [2:0] p_y
);


logic [2:0] cur_x;
logic [2:0] cur_y;

// ===== Sequential Circuits =====
always_ff @(posedge i_clk) begin
	// reset
	if (i_rst) begin
		p_x <= 3'd4;
		p_y <= 3'd4;
		cur_x <= 3'd4;
		cur_y <= 3'd4;
	end
	else begin
		case(command)
			4'b0001: // up
				if (cur_y - 1'b1 >= 0) begin
					cur_y <= cur_y - 1'b1;
					p_x <= cur_x;
					p_y <= cur_y;
				end
				else begin
					p_x <= cur_x;
					p_y <= cur_y;
				end
				
			
			4'b0010: // down
				if (cur_y + 1'b1 <= 4) begin
					cur_y <= cur_y + 1'b1;
					p_x <= cur_x;
					p_y <= cur_y;
				end
				else begin
					p_x <= cur_x;
					p_y <= cur_y;
				end
			
			4'b0100: // left
				if (cur_x - 1'b1 >= 0) begin
					cur_x <= cur_x - 1'b1;
					p_x <= cur_x;
					p_y <= cur_y;
				end
				else begin
					p_x <= cur_x;
					p_y <= cur_y;
				end
			
			4'b1000: // right
				if (cur_x + 1'b1 <= 4) begin
					cur_x <= cur_x + 1'b1;
					p_x <= cur_x;
					p_y <= cur_y;
				end
				else begin
					p_x <= cur_x;
					p_y <= cur_y;
				end
				
			default: begin
					p_x <= cur_x;
					p_y <= cur_y;
			end 
			
			endcase
		
	end
end

endmodule