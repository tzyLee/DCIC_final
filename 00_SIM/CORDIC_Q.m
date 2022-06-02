function [x_out, y_out, z_out] = CORDIC_Q(x, y, z, mode, iter)
%     F = fimath('SumMode', 'SpecifyPrecision', 'SumWordLength', WORD_LEN, 'SumFractionLength', FRAC_LEN);
%     WORD_LEN = 17;
%     FRAC_LEN = 13;
%     GAIN_WORD_LEN = 19;
%     GAIN_FRAC_LEN = 15;
    dz = fi(atan(2.^-(0:iter-1)), 1, get(x, 'WordLength'), get(x, 'FractionLength'));

    qgain = zeros(iter+1, 1);
    qgain(1) = 1;
    for i = 0:iter-1
        qgain(i+2) = qgain(i+1)*(1/sqrt(1+2^(-2*i)));
    end
    qgain = fi(qgain, 0, 10, 10);

    alt_gain = [-2^-2, -2^-3, -2^-4, -2^-5, -2^-5, 2^-6, 2^-6, 2^-7, 2^-7, 2^-7, -2^-8];
    alt_gain = cumprod(1 + alt_gain);


%    x = fi(x, 1, WORD_LEN, FRAC_LEN);
%    y = fi(y, 1, WORD_LEN, FRAC_LEN);
%    z = fi(z, 1, WORD_LEN, FRAC_LEN);
    x_n = x;
    y_n = y;
    z = fi(z, 1, get(x, 'WordLength'), get(x, 'FractionLength'));
    z_n = z;
%     gain = 1/1.64676025812082;
%     gain = fi(1, 0, GAIN_WORD_LEN, GAIN_FRAC_LEN, F);
    gain = 1;

    x_inv = 0;
    y_inv = 0;
%     if z < -pi/2 || z > pi/2
%         if z < 0
%             z(:) = z + pi;
%         else
%             z(:) = z - pi;
%         end
%         x_inv = 1;
%         y_inv = 1;
%     end
    if z < -1.7433 || z > 1.7433
        if z < 0
            z(:) = z + pi;
        else
            z(:) = z - pi;
        end
        x_inv = 1;
        y_inv = 1;
    end
    if mode == "rotation"
%         if abs(z) > 1.7433
%             error("z is not in convergence range");
%         end

        for i = 0:iter-1
            if z < 0
                x_n(:) = x + bitsra(y, i);
                y_n(:) = y - bitsra(x, i);
                z_n(:) = z + dz(i+1);
            elseif z > 0
                x_n(:) = x - bitsra(y, i);
                y_n(:) = y + bitsra(x, i);
                z_n(:) = z - dz(i+1);
            else
                break
            end
            
            gain = gain*(1/sqrt(1+2^(-2*i)));

            x(:) = x_n;
            y(:) = y_n;
            z(:) = z_n;
%             gain = fi(gain, 0, GAIN_WORD_LEN, GAIN_FRAC_LEN, F);
        end

        if x_inv
            x(:) = -x;
        end

        if y_inv
            y(:) = -y;
        end
    elseif mode == "vectoring"
        if x < 0
            if y < 0
                z(:) = -pi;
            else
                z(:) = pi;
            end
            x(:) = -x;
            y(:) = -y;
        end
%         if atan(double(y)/double(x)) > 1.7433
%             error("tan-1(y/x) is not in convergence range");
%         end

        for i = 0:iter-1
            if y > 0
                x_n(:) = x + bitsra(y, i);
                y_n(:) = y - bitsra(x, i);
                z_n(:) = z + dz(i+1);
            elseif y < 0
                x_n(:) = x - bitsra(y, i);
                y_n(:) = y + bitsra(x, i);
                z_n(:) = z - dz(i+1);
            else
                break
            end
            
            gain = gain*(1/sqrt(1+2^(-2*i)));

            x(:) = x_n;
            y(:) = y_n;
            z(:) = z_n;
%             gain = fi(gain, 0, GAIN_WORD_LEN, GAIN_FRAC_LEN, F);
        end
    %else
    %    error("Unknown operation mode %s", mode);
    end

    gain = fi(gain, 0, 10, 10);
    x(:) = x*gain;
    y(:) = y*gain;
    x_out = x;
    y_out = y;
    z_out = z;
end
