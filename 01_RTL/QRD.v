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
parameter ITER = 32;
parameter HALF_ITER = 16;
parameter ITER_SWITCH = 13; // 13 -> 16 (13th iteration for CORDIC mult)
parameter ITER_MAX = ITER-1;
parameter ITER_LAST = HALF_ITER+ITER_SWITCH;

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

// Input buffer
reg in_row_1_f_r, in_row_2_f_r, in_row_3_f_r;
reg in_row_1_f_w, in_row_2_f_w, in_row_3_f_w;
reg signed [WIDTH-1:0] in_row_1_r_r, in_row_1_i_r,
                       in_row_2_r_r, in_row_2_i_r,
                       in_row_3_r_r, in_row_3_i_r,
                       in_row_4_r_r, in_row_4_i_r;
reg signed [WIDTH-1:0] in_row_1_r_w, in_row_1_i_w,
                       in_row_2_r_w, in_row_2_i_w,
                       in_row_3_r_w, in_row_3_i_w,
                       in_row_4_r_w, in_row_4_i_w;

// Systolic array buffer (for pipelining)
reg signed [2*WIDTH:0] row_buf_1_1_r, row_buf_1_1_w; // {flag, real, imag}
reg signed [2*WIDTH:0] row_buf_1_2_r, row_buf_1_2_w;
reg signed [2*WIDTH:0] row_buf_1_3_r, row_buf_1_3_w;
reg signed [2*WIDTH:0] row_buf_2_1_r, row_buf_2_1_w;
reg signed [2*WIDTH:0] row_buf_2_2_r, row_buf_2_2_w;
reg signed [2*WIDTH:0] row_buf_3_1_r, row_buf_3_1_w;

reg signed [2*WIDTH:0] col_buf_1_2_r, col_buf_1_2_w;
reg signed [2*WIDTH:0] col_buf_1_3_r, col_buf_1_3_w;
reg signed [2*WIDTH:0] col_buf_2_2_r, col_buf_2_2_w;

// Row-wise wire
wire signed [WIDTH-1:0] row_in_1_r_1, row_out_1_r_1, row_in_1_i_1, row_out_1_i_1;
wire signed [WIDTH-1:0] row_in_1_r_2, row_out_1_r_2, row_in_1_i_2, row_out_1_i_2;
wire signed [WIDTH-1:0] row_in_1_r_3, row_out_1_r_3, row_in_1_i_3, row_out_1_i_3;
wire signed [WIDTH-1:0] row_out_1_r_4, row_out_1_i_4;

wire signed [WIDTH-1:0] row_in_2_r_2, row_out_2_r_2, row_in_2_i_2, row_out_2_i_2;
wire signed [WIDTH-1:0] row_in_2_r_3, row_out_2_r_3, row_in_2_i_3, row_out_2_i_3;
wire signed [WIDTH-1:0] row_out_2_r_4, row_out_2_i_4;

wire signed [WIDTH-1:0] row_in_3_r_3, row_out_3_r_3, row_in_3_i_3, row_out_3_i_3;
wire signed [WIDTH-1:0] row_out_3_r_4, row_out_3_i_4;

wire row_in_1_f_1, row_out_1_f_1, row_in_1_f_2, row_out_1_f_2, row_in_1_f_3, row_out_1_f_3;
wire row_in_2_f_2, row_out_2_f_2, row_in_2_f_3, row_out_2_f_3;
wire row_in_3_f_3, row_out_3_f_3;
// Column-wise wire
wire signed [WIDTH-1:0] col_in_3_r_1, col_out_3_r_1, col_in_3_i_1, col_out_3_i_1;
wire signed [WIDTH-1:0] col_in_3_r_2, col_out_3_r_2, col_in_3_i_2, col_out_3_i_2;
wire signed [WIDTH-1:0] col_in_3_r_3, col_out_3_r_3, col_in_3_i_3, col_out_3_i_3;

wire signed [WIDTH-1:0] col_in_2_r_1, col_out_2_r_1, col_in_2_i_1, col_out_2_i_1;
wire signed [WIDTH-1:0] col_in_2_r_2, col_out_2_r_2, col_in_2_i_2, col_out_2_i_2;

