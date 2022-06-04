%% Settings
dir = "..\TEST_PATTERN";
out_pattern_name = "pattern02";
out_golden_name = "golden02";

WORD_LEN = 14;
FRAC_LEN = WORD_LEN-4;
ITER = WORD_LEN-1;

NUM_PATTERN = 1;

F = fimath(...
  'RoundingMethod', 'Floor',...
  'OverflowAction', 'Wrap',...
  'SumMode', 'SpecifyPrecision',...
  'SumWordLength', WORD_LEN, ...
  'SumFractionLength', FRAC_LEN);

globalfimath(F);

%% Data generation
% H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
% 
% Hf = fi(H, 1, WORD_LEN, FRAC_LEN);
data = load("../TEST_PATTERN/H_pattern01.mat");
Hf = data.Hf;
H = data.H;

[Q, R] = QRD_CORDIC_14(Hf, ITER);
QH = Q';

% transpose to put row vectors into column
in_real = real(Hf).';
in_imag = imag(Hf).';

out_R_real = real(R).';
out_R_imag = imag(R).';

out_QH_real = real(QH).';
out_QH_imag = imag(QH).';

%% Output
writeToFile(in_real(:), fullfile(dir, sprintf("in_real_%s.txt", out_pattern_name)));
writeToFile(in_imag(:), fullfile(dir, sprintf("in_imag_%s.txt", out_pattern_name)));
writeToFile(out_R_real(:), fullfile(dir, sprintf("out_R_real_%s.txt", out_golden_name)));
writeToFile(out_R_imag(:), fullfile(dir, sprintf("out_R_imag_%s.txt", out_golden_name)));
writeToFile(out_QH_real(:), fullfile(dir, sprintf("out_QH_real_%s.txt", out_golden_name)));
writeToFile(out_QH_imag(:), fullfile(dir, sprintf("out_QH_imag_%s.txt", out_golden_name)));
save(fullfile(dir, sprintf("H_%s.mat", out_pattern_name)), "H", "Hf");

function writeToFile(mat, outFile)
    fd = fopen(outFile, 'w');
    matWithNewline = [bin(mat), char(zeros(size(mat))+newline)];
    fprintf(fd, '%s', matWithNewline.');
    fclose(fd);
end