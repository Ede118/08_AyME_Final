%% =========================================================================
%% CURVAS PARAMÉTRICAS: TORQUE vs VELOCIDAD Y EVALUACIÓN DE CUADRANTES
%% =========================================================================

% Parámetros de la máquina (ajustar si difieren en tu modelo)
% P: pares de polos, lambda_m: flujo de imán permanente
P = 4;           % Ejemplo: Pares de polos
lambda_m = 0.08; % [Wb] Flujo de imanes

% Cálculo de Te para NL y LTI (SPMSM: Te = 1.5 * P * lambda_m * iqs)
Te_NL  = 1.5 * P * lambda_m * iq_NL;
Te_LTI = 1.5 * P * lambda_m * iq_LTI;

figure('Name', 'Plano Paramétrico Te vs wm - Cuadrantes de Operación', ...
    'Color', 'w', 'Position', [150 150 900 650]);

% Gráfica del modelo NL
plot(wm_NL, Te_NL, 'b-', 'LineWidth', 1.8, 'DisplayName', 'Modelo NL Desacoplado');
hold on;
% Gráfica del modelo LTI
plot(wm_LTI, Te_LTI, 'r--', 'LineWidth', 1.4, 'DisplayName', 'Modelo LTI Equivalente');

% Ejes principales para delimitar cuadrantes
xline(0, 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
yline(0, 'k-', 'LineWidth', 1.2, 'HandleVisibility', 'off');
grid on;

% Marcar los instantes clave t_step sobre la curva NL
t_eval = [0.1, 0.3, 0.5, 0.7, 0.9];
colores = {'go', 'ro', 'mo', 'ko', 'co'};
etiquetas = {'t=0.1s (+Vqs*)', 't=0.3s (+Tl)', 't=0.5s (-Tl)', 't=0.7s (Vqs*=0)', 't=0.9s (Tl=0)'};

for k = 1:length(t_eval)
    [~, idx] = min(abs(t_wm_NL - t_eval(k)));
    plot(wm_NL(idx), Te_NL(idx), colores{k}, 'MarkerFaceColor', colores{k}(1), ...
        'MarkerSize', 7, 'DisplayName', etiquetas{k});
end

% Anotaciones de los Cuadrantes
xl = xlim; yl = ylim;
text(xl(2)*0.6, yl(2)*0.8, '\bf Q1: Motor Directo\rm\newline(P_{mec} > 0)', ...
    'Color', [0 0.5 0], 'FontSize', 10, 'HorizontalAlignment', 'center');
text(xl(2)*0.6, yl(1)*0.8, '\bf Q2: Frenado Regenerativo\rm\newline(P_{mec} < 0)', ...
    'Color', [0.7 0 0], 'FontSize', 10, 'HorizontalAlignment', 'center');
text(xl(1)*0.6, yl(1)*0.8, '\bf Q3: Motor Inverso\rm\newline(P_{mec} > 0)', ...
    'Color', [0 0.5 0], 'FontSize', 10, 'HorizontalAlignment', 'center');
text(xl(1)*0.6, yl(2)*0.8, '\bf Q4: Freno Inverso\rm\newline(P_{mec} < 0)', ...
    'Color', [0.7 0 0], 'FontSize', 10, 'HorizontalAlignment', 'center');

xlabel('\omega_m [rad/s] (Velocidad Mecánica)', 'FontWeight', 'bold');
ylabel('T_e [N\cdot m] (Torque Electromagnético)', 'FontWeight', 'bold');
title('Curva Paramétrica T_e(\omega_m) y Cuadrantes de Operación', 'FontSize', 12);
legend('Location', 'northeastoutside');