wire signed [WIDTH-1:0] col_in_1_r_1, col_out_1_r_1, col_in_1_i_1, col_out_1_i_1;

wire col_in_3_f_1, col_out_3_f_1, col_in_3_f_2, col_out_3_f_2, col_in_3_f_3, col_out_3_f_3;
wire col_in_2_f_1, col_out_2_f_1, col_in_2_f_2, col_out_2_f_2;
wire col_in_1_f_1, col_out_1_f_1;
// Pipeline control
wire PE_switch, PE_load, DU_load, CORDIC_load;

// Registers
reg [3:0] state_r, state_w;

reg [4:0] counter_r, counter_w;

/* 1st row */
DU #(.WIDTH(WIDTH)) du_row_1(
    .clk(clk), .load(DU_load),
    .din_r(in_row_1_r_r),   .din_i(in_row_1_i_r),   .din_f(in_row_1_f_r),
    .dout_r(row_out_1_r_1), .dout_i(row_out_1_i_1), .dout_f(row_out_1_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_1(
    .clk(clk), .rst_n(rst_n), .switch(PE_switch),
    .load(PE_load), .iter(counter_r[3:0]), .subload(CORDIC_load),
    .din_a_r(row_in_1_r_1),   .din_a_i(row_in_1_i_1),   .din_a_f(row_in_1_f_1),
    .din_b_r(in_row_2_r_r),   .din_b_i(in_row_2_i_r),   .din_b_f(in_row_2_f_r),
    .dout_x_r(row_out_1_r_2), .dout_x_i(row_out_1_i_2), .dout_x_f(row_out_1_f_2),
    .dout_y_r(col_out_1_r_1), .dout_y_i(col_out_1_i_1), .dout_y_f(col_out_1_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_2(
    .clk(clk), .rst_n(rst_n), .switch(PE_switch),
    .load(PE_load), .iter(counter_r[3:0]), .subload(CORDIC_load),
    .din_a_r(row_in_1_r_2),   .din_a_i(row_in_1_i_2),   .din_a_f(row_in_1_f_2),
    .din_b_r(in_row_3_r_r),   .din_b_i(in_row_3_i_r),   .din_b_f(in_row_3_f_r),
    .dout_x_r(row_out_1_r_3), .dout_x_i(row_out_1_i_3), .dout_x_f(row_out_1_f_3),
    .dout_y_r(col_out_2_r_1), .dout_y_i(col_out_2_i_1), .dout_y_f(col_out_2_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_3(
    .clk(clk), .rst_n(rst_n), .switch(PE_switch),
    .load(PE_load), .iter(counter_r[3:0]), .subload(CORDIC_load),
    .din_a_r(row_in_1_r_3),   .din_a_i(row_in_1_i_3),   .din_a_f(),
    .din_b_r(in_row_4_r_r),   .din_b_i(in_row_4_i_r),   .din_b_f(),
    .dout_x_r(row_out_1_r_4), .dout_x_i(row_out_1_i_4), .dout_x_f(),
    .dout_y_r(col_out_3_r_1), .dout_y_i(col_out_3_i_1), .dout_y_f()
);

/* 2nd row */
DU #(.WIDTH(WIDTH)) du_row_2(
    .clk(clk), .load(DU_load),
    .din_r(col_in_1_r_1),  .din_i(col_in_1_i_1),  .din_f(col_in_1_f_1),
    .dout_r(row_out_2_r_2), .dout_i(row_out_2_i_2), .dout_f(row_out_2_f_2)
);
PE #(.WIDTH(WIDTH)) pe_row_2_2(
    .clk(clk), .rst_n(rst_n), .switch(PE_switch),
    .load(PE_load), .iter(counter_r[3:0]), .subload(CORDIC_load),
    .din_a_r(row_in_2_r_2), .din_a_i(row_in_2_i_2), .din_a_f(row_in_2_f_2),
    .din_b_r(col_in_2_r_1), .din_b_i(col_in_2_i_1), .din_b_f(col_in_2_f_1),
    .dout_x_r(row_out_2_r_3), .dout_x_i(row_out_2_i_3), .dout_x_f(row_out_2_f_3),
    .dout_y_r(col_out_2_r_2), .dout_y_i(col_out_2_i_2), .dout_y_f(col_out_2_f_2)
);
PE #(.WIDTH(WIDTH)) pe_row_2_3(
    .clk(clk), .rst_n(rst_n), .switch(PE_switch),
    .load(PE_load), .iter(counter_r[3:0]), .subload(CORDIC_load),
    .din_a_r(row_in_2_r_3),   .din_a_i(row_in_2_i_3),   .din_a_f(),
    .din_b_r(col_in_3_r_1),   .din_b_i(col_in_3_i_1),   .din_b_f(),
    .dout_x_r(row_out_2_r_4), .dout_x_i(row_out_2_i_4), .dout_x_f(),
    .dout_y_r(col_out_3_r_2), .dout_y_i(col_out_3_i_2), .dout_y_f()
);

/* 3rd row */
DU #(.WIDTH(WIDTH)) du_row_3(
    .clk(clk), .load(DU_load),
    .din_r(col_in_2_r_2),   .din_i(col_in_2_i_2),   .din_f(col_in_2_f_2),
    .dout_r(row_out_3_r_3), .dout_i(row_out_3_i_3), .dout_f(row_out_3_f_3)
);
PE #(.WIDTH(WIDTH)) pe_row_3_3(
    .clk(clk), .rst_n(rst_n), .switch(PE_switch),
    .load(PE_load), .iter(counter_r[3:0]), .subload(CORDIC_load),
    .din_a_r(row_in_3_r_3),   .din_a_i(row_in_3_i_3),   .din_a_f(),
    .din_b_r(col_in_3_r_2),   .din_b_i(col_in_3_i_2),   .din_b_f(),
    .dout_x_r(row_out_3_r_4), .dout_x_i(row_out_3_i_4), .dout_x_f(),
    .dout_y_r(col_out_3_r_3), .dout_y_i(col_out_3_i_3), .dout_y_f()
);

