function [Q, R] = QRD_CORDIC(X, iter)
s = size(X);
QH = eye(s);
R = X;

for col = 1:s(2)-1
    for row = s(1):-1:col+1
        a = R(row-1, col);
        b = R(row, col);
        
        % calculate 3 angles
        [abs_a, ~, ang_a] = CORDIC(real(a), imag(a), 0, 'vectoring', iter);
        [abs_b, ~, ang_b] = CORDIC(real(b), imag(b), 0, 'vectoring', iter);
        [~, ~, ang_1] = CORDIC(abs_a, abs_b, 0, 'vectoring', iter);
        
        % rotation
        for col2 = col:s(2)
            c = R(row-1, col2);
            d = R(row, col2);

            [s_cr, s_ci, ~] = CORDIC(real(c), imag(c), -ang_a, 'rotation', iter);
            [s_dr, s_di, ~] = CORDIC(real(d), imag(d), -ang_b, 'rotation', iter);
    
            [x_r, y_r, ~] = CORDIC(s_cr, s_dr, -ang_1, 'rotation', iter);
            [x_i, y_i, ~] = CORDIC(s_ci, s_di, -ang_1, 'rotation', iter);

            R(row-1, col2) = x_r+1j*x_i;
            R(row, col2) = y_r+1j*y_i;
            if col2 == col
                R(row, col2) = 0;
            else
                R(row, col2) = y_r+1j*y_i;
            end

            %%
            qc = QH(row-1, col2);
            qd = QH(row, col2);

            [s_qcr, s_qci, ~] = CORDIC(real(qc), imag(qc), -ang_a, 'rotation', iter);
            [s_qdr, s_qdi, ~] = CORDIC(real(qd), imag(qd), -ang_b, 'rotation', iter);

            [qc_r, qd_r, ~] = CORDIC(s_qcr, s_qdr, -ang_1, 'rotation', iter);
            [qc_i, qd_i, ~] = CORDIC(s_qci, s_qdi, -ang_1, 'rotation', iter);

            QH(row-1, col2) = qc_r+1j*qc_i;
            QH(row, col2) = qd_r+1j*qd_i;
        end
    end
end
Q = QH';
end