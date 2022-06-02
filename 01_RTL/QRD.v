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
parameter ITER_SWITCH = 8; // 14 -> 16 (13th iteration for CORDIC mult)
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
// Pipeline control
wire PE_switch, PE_load, DU_load, CORDIC_load;

// Clock gating
wire pipeline_clk, input_clk;

// Registers
reg [3:0] state_r, state_w;

reg [4:0] counter_r, counter_w;
reg start_output_r, start_output_w;

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
    .din_a_r(row_in_1_r_3),   .din_a_i(row_in_1_i_3),   .din_a_f(row_in_1_f_3),
    .din_b_r(in_row_4_r_r),   .din_b_i(in_row_4_i_r),   .din_b_f(),
    .dout_x_r(row_out_1_r_4), .dout_x_i(row_out_1_i_4), .dout_x_f(row_out_1_f_4),
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
    .din_a_r(row_in_2_r_3),   .din_a_i(row_in_2_i_3),   .din_a_f(row_in_2_f_3),
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
    .din_a_r(row_in_3_r_3),   .din_a_i(row_in_3_i_3),   .din_a_f(row_in_3_f_3),
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

/* Clock gating */
assign pipeline_clk = clk & ((counter_r == ITER_LAST) || (counter_r == ITER_LAST-1));
assign input_clk = clk & (state_r == STATE_WAIT || (counter_r == ITER_LAST) || (counter_r == ITER_LAST-1));

/* Continuous assignment */
assign PE_switch = counter_r[4];
assign PE_load = counter_r == ITER_LAST;
assign DU_load = state_r == STATE_WAIT || counter_r == ITER_LAST;
assign CORDIC_load = counter_r == ITER_LAST || counter_r == ITER_SWITCH;

/* Output logic */
assign {row_out_1_r, row_out_1_i} = {row_out_1_r_4, row_out_1_i_4};
assign {row_out_2_r, row_out_2_i} = {row_out_2_r_4, row_out_2_i_4};
assign {row_out_3_r, row_out_3_i} = {row_out_3_r_4, row_out_3_i_4};
assign {row_out_4_r, row_out_4_i} = {row_out_4_r_4, row_out_4_i_4};

assign in_ready = (state_r == STATE_WAIT && counter_r != ITER_LAST) ||
                  counter_r == ITER_LAST-1;
assign out_valid = counter_r == ITER_LAST && start_output_r;

always @(*) begin
    case (state_r)
    STATE_IDLE:  counter_w = counter_r;
    STATE_WAIT:  counter_w = counter_r == ITER_LAST ? 0 : counter_r+1;
    STATE_CALC:  counter_w = counter_r == ITER_LAST ? 0 :
                             counter_r == ITER_SWITCH ? 16 :
                             counter_r+1;
    default:     counter_w = counter_r;
    endcase
end
always @(posedge clk) begin
    if (!rst_n) begin
        counter_r <= -10;
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

always @(*) begin
    start_output_w = row_out_1_f_4 || start_output_r;
end
always @(posedge clk) begin
    if (!rst_n) begin
        start_output_r <= 0;
    end
    else begin
        start_output_r <= start_output_w;
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

assign {col_in_2_f_1, col_in_2_r_1, col_in_2_i_1} = {col_out_2_f_1, col_out_2_r_1, col_out_2_i_1};
assign {col_in_2_f_2, col_in_2_r_2, col_in_2_i_2} = {col_out_2_f_2, col_out_2_r_2, col_out_2_i_2};

assign {col_in_3_r_1, col_in_3_i_1} = {col_out_3_r_1, col_out_3_i_1};
assign {col_in_3_r_2, col_in_3_i_2} = {col_out_3_r_2, col_out_3_i_2};
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

always @(posedge pipeline_clk) begin
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

always @(posedge input_clk) begin
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

assign is_vec_mode = din_a_f_r;
assign is_vec_mode_nxt = din_a_f;

assign cordic_1_x = (switch ? din_a_r : cordic_1_x_out);
assign cordic_2_x = (switch ? din_b_r : cordic_1_y_out);
assign cordic_1_y = (switch ? din_a_i : cordic_2_x_out);
assign cordic_2_y = (switch ? din_b_i : cordic_2_y_out);
assign cordic_1_z = is_vec_mode_nxt ? 0 : (switch ? ang_a_r : ang_1_r);
assign cordic_2_z = is_vec_mode_nxt ? 0 : (switch ? ang_b_r : ang_1_r);
// TODO disable cordic_2 in the 2nd cycle of vectoring mode

