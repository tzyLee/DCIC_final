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
parameter ITER_SWITCH = 3; // 14 -> 16 (13th iteration for CORDIC mult)
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
output signed [WIDTH-1:0] row_out_1_r, row_out_1_i,
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
wire signed [WIDTH-1:0] row_out_4_r_4, row_out_4_i_4;

wire row_in_1_f_1, row_out_1_f_1, row_in_1_f_2, row_out_1_f_2, row_in_1_f_3, row_out_1_f_3, row_out_1_f_4;
wire row_in_2_f_2, row_out_2_f_2, row_in_2_f_3, row_out_2_f_3;
wire row_in_3_f_3, row_out_3_f_3;
// Column-wise wire
wire signed [WIDTH-1:0] col_in_3_r_1, col_out_3_r_1, col_in_3_i_1, col_out_3_i_1;
wire signed [WIDTH-1:0] col_in_3_r_2, col_out_3_r_2, col_in_3_i_2, col_out_3_i_2;
wire signed [WIDTH-1:0] col_in_3_r_3, col_out_3_r_3, col_in_3_i_3, col_out_3_i_3;

wire signed [WIDTH-1:0] col_in_2_r_1, col_out_2_r_1, col_in_2_i_1, col_out_2_i_1;
wire signed [WIDTH-1:0] col_in_2_r_2, col_out_2_r_2, col_in_2_i_2, col_out_2_i_2;

wire signed [WIDTH-1:0] col_in_1_r_1, col_out_1_r_1, col_in_1_i_1, col_out_1_i_1;

wire col_in_2_f_1, col_out_2_f_1, col_in_2_f_2, col_out_2_f_2;
wire col_in_1_f_1, col_out_1_f_1;

wire enable2, enable3, enable4;
// Pipeline control
wire PE_switch, PE_load, DU_load, CORDIC_load;

// Clock gating
wire pipeline_clk, input_clk;

// Registers
reg [3:0] state_r, state_w;

reg [4:0] counter_r, counter_w;
reg [3:0] delay_ctrl_r, delay_ctrl_w;

reg start_output_r, start_output_w;

/* 1st row */
DU #(.WIDTH(WIDTH)) du_row_1(
    .clk(clk),
    .din_r(in_row_1_r_r),   .din_i(in_row_1_i_r),   .din_f(in_row_1_f_r),
    .dout_r(row_out_1_r_1), .dout_i(row_out_1_i_1), .dout_f(row_out_1_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_1(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_in_1_r_1),   .din_a_i(row_in_1_i_1),   .din_a_f(row_in_1_f_1),
    .din_b_r(in_row_2_r_r),   .din_b_i(in_row_2_i_r),   .din_b_f(in_row_2_f_r),
    .dout_x_r(row_out_1_r_2), .dout_x_i(row_out_1_i_2), .dout_x_f(row_out_1_f_2),
    .dout_y_r(col_out_1_r_1), .dout_y_i(col_out_1_i_1), .dout_y_f(col_out_1_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_2(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_in_1_r_2),   .din_a_i(row_in_1_i_2),   .din_a_f(row_in_1_f_2),
    .din_b_r(in_row_3_r_r),   .din_b_i(in_row_3_i_r),   .din_b_f(in_row_3_f_r),
    .dout_x_r(row_out_1_r_3), .dout_x_i(row_out_1_i_3), .dout_x_f(row_out_1_f_3),
    .dout_y_r(col_out_2_r_1), .dout_y_i(col_out_2_i_1), .dout_y_f(col_out_2_f_1)
);
PE #(.WIDTH(WIDTH)) pe_row_1_3(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_in_1_r_3),   .din_a_i(row_in_1_i_3),   .din_a_f(row_in_1_f_3),
    .din_b_r(in_row_4_r_r),   .din_b_i(in_row_4_i_r),   .din_b_f(),
    .dout_x_r(row_out_1_r_4), .dout_x_i(row_out_1_i_4), .dout_x_f(row_out_1_f_4),
    .dout_y_r(col_out_3_r_1), .dout_y_i(col_out_3_i_1), .dout_y_f()
);

