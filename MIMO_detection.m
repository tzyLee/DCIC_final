N_T = 4; % number of transmit antennas
N_R = 4; % number of receive antennas
EbN0 = 0:2:20;
decoders = ["K-Best (k=16, sorting)", "K-Best (k=16, sorting, GR)"];
CORDIC_ITER = 30;

%% Simulation
load("BER-16-QAM.mat");
% BER = simulation(N_T, N_R, "16-QAM", 1600, 100000, EbN0, decoders, CORDIC_ITER);

%% Plot
figure;
semilogy(EbN0, BER(1, :), '-o', 'LineWidth', 2, 'MarkerSize', 10);
hold on;
grid on;
semilogy(EbN0, BER(2, :), '-+', 'LineWidth', 2, 'MarkerSize', 10);
xlabel("Eb/N0 (dB)");
ylabel("BER");
title(sprintf("%dx%d 16-QAM Detection", N_T, N_R));
legend(decoders);
xlim([min(EbN0), max(EbN0)]);
ylim([1e-5, 1]);
ax = gca;
ax.FontSize = 14;

function BER = simulation(N_T, N_R, MODULATION, ERR_THRESHOLD, TRIALS, EbN0, decoders, CORDIC_ITER)
N_SNR = length(EbN0);
N_D = length(decoders);
%% Parallel related code
N_worker = parcluster('local').NumWorkers;
TRIALS_PER_WORKER = ceil(TRIALS/N_worker);
TRIALS = TRIALS_PER_WORKER*N_worker;

