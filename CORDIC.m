function [x_out, y_out, z_out] = CORDIC(x, y, z, mode, iter)
    x_inv = 0;
    y_inv = 0;

    gain = 1;
    if mode == "rotation"
        swap = 0;
        if z > pi/2 && z <= pi
            z = z - pi/2;
            x_inv = 1;
            swap = 1;
        elseif z < -pi/2 && z >= -pi
            z = z + pi/2;
            y_inv = 1;
            swap = 1;
        elseif z > pi/2 || z < -pi/2
            error("z is not in convergence range");
        end
        if abs(z) > 1.7433
            error("z is not in convergence range");
        end

        for i = 0:iter-1
            if z < 0
                di = -1;
            elseif z > 0
                di = 1;
            else
                break
            end
            x_n = x - y * di * 2^(-i);
            y_n = y + x * di * 2^(-i);
            z_n = z - di * atan(2^(-i));

            gain = gain*sqrt(1+2^(-2*i));

            x = x_n;
            y = y_n;
            z = z_n;
        end

        if swap
            temp = x;
            x = y;
            y = temp;
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
                swap = 1;
            else
                swap = 0;
            end
            x = -x;
            y = -y;
            x_inv = 1;
        end
        if atan(y/x) > 1.7433
            error("tan-1(y/x) is not in convergence range");
        end

        for i = 0:iter-1
            if y > 0
                di = -1;
            elseif y < 0
                di = 1;
            else
                break
            end
            x_n = x - y * di * 2^(-i);
            y_n = y + x * di * 2^(-i);
            z_n = z - di * atan(2^(-i));

            gain = gain*sqrt(1+2^(-2*i));

            x = x_n;
            y = y_n;
            z = z_n;
        end
        
        if x_inv
            if swap
                z = -pi+z;
            else
                z = pi+z;
            end
        end
    else
        error("Unknown operation mode %s", mode);
    end
    x_out = x/gain;
    y_out = y/gain;
    z_out = z;
end