/* 2nd row */
assign enable2 = delay_ctrl_r == 2;
DULong #(.WIDTH(WIDTH)) du_row_2(
    .clk(clk), .iter(counter_r), .enable(enable2),
    .din_r(col_in_1_r_1),  .din_i(col_in_1_i_1),  .din_f(col_in_1_f_1),
    .dout_r(row_out_2_r_2), .dout_i(row_out_2_i_2), .dout_f(row_out_2_f_2)
);
PE #(.WIDTH(WIDTH)) pe_row_2_2(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_in_2_r_2), .din_a_i(row_in_2_i_2), .din_a_f(row_in_2_f_2),
    .din_b_r(col_in_2_r_1), .din_b_i(col_in_2_i_1), .din_b_f(col_in_2_f_1),
    .dout_x_r(row_out_2_r_3), .dout_x_i(row_out_2_i_3), .dout_x_f(row_out_2_f_3),
    .dout_y_r(col_out_2_r_2), .dout_y_i(col_out_2_i_2), .dout_y_f(col_out_2_f_2)
);
PE #(.WIDTH(WIDTH)) pe_row_2_3(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_in_2_r_3),   .din_a_i(row_in_2_i_3),   .din_a_f(row_in_2_f_3),
    .din_b_r(col_in_3_r_1),   .din_b_i(col_in_3_i_1),   .din_b_f(),
    .dout_x_r(row_out_2_r_4), .dout_x_i(row_out_2_i_4), .dout_x_f(),
    .dout_y_r(col_out_3_r_2), .dout_y_i(col_out_3_i_2), .dout_y_f()
);

// /* 3rd row */
assign enable3 = delay_ctrl_r == 4;
DULong #(.WIDTH(WIDTH)) du_row_3(
    .clk(clk), .iter(counter_r), .enable(enable3),
    .din_r(col_in_2_r_2),   .din_i(col_in_2_i_2),   .din_f(col_in_2_f_2),
    .dout_r(row_out_3_r_3), .dout_i(row_out_3_i_3), .dout_f(row_out_3_f_3)
);
PE #(.WIDTH(WIDTH)) pe_row_3_3(
    .clk(clk), .rst_n(rst_n),
    .din_a_r(row_in_3_r_3),   .din_a_i(row_in_3_i_3),   .din_a_f(row_in_3_f_3),
    .din_b_r(col_in_3_r_2),   .din_b_i(col_in_3_i_2),   .din_b_f(),
    .dout_x_r(row_out_3_r_4), .dout_x_i(row_out_3_i_4), .dout_x_f(),
    .dout_y_r(col_out_3_r_3), .dout_y_i(col_out_3_i_3), .dout_y_f()
);

/* 4th row */
// assign enable4 = delay_ctrl_r == 6;
// DULong #(.WIDTH(WIDTH)) du_row_4(
//     .clk(clk), .iter(counter_r), .enable(enable4),
//     .din_r(col_in_3_r_3),   .din_i(col_in_3_i_3),   .din_f(),
//     .dout_r(row_out_4_r_4), .dout_i(row_out_4_i_4), .dout_f()
// );
assign {row_out_4_r_4, row_out_4_i_4} = {col_in_3_r_3, col_in_3_i_3};

/* Continuous assignment */
assign DU_load = state_r == STATE_WAIT || counter_r == ITER_LAST;

/* Output logic */
assign {row_out_1_r, row_out_1_i} = {row_out_1_r_4, row_out_1_i_4};
assign {row_out_2_r, row_out_2_i} = {row_out_2_r_4, row_out_2_i_4};
assign {row_out_3_r, row_out_3_i} = {row_out_3_r_4, row_out_3_i_4};
assign {row_out_4_r, row_out_4_i} = {row_out_4_r_4, row_out_4_i_4};

assign in_ready = (state_r == STATE_WAIT && counter_r != ITER_LAST) ||
                  counter_r == ITER_LAST-1;
assign out_valid = delay_ctrl_r >= 4 && counter_r <= 4;

always @(*) begin
    case (state_r)
    STATE_IDLE:  counter_w = counter_r;
    STATE_WAIT:  counter_w = counter_r == ITER_LAST ? 0 : counter_r+1;
    STATE_CALC:  counter_w = counter_r == ITER_LAST ? 0 : counter_r+1;
    default:     counter_w = counter_r;
    endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
        counter_r <= -14;
    end
    else begin
        counter_r <= counter_w;
    end
end

