
`timescale 1ns/10ps

module TESTBED;

integer i, j, latency, latency_total;
integer fp_r, fp_i, int_r, int_i;
integer SNR_ratio;

parameter QR_size		= 4; // 4x4 matrix
parameter dataset		= 5;
parameter IN_width		= 12;
parameter OUT_width		= 16;
parameter latency_limit	= 68;

parameter cycle			= 10.0;

reg clk, rst_n, in_valid;
reg row_in_1_r, row_in_1_i;
reg row_in_2_r, row_in_2_i;
reg row_in_3_r, row_in_3_i;
reg row_in_4_r, row_in_4_i;
wire out_valid;

always #(cycle/2.0) clk = ~clk;

initial begin

	`ifdef RTL
		$fsdbDumpfile("FFT_RTL.fsdb");
		$fsdbDumpvars(0, FFT_CORE, "+mda");
	`elsif GATE
		$sdf_annotate("../02_SYN/Netlist/FFT_SYN.sdf",FFT_CORE);

		`ifdef VCD
			$dumpfile("FFT_GATE.vcd");
			$dumpvars();
		`elsif FSDB
			$fsdbDumpfile("FFT_GATE.fsdb");
			$fsdbDumpvars(0, FFT_CORE);
		`endif
	`endif
end

initial begin
	clk = 0;
	rst_n = 1;
	in_valid = 0;

	for(i=0;i<dataset;i=i+1) begin

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
		@(negedge clk);

		for(j=0;j<FFT_size;j=j+1) begin
			@(negedge clk);
			in_valid = 1;
			int_r = $fscanf(fp_r, "%b", din_r);
			int_i = $fscanf(fp_i, "%b", din_i);
		end
		@(negedge clk) in_valid = 0;


		$fclose(fp_r);
		$fclose(fp_i);

		latency = 0;
		while(!out_valid) begin
			@(negedge clk) latency = latency + 1;
			if(latency > latency_limit) begin
				$display("Latency too long (> %0d cycles)", latency_limit);
				$finish;
			end
		end

		// Read golden data
        case(i)
        0: begin
            fp_r = $fopen("../Test_pattern/output/OUT_real_16_pattern01.txt", "r");
            fp_i = $fopen("../Test_pattern/output/OUT_imag_16_pattern01.txt", "r");
        end
        default: begin
            $display("Wrong dataset!? No Way!");
            $finish;
        end
        endcase

		for(j=0;j<FFT_size;j=j+1) begin

			while(!out_valid) begin
				@(negedge clk) latency = latency + 1;
				if(latency > latency_limit) begin
					$display("Total latency too long (> %0d cycles)", latency_limit);
					$finish;
				end
			end

			int_r = $fscanf(fp_r, "%d", gold_r);
			int_i = $fscanf(fp_i, "%d", gold_i);

			signal = gold_r;
			signal_energy = signal_energy + signal*signal;
			signal = gold_i;
			signal_energy = signal_energy + signal*signal;

			noise = gold_r - dout_r;
			noise_energy = noise_energy + noise*noise;
            $display("[%2d] GET dout_r %d, gold %d, differ %d", j, dout_r, gold_r, noise);
			noise = gold_i - dout_i;
			noise_energy = noise_energy + noise*noise;
            $display("[%2d] GET dout_i %d, gold %d, differ %d", j, dout_i, gold_i, noise);
			@(negedge clk);
		end

		if(noise_energy == 0) begin
			$display(" ---------- SNR = infinity");
			$display(" ---------- dataset %2d pass!!\n", i+1);
		end
		else begin

			SNR_ratio = signal_energy/noise_energy;
			$display(" ---------- SNR = %2.2f", $log10(SNR_ratio)*10.0);

			if(SNR_ratio >= 10000)
                $display(" ---------- dataset %2d passed!!\n", i+1);
			else begin
				$display(" ---------- dataset %2d failed!! Bye\n", i+1);
				$finish;
			end
		end

		$fclose(fp_r);
		$fclose(fp_i);

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
	$display("Clk period = %2.2f ns", cycle);
	$display("Average latency = %2.2f cycles", latency_total/dataset);
    $display("Bye\n\n");

    $finish;
end

QRD QRD_CORE(
    .clk       (clk      ),
    .rst_n     (rst_n    ),
    .in_valid  (in_valid ),
    .row_in_1_r(),
    .row_in_1_i(),
    .row_in_2_r(),
    .row_in_2_i(),
    .row_in_3_r(),
    .row_in_3_i(),
    .row_in_4_r(),
    .row_in_4_i(),
);

endmodule