/* 4th row */
DU #(.WIDTH(WIDTH)) du_row_4(
    .clk(clk), .load(DU_load),
    .din_r(col_in_3_r_3),   .din_i(col_in_3_i_3),   .din_f(),
    .dout_r(row_out_4_r_4), .dout_i(row_out_4_i_4), .dout_f()
);

/* Continuous assignment */
assign PE_switch = counter_r[4];
assign PE_load = counter_r == ITER_LAST;
assign DU_load = counter_r == ITER_LAST-1;
assign CORDIC_load = counter_r == ITER_LAST || counter_r == ITER_SWITCH;

/* Output logic */
assign {row_out_1_r, row_out_1_i} = {row_out_1_r_4, row_out_1_i_4};
assign {row_out_2_r, row_out_2_i} = {row_out_2_r_4, row_out_2_i_4};
assign {row_out_3_r, row_out_3_i} = {row_out_3_r_4, row_out_3_i_4};
assign {row_out_4_r, row_out_4_i} = {row_out_4_r_4, row_out_4_i_4};

assign in_ready = (state_r == STATE_WAIT && counter_r != ITER_LAST) ||
                  counter_r == ITER_LAST-1;

always @(*) begin
    case (state_r)
    STATE_IDLE:  counter_w = counter_r;
    STATE_WAIT:  counter_w = counter_r == ITER_LAST ? 0 : counter_r+1;
    STATE_CALC:  counter_w = counter_r == ITER_LAST ? 0 :
                             counter_r == ITER_SWITCH ? 16 :
                             counter_r+1;
    endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
        counter_r <= -5;
    end
    else begin
        counter_r <= counter_w;
    end
end

always @(*) begin
    case (state_r)
    STATE_IDLE: state_w = STATE_WAIT;
    STATE_WAIT: state_w = counter_r == ITER_LAST ? STATE_CALC : STATE_WAIT;
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