always @(*) begin
    if (state_r == STATE_IDLE) begin
        delay_ctrl_w = 0;
    end
    else begin
        delay_ctrl_w = counter_r == ITER_LAST ? delay_ctrl_r+1 : delay_ctrl_r;
    end
end
always @(posedge clk) begin
    delay_ctrl_r <= delay_ctrl_w;
end

always @(*) begin
    case (state_r)
    STATE_IDLE: state_w = STATE_WAIT;
    STATE_WAIT: state_w = counter_r == ITER_LAST ? STATE_CALC : STATE_WAIT;
    STATE_CALC: state_w = STATE_CALC;
    default:    state_w = STATE_IDLE;
    endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
        state_r <= STATE_IDLE;
    end
    else begin
        state_r <= state_w;
    end
end

// Interconnect
assign {row_in_1_f_1, row_in_1_r_1, row_in_1_i_1} = {row_out_1_f_1, row_out_1_r_1, row_out_1_i_1};
assign {row_in_1_f_2, row_in_1_r_2, row_in_1_i_2} = {row_out_1_f_2, row_out_1_r_2, row_out_1_i_2};
assign {row_in_1_f_3, row_in_1_r_3, row_in_1_i_3} = {row_out_1_f_3, row_out_1_r_3, row_out_1_i_3};

assign {row_in_2_f_2, row_in_2_r_2, row_in_2_i_2} = {row_out_2_f_2, row_out_2_r_2, row_out_2_i_2};
assign {row_in_2_f_3, row_in_2_r_3, row_in_2_i_3} = {row_out_2_f_3, row_out_2_r_3, row_out_2_i_3};

assign {row_in_3_f_3, row_in_3_r_3, row_in_3_i_3} = {row_out_3_f_3, row_out_3_r_3, row_out_3_i_3};

assign {col_in_1_f_1, col_in_1_r_1, col_in_1_i_1} = {col_out_1_f_1, col_out_1_r_1, col_out_1_i_1};

assign {col_in_2_f_1, col_in_2_r_1, col_in_2_i_1} = {col_out_2_f_1, col_out_2_r_1, col_out_2_i_1};
assign {col_in_2_f_2, col_in_2_r_2, col_in_2_i_2} = {col_out_2_f_2, col_out_2_r_2, col_out_2_i_2};

assign {col_in_3_r_1, col_in_3_i_1} = {col_out_3_r_1, col_out_3_i_1};
assign {col_in_3_r_2, col_in_3_i_2} = {col_out_3_r_2, col_out_3_i_2};
assign {col_in_3_r_3, col_in_3_i_3} = {col_out_3_r_3, col_out_3_i_3};

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

reg signed [2*WIDTH:0] reg_r, reg_w;

assign {dout_f, dout_r, dout_i} = reg_r;

always @(*) begin
    reg_w = {din_f, din_r, din_i};
end
always @(posedge clk) begin
    reg_r <= reg_w;
end
endmodule

module DULong(
    clk,
    iter,
    enable,
    din_f,
    din_r,
    din_i,
    dout_f,
    dout_r,
    dout_i
);
parameter WIDTH = 14;

input clk;
input enable, din_f;
input [4:0] iter;
input signed [WIDTH-1:0] din_r, din_i;
output reg dout_f;
output reg signed [WIDTH-1:0] dout_r, dout_i;

reg signed [2*WIDTH:0] reg_r[0:4], reg_w[0:4];
integer i;


always @(*) begin
    case (iter)
    0: {dout_f, dout_r, dout_i} = reg_r[0];
    1: {dout_f, dout_r, dout_i} = reg_r[1];
    2: {dout_f, dout_r, dout_i} = reg_r[2];
    3: {dout_f, dout_r, dout_i} = reg_r[3];
    4: {dout_f, dout_r, dout_i} = reg_r[4];
    default: {dout_f, dout_r, dout_i} = reg_r[0];
    endcase
end

always @(*) begin
    for (i=0; i<5; i=i+1) begin
        reg_w[i] = reg_r[i];
    end
    if (enable) begin
        case (iter)
        0: reg_w[0] = {din_f, din_r, din_i};
        1: reg_w[1] = {din_f, din_r, din_i};
        2: reg_w[2] = {din_f, din_r, din_i};
        3: reg_w[3] = {din_f, din_r, din_i};
        4: reg_w[4] = {din_f, din_r, din_i};
        endcase
    end
