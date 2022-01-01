// Ghost Algorithm for chase, scatter, frightened mode. 
// Pixel version.
module GhostAlgo_Inky ( 
    input i_clk,
    input i_rst,
    input [9:0] pac_x, // 10 bits.
    input [9:0] pac_y, // 10 bits.
    input [7:0] i_board [0:35][0:27], // map.
    input [3:0] i_mode, // chase, frightened, scatter.
	 input [3:0] random_move_2, // random 2 choice.
	 input [3:0] random_move_3, // random 3 choice.
	 input [1:0] pac_direction,
	 input [9:0] blinky_x,
	 input [9:0] blinky_y,
    output [9:0] o_x_location, // 10 bits.
    output [9:0] o_y_location, // 10 bits.
    output reach, // reach the target.
    output [1:0] next_direction, // ghost move's direction.
    output [9:0] test_distance, // debug for distance calculatuon.
    output illegal, // debug for visit on illegal tile.
    output [3:0] case_num, // debug for the categories of intersections.
    output [3:0] mode_state // debug for different mode state.
);

// next move direction.
parameter UP = 2'b00;
parameter DOWN = 2'b01;
parameter LEFT = 2'b10;
parameter RIGHT = 2'b11;
 
// game mode.
parameter MODE_CHASE = 4'd0;
parameter MODE_SCATTER = 4'd1;
parameter MODE_FRIGHTENED = 4'd2;


logic right_next, left_next, up_next, down_next;

logic target1; // scatter mode, reach ghost's home target.

// the distance between ghost and target.
logic [22:0] up_distance;  
logic [22:0] down_distance;
logic [22:0] left_distance;
logic [22:0] right_distance;

// can be simplified.
// the distance between ghost and home target.
logic [22:0] up_distance2;  
logic [22:0] down_distance2;
logic [22:0] left_distance2;
logic [22:0] right_distance2;

// count = 8, then walk through a tile.
logic [3:0] count;

// mode state.
logic [3:0] state;
assign mode_state = state;

logic [3:0] tile;

// the target of Clyde depends on its distance from pac-man.
logic [9:0] target_x;
logic [9:0] target_y;

// check the distance between Clyde and Pac-man >= 8 (Chase) or < 8 (Scatter).
logic chase_like_blinky;

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

// tile bound.
parameter ROW = 6'd36;
parameter COL = 6'd28;

// scatter mode.
//parameter inky_target_x = 9'd252;
//parameter inky_target_y = 9'd204;


