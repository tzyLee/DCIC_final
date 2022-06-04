% %% QR decomposition
bit = 14;
iter = 1:20;
error = zeros(size(iter));

% NUM_TRIALS = 20;
% for j = 1:NUM_TRIALS
%     H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
%     
%     for i = 1:length(iter)
%         [QC, RC] = QRD_CORDIC(H, iter(i), bit, bit-4);
%         error(i) = error(i) + mean(abs(QC*RC - H), 'all');
%     end
% end
% 
% error = error/NUM_TRIALS;
% save('QR_iter_sim.mat', 'bitwidth', 'error');

%% Plot
load('QR_iter_sim.mat');

figure;
plot(iter, error, '-o');
xlabel('iteration');
ylabel('mean error');
title('|QR - H| under different number of iteration');
grid on;



