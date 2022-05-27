module QRD(
    clk,
    rst_n,
    row_in_1_r, row_in_1_i, row_in_1_f,
    row_in_2_r, row_in_2_i, row_in_2_f,
    row_in_3_r, row_in_3_i, row_in_3_f,
    row_in_4_r, row_in_4_i,
    in_ready,
    out_valid,
    row_out_1_r, row_out_1_i,
    row_out_2_r, row_out_2_i,
    row_out_3_r, row_out_3_i,
    row_out_4_r, row_out_4_i
);
parameter WIDTH = 14;
parameter ITER = 2*13;
parameter ITER_MAX = ITER-1;

localparam STATE_IDLE = 0;
localparam STATE_WAIT = 1;
localparam STATE_CALC = 2;

input clk, rst_n;
input row_in_1_f, row_in_2_f, row_in_3_f;
input signed [WIDTH-1:0] row_in_1_r, row_in_1_i,
                         row_in_2_r, row_in_2_i,
                         row_in_3_r, row_in_3_i,
                         row_in_4_r, row_in_4_i;
input signed [WIDTH-1:0] row_out_1_r, row_out_1_i,
                         row_out_2_r, row_out_2_i,
                         row_out_3_r, row_out_3_i,
                         row_out_4_r, row_out_4_i;
output in_ready;
output out_valid;

// Row-wise wire
wire row_1_r_1, row_1_i_1, row_1_f_1;
wire row_1_r_2, row_1_i_2, row_1_f_2;
wire row_1_r_3, row_1_i_3, row_1_f_3;

wire row_2_r_2, row_2_i_2, row_2_f_2;
wire row_2_r_3, row_2_i_3, row_2_f_3;

wire row_3_r_3, row_3_i_3, row_3_f_3;

// Column-wise wire
wire col_3_r_1, col_3_i_1, col_3_f_1;
wire col_3_r_2, col_3_i_2, col_3_f_2;
wire col_3_r_3, col_3_i_3, col_3_f_3;

wire col_2_r_1, col_2_i_1, col_2_f_1;
wire col_2_r_2, col_2_i_2, col_2_f_2;

wire col_1_r_1, col_1_i_1, col_1_f_1;

// Registers
reg [3:0] state_r, state_w;

reg [4:0] counter_r, counter_w;

/* 1st row */
DU #(.WIDTH(WIDTH)) du_row_1(
    .clk(clk),
    .din_r(row_in_1_r), .din_i(row_in_1_i), .din_f(row_in_1_f),
    .dout_r(row_1_r_1), .dout_i(row_1_i_1), .dout_f(row_1_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_1(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_1_r_1),  .din_a_i(row_1_i_1),  .din_a_f(row_1_f_1),
    .din_b_r(row_in_2_r), .din_b_i(row_in_2_i), .din_b_f(row_in_2_f),
    .dout_x_r(row_1_r_2), .dout_x_i(row_1_i_2), .dout_x_f(row_1_f_2),
    .dout_y_r(col_1_r_1), .dout_y_i(col_1_i_1), .dout_y_f(col_1_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_2(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_1_r_2),  .din_a_i(row_1_i_2),  .din_a_f(row_1_f_2),
    .din_b_r(row_in_3_r), .din_b_i(row_in_3_i), .din_b_f(row_in_3_f),
    .dout_x_r(row_1_r_3), .dout_x_i(row_1_i_3), .dout_x_f(row_1_f_3),
    .dout_y_r(col_2_r_1), .dout_y_i(col_2_i_1), .dout_y_f(col_2_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_3(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_1_r_3),    .din_a_i(row_1_i_3),    .din_a_f(),
    .din_b_r(row_in_4_r),   .din_b_i(row_in_4_i),   .din_b_f(),
    .dout_x_r(row_out_1_r), .dout_x_i(row_out_1_i), .dout_x_f(),
    .dout_y_r(col_3_r_1),   .dout_y_i(col_3_i_1),   .dout_y_f()
);

/* 2nd row */
DU #(.WIDTH(WIDTH)) du_row_2(
    .clk(clk),
    .din_r(col_1_r_1),  .din_i(col_1_i_1),  .din_f(col_1_f_1),
    .dout_r(row_2_r_2), .dout_i(row_2_i_2), .dout_f(row_2_f_2)
);
PE #(.WIDTH(WIDTH)) pe_row_2_2(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_2_r_2),  .din_a_i(row_2_i_2),  .din_a_f(row_2_f_2),
    .din_b_r(col_2_r_1),  .din_b_i(col_2_i_1),  .din_b_f(col_2_f_1),
    .dout_x_r(row_2_r_3), .dout_x_i(row_2_i_3), .dout_x_f(row_2_f_3),
    .dout_y_r(col_2_r_2), .dout_y_i(col_2_i_2), .dout_y_f(col_2_f_2)
);
PE #(.WIDTH(WIDTH)) pe_row_2_3(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_2_r_3),    .din_a_i(row_2_i_3),    .din_a_f(),
    .din_b_r(col_3_r_1),    .din_b_i(col_3_i_1),    .din_b_f(),
    .dout_x_r(row_out_2_r), .dout_x_i(row_out_2_i), .dout_x_f(),
    .dout_y_r(col_3_r_2),   .dout_y_i(col_3_i_2),   .dout_y_f()
);

