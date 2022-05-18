function [Q, R] = QRD_GR(X)
s = size(X);
QH = eye(s);
R = X;

for col = 1:s(2)-1
    for row = s(1):-1:col+1
        a = R(row-1, col);
        b = R(row, col);
        
        % calculate 3 angles
        ang_a = angle(a);
        ang_b = angle(b);
        ang_1 = angle(abs(R(row-1, col))+1j*abs(R(row, col)));

        rot = [ ...
            cos(ang_1)*exp(-1j*ang_a) sin(ang_1)*exp(-1j*ang_b); ...
            -sin(ang_1)*exp(-1j*ang_a) cos(ang_1)*exp(-1j*ang_b)];

        golden_R_out = rot * R(row-1:row, :);
        R(row-1:row, :) = golden_R_out;
        
        golden_Q_out = rot * QH(row-1:row, :);
        QH(row-1:row, :) = golden_Q_out;
    end
end
Q = QH';
end