// Interconnect
assign {row_in_1_f_1, row_in_1_r_1, row_in_1_i_1} = {row_out_1_f_1, row_out_1_r_1, row_out_1_i_1};
assign {row_in_1_f_2, row_in_1_r_2, row_in_1_i_2} = row_buf_1_1_r;
assign {row_in_1_f_3, row_in_1_r_3, row_in_1_i_3} = row_buf_1_2_r;

assign {row_in_2_f_2, row_in_2_r_2, row_in_2_i_2} = {row_out_2_f_2, row_out_2_r_2, row_out_2_i_2};
assign {row_in_2_f_3, row_in_2_r_3, row_in_2_i_3} = row_buf_2_1_r;

assign {row_in_3_f_3, row_in_3_r_3, row_in_3_i_3} = {row_out_3_f_3, row_out_3_r_3, row_out_3_i_3};

assign {col_in_1_f_1, col_in_1_r_1, col_in_1_i_1} = {col_out_1_f_1, col_out_1_r_1, col_out_1_i_1};
assign {col_in_2_f_2, col_in_2_r_2, col_in_2_i_2} = {col_out_2_f_2, col_out_2_r_2, col_out_2_i_2};
assign {col_in_3_r_3, col_in_3_i_3} = {col_out_3_r_3, col_out_3_i_3};


