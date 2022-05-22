function [x_out, y_out, z_out] = CORDIC_Q(x, y, z, mode, iter, WORD_LEN, FRAC_LEN)
    F = fimath('SumMode', 'KeepMSB');
%     WORD_LEN = 17;
%     FRAC_LEN = 13;
%     GAIN_WORD_LEN = 19;
%     GAIN_FRAC_LEN = 15;

    x = fi(x, 1, WORD_LEN, FRAC_LEN, F);
    y = fi(y, 1, WORD_LEN, FRAC_LEN, F);
    z = fi(z, 1, WORD_LEN, FRAC_LEN, F);
%     gain = 1/1.64676025812082;
%     gain = fi(1, 0, GAIN_WORD_LEN, GAIN_FRAC_LEN, F);
    gain = 1;

    x_inv = 0;
    y_inv = 0;
    if z < -pi/2 || z > pi/2
        if z < 0
            z = z + pi;
        else
            z = z - pi;
        end
        x_inv = 1;
        y_inv = 1;
    end

    if mode == "rotation"
        if abs(z) > 1.7433
            error("z is not in convergence range");
        end

        for i = 0:iter-1
            if z < 0
                x_n = x + bitsra(y, i);
                y_n = y - bitsra(x, i);
                z_n = z + atan(2^(-i));
            elseif z > 0
                x_n = x - bitsra(y, i);
                y_n = y + bitsra(x, i);
                z_n = z - atan(2^(-i));
            else
                break
            end
            
            gain = gain*(1/sqrt(1+2^(-2*i)));

            x = fi(x_n, 1, WORD_LEN, FRAC_LEN, F);
            y = fi(y_n, 1, WORD_LEN, FRAC_LEN, F);
            z = fi(z_n, 1, WORD_LEN, FRAC_LEN, F);
%             gain = fi(gain, 0, GAIN_WORD_LEN, GAIN_FRAC_LEN, F);
        end

        if x_inv
            x = -x;
        end

        if y_inv
            y = -y;
        end
    elseif mode == "vectoring"
        if x < 0
            if y < 0
                z = -pi;
            else
                z = pi;
            end
            x = -x;
            y = -y;
        end
        if atan(double(y)/double(x)) > 1.7433
            error("tan-1(y/x) is not in convergence range");
        end

        for i = 0:iter-1
            if y > 0
                x_n = x + bitsra(y, i);
                y_n = y - bitsra(x, i);
                z_n = z + atan(2^(-i));
            elseif y < 0
                x_n = x - bitsra(y, i);
                y_n = y + bitsra(x, i);
                z_n = z - atan(2^(-i));
            else
                break
            end
            
            gain = gain*(1/sqrt(1+2^(-2*i)));

            x = fi(x_n, 1, WORD_LEN, FRAC_LEN, F);
            y = fi(y_n, 1, WORD_LEN, FRAC_LEN, F);
            z = fi(z_n, 1, WORD_LEN, FRAC_LEN, F);
%             gain = fi(gain, 0, GAIN_WORD_LEN, GAIN_FRAC_LEN, F);
        end
    else
        error("Unknown operation mode %s", mode);
    end

%     if y == 0
%         fprintf("?? %f %f %f %f\n", x, y, z, gain);
%     end
    x_out = x*gain;
    y_out = y*gain;
    z_out = z;
end