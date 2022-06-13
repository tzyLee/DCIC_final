%% Settings
dir = "..\TEST_PATTERN";
out_pattern_name = "pattern01";
out_golden_name = "golden01";

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
N_T = 4; % number of transmit antennas
N_R = 4; % number of receive antennas
EbN0 = [0:4:16, 18, 20];
sym_64QAM = qammod((0:63).', 64); % gray-code
sym = sym_64QAM(:)./7;

SYM_SIZE = numel(sym);
Q = log2(SYM_SIZE);     % number of bits per symbol
Es = mean(abs(sym).^2); % avg energy per symbol
Eb = Es / Q;            % avg energy per bit
N0 = Eb*N_T ./ db2pow(EbN0); % noise variance

%% Symbol genreation
idx = randi([1, SYM_SIZE], N_T, 1);
s = sym(idx);
% AWGN noise
n = (randn(N_R, 1) + 1j.*randn(N_R, 1)) ./ sqrt(2);
H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
x = H*s;
y = x + sqrt(N0(7)) .* n;

Hf = fi(H, 1, WORD_LEN, FRAC_LEN);
yf = fi(y, 1, WORD_LEN, FRAC_LEN);

% [Q, R] = QRD_CORDIC_14(Hf, ITER);
[Q, R, QHy] = QRD_CORDIC(Hf, yf, ITER);
QH = Q';
% QHy = QH*yf;

% transpose to put row vectors into column
Hf = [Hf, yf];
in_real = real(Hf).';
in_imag = imag(Hf).';

out_R_real = real(R).';
out_R_imag = imag(R).';

out_QH_real = real(QH).';
out_QH_imag = imag(QH).';

out_QHy_real = real(QHy).';
out_QHy_imag = imag(QHy).';

%% Output
writeToFile(in_real(:), fullfile(dir, sprintf("in_real_%s.txt", out_pattern_name)));
writeToFile(in_imag(:), fullfile(dir, sprintf("in_imag_%s.txt", out_pattern_name)));
writeToFile(out_R_real(:), fullfile(dir, sprintf("out_R_real_%s.txt", out_golden_name)));
writeToFile(out_R_imag(:), fullfile(dir, sprintf("out_R_imag_%s.txt", out_golden_name)));
writeToFile(out_QH_real(:), fullfile(dir, sprintf("out_QH_real_%s.txt", out_golden_name)));
writeToFile(out_QH_imag(:), fullfile(dir, sprintf("out_QH_imag_%s.txt", out_golden_name)));
writeToFile(out_QHy_real(:), fullfile(dir, sprintf("out_QHy_real_%s.txt", out_golden_name)));
writeToFile(out_QHy_imag(:), fullfile(dir, sprintf("out_QHy_imag_%s.txt", out_golden_name)));
save(fullfile(dir, sprintf("H_%s.mat", out_pattern_name)), "H", "Hf");

function writeToFile(mat, outFile)
    [fd, msg] = fopen(outFile, 'w');
    if fd < 0
        disp(msg);
    end
    matWithNewline = [bin(mat), char(zeros(size(mat))+newline)];
    fprintf(fd, '%s', matWithNewline.');
    fclose(fd);
end