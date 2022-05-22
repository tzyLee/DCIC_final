% clc;

% %% Rotation mode
% xx = [0.9; -0.7];
% angle = -2*pi/3;
% rot = [cos(angle) -sin(angle); sin(angle) cos(angle)];
% out = rot * xx;
% 
% [x, y, z] = CORDIC_Q(xx(1), xx(2), angle, 'rotation', 17, 17, 13);
% 
% fprintf("Rotation mode test:\n");
% fprintf("Expected: %f %f\n", out);
% fprintf("Actual: %f %f\n\n", x, y);
% 
% 
% %% Vectoring mode
% xx = [1; -0.89];
% norm = vecnorm(xx);
% atan_xx = atan(xx(2)/xx(1));
% 
% [x, y, z] = CORDIC_Q(xx(1), xx(2), 0, 'vectoring', 17, 17, 13);
% 
% fprintf("Vectoring mode test:\n");
% fprintf("Expected: %f %f\n", norm, atan_xx);
% fprintf("Actual: %f %f\n\n", x, z);


%% QR decomposition
% H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
% H = (randn(4, 4) + 1j.*randn(4, 4));
% H = [-1-2j 3+4j; -5+6j 7-8j];
H = [-1.0650 - 0.7543i  -0.1847 + 0.1290i  -0.6703 + 0.0695i 0.0088 + 0.1643i;...
  -0.3144 + 0.6602i   0.3135 - 1.1067i  -0.5240 + 0.0293i -2.1420 + 0.3015i;...
  -0.1103 + 0.2477i   0.2771 - 0.0598i  -0.3591 - 0.5191i -0.3232 - 0.2636i;...
   0.1952 - 0.0205i  -0.8844 + 1.1342i  -0.2267 - 0.0218i 0.8785 - 0.1672i];

% [Q, R] = qr(H);
[Q, R] = QRD_GR(H);
[QC, RC] = QRD_CORDIC(H, 19, 20, 15);

fprintf("Expected:\n");
disp("===========================");
disp(R);
disp(Q);
disp(mean(abs(Q*R - H), 'all'));
disp("===========================");
fprintf("Actual:\n");
disp("===========================");
disp(RC);
disp(QC);
disp(abs(QC*R - RC));
disp("===========================");

fprintf("Error of R:\n");
disp(mean(abs(R-RC), 'all'));
fprintf("Error of Q:\n");
disp(mean(abs(Q-QC), 'all'));
fprintf("Error of Q*R:\n");
disp(mean(abs(H - QC*RC), 'all'));