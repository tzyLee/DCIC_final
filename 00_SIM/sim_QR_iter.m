% %% QR decomposition
bit = 14;
iter = 8:13;
error = zeros(size(iter));
F = fimath(...
  'RoundingMethod', 'Floor',...
  'OverflowAction', 'Wrap',...
  'SumMode', 'SpecifyPrecision',...
  'SumWordLength', get(Hf, 'WordLength'), ...
  'SumFractionLength', get(Hf, 'FractionLength'));

globalfimath(F);

NUM_TRIALS = 20;
for j = 1:NUM_TRIALS
    H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
    Hf = fi(H, 1, bit, bit-4, F);
    
    for i = 1:length(iter)
        [QC, RC] = QRD_CORDIC(Hf, iter(i));
        error(i) = error(i) + mean(abs(double(QC)*double(RC) - H), 'all');
    end
end

error = error/NUM_TRIALS;
% save('QR_iter_sim14.mat', 'bitwidth', 'error');

%% Plot
% load('QR_iter_sim.mat');

figure;
plot(iter, error, '-o');
xlabel('iteration');
ylabel('mean error');
title('|QR - H| under different number of iteration');
grid on;



