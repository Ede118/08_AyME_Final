clear; clc; close all;

%% 1. Parámetros de la perturbación
Tl_pert = 5;            % Amplitud del escalón de torque [N.m]
t_step  = 2;            % Instante en el que se aplica el escalón [s]
eps_t   = 1e-6;         % Diferencial de tiempo para flanco vertical [s]
t_sim   = 25;           % Tiempo total de simulación [s]

% Definición de puntos para 1-D Lookup Table (Breakpoints y Table Data)
t_bp  = [0,  t_step,  t_step + eps_t,  t_sim];
Tl_td = [0,  0,       Tl_pert,         Tl_pert];

%% 2. Evaluación continua para graficar
t_vec = linspace(0, t_sim, 10000);
Tl_vec = interp1(t_bp, Tl_td, t_vec, 'linear');

%% 3. Gráfica del perfil de perturbación
figure('Color', 'w', 'Name', 'Perfil de Perturbación de Torque');
plot(t_vec, Tl_vec, 'LineWidth', 2, 'Color', [0 0.4470 0.7410]);
grid on; hold on;

% Marcar los vértices de la Lookup Table
plot(t_bp, Tl_td, 'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');

% Etiquetas y formato
title('Perturbación en Escalón de Torque de Carga T_l', 'Interpreter', 'latex', 'FontSize', 13);
xlabel('Tiempo [s]', 'FontSize', 11);
ylabel('Torque de Carga $T_l$ [N$\cdot$m]', 'Interpreter', 'latex', 'FontSize', 11);
legend('Señal interpolada', 'Puntos Lookup Table', 'Location', 'southeast');

ylim([-1, Tl_pert*1.3]);
xlim([0, t_sim]);
yticks([0, Tl_pert]);
yticklabels({'0 N\cdotm', '+5 N\cdotm'});

% Imprimir vectores listos para copiar en consola
disp('--- COPIAR EN BREAKPOINTS 1 (t_bp) ---');
fprintf('[%.6g, %.6g, %.7g, %.6g]\n', t_bp);
disp('--- COPIAR EN TABLE DATA (Tl_td) ---');
fprintf('[%.2f, %.2f, %.2f, %.2f]\n', Tl_td);