end
always @(posedge clk) begin
    for (i=0; i<5; i=i+1) begin
        reg_r[i] <= reg_w[i];
    end
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
parameter ITER = 8;

input clk, rst_n;
input din_a_f, din_b_f;
input signed [WIDTH-1:0] din_a_r, din_a_i,
                         din_b_r, din_b_i;
output dout_x_f, dout_y_f;
output signed [WIDTH-1:0] dout_x_r, dout_x_i,
                          dout_y_r, dout_y_i;

/* Registers */
reg din_a_f_r, din_a_f_w;
reg din_b_f_r, din_b_f_w;

reg [ITER-1:0] dir_a_r, update_a_r;
wire [ITER-1:0] dir_a_w, update_a_w;
reg [ITER-1:0] dir_b_r, update_b_r;
wire [ITER-1:0] dir_b_w, update_b_w;
reg [ITER-1:0] dir_1_r, update_1_r;
wire [ITER-1:0] dir_1_w, update_1_w;

reg [ITER+1:0] din_vec_1_r, din_vec_1_w;
reg [ITER+1:0] din_vec_2_r, din_vec_2_w;
reg [ITER+1:0] din_vec_y_1_r, din_vec_y_1_w;
reg [ITER+1:0] din_vec_y_2_r, din_vec_y_2_w;

reg ang_a_neg_r;
wire ang_a_neg_w;
reg ang_b_neg_r;
wire ang_b_neg_w;
reg ang_1_neg_r;
wire ang_1_neg_w;

/* Wires */
wire is_vec_mode, is_vec_mode_nxt, is_vec_mode_nxt2;
wire is_vec_mode2;
wire signed [WIDTH-1:0] cordic_1_x, cordic_2_x;
wire signed [WIDTH-1:0] cordic_1_y, cordic_2_y;
wire signed [WIDTH-1:0] cordic_1_z, cordic_2_z, cordic_3_z, cordic_4_z;

wire signed [WIDTH-1:0] cordic_1_x_out, cordic_2_x_out, cordic_3_x_out, cordic_4_x_out;
wire signed [WIDTH-1:0] cordic_1_y_out, cordic_2_y_out, cordic_3_y_out, cordic_4_y_out;
wire signed [WIDTH-1:0] cordic_1_z_out, cordic_2_z_out, cordic_3_z_out, cordic_4_z_out;

// assign is_vec_mode = din_a_f_r;
assign is_vec_mode_nxt = din_a_f;
assign is_vec_mode2 = din_vec_2_r[ITER+1];

assign cordic_1_z = 0;//is_vec_mode_nxt ? 0 : ang_a_r;
assign cordic_2_z = 0; //is_vec_mode_nxt ? 0 : ang_b_r;
assign cordic_3_z = 0; //is_vec_mode_nxt2 ? 0 : ang_1_r;
assign cordic_4_z = 0; //is_vec_mode_nxt2 ? 0 : ang_1_r;

PipelinedCORDIC #(.WIDTH(WIDTH), .ITER(ITER)) cordic_1(
    .clk(clk), .nxt_mode(is_vec_mode_nxt), .din_update(update_a_r), .dout_update(update_a_w), .din_ang_neg(ang_a_neg_r),
    .din_x(din_a_r), .din_y(din_a_i), .din_z(cordic_1_z), .din_dir(dir_a_r), .din_vec(din_vec_1_r),
    .dout_x(cordic_1_x_out), .dout_y(cordic_1_y_out), .dout_z(cordic_1_z_out), .dout_dir(dir_a_w), .dout_ang_neg(ang_a_neg_w)
);
PipelinedCORDIC #(.WIDTH(WIDTH), .ITER(ITER)) cordic_2(
    .clk(clk), .nxt_mode(is_vec_mode_nxt), .din_update(update_b_r), .dout_update(update_b_w), .din_ang_neg(ang_b_neg_r),
    .din_x(din_b_r), .din_y(din_b_i), .din_z(cordic_2_z), .din_dir(dir_b_r), .din_vec(din_vec_1_r),
    .dout_x(cordic_2_x_out), .dout_y(cordic_2_y_out), .dout_z(cordic_2_z_out), .dout_dir(dir_b_w), .dout_ang_neg(ang_b_neg_w)
);