CORDIC #(.WIDTH(WIDTH)) cordic_1(
    .clk(clk), .is_vec_mode(is_vec_mode), .nxt_mode(is_vec_mode_nxt),
    .load(subload), .iter(iter),
    .din_x(cordic_1_x), .din_y(cordic_1_y), .din_z(cordic_1_z),
    .dout_x(cordic_1_x_out), .dout_y(cordic_1_y_out), .dout_z(cordic_1_z_out)
);
CORDIC #(.WIDTH(WIDTH)) cordic_2(
    .clk(clk), .is_vec_mode(is_vec_mode), .nxt_mode(is_vec_mode_nxt),
    .load(subload), .iter(iter),
    .din_x(cordic_2_x), .din_y(cordic_2_y), .din_z(cordic_2_z),
    .dout_x(cordic_2_x_out), .dout_y(cordic_2_y_out), .dout_z(cordic_2_z_out)
);

always @(*) begin
    // angle can be retrieved 1 cycle before mult is finished
    ang_a_w = is_vec_mode && !switch && iter == 7 ? -cordic_1_z_out : ang_a_r;
    ang_b_w = is_vec_mode && !switch && iter == 7 ? -cordic_2_z_out : ang_b_r;
    ang_1_w = is_vec_mode && switch && iter == 7 ? -cordic_1_z_out : ang_1_r;
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
endmodule