/* 3rd row */
DU #(.WIDTH(WIDTH)) du_row_3(
    .clk(clk),
    .din_r(col_2_r_2),  .din_i(col_2_i_2),  .din_f(col_2_f_2),
    .dout_r(row_3_r_3), .dout_i(row_3_i_3), .dout_f(row_3_f_3)
);
PE #(.WIDTH(WIDTH)) pe_row_3_3(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_3_r_3),    .din_a_i(row_3_i_3),    .din_a_f(),
    .din_b_r(col_3_r_2),    .din_b_i(col_3_i_2),    .din_b_f(),
    .dout_x_r(row_out_3_r), .dout_x_i(row_out_3_i), .dout_x_f(),
    .dout_y_r(row_out_4_r), .dout_y_i(row_out_4_i), .dout_y_f()
);

/* Output logic */
assign in_ready = state_r == STATE_IDLE || counter_r == ITER_MAX;

always @(*) begin
    case (state_r)
    STATE_IDLE:  counter_w = counter_r;
    STATE_WAIT:  counter_w = counter_r;
    STATE_CALC: counter_w = counter_r == ITER_MAX ? 0 : counter_r+1;
    endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
        counter_r <= 0;
    end
    else begin
        counter_r <= counter_w;
    end
end

always @(*) begin
    case (state_r)
    STATE_IDLE: state_w = STATE_WAIT;
    STATE_WAIT: state_w = STATE_CALC;
    STATE_CALC: state_w = STATE_CALC;
    endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
        state_r <= 0;
    end
    else begin
        state_r <= state_w;
    end
end
endmodule

module DU(
    clk,
    din_f,
    din_r,
    din_i,
    dout_f,
    dout_r,
    dout_i
);
parameter WIDTH = 14;

input clk;
input din_f;
input signed [WIDTH-1:0] din_r, din_i;
output dout_f;
output signed [WIDTH-1:0] dout_r, dout_i;

reg signed [2*WIDTH-1:0] reg_r, reg_w;

assign {dout_f, dout_r, dout_i} = reg_r;

always @(*) begin
    reg_w = {din_f, din_r, din_i};
end
always @(posedge clk) begin
    reg_r <= reg_w;
end
endmodule

module PE(
    clk,
    rst_n,
    din_a_f,
    din_a_r,
    din_a_i,
    din_b_f,
    din_b_r,
    din_b_i,
    dout_x_f,
    dout_x_r,
    dout_x_i,
    dout_y_f,
    dout_y_r,
    dout_y_i
);
// [x y] = Transform([a b])
// North: b, West: a
// East: x, South: y

parameter WIDTH = 14;

input clk, rst_n;
input din_a_f, din_b_f;
input signed [WIDTH-1:0] din_a_r, din_a_i,
                         din_b_r, din_b_i;
output dout_x_f, dout_y_f;
output signed [WIDTH-1:0] dout_x_r, dout_x_i,
                          dout_y_r, dout_y_i;

wire is_vec_mode;
reg signed [WIDTH-1:0] ang_a_r, ang_a_w,
                       ang_b_r, ang_b_w,
                       ang_1_r, ang_1_w;

wire signed [WIDTH-1:0] cordic_1_z, cordic_2_z,
                        cordic_3_z, cordic_4_z;
wire signed [WIDTH-1:0] ang_a, ang_b;
wire signed [WIDTH-1:0] zf_a_r_or_abs_a, zf_a_i,
                        zf_b_r_or_abs_b, zf_b_i;
wire signed [WIDTH-1:0] x_r_or_mag, x_i,
                        y_r, y_i;
wire signed [WIDTH-1:0] ang_1;

// assign cordic_1_z = is_vec_mode ? 0 : ang_a_r;
// assign cordic_2_z = is_vec_mode ? 0 : ang_b_r;

// CORDIC #(.WIDTH(WIDTH)) cordic_1(
//     .clk(clk), .is_vec_mode(is_vec_mode),
//     .din_x(din_a_r), .din_y(din_a_i), .din_z(cordic_1_z),
//     .dout_x(zf_a_r_or_abs_a), .dout_y(zf_a_i), .dout_z(ang_a)
// );
// CORDIC #(.WIDTH(WIDTH)) cordic_2(
//     .clk(clk), .is_vec_mode(is_vec_mode),
//     .din_x(din_b_r), .din_y(din_b_i), .din_z(cordic_2_z),
//     .dout_x(zf_b_r_or_abs_b), .dout_y(zf_b_i), .dout_z(ang_b)
// );

// assign cordic_3_z = is_vec_mode ? 0 : ang_1_r;
// assign cordic_4_z = is_vec_mode ? 0 : ang_1_r;

// CORDIC #(.WIDTH(WIDTH)) cordic_3(
//     .clk(clk), .is_vec_mode(is_vec_mode),
//     .din_x(zf_b_r_or_abs_b), .din_y(zf_b_r_or_abs_b), .din_z(cordic_3_z),
//     .dout_x(x_r_or_mag), .dout_y(y_r), .dout_z(ang_1)
// );
// CORDIC #(.WIDTH(WIDTH)) cordic_4(
//     .clk(clk), .is_vec_mode(is_vec_mode),
//     .din_x(zf_a_i), .din_y(zf_b_i), .din_z(cordic_4_z),
//     .dout_x(x_i), .dout_y(y_i), .dout_z()
// );
endmodule

// module CORDIC(
//     clk,
//     is_vec_mode,
//     din_x,
//     din_y,
//     din_z,
//     dout_x,
//     dout_y,
//     dout_z
// );

// parameter WIDTH = 14;

// input clk, is_vec_mode;
// input signed [WITDH-1:0] din_x, din_y, din_z;
// input signed [WITDH-1:0] dout_x, dout_y, dout_z;

// endmodule