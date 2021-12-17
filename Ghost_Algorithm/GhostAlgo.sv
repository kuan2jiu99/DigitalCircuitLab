// Test Tile Version, chase mode.

module GhostAlgo ( // test version
    input i_clk,
    input i_rst,
    input [5:0] pac_x,
    input [5:0] pac_y,
    input [3:0] random,
    
    output [5:0] o_x_location,
    output [5:0] o_y_location,
    output reach,
    output [1:0] next_direction
    
);

// next move direction.
parameter UP = 2'b00;
parameter DOWN = 2'b01;
parameter LEFT = 2'b10;
parameter RIGHT = 2'b11;


logic [3:0] i_board [0:35][0:27];

logic signed [1:0] next_move_x, next_move_y
logic [5:0] temp_loc_x, temp_loc_y;

logic [10:0] up_candid;
logic [10:0] down_candid;
logic [10:0] left_candid;
logic [10:0] right_candid;

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

// calculate Norm2 distance.
function [10:0] distance;
    input [5:0] pac_x;
    input [5:0] pac_y;
    input [5:0] temp_loc_x;
    input [5:0] temp_loc_y;
    
    begin
    distance = (temp_loc_x - pac_x) * (temp_loc_x - pac_x) + (temp_loc_y - pac_y) * (temp_loc_y - pac_y);
    end
endfunction