module CORDIC(
    clk,
    is_vec_mode,
    nxt_mode,
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

input clk, is_vec_mode, nxt_mode, load;
input [3:0] iter;
input signed [WIDTH-1:0] din_x, din_y, din_z;
output signed [WIDTH-1:0] dout_x, dout_y, dout_z;

reg signed [WIDTH-1:0] x_r, x_w;
reg signed [WIDTH-1:0] y_r, y_w;
reg signed [WIDTH-1:0] z_r, z_w, dz, dz2;
reg should_mult_r, should_mult_w;
reg xy_inv_r, xy_inv_w;

wire signed [WIDTH-1:0] x_sft, y_sft;
wire signed [WIDTH-1:0] x_nxt, y_nxt, z_nxt;

wire signed [WIDTH-1:0] x_sft2, y_sft2;
wire signed [WIDTH-1:0] x_nxt2, y_nxt2, z_nxt2;

wire signed [WIDTH-1:0] x_mult, y_mult;
wire signed [WIDTH-1:0] x_update, y_update, z_update;

reg signed [WIDTH+GAIN_WIDTH-1:0] x_prod, y_prod;
wire din_x_is_neg, din_y_is_neg;
wire din_z_neg_out, din_z_pos_out;
wire signed [WIDTH-1:0] din_x_fixed;
wire signed [WIDTH-1:0] din_y_fixed;
wire signed [WIDTH-1:0] din_z_fixed;
wire mode, mode2;
wire update, update1, update2;
wire [3:0] iter2;

always @(*) begin
    case (iter)
    4'b0000: dz = 'b00001100100100;
    4'b0001: dz = 'b00000011111011;
    4'b0010: dz = 'b00000001000000;
    4'b0011: dz = 'b00000000010000;
    4'b0100: dz = 'b00000000000100;
    4'b0101: dz = 'b00000000000001;
    4'b0110: dz = 'b00000000000000;
    default: dz = 'b00000000000000;
    endcase
end

always @(*) begin
    case (iter)
    4'b0000: dz2 = 'b00000111011011;
    4'b0001: dz2 = 'b00000001111111;
    4'b0010: dz2 = 'b00000000100000;
    4'b0011: dz2 = 'b00000000001000;
    4'b0100: dz2 = 'b00000000000010;
    4'b0101: dz2 = 'b00000000000000;
    default: dz2 = 'b00000000000000;
    endcase
end

always @(*) begin
    if (should_mult_r) begin
        x_prod = $signed('b1001101110) * x_mult;
        y_prod = $signed('b1001101110) * y_mult;
    end
    else begin
        x_prod = {x_mult, {GAIN_WIDTH{1'b0}}};
        y_prod = {y_mult, {GAIN_WIDTH{1'b0}}};
    end
end

assign x_mult = update1 ? (xy_inv_r ? -x_nxt : x_nxt) : (xy_inv_r ? -x_r : x_r);
assign y_mult = update1 ? (xy_inv_r ? -y_nxt : y_nxt) : (xy_inv_r ? -y_r : y_r);

assign dout_x = x_r;
assign dout_y = y_r;
assign dout_z = z_r;

assign mode = (is_vec_mode && y_r > 0) || (!is_vec_mode && z_r < 0);
assign update1 = (is_vec_mode && y_r != 0) || (!is_vec_mode && z_r != 0);
assign x_nxt = mode ? (x_r + y_sft) : (x_r - y_sft);
assign y_nxt = mode ? (y_r - x_sft) : (y_r + x_sft);
assign z_nxt = mode ? (z_r + dz) : (z_r - dz);

assign mode2 = (is_vec_mode && y_nxt > 0) || (!is_vec_mode && z_nxt < 0);
assign update2 = (is_vec_mode && y_nxt != 0) || (!is_vec_mode && z_nxt != 0);
assign x_nxt2 = mode2 ? (x_nxt + y_sft2) : (x_nxt - y_sft2);
assign y_nxt2 = mode2 ? (y_nxt - x_sft2) : (y_nxt + x_sft2);
assign z_nxt2 = mode2 ? (z_nxt + dz2) : (z_nxt - dz2);

assign update = update1;
assign x_update = update2 ? x_nxt2 : x_nxt;
assign y_update = update2 ? y_nxt2 : y_nxt;
assign z_update = update2 ? z_nxt2 : z_nxt;

assign din_x_is_neg = din_x < 0;
assign din_y_is_neg = din_y < 0;
assign din_z_neg_out = din_z < -1786; // -1.7433
assign din_z_pos_out = din_z > 1785; // 1.7433

assign din_x_fixed = nxt_mode && din_x_is_neg ? -din_x : din_x;
assign din_y_fixed = nxt_mode && din_x_is_neg ? -din_y : din_y;
assign din_z_fixed = (
    nxt_mode ? (
        din_x_is_neg ? (
            din_y_is_neg ? $signed('b11001101101111) :
                           $signed('b00110010010000) // -pi and pi
        ) : din_z
    ) : (
        din_z_neg_out ? (din_z + 3216) : // z + pi
        din_z_pos_out ? (din_z - 3216) : // z - pi
                         din_z
));

BarrelShifter #(.WIDTH(WIDTH)) shift1 (.din(x_r), .shift({iter[2:0], 1'b0}), .dout(x_sft));
BarrelShifter #(.WIDTH(WIDTH)) shift2 (.din(y_r), .shift({iter[2:0], 1'b0}), .dout(y_sft));

BarrelShifter #(.WIDTH(WIDTH)) shift3 (.din(x_nxt), .shift({iter[2:0], 1'b1}), .dout(x_sft2));
BarrelShifter #(.WIDTH(WIDTH)) shift4 (.din(y_nxt), .shift({iter[2:0], 1'b1}), .dout(y_sft2));

always @(*) begin
    x_w = load ? din_x_fixed : (
        iter == 6 ? x_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH] : // remove fractions
        update ? x_update : (xy_inv_r ? -x_r : x_r)
    );
end
always @(*) begin
    y_w = load ? din_y_fixed : (
        iter == 6 ? y_prod[WIDTH+GAIN_WIDTH-1:GAIN_WIDTH] :
        update ? y_update : (xy_inv_r ? -y_r : y_r)
    );
end
always @(*) begin
    z_w = load ? din_z_fixed : (update ? z_update : z_r);
end
always @(*) begin
    should_mult_w = load ? 0 : (update || should_mult_r);
end
always @(*) begin
    xy_inv_w = load ? (din_z_neg_out || din_z_pos_out) :
               update && iter != 6 ? xy_inv_r : 0; // Reset when the x y is negated
end

always @(posedge clk) begin
    x_r <= x_w;
end
always @(posedge clk) begin
    y_r <= y_w;
end
always @(posedge clk) begin
    z_r <= z_w;
end
always @(posedge clk) begin
    should_mult_r <= should_mult_w;
end
always @(posedge clk) begin
    xy_inv_r <= xy_inv_w;
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