PipelinedCORDIC #(.WIDTH(WIDTH), .ITER(ITER)) cordic_3(
    .clk(clk), .nxt_mode(din_vec_1_r[ITER+1]), .din_update(update_1_r), .dout_update(update_1_w), .din_ang_neg(ang_1_neg_r),
    .din_x(cordic_1_x_out), .din_y(cordic_2_x_out), .din_z(cordic_3_z), .din_dir(dir_1_r), .din_vec(din_vec_2_r),
    .dout_x(cordic_3_x_out), .dout_y(cordic_3_y_out), .dout_z(cordic_3_z_out), .dout_dir(dir_1_w), .dout_ang_neg(ang_1_neg_w)
);
PipelinedCORDICNoVec #(.WIDTH(WIDTH), .ITER(ITER)) cordic_4(
    .clk(clk), .nxt_mode(din_vec_1_r[ITER+1]), .din_update(update_1_r), .dout_update(), .din_ang_neg(ang_1_neg_r),
    .din_x(cordic_1_y_out), .din_y(cordic_2_y_out), .din_z(cordic_4_z), .din_dir(dir_1_r), .din_vec(din_vec_2_r),
    .dout_x(cordic_4_x_out), .dout_y(cordic_4_y_out), .dout_z(cordic_4_z_out), .dout_dir(), .dout_ang_neg()
);

always @(posedge clk) begin
    dir_a_r <= dir_a_w;
    dir_b_r <= dir_b_w;
    dir_1_r <= dir_1_w;
    update_a_r <= update_a_w;
    update_b_r <= update_b_w;
    update_1_r <= update_1_w;
    ang_a_neg_r <= ang_a_neg_w;
    ang_b_neg_r <= ang_b_neg_w;
    ang_1_neg_r <= ang_1_neg_w;
end

always @(*) begin
    din_a_f_w = din_a_f;
    din_b_f_w = din_b_f;
end

