function [Q, R] = QRD_GR(X)
s = size(X);
QH = eye(s);
R = X;

for col = 1:s(2)-1
    for row = col+1:s(1)
        a = R(col, col);
        b = R(row, col);
        
        % calculate 3 angles
        ang_a = angle(a);
        ang_b = angle(b);
        ang_1 = angle(abs(a)+1j*abs(b));

        rot = [ ...
            cos(ang_1)*exp(-1j*ang_a) sin(ang_1)*exp(-1j*ang_b); ...
            -sin(ang_1)*exp(-1j*ang_a) cos(ang_1)*exp(-1j*ang_b)];

        golden_R_out = rot * [R(col, :); R(row, :)];
        R(col, :) = golden_R_out(1, :);
        R(row, :) = golden_R_out(2, :);
        
        golden_Q_out = rot * [QH(col, :); QH(row, :)];
        QH(col, :) = golden_Q_out(1, :);
        QH(row, :) = golden_Q_out(2, :);
    end
end
Q = QH';
end