% =========================================================================
% SCRIPT: Graficador de Estímulos de Tensión y Torque de Carga (qd0)
% =========================================================================
clear; clc; close all;

%% 1. Definición de Vectores de Datos (Puntos duplicados para saltos ideales)
% Vector de tiempo (segundos)
t = [0.0, 0.1, 0.1, 0.3, 0.3, 0.5, 0.5, 0.7, 0.7, 0.9, ...
    0.9, 1.1, 1.1, 1.3, 1.3, 1.5, 1.5, 1.7, 1.7, 1.9, 1.9, 2.0];

% Vector de Tensión de consigna en eje q (Vcc)
v_qs = [0.0, 0.0, 19.596, 19.596, 19.596, 19.596, 19.596, 19.596, 0.0, 0.0, ...
    0.0, 0.0, -19.596, -19.596, -19.596, -19.596, -19.596, -19.596, 0.0, 0.0, 0.0, 0.0];

% Vector de Torque de carga (N.m)
T_l = [0.0, 0.0, 0.0, 0.0, 6.28, 6.28, -6.28, -6.28, -6.28, -6.28, ...
    0.0, 0.0, 0.0, 0.0, 6.28, 6.28, -6.28, -6.28, 0.0, 0.0, 0.0, 0.0];

%% 2. Creación del Gráfico
figure('Name', 'Estímulos de Entrada para Simulación de Motor', 'NumberTitle', 'off', 'Color', 'w');

% --- SUBPLOT 1: Tensión de Estator v_qs* ---
subplot(2, 1, 1);
plot(t, v_qs, 'r-', 'LineWidth', 2.5);
grid on;
hold on;
% Marcamos los puntos de transición con círculos
plot(t, v_qs, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 4); 
ylabel('v_{qs}^{r*} (V)', 'FontSize', 11, 'FontWeight', 'bold');
title('Consignas de Entrada del Ensayo Dinámico', 'FontSize', 13, 'FontWeight', 'bold');
ylim([-25, 25]);
xlim([0, 2.0]);
set(gca, 'FontSize', 10, 'GridLineStyle', ':');

% --- SUBPLOT 2: Torque de Carga T_l ---
subplot(2, 1, 2);
plot(t, T_l, 'b-', 'LineWidth', 2.5);
grid on;
hold on;
% Marcamos los puntos de transición con círculos
plot(t, T_l, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 4); 
xlabel('Tiempo (s)', 'FontSize', 11, 'FontWeight', 'bold');
ylabel('T_l (N\cdotm)', 'FontSize', 11, 'FontWeight', 'bold');
ylim([-8, 8]);
xlim([0, 2.0]);
set(gca, 'FontSize', 10, 'GridLineStyle', ':');

%% 3. Mostrar líneas verticales de sincronización (Opcional pero muy útil)
% Esto dibuja líneas discontinuas grises en cada "t_step" clave para ver cómo coinciden los eventos
for i = 1:length(t)
    % Evitamos duplicar líneas en el mismo instante de tiempo para no sobrecargar el gráfico
    if i > 1 && t(i) == t(i-1)
        continue;
    end

    subplot(2, 1, 1);
    xline(t(i), '--', 'Color', [0.5 0.5 0.5 0.5], 'LineWidth', 1);

    subplot(2, 1, 2);
    xline(t(i), '--', 'Color', [0.5 0.5 0.5 0.5], 'LineWidth', 1);
end

% Ajuste de distribución del gráfico en pantalla
sgtitle('Entradas del Sistema: Voltaje del Estator y Torque de Carga', 'FontSize', 14, 'FontWeight', 'bold');