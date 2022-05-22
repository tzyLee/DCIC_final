function [Q, R] = QRD_CORDIC(X, iter, WORD_LEN, FRAC_LEN)
s = size(X);
QH = eye(s);
R = X;

for col = 1:s(2)-1
    for row = col+1:s(1)
        a = R(col, col);
        b = R(row, col);

        % calculate 3 angles
        [abs_a, ~, ang_a] = CORDIC_Q(real(a), imag(a), 0, 'vectoring', iter, WORD_LEN, FRAC_LEN);
        [abs_b, ~, ang_b] = CORDIC_Q(real(b), imag(b), 0, 'vectoring', iter, WORD_LEN, FRAC_LEN);
        [norm_ab, ~, ang_1] = CORDIC_Q(abs_a, abs_b, 0, 'vectoring', iter, WORD_LEN, FRAC_LEN);

        R(col, col) = norm_ab;
        R(row, col) = 0;

        for col2 = col+1:s(2)
            c = R(col, col2);
            d = R(row, col2);

            [s_cr, s_ci, ~] = CORDIC_Q(real(c), imag(c), -ang_a, 'rotation', iter, WORD_LEN, FRAC_LEN);
            [s_dr, s_di, ~] = CORDIC_Q(real(d), imag(d), -ang_b, 'rotation', iter, WORD_LEN, FRAC_LEN);
    
            [x_r, y_r, ~] = CORDIC_Q(s_cr, s_dr, -ang_1, 'rotation', iter, WORD_LEN, FRAC_LEN);
            [x_i, y_i, ~] = CORDIC_Q(s_ci, s_di, -ang_1, 'rotation', iter, WORD_LEN, FRAC_LEN);

            R(col, col2) = x_r+1j*x_i;
            R(row, col2) = y_r+1j*y_i;
        end

        for col2 = 1:s(2)
            c = QH(col, col2);
            d = QH(row, col2);

            [s_cr, s_ci, ~] = CORDIC_Q(real(c), imag(c), -ang_a, 'rotation', iter, WORD_LEN, FRAC_LEN);
            [s_dr, s_di, ~] = CORDIC_Q(real(d), imag(d), -ang_b, 'rotation', iter, WORD_LEN, FRAC_LEN);
    
            [x_r, y_r, ~] = CORDIC_Q(s_cr, s_dr, -ang_1, 'rotation', iter, WORD_LEN, FRAC_LEN);
            [x_i, y_i, ~] = CORDIC_Q(s_ci, s_di, -ang_1, 'rotation', iter, WORD_LEN, FRAC_LEN);

            QH(col, col2) = x_r+1j*x_i;
            QH(row, col2) = y_r+1j*y_i;
        end
    end
end

Q = QH';
end