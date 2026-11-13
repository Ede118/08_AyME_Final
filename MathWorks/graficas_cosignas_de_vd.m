%% Gráficas de Consignas Escalón en Eje Directo v_ds^{r*}(t) - Inciso 5.1.6.d
clc;
close all;

%% 1. Parámetros de tiempo y amplitudes
t_step = 0.5;          % Instante de aplicación del escalón [s]
t_fin  = 3.0;          % Tiempo final de simulación [s] (ajustable a tu modelo)
V_mag  = 1.9596;       % Magnitud Vqs_nom / 10 [Vcc]

t = linspace(0, t_fin, 3000);

% Construcción de las 3 señales escalón en t = 0.5 s
vds_pos  = V_mag  * double(t >= t_step);   % Caso 1: +1.9596 V (Field Forcing)
vds_neg  = -V_mag * double(t >= t_step);   % Caso 2: -1.9596 V (Field Weakening)
vds_cero = zeros(size(t));                 % Caso 3:  0 V      (Caso Base)

%% 2. Figura 1: Escalón Positivo (+1.9596 V)
figure('Name', 'Consigna vds* Positiva', 'Color', 'w', 'Position', [100 150 750 380]);
plot(t, vds_pos, 'b-', 'LineWidth', 2);
hold on;
xline(t_step, 'k--', sprintf('t_{step} = %.1f s', t_step), ...
    'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');
grid on;
xlabel('Tiempo [s]', 'FontWeight', 'bold');
ylabel('v_{ds}^{r*}(t) [V_{cc}]', 'FontWeight', 'bold');
title('Consigna Escalón Positiva: v_{ds}^{r*}(t) = +1.9596 V (Reforzamiento de Campo)', 'FontSize', 11);
ylim([-0.5, 2.5]);
xlim([0, t_fin]);

%% 3. Figura 2: Escalón Negativo (-1.9596 V)
figure('Name', 'Consigna vds* Negativa', 'Color', 'w', 'Position', [140 120 750 380]);
plot(t, vds_neg, 'r-', 'LineWidth', 2);
hold on;
xline(t_step, 'k--', sprintf('t_{step} = %.1f s', t_step), ...
    'LabelVerticalAlignment', 'top', 'HandleVisibility', 'off');
grid on;
xlabel('Tiempo [s]', 'FontWeight', 'bold');
ylabel('v_{ds}^{r*}(t) [V_{cc}]', 'FontWeight', 'bold');
title('Consigna Escalón Negativa: v_{ds}^{r*}(t) = -1.9596 V (Debilitamiento de Campo)', 'FontSize', 11);
ylim([-2.5, 0.5]);
xlim([0, t_fin]);

%% 4. Figura 3: Consigna Nula (0 V)
figure('Name', 'Consigna vds* Nula', 'Color', 'w', 'Position', [180 90 750 380]);
plot(t, vds_cero, 'Color', [0.1 0.6 0.2], 'LineWidth', 2);
hold on;
xline(t_step, 'k--', sprintf('t_{step} = %.1f s', t_step), ...
    'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');
grid on;
xlabel('Tiempo [s]', 'FontWeight', 'bold');
ylabel('v_{ds}^{r*}(t) [V_{cc}]', 'FontWeight', 'bold');
title('Consigna Nula: v_{ds}^{r*}(t) = 0 V (Operación Base Desacoplada)', 'FontSize', 11);
ylim([-1.0, 1.0]);
xlim([0, t_fin]);