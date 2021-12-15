// Test Tile Version, chase mode.

module GhostAlgo ( // test version
    input i_clk,
    input i_rst,
    input [5:0] pac_x,
    input [5:0] pac_y,
    input [3:0] random,
    
    output [5:0] o_x_location,
    output [5:0] o_y_location,
    output reach
    
);

logic [3:0] i_board [0:35][0:27];

// 6bit -> location

// Tile: 36x28
// Pixel: 288x224

// * 0 1 0 1
// 1 0 0 1 0
// 1 1 0 1 0
// 1 0 0 0 0
// 1 0 0 1 X

//    0 1 2 3 4
// 0: G 0 0 0 0
// 1: 0 0 0 0 0
// 2: 0 0 0 0 0
// 3: 0 0 0 0 0
// 4: 0 0 0 0 P

parameter ROW = 6'd36;
parameter COL = 6'd28;

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_x_location <= 3'd0;
        o_y_location <= 3'd0;
        
        reach <= 1'b0;
    end
    
    else begin
		 if (o_x_location == pac_x && o_y_location == pac_y) begin // catch target.
			  reach <= 1'b1;
			  o_x_location <= o_x_location;
			  o_y_location <= o_y_location;
		 end
		 
		 else if (o_x_location < pac_x && o_y_location < pac_y) begin
                          reach = 1'b0;
			  if (random % 2 == 0) begin // right
                                if (o_x_location + 1'b1 < ROW && i_board[o_x_location + 1'b1][o_y_location] == 0) begin
					o_x_location <= o_x_location + 1'b1;
                                end
			  end
			  else begin // down
                                if (o_y_location + 1'b1 < COL && i_board[o_x_location][o_y_location + 1'b1] == 0) begin
					o_y_location <= o_y_location + 1'b1;
                                end
                                
                                
                                else begin
                                    if (o_x_location - 1'b1 >= 0 && i_board[o_x_location - 1'b1][o_y_location] == 0) begin
                                        o_x_location <= o_x_location - 1'b1;  // left
                                    end
                                    else begin
                                        o_y_location <= o_y_location - 1'b1;  // up
                                    end
                                end
                                
			  end
		 end
		 
		 else if (o_x_location > pac_x && o_y_location > pac_y) begin
                          reach = 1'b0;
			  if (random % 2 == 0) begin // left
					o_x_location = o_x_location - 1'b1;
			  end
			  else begin // up
					o_y_location = o_y_location - 1'b1;
			  end
			  
		 end
		 
		 else if (o_x_location > pac_x && o_y_location < pac_y) begin
				reach = 1'b0;
			  if (random % 2 == 0) begin // left
					o_x_location = o_x_location - 1'b1;
			  end
			  else begin // up
					o_y_location = o_y_location + 1'b1;
			  end
			  
		 end
		 
		 else if (o_x_location < pac_x && o_y_location > pac_y) begin
				reach = 1'b0;
			  if (random % 2 == 0) begin // left
					o_x_location = o_x_location + 1'b1;
			  end
			  else begin // up
					o_y_location = o_y_location - 1'b1;
			  end
			  
		 end
		 
		 else if (o_x_location == pac_x && o_y_location < pac_y) begin
				reach = 1'b0;
			  o_y_location = o_y_location + 1'b1;
		 end
		 
		 else if (o_x_location == pac_x && o_y_location > pac_y) begin
				reach = 1'b0;
			  o_y_location = o_y_location - 1'b1;
		 end
		 
		 else if (o_y_location == pac_y && o_x_location < pac_x) begin
				reach = 1'b0;
			  o_x_location = o_x_location + 1'b1;
		 end
		 
		 else if (o_y_location == pac_y && o_x_location > pac_x) begin
				reach = 1'b0;
			  o_x_location = o_x_location - 1'b1;
		 end
		 
		 else begin
				reach = 1'b0;
			  o_x_location = 3'd0;
			  o_y_location = 3'd0;
		 end
        
    end
end
        

endmodule