assign illegal = (i_board[(o_x_location + 4) >> 3][(o_y_location + 4) >> 3] == 1'b0)? 1'b0: 1'b1;

assign test_distance = distance(pac_x, pac_y, o_x_location, o_y_location);

// calculate Norm2 distance by tile for pinky.
function [11:0] distance_pinky;
	 input [9:0] pac_x;  // the x-coordination of pac-man.
    input [9:0] pac_y;  // the y-coordination of pac-man.
    input [9:0] o_x_location; // the x-coordination of ghost.
    input [9:0] o_y_location; // the y-coordination of ghost.
	 input [1:0] next_direction // pac-man direction.
	 
	 logic [5:0] pac_tile_x;
	 logic [5:0] pac_tile_y;
	 
	 logic [5:0] ghost_tile_x;
	 logic [5:0] ghost_tile_y;
	 
	 logic [5:0] target_tile_x;
	 logic [5:0] target_tile_y;
	 
	 logic [5:0] abs_x; // absolute value of distance in the x-coordination.
    logic [5:0] abs_y; // absolute value of distance in the y-coordination.
    
	 
	 pac_tile_x = (pac_x + 3'd4) >> 3;
	 pac_tile_y = (pac_x + 3'd4) >> 3;
	 
	 ghost_tile_x = (o_x_location + 3'd4) >> 3;
	 ghost_tile_y = (o_y_location + 3'd4) >> 3;
	 
	 if (next_direction == LEFT) begin 
	     target_tile_x = (pac_tile_x - 3'd4 >= 0)? (pac_tile_x - 3'd4): pac_tile_x;
		  target_tile_y = pac_tile_y;
	 end
	 else if (next_direction == RIGHT) begin
	     target_tile_x = (pac_tile_x + 3'd4 < ROW)? (pac_tile_x + 3'd4): pac_tile_x;
		  target_tile_y = pac_tile_y;
	 end
	 else if (next_direction == UP) begin
	     target_tile_y = (pac_tile_y - 3'd4 >= 0)? (pac_tile_y - 3'd4): pac_tile_y;
		  target_tile_x = pac_tile_x;
	 end
	 else begin
	     target_tile_y = (pac_tile_y + 3'd4 < COL)? (pac_tile_y + 3'd4): pac_tile_y;
		  target_tile_x = pac_tile_x;
	 end
	 
	 if (target_tile_x >= ghost_tile_x) begin
	     abs_x = target_tile_x - ghost_tile_x;
	 end
	 
	 else begin
		  abs_x = ghost_tile_x - target_tile_x; 
	 end
	 
	 if (target_tile_y >= ghost_tile_y) begin
	     abs_y = target_tile_y - ghost_tile_y;
	 end
	 
	 else begin
		  abs_y = ghost_tile_y - target_tile_y; 
	 end
	 
	 distance = abs_x * abs_x + abs_y * abs_y;
	 
endfunction



// calculate Norm2 distance by tile.
function [11:0] distance;
	 input [9:0] pac_x;  // the x-coordination of pac-man.
    input [9:0] pac_y;  // the y-coordination of pac-man.
    input [9:0] o_x_location; // the x-coordination of ghost.
    input [9:0] o_y_location; // the y-coordination of ghost.
	 
	 logic [5:0] pac_tile_x;
	 logic [5:0] pac_tile_y;
	 
	 logic [5:0] ghost_tile_x;
	 logic [5:0] ghost_tile_y;
	 
	 logic [5:0] abs_x; // absolute value of distance in the x-coordination.
    logic [5:0] abs_y; // absolute value of distance in the y-coordination.
    
	 
	 pac_tile_x = (pac_x + 3'd4) >> 3;
	 pac_tile_y = (pac_x + 3'd4) >> 3;
	 
	 ghost_tile_x = (o_x_location + 3'd4) >> 3;
	 ghost_tile_y = (o_y_location + 3'd4) >> 3;
	 
	 if (pac_tile_x >= ghost_tile_x) begin
	     abs_x = pac_tile_x - ghost_tile_x;
	 end
	 
	 else begin
		  abs_x = ghost_tile_x - pac_tile_x; 
	 end
	 
	 if (pac_tile_y >= ghost_tile_y) begin
	     abs_y = pac_tile_y - ghost_tile_y;
	 end
	 
	 else begin
		  abs_y = ghost_tile_y - pac_tile_y; 
	 end
	 
	 distance = abs_x * abs_x + abs_y * abs_y;
	 
endfunction
	 
// calculate Norm2 distance by pixel
function [22:0] distance_pixel;
    input [9:0] pac_x;  // the x-coordination of pac-man.
    input [9:0] pac_y;  // the y-coordination of pac-man.
    input [9:0] o_x_location; // the x-coordination of ghost.
    input [9:0] o_y_location; // the y-coordination of ghost.
	 
    logic [9:0] abs_x; // absolute value of distance in the x-coordination.
    logic [9:0] abs_y; // absolute value of distance in the y-coordination.
    
    begin
        if (o_x_location >= pac_x) begin
            abs_x = o_x_location - pac_x;
        end
	else begin
            abs_x = pac_x - o_x_location;
        end
		  
        if (o_y_location >= pac_y) begin
            abs_y = o_y_location - pac_y;
        end
        else begin
            abs_y = pac_y - o_y_location;
        end
		  
        distance_pixel = abs_x * abs_x + abs_y * abs_y;
    end
    
endfunction

// determine the categories of intersection.
function [3:0] tile_situation;
    input [9:0] o_x_location; // the x-coordination of ghost.
    input [9:0] o_y_location; // the y-coordination of ghost.
    input [7:0] i_board [0:35][0:27]; // map.
    input [1:0] next_direction; // the direction of ghost.
	
    logic [5:0] tile_x; // the tile x-coordination of ghost.
    logic [5:0] tile_y; // the tile y-coordination of ghost.
    logic up, down, left, right; // up-tile, down-tile, left-tile, right-tile.
	
    tile_x = ((o_x_location + 3'd4) >> 3); // current tile.
    tile_y = ((o_y_location + 3'd4) >> 3);
		
    // 0 for road, 1 for non-road.
    if (tile_x - 1 >= 0) begin
        up = (i_board[tile_x - 1][tile_y] == 1'b0)? 1'b0: 1'b1;
    end
    else begin
        up = 1'b1; // boundary.
    end
    
    if (tile_x + 1 < ROW) begin
        down = (i_board[tile_x + 1][tile_y] == 1'b0)? 1'b0: 1'b1; // down tile.
    end
    else begin
        down = 1'b1; // boundary.
    end
    
    if (tile_y - 1 >= 0) begin
        left = (i_board[tile_x][tile_y - 1] == 1'b0)? 1'b0: 1'b1; // left tile.
    end
    else begin
        left = 1'b1; // boundary.
    end
    
    if (tile_y + 1 < COL) begin
        right = (i_board[tile_x][tile_y + 1] == 1'b0)? 1'b0: 1'b1; // right tile.
    end
    else begin
        right = 1'b1; // boundary.
    end
    
    tile_situation = {up, down, left, right};
	
endfunction







function [5:0] target_tile_y;

	
   input [9:0] pac_y;  // the y-coordination of pac-man.
   
   input [9:0] o_y_location; // the y-coordination of ghost. (blinky)
	input [1:0] pac_direction;
	
	logic [5:0] pac_tile_y;
	 
	
	logic [5:0] ghost_tile_y;
	
	
   logic [5:0] temp_y; // absolute value of distance in the y-coordination.
    
	 
	
	pac_tile_y = (pac_x + 3'd4) >> 3;
	 
	
	ghost_tile_y = (o_y_location + 3'd4) >> 3;
	
	if (pac_direction == LEFT) begin
	    temp_y = (pac_tile_y - 3'd2 >= 0)? (pac_tile_y - 3'd2): pac_tile_y;
		 target_tile_y = 2 * temp_y - ghost_tile_y;
	end
	else if (pac_direction == RIGHT) begin
		 temp_y = (pac_tile_y + 3'd2 < COL)? (pac_tile_y + 3'd2): pac_tile_y;
		 target_tile_y = 2 * temp_y - ghost_tile_y;
	end
	else if (pac_direction == UP) begin
		 temp_y = (pac_tile_y - 3'd2 >= 0)? (pac_tile_y - 3'd2): pac_tile_y;
		 target_tile_y = 2 * temp_y - ghost_tile_y;
	end
	else begin // down.
	    target_tile_y = 2 * pac_tile_y - ghost_tile_y;
	end
    

endfunction

function [5:0] target_tile_x;

	input [9:0] pac_x;  // the x-coordination of pac-man.
   
   input [9:0] o_x_location; // the x-coordination of ghost. (blinky)
   
	input [1:0] pac_direction;
	logic [5:0] pac_tile_x;
	
	 
	logic [5:0] ghost_tile_x;
	
	
	logic [5:0] temp_x; // absolute value of distance in the x-coordination.
   
    
	 
	pac_tile_x = (pac_x + 3'd4) >> 3;
	
	 
	ghost_tile_x = (o_x_location + 3'd4) >> 3;
	
	
	if (pac_direction == LEFT) begin
		 target_tile_x = 2 * pac_tile_x - ghost_tile_x;
	end
	else if (pac_direction == RIGHT) begin
		 target_tile_x = 2 * pac_tile_x - ghost_tile_x;
	end
	else if (pac_direction == UP) begin
		 temp_x = (pac_tile_x - 3'd2 >= 0)? (pac_tile_x - 3'd2): pac_tile_x;
		 target_tile_x = 2 * temp_x - ghost_tile_x;
	end
	else begin // down.
	    temp_x = (pac_tile_x + 3'd2 < ROW)? (pac_tile_x + 3'd2): pac_tile_x;
		 target_tile_x = 2 * temp_x - ghost_tile_x;
	end
    

endfunction
// the target of Clyde depends on its distance from pac-man.
assign target_x = target_tile_x(pac_x, blinky_x, pac_direction);
assign target_y = target_tile_x(pac_y, blinky_y, pac_direction);

// the categories of current tile.
assign tile = tile_situation(o_x_location, o_y_location, i_board, next_direction); // cow bei

// the distance between next-predict location of ghost and current location of pac-man.
assign right_distance = distance(target_x, target_y, o_x_location, o_y_location + 4'd8, pac_direction);
assign left_distance = distance(target_x, target_y, o_x_location, o_y_location - 4'd8, pac_ditection);
assign down_distance = distance(target_x, target_y, o_x_location + 4'd8, o_y_location, pac_direction);
assign up_distance = distance(target_x, target_y, o_x_location - 4'd8, o_y_location, pac_direction);

// the distance between next-predict location of ghost and its target location for scatter mode.
assign right_distance2 = distance(inky_target_x, inky_target_y, o_x_location, o_y_location + 4'd8);
assign left_distance2 = distance(inky_target_x, inky_target_y, o_x_location, o_y_location - 4'd8);
assign down_distance2 = distance(inky_target_x, inky_target_y, o_x_location + 4'd8, o_y_location);
assign up_distance2 = distance(inky_target_x, inky_target_y, o_x_location - 4'd8, o_y_location);

// go through the map, right to left, or, left to right.
assign right_to_left = (((o_x_location + 3'd4) >> 3) == 17 && ((o_y_location + 3'd4) >> 3) == 27 && next_direction == RIGHT)? 1'b1: 1'b0;
assign left_to_right = (((o_x_location + 3'd4) >> 3) == 17 && ((o_y_location + 3'd4) >> 3) == 0 && next_direction == LEFT)? 1'b1: 1'b0;


logic [9:0] inky_target_x;
logic [9:0] inky_target_y;

always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_x_location <= 9'd60; // ghost initial location.
        o_y_location <= 9'd100;
        
        state <= MODE_CHASE;
        
        left_next <= 1'b0;
        right_next <= 1'b1;
        up_next <= 1'b0;
        down_next <= 1'b0;
        
        next_direction <= RIGHT; // ghost initial move direction.
        
        reach <= 1'b0; // no reach.
        count <= 4'd0;
		  case_num <= 4'd0;
		  
		  target1 <= 1'b0;
 
    end
    
    else begin
        case(state)
            MODE_CHASE: begin
                if (o_x_location == pac_x && o_y_location == pac_y) begin // catch the target.
                    reach <= 1'b1;
                    count <= 4'd0;
                    // todo
                    
                end
                
                else begin
                    if (count == 4'd8) begin // count = 8, predict next move's next direction.
								
                        if (i_mode == MODE_SCATTER) begin
                            state <= MODE_SCATTER;
									 count <= 4'd8;
									 inky_target_x <= 9'd252;
									 inky_target_y <= 9'd204;
                        end
                        else if (i_mode == MODE_FRIGHTENED) begin
                            state <= MODE_FRIGHTENED;
									 count <= 4'd0; // ?
									 if (next_direction == LEFT) begin
									     next_direction <= RIGHT;
										  up_next <= 1'b0;
										  down_next <= 1'b0;
										  right_next <= 1'b1;
										  left_next <= 1'b0;
									 end
									 else if (next_direction == RIGHT) begin
									     next_direction <= LEFT;
										  up_next <= 1'b0;
										  down_next <= 1'b0;
										  right_next <= 1'b0;
										  left_next <= 1'b1;
									 end
									 else if (next_direction == UP) begin
									     next_direction <= DOWN;
										  up_next <= 1'b0;
										  down_next <= 1'b1;
										  right_next <= 1'b0;
										  left_next <= 1'b0;
									 end
									 else begin // down.
									     next_direction <= UP;
										  up_next <= 1'b1;
										  down_next <= 1'b0;
										  right_next <= 1'b0;
										  left_next <= 1'b0;
									 end
                        end
								
								else if (right_to_left == 1'b1) begin
								    o_x_location <= 10'd132; 
									 o_y_location <= 10'd212;
									 next_direction <= RIGHT;
									 up_next <= 1'b0;
									 down_next <= 1'b0;
									 right_next <= 1'b1;
									 left_next <= 1'b0;
								end
								
								else if (left_to_right == 1'b1) begin
									o_x_location <= 10'd132; 
									o_y_location <= 10'd220;
									next_direction <= LEFT;
									up_next <= 1'b0;
									down_next <= 1'b0;
									right_next <= 1'b0;
									left_next <= 1'b1;
								end
								
                        else begin // chase mode.
								
                            state <= MODE_CHASE;
                            count <= 4'd0;
                            case(next_direction)
                                
                                UP: begin
                                    // case 1.
                                    if (tile == 4'b0011) begin
                                        
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd1;
                                        
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b1010) begin
                                          
                                        next_direction <= RIGHT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b1;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd2;
                                    
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b1001) begin
                                        
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                        
                                        case_num <= 4'd3;
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b0010) begin
                                        
                                        
                                        case_num <= 4'd4;
                                        
                                        if (up_distance <= right_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b1000) begin
                                        
                                                
                                        case_num <= 4'd5;
                                        
                                        if (left_distance <= right_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end // end case 5.
                                    
                                    // case 6.
                                    else if (tile == 4'b0001) begin
                                        
                                        
                                        case_num <= 4'd6;
                                        
                                        if (up_distance <= left_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin
                                                
                                        case_num <= 4'd7;
                                                              
                                        
                                        if (up_distance <= left_distance && up_distance <= right_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else if (left_distance <= up_distance && left_distance <= right_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b1011) begin
                                                case_num <= 4'd8;
                                        next_direction <= DOWN;
                                        down_next <= 1'b1;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                    end
                            
                                end // end UP case.
                                
                                LEFT: begin
                                    // case 1.
                                    if (tile == 4'b1100) begin
                                         
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                                
                                        case_num <= 4'd1;
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b0000) begin
                                              
                                        
                                        case_num <= 4'd2;
                                        
                                        if (up_distance <= down_distance && up_distance <= left_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                                
                                        else if (left_distance <= up_distance && left_distance <= down_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                                
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b0010) begin
                                                 
                                        case_num <= 4'd3;
                                              
                                      
                                        if (up_distance <= down_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    
                                    // case 6.
                                    else if (tile == 4'b0100) begin
                                                 
                                        case_num <= 4'd6;
                                              
                                        
                                        if (up_distance <= left_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                    
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin
                                                
                                        case_num <= 4'd7;
                                              
                                       
                                        if (left_distance <= down_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                    
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b1010) begin
                                                 
                                        case_num <= 4'd5;
                                              
                                        next_direction <= DOWN;
                                        down_next <= 1'b1;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b0110) begin
                                          
                                        case_num <= 4'd4;
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;

                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b1110) begin
                                        next_direction <= RIGHT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b1;
                                        left_next <= 1'b0;
                                        case_num <= 4'd8;
                                    end
                                    
                                end // case LEFT end
                                
                                DOWN: begin
                                
                                    // case 1.
                                    if (tile == 4'b0011) begin
                                                 
                                                
                                        case_num <= 4'd1;
                                        next_direction <= DOWN;
                                        down_next <= 1'b1;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                        
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b0110) begin
                                         
                                        next_direction <= RIGHT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b1;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd2;
                                         
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b0101) begin
                                         
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                                
                                        case_num <= 4'd3;
                                        
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b0010) begin
                                        
                                        case_num <= 4'd4;
                                        if (down_distance <= right_distance) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                    
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b0100) begin
                                         
                                        case_num <= 4'd5;
                                        
                                        if (left_distance <= right_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 6.
                                    else if (tile == 4'b0001) begin
                                                
                                        case_num <= 4'd6;
                                        
                                        if (left_distance <= down_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin

                                        case_num <= 4'd7;
                                        
                                        if (left_distance <= right_distance && left_distance <= down_distance) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else if (down_distance <= left_distance && down_distance <= right_distance) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b0111) begin
                                        case_num <= 4'd8;
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                    end
                                    
                                end // case DOWN end
                                
                                RIGHT: begin
                                    // case 1.
                                    if (tile == 4'b1100) begin
                                         
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                                     
                                            case_num <= 4'd1;
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b1001) begin
                                            
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                                     
                                            case_num <= 4'd2;
                                         
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b0101) begin
                                         
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd3;
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b1000) begin
                                         
                                        
                                                
                                        case_num <= 4'd4;
                                        
                                        if (down_distance <= right_distance) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                                     
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                         
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b0001) begin
                                       
                                        case_num <= 4'd5;
                                        
                                        if (up_distance <= down_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    // case 6.
                                    else if (tile == 4'b0100) begin
                                          
                                        case_num <= 4'd6;
                                                
                                        
                                        if (up_distance <= right_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                         
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin
                                         
                                        case_num <= 4'd7;
                                                
                                        
                                        if (up_distance <= right_distance && up_distance <= down_distance) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else if (down_distance <= up_distance && down_distance <= right_distance) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                         
                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b1101) begin
                                        case_num <= 4'd8;
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                    end
                                    
                                end // case RIGHT end
                              
                            endcase
                        end 
                    end
                      
                      
                    else begin
                          reach <= 1'b0;
                          o_x_location <= o_x_location + down_next - up_next;
                          o_y_location <= o_y_location + right_next - left_next;
                        
                          count <= count + 1'b1;
                          
                     end
          

                end
            end // end mode chase.
            
            MODE_SCATTER: begin
                if (count == 4'd8) begin
							/*
							if (o_x_location == 9'd28 && o_y_location == 9'd204) begin
								if (next_direction == RIGHT) begin
									inky_target_x <= 9'd60;
									inky_target_y <= 9'd204;
								end
								else begin // up.
									inky_target_x <= 9'd28;
									inky_target_y <= 9'd164;
								end
								
							end
							
							else if (o_x_location == 9'd28 && o_y_location == 9'd164) begin
								if (next_direction == LEFT) begin
									inky_target_x <= 9'd60;
									inky_target_y <= 9'd164;
								end
								else begin // up.
									inky_target_x <= 9'd28;
									inky_target_y <= 9'd204;
								end
							end
							
							else if (o_x_location == 9'd60 && o_y_location == 9'd164) begin
								if (next_direction == RIGHT) begin
									inky_target_x <= 9'd28;
									inky_target_y <= 9'd164;
								end
								else begin // down.
									inky_target_x <= 9'd60;
									inky_target_y <= 9'd204;
								end
							end
							
							else if (o_x_location == 9'd60 && o_y_location == 9'd204) begin
								if (next_direction == RIGHT) begin
									inky_target_x <= 9'd28;
									inky_target_y <= 9'd204;
								end
								else begin // down.
									inky_target_x <= 9'd60;
									inky_target_y <= 9'd164;
								end
							end
							*/
							
					 
							if (i_mode == MODE_CHASE) begin
								state <= MODE_CHASE;
								count <= 4'd8;
							end
							
							else if (i_mode == MODE_FRIGHTENED) begin
								state <= MODE_FRIGHTENED;
								count <= 4'd0; //?
								
								if (next_direction == LEFT) begin
									 next_direction <= RIGHT;
									 up_next <= 1'b0;
									 down_next <= 1'b0;
									 right_next <= 1'b1;
									 left_next <= 1'b0;
								end
								else if (next_direction == RIGHT) begin
									 next_direction <= LEFT;
									 up_next <= 1'b0;
									 down_next <= 1'b0;
									 right_next <= 1'b0;
									 left_next <= 1'b1;
								end
								else if (next_direction == UP) begin
									 next_direction <= DOWN;
									 up_next <= 1'b0;
									 down_next <= 1'b1;
									 right_next <= 1'b0;
									 left_next <= 1'b0;
								end
								else begin // down.
									 next_direction <= UP;
									 up_next <= 1'b1;
									 down_next <= 1'b0;
									 right_next <= 1'b0;
									 left_next <= 1'b0;
								end
								
							end
							
							else if (o_x_location == 9'd252 && o_y_location == 9'd204) begin
								target1 <= 1'b1;
								count <= 4'd0;
								
								if (next_direction == DOWN) begin
									next_direction <= LEFT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b1;
								end
								else begin // right.
									next_direction <= UP;
									down_next <= 1'b0;
                           up_next <= 1'b1;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
							end
							
							else if (o_x_location == 9'd252 && o_y_location == 9'd116 && target1 == 1'b1) begin
								count <= 4'd0;
								
								if (next_direction == RIGHT) begin
									next_direction <= UP;
									down_next <= 1'b0;
                           up_next <= 1'b1;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
								else begin // down.
									next_direction <= RIGHT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b1;
                           left_next <= 1'b0;
								end
							end
							
							else if (o_x_location == 9'd228 && o_y_location == 9'd116 && target1 == 1'b1) begin
								count <= 4'd0;
							
								if (next_direction == UP) begin
									next_direction <= RIGHT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b1;
                           left_next <= 1'b0;
								end
								else begin // left.
									next_direction <= DOWN;
									down_next <= 1'b1;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
							end
							
							else if (o_x_location == 9'd228 && o_y_location == 9'd140 && target1 == 1'b1) begin
								count <= 4'd0;
							
								if (next_direction == RIGHT) begin
									next_direction <= UP;
									down_next <= 1'b0;
                           up_next <= 1'b1;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
								else begin // down.
									next_direction <= LEFT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b1;
								end
							end
							
							else if (o_x_location == 9'd204 && o_y_location == 9'd140 && target1 == 1'b1) begin
								count <= 4'd0;
							
								if (next_direction == UP) begin
									next_direction <= RIGHT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b1;
                           left_next <= 1'b0;
								end
								else begin // left.
									next_direction <= DOWN;
									down_next <= 1'b1;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
							end
							
							else if (o_x_location == 9'd204 && o_y_location == 9'd164 && target1 == 1'b1) begin
								count <= 4'd0;
							
								if (next_direction == RIGHT) begin
									next_direction <= DOWN;
									down_next <= 1'b1;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
								else begin // up.
									next_direction <= LEFT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b1;
								end
							end
							
							else if (o_x_location == 9'd228 && o_y_location == 9'd164 && target1 == 1'b1) begin
								count <= 4'd0;
							
								if (next_direction == DOWN) begin
									next_direction <= RIGHT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b1;
                           left_next <= 1'b0;
								end
								else begin // left.
									next_direction <= UP;
									down_next <= 1'b0;
                           up_next <= 1'b1;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
							end
							
							else if (o_x_location == 9'd228 && o_y_location == 9'd204 && target1 == 1'b1) begin
								count <= 4'd0;
							
								if (next_direction == RIGHT) begin
									next_direction <= DOWN;
									down_next <= 1'b1;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b0;
								end
								else begin // up.
									next_direction <= LEFT;
									down_next <= 1'b0;
                           up_next <= 1'b0;
                           right_next <= 1'b0;
                           left_next <= 1'b1;
								end
							end
							
							else begin// scatter mode.
								state <= MODE_SCATTER;
								count <= 4'd0;
								
								case(next_direction)
                                
                                UP: begin
                                    // case 1.
                                    if (tile == 4'b0011) begin
                                        
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd1;
                                        
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b1010) begin
                                          
                                        next_direction <= RIGHT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b1;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd2;
                                    
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b1001) begin
                                        
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                        
                                        case_num <= 4'd3;
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b0010) begin
                                        
                                        
                                        case_num <= 4'd4;
                                        
                                        if (up_distance2 <= right_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b1000) begin
                                        
                                                
                                        case_num <= 4'd5;
                                        
                                        if (left_distance2 <= right_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end // end case 5.
                                    
                                    // case 6.
                                    else if (tile == 4'b0001) begin
                                        
                                        
                                        case_num <= 4'd6;
                                        
                                        if (up_distance2 <= left_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin
                                                
                                        case_num <= 4'd7;
                                                              
                                        
                                        if (up_distance2 <= left_distance2 && up_distance2 <= right_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else if (left_distance2 <= up_distance2 && left_distance2 <= right_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b1011) begin
                                        case_num <= 4'd8;
                                        next_direction <= DOWN;
                                        down_next <= 1'b1;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                    end
                            
                                end // end UP case.
                                
                                LEFT: begin
                                    // case 1.
                                    if (tile == 4'b1100) begin
                                         
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                                
                                        case_num <= 4'd1;
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b0000) begin
                                              
                                        
                                        case_num <= 4'd2;
                                        
                                        if (up_distance2 <= down_distance2 && up_distance2 <= left_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                                
                                        else if (left_distance2 <= up_distance2 && left_distance2 <= down_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                                
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b0010) begin
                                                 
                                        case_num <= 4'd3;
                                              
                                      
                                        if (up_distance2 <= down_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    
                                    // case 6.
                                    else if (tile == 4'b0100) begin
                                                 
                                        case_num <= 4'd6;
                                              
                                        
                                        if (up_distance2 <= left_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                    
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin
                                                
                                        case_num <= 4'd7;
                                              
                                       
                                        if (left_distance2 <= down_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                    
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b1010) begin
                                                 
                                        case_num <= 4'd5;
                                              
                                        next_direction <= DOWN;
                                        down_next <= 1'b1;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b0110) begin
                                          
                                        case_num <= 4'd4;
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;

                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b1110) begin
                                        next_direction <= RIGHT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b1;
                                        left_next <= 1'b0;
                                        case_num <= 4'd8;
                                    end
                                    
                                end // case LEFT end
                                
                                DOWN: begin
                                
                                    // case 1.
                                    if (tile == 4'b0011) begin
                                                 
                                                
                                        case_num <= 4'd1;
                                        next_direction <= DOWN;
                                        down_next <= 1'b1;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                        
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b0110) begin
                                         
                                        next_direction <= RIGHT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b1;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd2;
                                         
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b0101) begin
                                         
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                                
                                        case_num <= 4'd3;
                                        
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b0010) begin
                                        
                                        case_num <= 4'd4;
                                        if (down_distance2 <= right_distance2) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                    
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b0100) begin
                                         
                                        case_num <= 4'd5;
                                        
                                        if (left_distance2 <= right_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 6.
                                    else if (tile == 4'b0001) begin
                                                
                                        case_num <= 4'd6;
                                        
                                        if (left_distance2 <= down_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin

                                        case_num <= 4'd7;
                                        
                                        if (left_distance2 <= right_distance2 && left_distance2 <= down_distance2) begin
                                            next_direction <= LEFT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b1;
                                        end
                                        
                                        else if (down_distance2 <= left_distance2 && down_distance2 <= right_distance2) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                        
                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b0111) begin
                                        case_num <= 4'd8;
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                    end
                                    
                                end // case DOWN end
                                
                                RIGHT: begin
                                    // case 1.
                                    if (tile == 4'b1100) begin
                                         
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                                     
                                            case_num <= 4'd1;
                                    end
                                    
                                    // case 2.
                                    else if (tile == 4'b1001) begin
                                            
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                                     
                                            case_num <= 4'd2;
                                         
                                    end
                                    
                                    // case 3.
                                    else if (tile == 4'b0101) begin
                                         
                                        next_direction <= UP;
                                        down_next <= 1'b0;
                                        up_next <= 1'b1;
                                        right_next <= 1'b0;
                                        left_next <= 1'b0;
                                                
                                        case_num <= 4'd3;
                                    end
                                    
                                    // case 4.
                                    else if (tile == 4'b1000) begin
                                         
                                        
                                                
                                        case_num <= 4'd4;
                                        
                                        if (down_distance2 <= right_distance2) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                                     
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                         
                                    end
                                    
                                    // case 5.
                                    else if (tile == 4'b0001) begin
                                       
                                        case_num <= 4'd5;
                                        
                                        if (up_distance2 <= down_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                    end
                                    
                                    // case 6.
                                    else if (tile == 4'b0100) begin
                                          
                                        case_num <= 4'd6;
                                                
                                        
                                        if (up_distance2 <= right_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                         
                                    end
                                    
                                    // case 7.
                                    else if (tile == 4'b0000) begin
                                         
                                        case_num <= 4'd7;
                                                
                                        
                                        if (up_distance2 <= right_distance2 && up_distance2 <= down_distance2) begin
                                            next_direction <= UP;
                                            down_next <= 1'b0;
                                            up_next <= 1'b1;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else if (down_distance2 <= up_distance2 && down_distance2 <= right_distance2) begin
                                            next_direction <= DOWN;
                                            down_next <= 1'b1;
                                            up_next <= 1'b0;
                                            right_next <= 1'b0;
                                            left_next <= 1'b0;
                                        end
                                        
                                        else begin
                                            next_direction <= RIGHT;
                                            down_next <= 1'b0;
                                            up_next <= 1'b0;
                                            right_next <= 1'b1;
                                            left_next <= 1'b0;
                                        end
                                         
                                    end
                                    
                                    // case 8.
                                    else if (tile == 4'b1101) begin
                                        case_num <= 4'd8;
                                        next_direction <= LEFT;
                                        down_next <= 1'b0;
                                        up_next <= 1'b0;
                                        right_next <= 1'b0;
                                        left_next <= 1'b1;
                                    end
                                    
                                end // case RIGHT end
                              
                            endcase
							end
					 end
					 
					 else begin
							o_x_location <= o_x_location + down_next - up_next;
							o_y_location <= o_y_location + right_next - left_next;
							count <= count + 1'b1;
					 end
					 
					 
            end
            
            MODE_FRIGHTENED: begin
					if (count == 4'd8) begin
						if (i_mode == MODE_CHASE) begin
							state <= MODE_CHASE;
							count <= 4'd8;
						end
						
						else if (i_mode == MODE_SCATTER) begin
							state <= MODE_SCATTER;
							count <= 4'd8;
							inky_target_x <= 9'd252;
							inky_target_y <= 9'd204;
						end
						
						else if (right_to_left == 1'b1) begin
							o_x_location <= 10'd132; 
							o_y_location <= 10'd212;
							next_direction <= RIGHT;
							up_next <= 1'b0;
							down_next <= 1'b0;
							right_next <= 1'b1;
							left_next <= 1'b0;
						end
								
						else if (left_to_right == 1'b1) begin
							o_x_location <= 10'd132; 
							o_y_location <= 10'd220;
							next_direction <= LEFT;
							up_next <= 1'b0;
							down_next <= 1'b0;
							right_next <= 1'b0;
							left_next <= 1'b1;
						end
						
						else begin // frightened mode.
							count <= 4'd0;
							state <= MODE_FRIGHTENED;
							case(next_direction)
                                
								UP: begin
									// case 1.
									if (tile == 4'b0011) begin
										 
										 next_direction <= UP;
										 down_next <= 1'b0;
										 up_next <= 1'b1;
										 right_next <= 1'b0;
										 left_next <= 1'b0;
													
										 case_num <= 4'd1;
										 
									end
													
									// case 2.
									else if (tile == 4'b1010) begin
											
										 next_direction <= RIGHT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b1;
										 left_next <= 1'b0;
													
										 case_num <= 4'd2;
									
									end
									
									// case 3.
									else if (tile == 4'b1001) begin
										 
										 next_direction <= LEFT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b1;
										 
										 case_num <= 4'd3;
									end
									
									// case 4.
									else if (tile == 4'b0010) begin
										 
										 case_num <= 4'd4;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
									end
													
									// case 5.
									else if (tile == 4'b1000) begin
										 
													
										 case_num <= 4'd5;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
										 
									end // end case 5.
									
									// case 6.
									else if (tile == 4'b0001) begin
										 
										 
										 case_num <= 4'd6;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 
									end
									
									// case 7.
									else if (tile == 4'b0000) begin
													
										 case_num <= 4'd7;
																	  
										 if (random_move_3 == 4'd1) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else if (random_move_3 == 4'd2) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
									end
									
									// case 8.
									else if (tile == 4'b1011) begin
										 case_num <= 4'd8;
										 next_direction <= DOWN;
										 down_next <= 1'b1;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b0;
									end
						 
							  end // end UP case.
												  
								LEFT: begin
									// case 1.
									if (tile == 4'b1100) begin
										  
										 next_direction <= LEFT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b1;
													
										 case_num <= 4'd1;
									end
									
									// case 2.
									else if (tile == 4'b0000) begin
												 
										 
										 case_num <= 4'd2;
										 
										 if (random_move_3 == 4'd1) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
													
										 else if (random_move_3 == 4'd2) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
													
										 else begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
									end
									
									// case 3.
									else if (tile == 4'b0010) begin
													 
										 case_num <= 4'd3;
												 
									  
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 else begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
									end
									
									
									// case 6.
									else if (tile == 4'b0100) begin
													 
										 case_num <= 4'd6;
												 
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
									
									end
									
									// case 7.
									else if (tile == 4'b0000) begin
													
										 case_num <= 4'd7;
												 
										
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 
										 else begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
									
									end
									
									// case 5.
									else if (tile == 4'b1010) begin
													 
										 case_num <= 4'd5;
												 
										 next_direction <= DOWN;
										 down_next <= 1'b1;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b0;
									end
									
									// case 4.
									else if (tile == 4'b0110) begin
											
										 case_num <= 4'd4;
										 next_direction <= UP;
										 down_next <= 1'b0;
										 up_next <= 1'b1;
										 right_next <= 1'b0;
										 left_next <= 1'b0;

									end
									
									// case 8.
									else if (tile == 4'b1110) begin
										 next_direction <= RIGHT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b1;
										 left_next <= 1'b0;
										 case_num <= 4'd8;
									end
									
							  end // case LEFT end
							  
							   DOWN: begin
							  
									// case 1.
									if (tile == 4'b0011) begin
													 
													
										 case_num <= 4'd1;
										 next_direction <= DOWN;
										 down_next <= 1'b1;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b0;
										 
									end
									
									// case 2.
									else if (tile == 4'b0110) begin
										  
										 next_direction <= RIGHT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b1;
										 left_next <= 1'b0;
													
										 case_num <= 4'd2;
										  
									end
									
									// case 3.
									else if (tile == 4'b0101) begin
										  
										 next_direction <= LEFT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b1;
													
										 case_num <= 4'd3;
										 
									end
									
									// case 4.
									else if (tile == 4'b0010) begin
										 
										 case_num <= 4'd4;
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
									
									end
									
									// case 5.
									else if (tile == 4'b0100) begin
										  
										 case_num <= 4'd5;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
										 
									end
									
									// case 6.
									else if (tile == 4'b0001) begin
													
										 case_num <= 4'd6;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 
										 else begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
									end
									
									// case 7.
									else if (tile == 4'b0000) begin

										 case_num <= 4'd7;
										 
										 if (random_move_3 == 4'd1) begin
											  next_direction <= LEFT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b1;
										 end
										 
										 else if (random_move_3 == 4'd2) begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
										 
									end
									
									// case 8.
									else if (tile == 4'b0111) begin
										 case_num <= 4'd8;
										 next_direction <= UP;
										 down_next <= 1'b0;
										 up_next <= 1'b1;
										 right_next <= 1'b0;
										 left_next <= 1'b0;
									end
									
							  end // case DOWN end
												  
								RIGHT: begin
									// case 1.
									if (tile == 4'b1100) begin
										  
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
														  
											  case_num <= 4'd1;
									end
									
									// case 2.
									else if (tile == 4'b1001) begin
											  
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
														  
											  case_num <= 4'd2;
										  
									end
									
									// case 3.
									else if (tile == 4'b0101) begin
										  
										 next_direction <= UP;
										 down_next <= 1'b0;
										 up_next <= 1'b1;
										 right_next <= 1'b0;
										 left_next <= 1'b0;
													
										 case_num <= 4'd3;
									end
									
									// case 4.
									else if (tile == 4'b1000) begin
										  
										 
													
										 case_num <= 4'd4;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
														  
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
										  
									end
									
									// case 5.
									else if (tile == 4'b0001) begin
										
										 case_num <= 4'd5;
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
									end
									
									// case 6.
									else if (tile == 4'b0100) begin
											
										 case_num <= 4'd6;
													
										 
										 if (random_move_2 % 2 == 0) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
										  
									end
									
									// case 7.
									else if (tile == 4'b0000) begin
										  
										 case_num <= 4'd7;
													
										 
										 if (random_move_3 == 4'd1) begin
											  next_direction <= UP;
											  down_next <= 1'b0;
											  up_next <= 1'b1;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else if (random_move_3 == 4'd2) begin
											  next_direction <= DOWN;
											  down_next <= 1'b1;
											  up_next <= 1'b0;
											  right_next <= 1'b0;
											  left_next <= 1'b0;
										 end
										 
										 else begin
											  next_direction <= RIGHT;
											  down_next <= 1'b0;
											  up_next <= 1'b0;
											  right_next <= 1'b1;
											  left_next <= 1'b0;
										 end
										  
									end
									
									// case 8.
									else if (tile == 4'b1101) begin
										 case_num <= 4'd8;
										 next_direction <= LEFT;
										 down_next <= 1'b0;
										 up_next <= 1'b0;
										 right_next <= 1'b0;
										 left_next <= 1'b1;
									end
									
							  end // case RIGHT end
						
                     endcase
						end
					end
					
					else begin
						o_x_location <= o_x_location + down_next - up_next;
                  o_y_location <= o_y_location + right_next - left_next;
                        
                  count <= count + 1'b1;
					end
					
				end
				
        endcase                      
    end
end


    
   




endmodule
