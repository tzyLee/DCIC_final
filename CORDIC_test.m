clc;

%% Rotation mode
xx = [2; -3];
angle = -2*pi/3;
rot = [cos(angle) -sin(angle); sin(angle) cos(angle)];
out = rot * xx;

[x, y, z] = CORDIC(xx(1), xx(2), angle, 'rotation', 30);

fprintf("Rotation mode test:\n");
fprintf("Expected: %f %f\n", out);
fprintf("Actual: %f %f\n\n", x, y);


%% Vectoring mode
xx = [-5; 4];

[x, y, z] = CORDIC(xx(1), xx(2), 0, 'vectoring', 12);

fprintf("Vectoring mode test:\n");
fprintf("Expected: %f %f\n", vecnorm(xx), atan(xx(2)/xx(1)));
fprintf("Actual: %f %f\n\n", x, z);


%% QR decomposition
% H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
H = (randn(4, 4) + 1j.*randn(4, 4)) ./ sqrt(2);
% H = [-1-2j 3+4j; -5+6j 7-8j];

% % [Q, R] = qr(H);
[Q, R] = QRD_GR(H);
[QC, RC] = QRD_CORDIC(H, 180);

fprintf("Expected:\n");
disp("===========================");
disp(Q*R);
disp("===========================");
fprintf("Actual:\n");
disp("===========================");
disp(QC*RC);
disp("===========================");

fprintf("Error of R:\n");
disp(abs(R-RC));
fprintf("Error of Q:\n");
disp(abs(Q-QC));
fprintf("Error of Q*R:\n");
disp(abs(Q*R - QC*RC));