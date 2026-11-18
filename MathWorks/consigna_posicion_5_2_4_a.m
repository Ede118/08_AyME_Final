%% Perfil trapezoidal de consigna de posición q1*(t)
clear; clc; close all;

% 1. Definición de breakpoints y tabla (mismos valores que en Simulink)
t_bp = [0, 2, 7, 9, 14, 16];          % Tiempo [s]
q1_table = [0, 0, 2*pi, 2*pi, 0, 0];  % Posición [rad]

% 2. Vector de tiempo fino para interpolación y cálculo de velocidad
t = linspace(0, 16, 1601);            % Paso de 0.01 s
q1_ref = interp1(t_bp, q1_table, t, 'linear');
dq1_ref = gradient(q1_ref, t);        % Derivada numérica (velocidad) [rad/s]

%% 3. Gráficas
figure('Color', 'w', 'Position', [100, 100, 800, 500]);

% Subgráfica 1: Posición q1*(t)
subplot(2, 1, 1);
plot(t, q1_ref, 'b', 'LineWidth', 1.8); hold on;
plot(t_bp, q1_table, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 5); % Vértices
grid on;
ylabel('Posición q_1^*(t) [rad]', 'FontWeight', 'bold');
title('Consigna de Movimiento Trapezoidal', 'FontSize', 12);
legend('Consigna q_1^*(t)', 'Breakpoints', 'Location', 'northeast');
ylim([-0.5, 2*pi + 0.8]);
yticks([0, pi, 2*pi]);
yticklabels({'0', '\pi', '2\pi'});

% Subgráfica 2: Velocidad dq1*(t)/dt
subplot(2, 1, 2);
plot(t, dq1_ref, 'Color', [0.85, 0.33, 0.1], 'LineWidth', 1.8);
grid on;
xlabel('Tiempo t [s]', 'FontWeight', 'bold');
ylabel('Velocidad \omega_1^*(t) [rad/s]', 'FontWeight', 'bold');
ylim([-1.8, 1.8]);