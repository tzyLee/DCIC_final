close all;
clear all;
clc;

%% Data
H = [-1.0650 - 0.7543i  -0.1847 + 0.1290i  -0.6703 + 0.0695i 0.0088 + 0.1643i;...
  -0.3144 + 0.6602i   0.3135 - 1.1067i  -0.5240 + 0.0293i -2.1420 + 0.3015i;...
  -0.1103 + 0.2477i   0.2771 - 0.0598i  -0.3591 - 0.5191i -0.3232 - 0.2636i;...
   0.1952 - 0.0205i  -0.8844 + 1.1342i  -0.2267 - 0.0218i 0.8785 - 0.1672i];

% [Q, R] = qr(H);
[Q, R] = QRD_GR(H);

for WORD_LEN = [14,15,16,17,18,19,20]
%WORD_LEN = 17;
%FRAC_LEN = 13;
FRAC_LEN = WORD_LEN-4;
F = fimath(...
  'RoundingMethod', 'Floor',...
  'OverflowAction', 'Wrap',...
  'SumMode', 'SpecifyPrecision',...
  'SumWordLength', WORD_LEN, ...
  'SumFractionLength', FRAC_LEN);

globalfimath(F);
Hf = fi(H, 1, WORD_LEN, FRAC_LEN, F);

%% Compile
iter = WORD_LEN-1;
switch WORD_LEN
case 14
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_14
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_14(Hf, iter);toc
case 15
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_15
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_15(Hf, iter);toc
case 16
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_16
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_16(Hf, iter);toc
case 17
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_17
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_17(Hf, iter);toc
case 18
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_18
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_18(Hf, iter);toc
case 19
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_19
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_19(Hf, iter);toc
case 20
  fiaccel QRD_CORDIC -args {Hf,iter} -report -o QRD_CORDIC_20
  % Compiled version
  tic, [QCm, RCm] = QRD_CORDIC_20(Hf, iter);toc
end

%% Test
% Non-compiled version
tic, [QC, RC] = QRD_CORDIC(Hf, iter);toc

QC = double(QC);
RC = double(RC);
disp(mean(abs(QC*RC - H), 'all'));

QCm = double(QCm);
RCm = double(RCm);
disp(mean(abs(QCm*RCm - H), 'all'));
end