always_ff @(posedge i_clk) begin
    if (i_rst) begin
        o_x_location <= 3'd8; // initial location,
        o_y_location <= 3'd13;
        next_move_x <= 2'd0;
        next_move_y <= (-2'd1); // first, go left
        next_direction <= LEFT
        reach <= 1'b0;
    end
    
    else begin
        temp_loc_x <= o_x_location + next_move_x; // predict next move.
        temp_loc_y <= o_y_location + next_move_y;
        
        case(next_direction)
            UP: begin
                // case 1.
                if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0) begin
                    
                    next_direction <= UP;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= (-2'd1);
                    next_move_y <= 2'd0; // move up.
                    
                end
                
                // case 2.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0) begin
                    
                    next_direction <= RIGHT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= 2'd1; // move right.
                
                end
                
                // case 3.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0) begin
                    
                    next_direction <= LEFT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= (-2'd1); // move left.
                    
                end
                
                // case 4.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0) begin
                    
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    
                    if (up_candid <= right_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                end
                
                // case 5.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0) begin
                    
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    
                    if (left_candid <= right_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                    
                end // end case 5.
                
                // case 6.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0) begin
                    
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    
                    if (up_candid <= left_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    
                end
                
                // case 7.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x - 1'b1) >= 0
                    && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                    && && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0) begin
                    
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    
                    if (up_candid <= left_candid && up_candid <= right_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else if (left_candid <= up_candid && left_candid <= right_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                end
                
                // case 8.
                else begin
                    next_direction <= DOWN;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd1;
                    next_move_y <= 2'd0; // move down.
                end
        
            end // end UP case.
            
            LEFT: begin
                // case 1.
                if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1) >= 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0
                     && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0) begin
                    next_direction <= LEFT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= (-2'd1); // move left.
                end
                
                // case 2.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1 >= 0)
                          && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0
                          && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0) begin
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    if (up_candid <= down_candid && up_candid <= left_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    else if (left_candid <= up_candid && left_candid <= down_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    else
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                    
                end
                
                // case 3.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1) >= 0
                          && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0 && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0
                          && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0) begin
                          
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    if (up_candid <= down_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    else begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                end
                
                
                // case 6.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1) >= 0
                          && i_board[temp_loc_x + 1'b1][temp_loc_y - 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                          && i_board[temp_loc_x - 1'b1][temp_loc_y - 1'b1] == 0) begin
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    
                    if (up_candid <= left_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                
                end
                
                // case 7.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1) >= 0
                          && i_board[temp_loc_x + 1'b1][temp_loc_y - 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                          && i_board[temp_loc_x - 1'b1][temp_loc_y - 1'b1] != 0) begin
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    if (left_candid <= down_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    
                    else begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                
                end
                
                // case 5.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1) >= 0
                          && i_board[temp_loc_x + 1'b1][temp_loc_y - 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                          && i_board[temp_loc_x - 1'b1][temp_loc_y - 1'b1] != 0) begin
                    next_direction <= DOWN;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd1;
                    next_move_y <= 2'd0; // move down.
                end
                
                // case 4.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y - 1'b1) >= 0
                          && i_board[temp_loc_x + 1'b1][temp_loc_y - 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                          && i_board[temp_loc_x - 1'b1][temp_loc_y - 1'b1] == 0) begin
                    next_direction <= UP;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= (-2'd1);
                    next_move_y <= 2'd0; // move up.

                end
                
                // case 8.
                else begin
                    next_direction <= RIGHT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= 2'd1; // move right.
                end
                
            end // case LEFT end
            
            DOWN: begin
            
                // case 1.
                if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0) begin
                     
                    next_direction <= DOWN;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd1;
                    next_move_y <= 2'd0; // move down.
                    
                end
                
                // case 2.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0) begin
                     
                    next_direction <= RIGHT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= 2'd1; // move right.
                     
                end
                
                // case 3.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0) begin
                     
                    next_direction <= LEFT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= (-2'd1); // move left.
                end
                
                // case 4.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] != 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0) begin
                     
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    
                    if (down_candid <= right_candid) begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                
                end
                
                // case 5.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0) begin
                     
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    
                    if (left_candid <= right_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                    
                end
                
                // case 6.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0) begin
                     
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    
                    if (left_candid <= down_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    
                    else begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                    
                end
                
                // case 7.
                else if ((temp_loc_y + 1'b1) < COL && (temp_loc_y - 1'b1) >= 0 && (temp_loc_x + 1'b1) < ROW
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0 && i_board[temp_loc_x][temp_loc_y - 1'b1] == 0
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0) begin
                     
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    left_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y - 1'b1);
                    
                    if (left_candid <= right_candid && left_candid <= down_candid) begin
                        next_direction <= LEFT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= (-2'd1); // move left.
                    end
                    
                    else if (down_candid <= left_candid && down_candid <= right_candid) begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                    
                end
                
                // case 8.
                else begin
                    next_direction <= UP;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= (-2'd1);
                    next_move_y <= 2'd0; // move up.
                end
                
            end // case DOWN end
            
            RIGHT: begin
                // case 1.
                if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0) begin
                     
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                end
                
                // case 2.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0) begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                     
                end
                
                // case 3.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0) begin
                     
                    next_direction <= UP;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= (-2'd1);
                    next_move_y <= 2'd0; // move up.
                end
                
                // case 4.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] != 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0) begin
                     
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    
                    if (down_candid <= right_candid) begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                     
                end
                
                // case 5.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] != 0) begin
                     
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    
                    if (up_candid <= down_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                end
                
                // case 6.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] != 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0) begin
                     
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    
                    if (up_candid <= right_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                     
                end
                
                // case 7.
                else if ((temp_loc_x + 1'b1) < ROW && (temp_loc_x - 1'b1) >= 0 && (temp_loc_y + 1'b1) < COL
                     && i_board[temp_loc_x + 1'b1][temp_loc_y] == 0 && i_board[temp_loc_x - 1'b1][temp_loc_y] == 0
                     && i_board[temp_loc_x][temp_loc_y + 1'b1] == 0) begin
                     
                    up_candid <= distance(pac_x, pac_y, temp_loc_x - 1'b1, temp_loc_y);
                    right_candid <= distance(pac_x, pac_y, temp_loc_x, temp_loc_y + 1'b1);
                    down_candid <= distance(pac_x, pac_y, temp_loc_x + 1'b1, temp_loc_y);
                    
                    if (up_candid <= right_candid && up_candid <= down_candid) begin
                        next_direction <= UP;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= (-2'd1);
                        next_move_y <= 2'd0; // move up.
                    end
                    
                    else if (down_candid <= up_candid && down_candid <= right_candid) begin
                        next_direction <= DOWN;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd1;
                        next_move_y <= 2'd0; // move down.
                    end
                    
                    else begin
                        next_direction <= RIGHT;
                        o_x_location <= o_x_location + next_move_x;
                        o_y_location <= o_y_location + next_move_y;
                        next_move_x <= 2'd0;
                        next_move_y <= 2'd1; // move right.
                    end
                     
                end
                
                // case 8.
                else begin
                    next_direction <= LEFT;
                    o_x_location <= o_x_location + next_move_x;
                    o_y_location <= o_y_location + next_move_y;
                    next_move_x <= 2'd0;
                    next_move_y <= (-2'd1); // move left.
                end
                
            end // case RIGHT end
          
            
        endcase
            
    end

end