// Output logic
assign dout_x_f = din_vec_2_r[ITER+1];
assign {dout_x_r, dout_x_i} = (
    is_vec_mode2 ? {cordic_3_x_out, {WIDTH{1'b0}}} : {cordic_3_x_out, cordic_4_x_out}
);
assign dout_y_f = din_vec_y_2_r[ITER+1];
assign {dout_y_r, dout_y_i} = (
    is_vec_mode2 ? 0 : {cordic_3_y_out, cordic_4_y_out}
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

always @(*) begin
    din_vec_1_w = {din_vec_1_r[ITER:0], din_a_f};
    din_vec_2_w = {din_vec_2_r[ITER:0], din_vec_1_r[ITER+1]};
end

always @(posedge clk) begin
    din_vec_1_r <= din_vec_1_w;
    din_vec_2_r <= din_vec_2_w;
end

always @(*) begin
    din_vec_y_1_w = {din_vec_y_1_r[ITER:0], din_b_f};
    din_vec_y_2_w = {din_vec_y_2_r[ITER:0], din_vec_y_1_r[ITER+1]};
end

always @(posedge clk) begin
    din_vec_y_1_r <= din_vec_y_1_w;
    din_vec_y_2_r <= din_vec_y_2_w;
end
endmodule

module PipelinedCORDIC(
    clk,
    nxt_mode,
    din_x,
    din_y,
    din_z,
    din_dir,
    din_vec,
    din_update,
    din_ang_neg,
    dout_x,
    dout_y,
    dout_z,
    dout_dir,
    dout_update,
    dout_ang_neg
);

parameter WIDTH = 14;
parameter GAIN_WIDTH = 10; // 10 fraction bits
parameter ITER = 8;

input clk, nxt_mode;
input din_ang_neg;
// output dout_vec_mode;
input signed [WIDTH-1:0] din_x, din_y, din_z;
output signed [WIDTH-1:0] dout_x, dout_y, dout_z;
input [ITER-1:0] din_dir;
output [ITER-1:0] dout_dir;
input [ITER+1:0] din_vec;
input [ITER-1:0] din_update;
output [ITER-1:0] dout_update;
output dout_ang_neg;

reg signed [WIDTH-1:0] x_r[0:ITER+1], x_w[0:ITER+1];
reg signed [WIDTH-1:0] y_r[0:ITER+1], y_w[0:ITER+1];
reg signed [WIDTH-1:0] z_r[0:ITER+1], z_w[0:ITER+1];

// reg signed dir_r[0:ITER-1], dir_w[0:ITER-1];
reg xy_inv_r[0:ITER], xy_inv_w[0:ITER];
reg [ITER-1:0] should_mult_r;
wire [ITER-1:0] should_mult_w;

// Wire
wire signed [WIDTH-1:0] x_nxt[0:ITER-1], y_nxt[0:ITER-1], z_nxt[0:ITER-1];
wire signed update[0:ITER-1];
wire signed mode[0:ITER-1];

wire din_x_is_neg, din_y_is_neg;
wire din_z_neg_out, din_z_pos_out;
wire signed [WIDTH-1:0] din_x_fixed;
wire signed [WIDTH-1:0] din_y_fixed;
wire signed [WIDTH-1:0] din_z_fixed;

wire signed [WIDTH-1:0] dz[0:ITER-1];

wire signed [WIDTH-1:0] x_mult, y_mult;
reg signed [WIDTH+GAIN_WIDTH-1:0] x_prod, y_prod;

// Loop vars
integer i;
genvar gi;

assign dz[0] = 'b00001100100100;
assign dz[1] = 'b00000111011011;
assign dz[2] = 'b00000011111011;
assign dz[3] = 'b00000001111111;
assign dz[4] = 'b00000001000000;
assign dz[5] = 'b00000000100000;
assign dz[6] = 'b00000000010000;
assign dz[7] = 'b00000000001000;
// assign dz[8] = 'b00000000000100;
// assign dz[9] = 'b00000000000010;
// assign dz[10] = 'b00000000000001;
// assign dz[11] = 'b00000000000000;
// assign dz[12] = 'b00000000000000;

assign x_mult = (xy_inv_r[ITER] ? -x_r[ITER] : x_r[ITER]);
assign y_mult = (xy_inv_r[ITER] ? -y_r[ITER] : y_r[ITER]);
always @(*) begin
    if (should_mult_r[ITER-1]) begin
        x_prod = $signed('b1001101110) * x_mult;
        y_prod = $signed('b1001101110) * y_mult;
    end
    else begin
        x_prod = {x_mult, {GAIN_WIDTH{1'b0}}};
        y_prod = {y_mult, {GAIN_WIDTH{1'b0}}};
    end
end

always @(*) begin
    x_w[ITER+1] = x_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH];
    y_w[ITER+1] = y_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH];
    z_w[ITER+1] = z_r[ITER];
end
always @(posedge clk) begin
    x_r[ITER+1] <= x_w[ITER+1];
    y_r[ITER+1] <= y_w[ITER+1];
    z_r[ITER+1] <= z_w[ITER+1];
end

assign din_x_is_neg = din_x < 0;
assign din_y_is_neg = din_y < 0;
assign din_z_neg_out = din_z < -1786; // -1.7433
assign din_z_pos_out = din_z > 1785; // 1.7433

assign din_x_fixed = nxt_mode ? (din_x_is_neg ? -din_x : din_x) : (din_ang_neg ? -din_x : din_x);
assign din_y_fixed = nxt_mode ? (din_x_is_neg ? -din_y : din_y) : (din_ang_neg ? -din_y : din_y);
assign din_z_fixed = (
    nxt_mode && din_x_is_neg ? (
        din_y_is_neg ? $signed('b11001101101111) :
                        $signed('b00110010010000) // -pi and pi
    ) : din_z
);
assign dout_ang_neg = nxt_mode ? (din_x_is_neg ? 1 : 0) : din_ang_neg;

always @(*) begin
    x_w[0] = din_x_fixed;
    y_w[0] = din_y_fixed;
    z_w[0] = din_z_fixed;
    xy_inv_w[0] = (din_z_neg_out || din_z_pos_out); // Reset when the x y is negated
end
always @(posedge clk) begin
    x_r[0] <= x_w[0];
    y_r[0] <= y_w[0];
    z_r[0] <= z_w[0];
    xy_inv_r[0] <= xy_inv_w[0];
end

for (gi=0; gi<ITER; gi=gi+1) begin : generate_CORDIC_iter
    assign mode[gi] = (din_vec[gi] && y_r[gi] > 0) || (!din_vec[gi] && din_dir[gi]);
    assign update[gi] = (din_vec[gi] && y_r[gi] != 0) || (!din_vec[gi] && din_update[gi]);
    assign x_nxt[gi] = mode[gi] ? x_r[gi] + (y_r[gi] >>> gi) : x_r[gi] - (y_r[gi] >>> gi);
    assign y_nxt[gi] = mode[gi] ? y_r[gi] - (x_r[gi] >>> gi) : y_r[gi] + (x_r[gi] >>> gi);
    assign z_nxt[gi] = mode[gi] ? z_r[gi] + dz[gi] : z_r[gi] - dz[gi];
    // Update angle when in vectoring mode
    assign dout_dir[gi] = din_vec[gi] ? mode[gi] : din_dir[gi];
    assign dout_update[gi] = din_vec[gi] ? update[gi] : din_update[gi];

    if (gi == 0) begin
        assign should_mult_w[0] = update[0];
    end
    else begin
        assign should_mult_w[gi] = update[gi] || should_mult_r[gi-1];
    end

    always @(*) begin
        y_w[gi+1] = update[gi] ? y_nxt[gi] : y_r[gi];
        x_w[gi+1] = update[gi] ? x_nxt[gi] : x_r[gi];
        z_w[gi+1] = update[gi] ? z_nxt[gi] : z_r[gi];
        xy_inv_w[gi+1] = xy_inv_r[gi];
    end

    always @(posedge clk) begin
        x_r[gi+1] <= x_w[gi+1];
        y_r[gi+1] <= y_w[gi+1];
        z_r[gi+1] <= z_w[gi+1];
        xy_inv_r[gi+1] <= xy_inv_w[gi];
    end
end

always @(posedge clk) begin
    should_mult_r <= should_mult_w;
end

assign dout_x = x_r[ITER+1];
assign dout_y = y_r[ITER+1];
assign dout_z = z_r[ITER+1];
endmodule

module PipelinedCORDICNoVec(
    clk,
    nxt_mode,
    din_x,
    din_y,
    din_z,
    din_dir,
    din_vec,
    din_update,
    din_ang_neg,
    dout_x,
    dout_y,
    dout_z,
    dout_dir,
    dout_update,
    dout_ang_neg
);

parameter WIDTH = 14;
parameter GAIN_WIDTH = 10; // 10 fraction bits
parameter ITER = 8;

input clk, nxt_mode;
input din_ang_neg;
// output dout_vec_mode;
input signed [WIDTH-1:0] din_x, din_y, din_z;
output signed [WIDTH-1:0] dout_x, dout_y, dout_z;
input [ITER-1:0] din_dir;
output [ITER-1:0] dout_dir; // unused
input [ITER+1:0] din_vec;
input [ITER-1:0] din_update;
output [ITER-1:0] dout_update;
output dout_ang_neg;

reg signed [WIDTH-1:0] x_r[0:ITER+1], x_w[0:ITER+1];
reg signed [WIDTH-1:0] y_r[0:ITER+1], y_w[0:ITER+1];
reg signed [WIDTH-1:0] z_r[0:ITER+1], z_w[0:ITER+1];
// reg signed is_vec_r[0:ITER+1], is_vec_w[0:ITER+1];
reg signed dir_r[0:ITER-1], dir_w[0:ITER-1];
reg xy_inv_r[0:ITER], xy_inv_w[0:ITER];

// Wire
wire signed [WIDTH-1:0] x_nxt[0:ITER-1], y_nxt[0:ITER-1], z_nxt[0:ITER-1];
wire signed update[0:ITER-1];
wire signed mode[0:ITER-1];

wire din_x_is_neg, din_y_is_neg;
wire din_z_neg_out, din_z_pos_out;
wire signed [WIDTH-1:0] din_x_fixed;
wire signed [WIDTH-1:0] din_y_fixed;
wire signed [WIDTH-1:0] din_z_fixed;

wire signed [WIDTH-1:0] dz[0:ITER-1];

wire signed [WIDTH-1:0] x_mult, y_mult;
reg signed [WIDTH+GAIN_WIDTH-1:0] x_prod, y_prod;

// Loop vars
integer i;
genvar gi;

assign dz[0] = 'b00001100100100;
assign dz[1] = 'b00000111011011;
assign dz[2] = 'b00000011111011;
assign dz[3] = 'b00000001111111;
assign dz[4] = 'b00000001000000;
assign dz[5] = 'b00000000100000;
assign dz[6] = 'b00000000010000;
assign dz[7] = 'b00000000001000;
// assign dz[8] = 'b00000000000100;
// assign dz[9] = 'b00000000000010;
// assign dz[10] = 'b00000000000001;
// assign dz[11] = 'b00000000000000;
// assign dz[12] = 'b00000000000000;

assign x_mult = (xy_inv_r[ITER] ? -x_r[ITER] : x_r[ITER]);
assign y_mult = (xy_inv_r[ITER] ? -y_r[ITER] : y_r[ITER]);
always @(*) begin
    x_prod = $signed('b1001101110) * x_mult;
    y_prod = $signed('b1001101110) * y_mult;
end

always @(*) begin
    x_w[ITER+1] = !din_vec[ITER] ? x_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH] : x_r[ITER];
    y_w[ITER+1] = !din_vec[ITER] ? y_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH] : y_r[ITER];
    z_w[ITER+1] = z_r[ITER];
end
always @(posedge clk) begin
    x_r[ITER+1] <= x_w[ITER+1];
    y_r[ITER+1] <= y_w[ITER+1];
    z_r[ITER+1] <= z_w[ITER+1];
end

assign din_x_is_neg = din_x < 0;
assign din_y_is_neg = din_y < 0;
assign din_z_neg_out = din_z < -1786; // -1.7433
assign din_z_pos_out = din_z > 1785; // 1.7433

assign din_x_fixed = nxt_mode ? (din_x_is_neg ? -din_x : din_x) : (din_ang_neg ? -din_x : din_x);
assign din_y_fixed = nxt_mode ? (din_x_is_neg ? -din_y : din_y) : (din_ang_neg ? -din_y : din_y);
assign din_z_fixed = (
    nxt_mode && din_x_is_neg ? (
        din_y_is_neg ? $signed('b11001101101111) :
                        $signed('b00110010010000) // -pi and pi
    ) : din_z
);
assign dout_ang_neg = nxt_mode ? (din_x_is_neg ? 1 : 0) : din_ang_neg;

always @(*) begin
    x_w[0] = din_x_fixed;
    y_w[0] = din_y_fixed;
    z_w[0] = din_z_fixed;
    xy_inv_w[0] = (din_z_neg_out || din_z_pos_out); // Reset when the x y is negated
end
always @(posedge clk) begin
    x_r[0] <= x_w[0];
    y_r[0] <= y_w[0];
    z_r[0] <= z_w[0];
    xy_inv_r[0] <= xy_inv_w[0];
end

for (gi=0; gi<ITER; gi=gi+1) begin : generate_CORDIC_iter
    assign mode[gi] = (din_vec[gi] && y_r[gi] > 0) || (!din_vec[gi] && din_dir[gi]);
    assign update[gi] = (din_vec[gi] && y_r[gi] != 0) || (!din_vec[gi] && din_update[gi]);
    assign x_nxt[gi] = mode[gi] ? x_r[gi] + (y_r[gi] >>> gi) : x_r[gi] - (y_r[gi] >>> gi);
    assign y_nxt[gi] = mode[gi] ? y_r[gi] - (x_r[gi] >>> gi) : y_r[gi] + (x_r[gi] >>> gi);
    assign z_nxt[gi] = mode[gi] ? z_r[gi] + dz[gi] : z_r[gi] - dz[gi];
    // Update angle when in vectoring mode
    assign dout_dir[gi] = din_vec[gi] ? mode[gi] : din_dir[gi];
    assign dout_update[gi] = din_vec[gi] ? update[gi] : din_update[gi];

    always @(*) begin
        x_w[gi+1] = update[gi] ? (!din_vec[gi] ? x_nxt[gi] : x_r[gi]) : x_r[gi];
        y_w[gi+1] = update[gi] ? (!din_vec[gi] ? y_nxt[gi] : y_r[gi]) : y_r[gi];
        z_w[gi+1] = update[gi] ? z_nxt[gi] : z_r[gi];
        xy_inv_w[gi+1] = xy_inv_r[gi];
    end

    always @(posedge clk) begin
        x_r[gi+1] <= x_w[gi+1];
        y_r[gi+1] <= y_w[gi+1];
        z_r[gi+1] <= z_w[gi+1];
        xy_inv_r[gi+1] <= xy_inv_w[gi];
    end
end

assign dout_x = x_r[ITER+1];
assign dout_y = y_r[ITER+1];
assign dout_z = z_r[ITER+1];
endmodule