always @(*) begin
    row_buf_1_1_w = {row_out_1_f_2, row_out_1_r_2, row_out_1_i_2};
    row_buf_1_2_w = {row_out_1_f_3, row_out_1_r_3, row_out_1_i_3};
    row_buf_1_3_w = {1'b0, row_out_1_r_4, row_out_1_i_4};
    row_buf_2_1_w = {row_out_2_f_3, row_out_2_r_3, row_out_2_i_3};
    row_buf_2_2_w = {1'b0, row_out_2_r_4, row_out_2_i_4};
    row_buf_3_1_w = {1'b0, row_out_3_r_4, row_out_3_i_4};
    col_buf_1_2_w = {col_out_2_f_1, col_out_2_r_1, col_out_2_i_1};
    col_buf_1_3_w = {1'b0, col_out_3_r_1, col_out_3_i_1};
    col_buf_2_2_w = {1'b0, col_out_3_r_2, col_out_3_i_2};
end

always @(posedge clk) begin
    row_buf_1_1_r <= row_buf_1_1_w;
    row_buf_1_2_r <= row_buf_1_2_w;
    row_buf_1_3_r <= row_buf_1_3_w;
    row_buf_2_1_r <= row_buf_2_1_w;
    row_buf_2_2_r <= row_buf_2_2_w;
    row_buf_3_1_r <= row_buf_3_1_w;
    col_buf_1_2_r <= col_buf_1_2_w;
    col_buf_1_3_r <= col_buf_1_3_w;
    col_buf_2_2_r <= col_buf_2_2_w;
end

// Input buffer
always @(*) begin
    in_row_1_f_w = row_in_1_f;
    in_row_2_f_w = row_in_2_f;
    in_row_3_f_w = row_in_3_f;
    in_row_1_r_w = row_in_1_r;
    in_row_2_r_w = row_in_2_r;
    in_row_3_r_w = row_in_3_r;
    in_row_4_r_w = row_in_4_r;
    in_row_1_i_w = row_in_1_i;
    in_row_2_i_w = row_in_2_i;
    in_row_3_i_w = row_in_3_i;
    in_row_4_i_w = row_in_4_i;
end

always @(posedge clk) begin
    in_row_1_f_r <= in_row_1_f_w;
    in_row_2_f_r <= in_row_2_f_w;
    in_row_3_f_r <= in_row_3_f_w;
    in_row_1_r_r <= in_row_1_r_w;
    in_row_2_r_r <= in_row_2_r_w;
    in_row_3_r_r <= in_row_3_r_w;
    in_row_4_r_r <= in_row_4_r_w;
    in_row_1_i_r <= in_row_1_i_w;
    in_row_2_i_r <= in_row_2_i_w;
    in_row_3_i_r <= in_row_3_i_w;
    in_row_4_i_r <= in_row_4_i_w;
end
endmodule

module DU(
    clk,
    load,
    din_f,
    din_r,
    din_i,
    dout_f,
    dout_r,
    dout_i
);
parameter WIDTH = 14;

input clk;
input din_f, load;
input signed [WIDTH-1:0] din_r, din_i;
output dout_f;
output signed [WIDTH-1:0] dout_r, dout_i;

reg signed [2*WIDTH:0] reg_r, reg_w;

assign {dout_f, dout_r, dout_i} = reg_r;

always @(*) begin
    reg_w = load ? {din_f, din_r, din_i} : reg_r;
end
always @(posedge clk) begin
    reg_r <= reg_w;
end
endmodule

module PE(
    clk,
    rst_n,
    switch,
    load,
    subload,
    iter,
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
input switch, load, subload;
input [3:0] iter;
input din_a_f, din_b_f;
input signed [WIDTH-1:0] din_a_r, din_a_i,
                         din_b_r, din_b_i;
output dout_x_f, dout_y_f;
output signed [WIDTH-1:0] dout_x_r, dout_x_i,
                          dout_y_r, dout_y_i;

/* Registers */
reg signed [WIDTH-1:0] ang_a_r, ang_a_w,
                       ang_b_r, ang_b_w,
                       ang_1_r, ang_1_w;
reg signed [WIDTH-1:0] cordic_1_x_r, cordic_1_x_w;
reg signed [WIDTH-1:0] cordic_1_yz_r, cordic_1_yz_w;
reg signed [WIDTH-1:0] cordic_2_x_r, cordic_2_x_w;
reg signed [WIDTH-1:0] cordic_2_yz_r, cordic_2_yz_w;
reg din_a_f_r, din_a_f_w;
reg din_b_f_r, din_b_f_w;

/* Wires */
wire is_vec_mode, is_vec_mode_nxt;
wire signed [WIDTH-1:0] cordic_1_x, cordic_2_x;
wire signed [WIDTH-1:0] cordic_1_y, cordic_2_y;
wire signed [WIDTH-1:0] cordic_1_z, cordic_2_z;

wire signed [WIDTH-1:0] cordic_1_x_out, cordic_2_x_out;
wire signed [WIDTH-1:0] cordic_1_y_out, cordic_2_y_out;
wire signed [WIDTH-1:0] cordic_1_z_out, cordic_2_z_out;

// wire signed [WIDTH-1:0] cordic_1_x_load, cordic_2_x_load;
// wire signed [WIDTH-1:0] cordic_1_yz_load, cordic_2_yz_load;

assign is_vec_mode = din_a_f_r;
assign is_vec_mode_nxt = din_a_f;

// assign cordic_1_x_load = load ? din_a_r : cordic_1_x_r;
// assign cordic_2_x_load = load ? din_a_i : cordic_2_x_r;
// assign cordic_1_yz_load = load ? din_b_r : cordic_1_yz_r;
// assign cordic_2_yz_load = load ? din_b_i : cordic_2_yz_r;

// assign cordic_1_x = (switch ? cordic_1_x_load : din_a_r);
// assign cordic_2_x = (switch ? cordic_1_yz_load : din_b_r);
// assign cordic_1_y = (switch ? cordic_2_x_load : din_a_i);
// assign cordic_2_y = (switch ? cordic_2_yz_load : din_b_i);

assign cordic_1_x = (switch ? din_a_r : cordic_1_x_out);
assign cordic_2_x = (switch ? din_b_r : cordic_1_y_out);
assign cordic_1_y = (switch ? din_a_i : cordic_2_x_out);
assign cordic_2_y = (switch ? din_b_i : cordic_2_y_out);
assign cordic_1_z = is_vec_mode_nxt ? 0 : (switch ? ang_a_r : ang_1_r);
assign cordic_2_z = is_vec_mode_nxt ? 0 : (switch ? ang_b_r : ang_1_r);
// TODO disable cordic_2 in the 2nd cycle of vectoring mode

CORDIC #(.WIDTH(WIDTH)) cordic_1(
    .clk(clk), .is_vec_mode(is_vec_mode), .load(subload), .iter(iter),
    .din_x(cordic_1_x), .din_y(cordic_1_y), .din_z(cordic_1_z),
    .dout_x(cordic_1_x_out), .dout_y(cordic_1_y_out), .dout_z(cordic_1_z_out)
);
CORDIC #(.WIDTH(WIDTH)) cordic_2(
    .clk(clk), .is_vec_mode(is_vec_mode), .load(subload), .iter(iter),
    .din_x(cordic_2_x), .din_y(cordic_2_y), .din_z(cordic_2_z),
    .dout_x(cordic_2_x_out), .dout_y(cordic_2_y_out), .dout_z(cordic_2_z_out)
);

always @(*) begin
    // angle can be retrieved 1 cycle before mult is finished
    ang_a_w = is_vec_mode && !switch && iter == 12 ? -cordic_1_z_out : ang_a_r;
    ang_b_w = is_vec_mode && !switch && iter == 12 ? -cordic_2_z_out : ang_b_r;
    ang_1_w = is_vec_mode && switch && iter == 12 ? -cordic_1_z_out : ang_1_r;
end

always @(*) begin
    din_a_f_w = load ? din_a_f : din_a_f_r;
    din_b_f_w = load ? din_b_f : din_b_f_r;
end

// Output logic
assign dout_x_f = din_a_f_r;
assign {dout_x_r, dout_x_i} = (
    is_vec_mode ? {cordic_1_x_out, {WIDTH{1'b0}}} : {cordic_1_x_out, cordic_2_x_out}
);
assign dout_y_f = din_b_f_r;
assign {dout_y_r, dout_y_i} = (
    is_vec_mode ? 0 : {cordic_1_y_out, cordic_2_y_out}
);

always @(posedge clk) begin
    if (!rst_n) begin
        din_a_f_r <= 0;
    end
    else begin
        din_a_f_r <= din_a_f_w;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        din_b_f_r <= 0;
    end
    else begin
        din_b_f_r <= din_b_f_w;
    end
end

always @(posedge clk) begin
    if (!rst_n) begin
        ang_a_r <= 0;
    end
    else begin
        ang_a_r <= ang_a_w;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        ang_b_r <= 0;
    end
    else begin
        ang_b_r <= ang_b_w;
    end
end
always @(posedge clk) begin
    if (!rst_n) begin
        ang_1_r <= 0;
    end
    else begin
        ang_1_r <= ang_1_w;
    end
end
always @(posedge clk) begin
    cordic_1_x_r  <= cordic_1_x_w;
end
always @(posedge clk) begin
    if (!rst_n) begin
        cordic_1_yz_r <= 0;
    end
    else begin
        cordic_1_yz_r <= cordic_1_yz_w;
    end
end
always @(posedge clk) begin
    cordic_2_x_r  <= cordic_2_x_w;
end
always @(posedge clk) begin
    if (!rst_n) begin
        cordic_2_yz_r <= 0;
    end
    else begin
        cordic_2_yz_r <= cordic_2_yz_w;
    end
end
endmodule

module CORDIC(
    clk,
    is_vec_mode,
    load,
    iter,
    din_x,
    din_y,
    din_z,
    dout_x,
    dout_y,
    dout_z
);

parameter WIDTH = 14;
parameter GAIN_WIDTH = 10; // 10 fraction bits

input clk, is_vec_mode, load;
input [3:0] iter;
input signed [WIDTH-1:0] din_x, din_y, din_z;
input signed [WIDTH-1:0] dout_x, dout_y, dout_z;

reg signed [WIDTH-1:0] x_r, x_w;
reg signed [WIDTH-1:0] y_r, y_w;
reg signed [WIDTH-1:0] z_r, z_w, dz;
reg [3:0] last_iter_r, last_iter_w;

wire signed [WIDTH-1:0] x_sft, y_sft;
wire signed [WIDTH-1:0] x_nxt, y_nxt, z_nxt;

reg signed [WIDTH+GAIN_WIDTH-1:0] x_prod, y_prod;
wire mode;

always @(*) begin
    case (iter)
    4'b0000: dz = 'b00001100100100;
    4'b0001: dz = 'b00000111011011;
    4'b0010: dz = 'b00000011111011;
    4'b0011: dz = 'b00000001111111;
    4'b0100: dz = 'b00000001000000;
    4'b0101: dz = 'b00000000100000;
    4'b0110: dz = 'b00000000010000;
    4'b0111: dz = 'b00000000001000;
    4'b1000: dz = 'b00000000000100;
    4'b1001: dz = 'b00000000000010;
    4'b1010: dz = 'b00000000000001;
    4'b1011: dz = 'b00000000000000;
    4'b1100: dz = 'b00000000000000;
    default: dz = 'b00000000000000;
    endcase
end

always @(*) begin
    case(last_iter_r)
    4'b0001: begin x_prod = $signed('b1111111111) * x_r; y_prod = $signed('b1111111111) * y_r; end
    4'b0010: begin x_prod = $signed('b1011010100) * x_r; y_prod = $signed('b1011010100) * y_r; end
    4'b0011: begin x_prod = $signed('b1010001000) * x_r; y_prod = $signed('b1010001000) * y_r; end
    4'b0100: begin x_prod = $signed('b1001110100) * x_r; y_prod = $signed('b1001110100) * y_r; end
    4'b0101: begin x_prod = $signed('b1001101111) * x_r; y_prod = $signed('b1001101111) * y_r; end
    4'b1111: begin x_prod = {x_r, {GAIN_WIDTH{1'b0}}}; y_prod = {y_r, {GAIN_WIDTH{1'b0}}}; end
    default: begin x_prod = $signed('b1001101110) * x_r; y_prod = $signed('b1001101110) * y_r; end
    endcase
end

assign dout_x = x_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH]; // remove fractions
assign dout_y = y_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH];
assign dout_z = z_r;

assign mode = (is_vec_mode && y_r > 0) || (!is_vec_mode && z_r < 0);
assign update = (is_vec_mode && y_r != 0) || (!is_vec_mode && z_r != 0);
assign x_nxt = mode ? (x_r + y_sft) : (x_r - y_sft);
assign y_nxt = mode ? (y_r - x_sft) : (y_r + x_sft);
assign z_nxt = mode ? (z_r + dz) : (z_r - dz);

BarrelShifter #(.WIDTH(WIDTH)) shift1 (.din(x_r), .shift(iter), .dout(x_sft));
BarrelShifter #(.WIDTH(WIDTH)) shift2 (.din(y_r), .shift(iter), .dout(y_sft));

always @(*) begin // TODO handling values out of convergence
    x_w = load ? din_x : (update ? x_nxt : x_r);
    y_w = load ? din_y : (update ? y_nxt : y_r);
    z_w = load ? din_z : (update ? z_nxt : z_r);
    last_iter_w = load ? -1 : (update ? last_iter_r+1 : last_iter_r);
end

always @(posedge clk) begin
    x_r <= x_w;
    y_r <= y_w;
    z_r <= z_w;
    last_iter_r <= last_iter_w;
end
endmodule

module BarrelShifter(
    din,
    shift,
    dout
);

parameter WIDTH = 14;
input  [WIDTH-1:0] din;
input  [3:0] shift;
output [WIDTH-1:0] dout;
wire   [WIDTH-1:0] shr1, shr2, shr4;

assign shr1 = shift[0] ? {din[WIDTH-1], din[WIDTH-1:1]} : din;
assign shr2 = shift[1] ? {{2{din[WIDTH-1]}}, shr1[WIDTH-1:2]} : shr1;
assign shr4 = shift[2] ? {{4{din[WIDTH-1]}}, shr2[WIDTH-1:4]} : shr2;
assign dout = shift[3] ? {{8{din[WIDTH-1]}}, shr4[WIDTH-1:8]} : shr4;
endmodule