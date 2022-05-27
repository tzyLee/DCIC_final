module QRD(
    clk,
    rst_n,
    in_valid,
    row_in_1_r,
    row_in_1_i,
    row_in_2_r,
    row_in_2_i,
    row_in_3_r,
    row_in_3_i,
    row_in_4_r,
    row_in_4_i,
    out_valid,
    row_out_1_r,
    row_out_1_i,
    row_out_2_r,
    row_out_2_i,
    row_out_3_r,
    row_out_3_i,
    row_out_4_r,
    row_out_4_i
);
parameter WIDTH = 14;

input clk, rst_n;
input signed [WITDH-1:0] row_in_1_r, row_in_1_i,
                         row_in_2_r, row_in_2_i,
                         row_in_3_r, row_in_3_i,
                         row_in_4_r, row_in_4_i;
input signed [WITDH-1:0] row_out_1_r, row_out_1_i,
                         row_out_2_r, row_out_2_i,
                         row_out_3_r, row_out_3_i,
                         row_out_4_r, row_out_4_i;
output in_valid, out_valid;

PE #(.width(WIDTH)) pe_row_1_1(
    .clk(clk), .rst_n(rst_n),
    .din_b_r(row_in_2_r), .din_b_i(row_in_2_i),
);
PE #(.width(WIDTH)) pe_row_1_2();
PE #(.width(WIDTH)) pe_row_1_3();

PE #(.width(WIDTH)) pe_row_2_2(
    .clk(clk), .rst_n(rst_n),
    .din_b_r(row_in_3_r), .din_b_i(row_in_3_i),
);
PE #(.width(WIDTH)) pe_row_2_3();

PE #(.width(WIDTH)) pe_row_2_3(
    .clk(clk), .rst_n(rst_n),
    .din_b_r(row_in_4_r), .din_b_i(row_in_4_i),
    .dout_x_r(), .dout_x_i(),
);

endmodule

module DU(
    clk,
    din_r,
    din_i,
    dout_r,
    dout_i
);

endmodule

module PE(
    clk,
    rst_n,
    is_vec_mode,
    din_a_r,
    din_a_i,
    din_b_r,
    din_b_i,
    dout_x_r,
    dout_x_i,
    dout_y_r,
    dout_y_i
);
parameter WIDTH = 14;

input clk, rst_n, is_vec_mode;
input signed [WITDH-1:0] din_a_r, din_a_i,
                         din_b_r, din_b_i;
input signed [WITDH-1:0] dout_x_r, dout_x_i,
                         dout_y_r, dout_y_i;

reg signed [WIDTH-1:0] ang_a_r, ang_a_w,
                       ang_b_r, ang_b_w,
                       ang_1_r, ang_b_w;

wire signed [WIDTH-1:0] cordic_1_z, cordic_2_z,
                        cordic_3_z, cordic_4_z;
wire signed [WIDTH-1:0] ang_a, ang_b;
wire signed [WIDTH-1:0] zf_a_r_or_abs_a, zf_a_i,
                        zf_b_r_or_abs_b, zf_b_i;
wire signed [WIDTH-1:0] x_r_or_mag, x_i,
                        y_r, y_i;
wire signed [WIDTH-1:0] ang_1;

assign cordic_1_z = is_vec_mode ? 0 : ang_a_r;
assign cordic_2_z = is_vec_mode ? 0 : ang_b_r;

CORDIC #(.width(WIDTH)) cordic_1(
    .clk(clk), .is_vec_mode(is_vec_mode),
    .din_x(din_a_r), .din_y(din_a_i), .din_z(cordic_1_z),
    .dout_x(zf_a_r_or_abs_a), .dout_y(zf_a_i), .dout_z(ang_a)
);
CORDIC #(.width(WIDTH)) cordic_2(
    .clk(clk), .is_vec_mode(is_vec_mode),
    .din_x(din_b_r), .din_y(din_b_i), .din_z(cordic_2_z),
    .dout_x(zf_b_r_or_abs_b), .dout_y(zf_b_i), .dout_z(ang_b)
);

assign cordic_3_z = is_vec_mode ? 0 : ang_1_r;
assign cordic_4_z = is_vec_mode ? 0 : ang_1_r;

CORDIC #(.width(WIDTH)) cordic_3(
    .clk(clk), .is_vec_mode(is_vec_mode),
    .din_x(zf_b_r_or_abs_b), .din_y(zf_b_r_or_abs_b), .din_z(cordic_3_z),
    .dout_x(x_r_or_mag), .dout_y(y_r), .dout_z(ang_1)
);
CORDIC #(.width(WIDTH)) cordic_4(
    .clk(clk), .is_vec_mode(is_vec_mode),
    .din_x(zf_a_i), .din_y(zf_b_i), .din_z(cordic_4_z),
    .dout_x(x_i), .dout_y(y_i), .dout_z()
);
endmodule

module CORDIC(
    clk,
    is_vec_mode,
    din_x,
    din_y,
    din_z,
    dout_x,
    dout_y,
    dout_z
);

parameter WIDTH = 14;

input clk, is_vec_mode;
input signed [WITDH-1:0] din_x, din_y, din_z;
input signed [WITDH-1:0] dout_x, dout_y, dout_z;

endmodule