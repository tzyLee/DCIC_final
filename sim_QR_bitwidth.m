%% QR decomposition
% bitwidth = 8:20;
% error = zeros(size(bitwidth));
% 
% H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
% 
% for i = 1:length(bitwidth)
%     bit = bitwidth(i)
%     
%     [QC, RC] = QRD_CORDIC(H, 17, bit, bit-4);
%     error(i) = mean(abs(QC*RC - H), 'all');
% end
% save('QR_bitwidth_sim.mat', 'bitwidth', 'error');

%% Plot
load('QR_bitwidth_sim.mat');

figure;
plot(bitwidth, error, '-o');
xlabel('word length');
ylabel('mean error');
title('|QR - H| under different word length');
grid on;



