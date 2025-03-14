// Board configuration: tang_nano_9k_lcd_480_272_tm1638_hackathon
// This module uses few parameterization and relaxed typing rules

module hackathon_top
(
    input  logic       clock,
    input  logic       slow_clock,
    input  logic       reset,

    input  logic [7:0] key,
    output logic [7:0] led,

    // A dynamic seven-segment display

    output logic [7:0] abcdefgh,
    output logic [7:0] digit,

    // LCD screen interface

    input  logic [8:0] x,
    input  logic [8:0] y,

    output logic [4:0] red,
    output logic [5:0] green,
    output logic [4:0] blue,

    inout  logic [2:0] gpio
);

    //------------------------------------------------------------------------
    //
    //  Screen, object and color constants

    localparam screen_width  = 480,
               screen_height = 272,

               wx            = 30,
               wy            = 30,

               start_0_x     = 0,
               start_0_y     = screen_height     / 5,

               start_1_x     = screen_width      / 2,
               start_1_y     = screen_height * 4 / 5,

               max_red       = 31,
               max_green     = 63,
               max_blue      = 31;

    //------------------------------------------------------------------------
    //
    //  Pulse generator, 50 times a second

    logic enable;

    strobe_gen # (.clk_mhz (27), .strobe_hz (50))
    i_strobe_gen (clock, reset, enable);

    //------------------------------------------------------------------------
    //
    //  Finite State Machine (FSM) for the game

    localparam [2:0]
        STATE_START = 0,
        STATE_AIM   = 1,
        STATE_SHOOT = 2,
        STATE_WON   = 3,
        STATE_LOST  = 4;

    logic [2:0] state, new_state;

    //------------------------------------------------------------------------

    // Conditions to change the state - declarations

    logic out_of_screen, collision, launch, timeout;

    //------------------------------------------------------------------------
    //
    //  Computing new object coordinates

    logic [8:0] x0,  y0,  x1,  y1,
                x0r, y0r, x1r, y1r;

    // logic [8:0] Dino_x_start;
    parameter [8:0] Dino_x_start = 40;
    logic [8:0] Dino_y_start;
    logic [8:0] Dino_y_start_prev;
    logic [8:0] Dino_y_start_new;
    logic [8:0] jump_count;
    logic [9:0] bush_shift;

    logic collision1;
    parameter [8:0] Bush_x = 480;
    parameter [8:0] Bush_y = 210;
    parameter [8:0] Bush_height = 20;
    parameter [8:0] Bush_width = 10;



    wire left  = | key [6:1];
    wire right =   key [0];


    //------------------------------------------------------------------------
    //
    // Conditions to change the state - implementations

    assign out_of_screen =   x0 == screen_width
                           | x1 == 0
                           | x1 == screen_width
                           | y1 == 0;

    assign collision = ~ (  x0 + wx <= x1
                          | x1 + wx <= x0
                          | y0 + wy <= y1
                          | y1 + wy <= y0 );

    assign launch = left | right;

    //------------------------------------------------------------------------
    //
    // Timeout condition

    logic [7:0] timer;

    //------------------------------------------------------------------------
    //
    //  Determine pixel color

    //-----------------------------------------------------------------------


    always_comb
    begin
        red   = 0;
        green = 0;
        blue  = 0;
        Dino_y_start_new = Dino_y_start;


        if ((x - 30)**2 + (y - 10)**2 < 500 ) begin
            red = 31;
            green = 25;
        end

        if ((x - 200)**2 + (y - 70)**2 < 600 ) begin
            red = '1;
            blue = '1;
            green = '1;
        end


        if ((x - 400)**2 + (y - 30)**2 < 300 ) begin
            red = '1;
            blue = '1;
            green = '1;
        end

        if ((x - 300)**2 + (y - 20)**2 < 500 ) begin
            red = '1;
            blue = '1;
            green = '1;
        end

        if (x >= Dino_x_start + 25 & x < Dino_x_start + 35 &
            y >= Dino_y_start_new - 20 & y < Dino_y_start_new - 5) begin
            blue = 31;
        end
        if (x >= Dino_x_start + 32 & x < Dino_x_start + 34 &
            y >= Dino_y_start_new - 16 & y < Dino_y_start_new - 14) begin
            red = 31;
            blue = 31;
            green = 32;
        end
        else if (x >= Dino_x_start + 5 & x < Dino_x_start + 30 &
            y >= Dino_y_start_new - 5 & y < Dino_y_start_new + 20) begin
            blue = 31;
        end
        else if (x >= Dino_x_start + 5 & x < Dino_x_start + 12 &
            y >= Dino_y_start_new + 20 & y < Dino_y_start_new + 30) begin
            blue = 31;
        end
        else if (x >= Dino_x_start + 18 & x < Dino_x_start + 25 &
            y >= Dino_y_start_new + 20 & y < Dino_y_start_new + 30) begin
            blue = 31;
        end
        else if (x >= Dino_x_start - 5 & x < Dino_x_start + 5 &
            y >= Dino_y_start_new - 3 & y < Dino_y_start_new + 5) begin
            blue = 31;
        end
        if (y >= Dino_ground_y + 30 & y < 282) begin
            green = 31;
        end

        else if (x >= Bush_x + 5 - bush_shift & x < Bush_x + 15 - bush_shift &
            y >= Bush_y - Bush_height - 5 & y < Bush_y - Bush_height) begin
            green = 20;
            if (x >= Dino_x_start - 5 & x < Dino_x_start + 20 &
                y >= Dino_y_start_new - 20 & y < Dino_y_start_new + 20) begin
                collision1 = 1;
            end
        end


        else if (x >= Bush_x + 14 - bush_shift & x < Bush_x + Bush_width + 14 - bush_shift &
            y >= Bush_y - Bush_height & y < Bush_y) begin
            green = 20;
            if (x >= Dino_x_start - 5 & x < Dino_x_start + 20 &
                y >= Dino_y_start_new - 20 & y < Dino_y_start_new + 20) begin
                collision1 = 1;
            end
        end

        else if (x >= Bush_x + 20 - bush_shift & x < Bush_x + 30 - bush_shift &
            y >= Bush_y - Bush_height - 7 & y < Bush_y - Bush_height) begin
            green = 20;
            if (x >= Dino_x_start - 5 & x < Dino_x_start + 20 &
                y >= Dino_y_start_new - 20 & y < Dino_y_start_new + 20) begin
                collision1 = 1;
            end
        end

        // if (collision1 == 1)
        // begin
        //     red = 31;
        // end


    end


    parameter Dino_ground_y = 180;

    always_ff @ (posedge enable)
        if (key[0])
        begin
            if (Dino_y_start > 0 & Dino_y_start < 282 & jump_count < 101) begin
                Dino_y_start <= Dino_y_start - 2;
                jump_count <= jump_count + 2;
            end
            else if (Dino_y_start > 0 & Dino_y_start < 282 & jump_count > 100) begin
                Dino_y_start <= Dino_y_start + 2;
                jump_count <= jump_count + 2; 
                if( jump_count > 200)
                    jump_count <= 0;
            end
        end
        else 
        begin
            Dino_y_start <=  180;
            jump_count <= 0;
        end


    always_ff @ (posedge clock or posedge reset)
        if (reset)
        begin
            bush_shift <= '0;

        end
        else if (enable)
            begin                   
                bush_shift <= bush_shift + 2;
                if (bush_shift > 500) begin
                    bush_shift <= 0;
                end       
            end


    //------------------------------------------------------------------------
    //
    //  Output to LED and 7-segment display

    assign led = x1;

    wire [31:0] number
        = key [7] ? { 7'b0, x0, 7'b0, y0 }
                  : { 7'b0, x1, 7'b0, y1 };

    seven_segment_display # (.w_digit (8)) i_7segment
    (
        .clk      ( clock    ),
        .rst      ( reset    ),
        .number   ( number   ),
        .dots     ( '0       ),  // This syntax means "all 0s in the context"
        .abcdefgh ( abcdefgh ),
        .digit    ( digit    )
    );


endmodule