%% Result buffer
BER = zeros(N_D, N_SNR, N_worker);
%% Modulation
sym_16QAM = qammod((0:15).', 16); % gray-code
sym_64QAM = qammod((0:63).', 64); % gray-code
sym_QPSK = [-1-1j,-1+1j, +1-1j, +1+1j];
if MODULATION == "16-QAM"
    sym = sym_16QAM(:);
elseif MODULATION == "64-QAM"
    sym = sym_64QAM(:);
else
    sym = sym_QPSK(:);
end
SYM_SIZE = numel(sym);
Q = log2(SYM_SIZE);     % number of bits per symbol
Es = mean(abs(sym).^2); % avg energy per symbol
Eb = Es / Q;            % avg energy per bit
N0 = Eb*N_T ./ db2pow(EbN0); % noise variance

%% Bit error table
bitDiff = bitxor((0:SYM_SIZE-1), (0:SYM_SIZE-1)');
numBitDiff = zeros(size(bitDiff));
for i=1:Q
    numBitDiff = numBitDiff + bitget(bitDiff, i);
end

%% Set random seed
rngS = rng(6743);

%% Run for at least `TRIALS` iterations
tic;
parfor p=1:N_worker
BER_worker = zeros(N_D, N_SNR);
for t=1:TRIALS_PER_WORKER
    %% Symbol genreation
    idx = randi([1, SYM_SIZE], N_T, 1);
    s = sym(idx);
    % (row-1)*colSize + (cow-1) + 1
    % == rowIdx (0 Based) + cowIdx (1 Based)
    rowIdx = (idx-1)*SYM_SIZE;

    % AWGN noise
    n = (randn(N_R, 1) + 1j.*randn(N_R, 1)) ./ sqrt(2);

    % Rayleigh fading channel
    H = (randn(N_R, N_T) + 1j.*randn(N_R, N_T)) ./ sqrt(2);
    x = H*s;
    
    % sort by column power of H
    [~, sortIdx] = sort(vecnorm(H, 2, 1));
    Hs = H(:, sortIdx); % sorted H

    % QR decomposition of H
    [QHs, RHs] = QRD_CORDIC(Hs, CORDIC_ITER);
    [QHs_GR, RHs_GR] = QRD_GR(Hs);

    for si = 1:N_SNR
        % Transmit data
        y = x + sqrt(N0(si)) .* n;
        zs_tilde = QHs' * y;
        zs_GR_tilde = QHs_GR' * y;
    
        %% KBest (k=16, sorting)
        x_hat_KBest16_s = KBest(16, RHs, zs_tilde, sym);
        % restore original order
        x_hat_KBest16 = zeros(size(x_hat_KBest16_s));
        x_hat_KBest16(sortIdx) = x_hat_KBest16_s;
        [~, idx_hat_KBest16_s] = min(abs(x_hat_KBest16 - sym.').^2, [], 2);
        

        %% KBest (k=16, sorting)
        x_hat_KBest16_s = KBest(16, RHs_GR, zs_GR_tilde, sym);
        % restore original order
        x_hat_KBest16_GR = zeros(size(x_hat_KBest16_s));
        x_hat_KBest16_GR(sortIdx) = x_hat_KBest16_s;
        [~, idx_hat_KBest16_s_GR] = min(abs(x_hat_KBest16_GR - sym.').^2, [], 2);
        %% Store result
        for di = 1:N_D
            decoder = decoders(di);
            switch decoder
                case "K-Best (k=16, sorting)"
                    bitErr = sum(numBitDiff(rowIdx + idx_hat_KBest16_s));
                case "K-Best (k=16, sorting, GR)"
                    bitErr = sum(numBitDiff(rowIdx + idx_hat_KBest16_s_GR));
                otherwise
                    bitErr = sum(numBitDiff(rowIdx + idx_hat_KBest16_s));
            end
            BER_worker(di, si) = BER_worker(di, si) + bitErr / (N_T*Q);
        end
    end
end
BER(:, :, p) = BER_worker;
end

%% Run until error meets threhsold
numError = round(sum(BER, 3)*N_T*Q);
numTrials = zeros(size(numError)) + TRIALS;
TRIALS_PER_WORKER_INC = 10000;
for si = 1:N_SNR
    % make all decoders in the given SNR runs the same number of iterations
    % using the same H and n -> reduce random affects
    while any(numError(:, si) < ERR_THRESHOLD)
        numError_worker = zeros(N_D, N_worker);
        parfor p=1:N_worker
        for t=1:TRIALS_PER_WORKER_INC
            %% Symbol genreation
            idx = randi([1, SYM_SIZE], N_T, 1);
            s = sym(idx);
            rowIdx = (idx-1)*SYM_SIZE;
        
            % AWGN noise
            n = (randn(N_R, 1) + 1j.*randn(N_R, 1)) ./ sqrt(2);
            % Rayleigh fading channel
            H = (randn(N_R, N_T) + 1j.*randn(N_R, N_T)) ./ sqrt(2);
            
            % sort by column power of H
            [~, sortIdx] = sort(vecnorm(H, 2, 1));
            Hs = H(:, sortIdx); % sorted H
        
            % QR decomposition of H
            [QHs, RHs] = QRD_CORDIC(Hs, CORDIC_ITER);
            [QHs_GR, RHs_GR] = QRD_GR(Hs);
    
            % Transmit data
            y = H*s + sqrt(N0(si)) .* n;
            zs_tilde = QHs' * y;
            zs_GR_tilde = QHs_GR' * y;
        
            %% KBest (k=16, sorting)
            x_hat_KBest16_s = KBest(16, RHs, zs_tilde, sym);
            % restore original order
            x_hat_KBest16 = zeros(size(x_hat_KBest16_s));
            x_hat_KBest16(sortIdx) = x_hat_KBest16_s;
            [~, idx_hat_KBest16_s] = min(abs(x_hat_KBest16 - sym.').^2, [], 2);
            
    
            %% KBest (k=16, sorting)
            x_hat_KBest16_s = KBest(16, RHs_GR, zs_GR_tilde, sym);
            % restore original order
            x_hat_KBest16_GR = zeros(size(x_hat_KBest16_s));
            x_hat_KBest16_GR(sortIdx) = x_hat_KBest16_s;
            [~, idx_hat_KBest16_s_GR] = min(abs(x_hat_KBest16_GR - sym.').^2, [], 2);
            %% Store result
            for di = 1:N_D
                decoder = decoders(di);
                switch decoder
                    case "K-Best (k=16, sorting)"
                        bitErr = sum(numBitDiff(rowIdx + idx_hat_KBest16_s));
                    case "K-Best (k=16, sorting, GR)"
                        bitErr = sum(numBitDiff(rowIdx + idx_hat_KBest16_s_GR));
                    otherwise
                        bitErr = sum(numBitDiff(rowIdx + idx_hat_KBest16_s));
                end
                numError_worker(di, p) = numError_worker(di, p) + bitErr;
            end
        end
        end
        numError(:, si) = numError(:, si) + sum(numError_worker, 2);
        numTrials(:, si) = numTrials(:, si) + N_worker*TRIALS_PER_WORKER_INC;
    end
end
toc;

%% Restore RNG
rng(rngS);

%% Average
BER = numError ./ (N_T * Q) ./ numTrials;

save(sprintf('BER-%s', MODULATION), 'MODULATION', 'BER', 'numError', 'numTrials');
end

%% Decoders
function x_hat = KBest(k, R, z_tilde, sym)
    P = length(z_tilde);
    SYM_SIZE = length(sym);
    
    % First level
    cost = abs(z_tilde(end) - R(end, end) .* sym) .^ 2;
    accCost = cost;
    x = sym.';

    % The rest levels
    for level = 1:P-1
        uppTrigProd = R(end-level, end-level+1:end) * x;
        diagProd = R(end-level, end-level) .* sym;
        cost = accCost.' ...
             + abs((z_tilde(end-level) - uppTrigProd) - diagProd) .^ 2; % (SYM_SIZE, k)
        % Find best k
        [~, minIdx] = mink(cost(:), k);
        % minIdx-1 == (xIdx-1)*SYM_SIZE + (symIdx-1), use divmod because
        % ind2sub is too slow
        minIdx0based = minIdx-1;
        symIdx = rem(minIdx0based, SYM_SIZE)+1;
        xIdx = floor((minIdx-symIdx)/SYM_SIZE)+1;
        % Save best k guesses
        x = [sym(symIdx).'; x(:, xIdx)];
        accCost = cost(minIdx);
    end
    
    [~, finalMinIdx] = min(accCost);
    x_hat = x(:, finalMinIdx);
end
