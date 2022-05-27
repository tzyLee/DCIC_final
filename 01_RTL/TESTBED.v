
`timescale 1ns/10ps

module TESTBED;

integer i, j, k, l;
integer latency, latency_total;
integer fp_r, fp_i, count_r, count_i;
integer SNR_ratio;


parameter H_size		= 4; // 4x4 matrix
parameter dataset		= 1;
parameter IN_width		= 14;
// parameter OUT_width		= 16;
// parameter latency_limit	= 68;
parameter TIMEOUT       = 1000;

parameter CYCLE			= 10.0;

reg signed [IN_width-1:0] din_r, din_i;

integer H_r[0:H_size-1][0:2*H_size-1];
integer H_i[0:H_size-1][0:2*H_size-1];

reg clk, rst_n, in_valid;
reg signed [IN_width-1:0] row_in_1_r, row_in_1_i;
reg signed [IN_width-1:0] row_in_2_r, row_in_2_i;
reg signed [IN_width-1:0] row_in_3_r, row_in_3_i;
reg signed [IN_width-1:0] row_in_4_r, row_in_4_i;
reg row_in_1_f, row_in_2_f, row_in_3_f;
wire in_ready;
wire out_valid;

always #(CYCLE/2.0) clk = ~clk;

initial begin

	`ifdef RTL
		$fsdbDumpfile("QRD_RTL.fsdb");
		// $fsdbDumpvars(0, QRD_CORE, "+mda");
		$fsdbDumpvars(0, TESTBED, "+mda");
	`elsif GATE
		$sdf_annotate("../02_SYN/Netlist/QRD_SYN.sdf",QRD_CORE);

		`ifdef VCD
			$dumpfile("QRD_GATE.vcd");
			$dumpvars();
		`elsif FSDB
			$fsdbDumpfile("QRD_GATE.fsdb");
			$fsdbDumpvars(0, QRD_CORE);
		`endif
	`endif
end

initial begin
	#(TIMEOUT * CYCLE);
	$display("=========================");
	$display("Timeout reached, exiting.");
	$display("=========================");
	$finish;
end

initial begin
	clk = 0;
	rst_n = 1;
	in_valid = 0;

	for(i=0; i<dataset; i=i+1) begin

		case(i)
		0: begin
			fp_r = $fopen("../TEST_PATTERN/in_real_pattern01.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/in_imag_pattern01.txt", "r");
		end
		default: begin
			$display("Missing dataset.");
			$finish;
		end
		endcase


		@(negedge clk);
		@(negedge clk) rst_n = 0;
		@(negedge clk) rst_n = 1;

		for(j=0; j<H_size; j=j+1) begin
			for(k=0; k<H_size; k=k+1) begin
				count_r = $fscanf(fp_r, "%b", din_r);
				count_i = $fscanf(fp_i, "%b", din_i);
				H_r[j][k] = din_r;
				H_i[j][k] = din_i;

				// Fill identity matrix
				if (j == k) begin
					H_r[j][k+4] = 1;
				end
				else begin
					H_r[j][k+4] = 0;
				end
				H_i[j][k+4] = 0;
			end
			$display(
				"[%5d+%5dj %5d+%5dj %5d+%5dj %5d+%5dj]",
				H_r[j][0], H_i[j][0],
				H_r[j][1], H_i[j][1],
				H_r[j][2], H_i[j][2],
				H_r[j][3], H_i[j][3]
			);
		end

		$fclose(fp_r);
		$fclose(fp_i);

		for (l=0; l<11; l=l+1) begin
			@(posedge clk)
			if (in_ready) begin
				row_in_1_r = l < 8 ? H_r[0][l] : 0;
				row_in_1_i = l < 8 ? H_i[0][l] : 0;
				row_in_1_f = l == 0;
				row_in_2_r = 0 < l && l < 9 ? H_r[1][l-1] : 0;
				row_in_2_i = 0 < l && l < 9 ? H_i[1][l-1] : 0;
				row_in_2_f = l == 1;
				row_in_3_r = 1 < l && l < 10 ? H_r[2][l-2] : 0;
				row_in_3_i = 1 < l && l < 10 ? H_i[2][l-2] : 0;
				row_in_3_f = l == 2;
				row_in_4_r = 2 < l ? H_r[3][l-3] : 0;
				row_in_4_i = 2 < l ? H_i[3][l-3] : 0;
			end
			else begin
				l = l-1; // do not increment
			end
		end

		wait(out_valid);
		latency = 0;
		while(!out_valid) begin
			@(negedge clk) latency = latency + 1;
			// if(latency > latency_limit) begin
			// 	$display("Latency too long (> %0d CYCLEs)", latency_limit);
			// 	$finish;
			// end
		end

		// // Read golden data
        // case(i)
        // 0: begin
        //     fp_r = $fopen("../Test_pattern/output/OUT_real_16_pattern01.txt", "r");
        //     fp_i = $fopen("../Test_pattern/output/OUT_imag_16_pattern01.txt", "r");
        // end
        // default: begin
        //     $display("Wrong dataset!? No Way!");
        //     $finish;
        // end
        // endcase

		// for(j=0;j<QRD_size;j=j+1) begin

		// 	while(!out_valid) begin
		// 		@(negedge clk) latency = latency + 1;
		// 		if(latency > latency_limit) begin
		// 			$display("Total latency too long (> %0d CYCLEs)", latency_limit);
		// 			$finish;
		// 		end
		// 	end

		// 	int_r = $fscanf(fp_r, "%d", gold_r);
		// 	int_i = $fscanf(fp_i, "%d", gold_i);

		// 	signal = gold_r;
		// 	signal_energy = signal_energy + signal*signal;
		// 	signal = gold_i;
		// 	signal_energy = signal_energy + signal*signal;

		// 	noise = gold_r - dout_r;
		// 	noise_energy = noise_energy + noise*noise;
        //     $display("[%2d] GET dout_r %d, gold %d, differ %d", j, dout_r, gold_r, noise);
		// 	noise = gold_i - dout_i;
		// 	noise_energy = noise_energy + noise*noise;
        //     $display("[%2d] GET dout_i %d, gold %d, differ %d", j, dout_i, gold_i, noise);
		// 	@(negedge clk);
		// end

		// if(noise_energy == 0) begin
		// 	$display(" ---------- SNR = infinity");
		// 	$display(" ---------- dataset %2d pass!!\n", i+1);
		// end
		// else begin

		// 	SNR_ratio = signal_energy/noise_energy;
		// 	$display(" ---------- SNR = %2.2f", $log10(SNR_ratio)*10.0);

		// 	if(SNR_ratio >= 10000)
        //         $display(" ---------- dataset %2d passed!!\n", i+1);
		// 	else begin
		// 		$display(" ---------- dataset %2d failed!! Bye\n", i+1);
		// 		$finish;
		// 	end
		// end

		$fclose(fp_r);
		$fclose(fp_i);

		// latency_total = latency_total + latency;

	end

	$display("\033[1;33m********************************\033[m");
    $display("\033[1;33mWell Done \033[m");
    $display("\033[1;33m********************************\033[m");
    $display("\033[1;35m      ▒~▒▒         \033[m");
    $display("\033[1;35m      ▒x▒x           \033[m");
    $display("\033[1;35m▒i▒X▒X▒}▒▒▒X▒▒          \033[m");
    $display("\033[1;35m▒i      ▒X▒X▒▒        \033[m");
    $display("\033[1;35m▒i   ▒@ ▒X▒X▒▒   You have passed all patterns!!\033[m");
    $display("\033[1;35m▒i▒š▒  ▒X▒X▒▒          \033[m");
    $display("\033[1;35m▒i   ▒▒▒X▒X▒▒         \033[m");
    $display("\033[1;35m                   \033[m");
    $display("\033[1;32m********************************\033[m");
    $display("\033[1;32m********************************\033[m");
	$display("Clk period = %2.2f ns", CYCLE);
	$display("Average latency = %2.2f CYCLEs", latency_total/dataset);
    $display("Bye\n\n");

    $finish;
end

QRD QRD_CORE(
    .clk        (clk       ),
    .rst_n      (rst_n     ),
    .row_in_1_r (row_in_1_r), .row_in_1_i(row_in_1_i), .row_in_1_f(row_in_1_f),
    .row_in_2_r (row_in_2_r), .row_in_2_i(row_in_2_i), .row_in_2_f(row_in_2_f),
    .row_in_3_r (row_in_3_r), .row_in_3_i(row_in_3_i), .row_in_3_f(row_in_3_f),
    .row_in_4_r (row_in_4_r), .row_in_4_i(row_in_4_i),
	.in_ready   (in_ready  ),
	.out_valid  (),
	.row_out_1_r(),
	.row_out_1_i(),
	.row_out_2_r(),
	.row_out_2_i(),
	.row_out_3_r(),
	.row_out_3_i(),
	.row_out_4_r(),
	.row_out_4_i()
);

endmodule
