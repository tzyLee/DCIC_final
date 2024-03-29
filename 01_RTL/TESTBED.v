
`timescale 1ns/10ps

module TESTBED;

integer i, j, k, l;
integer latency, latency_total;
integer fp_r, fp_i, count_r, count_i;
integer SNR_ratio;


parameter H_size		= 4; // 4x4 matrix
parameter dataset		= 2;
parameter IN_width		= 14;
// parameter OUT_width		= 16;
// parameter latency_limit	= 68;
parameter TIMEOUT       = 1000;

parameter CYCLE			= 4.2;
parameter ERR_THRESHOLD = 21;

reg signed [IN_width-1:0] din_r, din_i;

integer H_r[0:H_size-1][0:H_size];
integer H_i[0:H_size-1][0:H_size];
integer R_gold_r[0:H_size-1][0:H_size-1];
integer R_gold_i[0:H_size-1][0:H_size-1];
integer QH_gold_r[0:H_size-1];
integer QH_gold_i[0:H_size-1];
integer R_r[0:H_size-1][0:H_size-1];
integer R_i[0:H_size-1][0:H_size-1];
integer QHy_r[0:H_size-1];
integer QHy_i[0:H_size-1];
integer QHy_diff;
integer R_diff;
integer diff;
integer first_output_received;

reg clk, rst_n, in_valid;
reg signed [IN_width-1:0] row_in_1_r, row_in_1_i;
reg signed [IN_width-1:0] row_in_2_r, row_in_2_i;
reg signed [IN_width-1:0] row_in_3_r, row_in_3_i;
reg signed [IN_width-1:0] row_in_4_r, row_in_4_i;
reg row_in_1_f, row_in_2_f, row_in_3_f;
wire signed [IN_width-1:0] row_out_1_r, row_out_1_i;
wire signed [IN_width-1:0] row_out_2_r, row_out_2_i;
wire signed [IN_width-1:0] row_out_3_r, row_out_3_i;
wire signed [IN_width-1:0] row_out_4_r, row_out_4_i;
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
	latency_total = 0;

	for(i=0; i<dataset; i=i+1) begin

		case(i)
		0: begin
			fp_r = $fopen("../TEST_PATTERN/in_real_pattern01.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/in_imag_pattern01.txt", "r");
		end
		1: begin
			fp_r = $fopen("../TEST_PATTERN/in_real_pattern02.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/in_imag_pattern02.txt", "r");
		end
		default: begin
			$display("Missing dataset.");
			$finish;
		end
		endcase


		@(negedge clk);
		@(negedge clk) rst_n = 0;
		@(negedge clk) rst_n = 1;

		$display("============= Input Matrix H and y=============");
		for(j=0; j<H_size; j=j+1) begin
			for(k=0; k<H_size+1; k=k+1) begin
				count_r = $fscanf(fp_r, "%b", din_r);
				count_i = $fscanf(fp_i, "%b", din_i);
				H_r[j][k] = din_r;
				H_i[j][k] = din_i;
			end
			$display(
				"[%5d+%5dj %5d+%5dj %5d+%5dj %5d+%5dj] [%5d+%5dj]",
				H_r[j][0], H_i[j][0],
				H_r[j][1], H_i[j][1],
				H_r[j][2], H_i[j][2],
				H_r[j][3], H_i[j][3],
				H_r[j][4], H_i[j][4],
			);
		end
		$fclose(fp_r);
		$fclose(fp_i);

		// Read golden data
		case(i)
		0: begin
			fp_r = $fopen("../TEST_PATTERN/out_R_real_golden01.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/out_R_imag_golden01.txt", "r");
		end
		1: begin
			fp_r = $fopen("../TEST_PATTERN/out_R_real_golden02.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/out_R_imag_golden02.txt", "r");
		end
		default: begin
			$display("Missing dataset.");
			$finish;
		end
		endcase
		$display("============= Expected R =============");
		for(j=0; j<H_size; j=j+1) begin
			for(k=0; k<H_size; k=k+1) begin
				count_r = $fscanf(fp_r, "%b", din_r);
				count_i = $fscanf(fp_i, "%b", din_i);

				R_gold_r[j][k] = din_r;
				R_gold_i[j][k] = din_i;
			end
			$display(
				"[%5d+%5dj %5d+%5dj %5d+%5dj %5d+%5dj]",
				R_gold_r[j][0], R_gold_i[j][0],
				R_gold_r[j][1], R_gold_i[j][1],
				R_gold_r[j][2], R_gold_i[j][2],
				R_gold_r[j][3], R_gold_i[j][3]
			);
		end
		$fclose(fp_r);
		$fclose(fp_i);

		case(i)
		0: begin
			fp_r = $fopen("../TEST_PATTERN/out_QHy_real_golden01.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/out_QHy_imag_golden01.txt", "r");
		end
		1: begin
			fp_r = $fopen("../TEST_PATTERN/out_QHy_real_golden02.txt", "r");
			fp_i = $fopen("../TEST_PATTERN/out_QHy_imag_golden02.txt", "r");
		end
		default: begin
			$display("Missing dataset.");
			$finish;
		end
		endcase
		$display("============= Expected QH*y =============");
		for(j=0; j<H_size; j=j+1) begin
			count_r = $fscanf(fp_r, "%b", din_r);
			count_i = $fscanf(fp_i, "%b", din_i);

			QH_gold_r[j] = din_r;
			QH_gold_i[j] = din_i;
		end
		$display(
			"[%5d+%5dj %5d+%5dj %5d+%5dj %5d+%5dj]",
			QH_gold_r[0], QH_gold_i[0],
			QH_gold_r[1], QH_gold_i[1],
			QH_gold_r[2], QH_gold_i[2],
			QH_gold_r[3], QH_gold_i[3]
		);
		$fclose(fp_r);
		$fclose(fp_i);

		first_output_received = 0;
		latency = 0;
		begin : loop
		for (l=0; l<180; l=l+1) begin
			@(negedge clk);
			if (out_valid) begin
				if (l > 91 && l < 96) begin
					R_r[0][l-92] = row_out_1_r;
					R_i[0][l-92] = row_out_1_i;
					first_output_received = 1;
				end
				else if (l == 96) begin
					QHy_r[0] = row_out_1_r;
					QHy_i[0] = row_out_1_i;
				end

				if (l > 121 && l < 126) begin
					R_r[1][l-122] = row_out_2_r;
					R_i[1][l-122] = row_out_2_i;
				end
				else if (l == 126) begin
					QHy_r[1] = row_out_2_r;
					QHy_i[1] = row_out_2_i;
				end

				if (l > 151 && l < 156) begin
					R_r[2][l-152] = row_out_3_r;
					R_i[2][l-152] = row_out_3_i;
				end
				else if (l == 156) begin
					QHy_r[2] = row_out_3_r;
					QHy_i[2] = row_out_3_i;
				end

				if (l > 151 && l < 156) begin
					R_r[3][l-152] = row_out_4_r;
					R_i[3][l-152] = row_out_4_i;
				end
				else if (l == 156) begin
					QHy_r[3] = row_out_4_r;
					QHy_i[3] = row_out_4_i;
				end

				if (l == 157) begin
					disable loop;
				end
			end
			row_in_1_r = l < 5 ? H_r[0][l] : 0;
			row_in_1_i = l < 5 ? H_i[0][l] : 0;
			row_in_1_f = l == 0;
			row_in_2_r = 0 < l && l < 6 ? H_r[1][l-1] : 0;
			row_in_2_i = 0 < l && l < 6 ? H_i[1][l-1] : 0;
			row_in_2_f = l == 2;
			row_in_3_r = 30 < l && l < 36 ? H_r[2][l-31] : 0;
			row_in_3_i = 30 < l && l < 36 ? H_i[2][l-31] : 0;
			row_in_3_f = l == 33;
			row_in_4_r = 60 < l && l < 66? H_r[3][l-61] : 0;
			row_in_4_i = 60 < l && l < 66? H_i[3][l-61] : 0;

			if (first_output_received == 0) begin
				latency = latency + 1;
			end
		end
		end

		// latency = 0;
		// while(!out_valid) begin
		// 	@(negedge clk) latency = latency + 1;
		// 	// if(latency > latency_limit) begin
		// 	// 	$display("Latency too long (> %0d CYCLEs)", latency_limit);
		// 	// 	$finish;
		// 	// end
		// end
		$display("============= Actual R =============");
		for(j=0; j<H_size; j=j+1) begin
			$display(
				"[%5d+%5dj %5d+%5dj %5d+%5dj %5d+%5dj]",
				R_r[j][0], R_i[j][0],
				R_r[j][1], R_i[j][1],
				R_r[j][2], R_i[j][2],
				R_r[j][3], R_i[j][3]
			);
		end
		$display("============= Actual QH =============");
		$display(
			"[%5d+%5dj %5d+%5dj %5d+%5dj %5d+%5dj]",
			QHy_r[0], QHy_i[0],
			QHy_r[1], QHy_i[1],
			QHy_r[2], QHy_i[2],
			QHy_r[3], QHy_i[3]
		);

		QHy_diff = 0;
		R_diff = 0;
		for(j=0; j<H_size; j=j+1) begin
			diff = QHy_r[j] - QH_gold_r[j];
			diff = (diff < 0 ? -diff : diff); // absolute value
			QHy_diff = QHy_diff + diff;
			if (diff > ERR_THRESHOLD || ^diff === 1'bx) begin
				$display("QHy_r[%2d][%2d] = %d (Expected) != %d (Actual); diff = %d",
							j, k, QH_gold_r[j], QHy_r[j], diff);
				$finish;
			end

			diff = QHy_i[j] - QH_gold_i[j];
			diff = (diff < 0 ? -diff : diff);
			QHy_diff = QHy_diff + diff;
			if (diff > ERR_THRESHOLD || ^diff === 1'bx) begin
				$display("QHy_i[%2d][%2d] = %d (Expected) != %d (Actual); diff = %d",
							j, k, QH_gold_i[j], QHy_i[j], diff);
				$finish;
			end
			for(k=0; k<H_size; k=k+1) begin
				if (k >= j) begin
					diff = R_r[j][k] - R_gold_r[j][k];
					diff = (diff < 0 ? -diff : diff);
					R_diff = R_diff + diff;
					if (diff > ERR_THRESHOLD || ^diff === 1'bx) begin
						$display("R_r[%2d][%2d] = %d (Expected) != %d (Actual); diff = %d",
								j, k, R_gold_r[j][k], R_r[j][k], diff);
						$finish;
					end

					diff = R_i[j][k] - R_gold_i[j][k];
					diff = (diff < 0 ? -diff : diff || ^diff === 1'bx);
					R_diff = R_diff + diff;
					if (diff > ERR_THRESHOLD) begin
						$display("R_i[%2d][%2d] = %d (Expected) != %d (Actual); diff = %d",
								j, k, R_gold_i[j][k], R_i[j][k], diff);
						$finish;
					end
				end
			end
		end

		$display("=========================");
		$display("QHy_diff: %d, R_diff: %d", QHy_diff, R_diff);
		$display("=========================");

		latency_total = latency_total + latency;
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
	.out_valid  (out_valid),
	.row_out_1_r(row_out_1_r), .row_out_1_i(row_out_1_i),
	.row_out_2_r(row_out_2_r), .row_out_2_i(row_out_2_i),
	.row_out_3_r(row_out_3_r), .row_out_3_i(row_out_3_i),
	.row_out_4_r(row_out_4_r), .row_out_4_i(row_out_4_i)
);

endmodule
