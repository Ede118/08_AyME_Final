%% =========================================================================
%% CURVAS PARAMÉTRICAS: TORQUE vs VELOCIDAD Y EVALUACIÓN DE CUADRANTES
%% =========================================================================
clc;

%% 1. Extracción de las señales desde el Workspace o el objeto 'out'
function val = obtener_datos(nombre)
% Busca la variable en el workspace base; si no existe suelta, busca dentro de 'out'
if evalin('base', sprintf('exist(''%s'', ''var'')', nombre))
    val = evalin('base', nombre);
elseif evalin('base', 'exist(''out'', ''var'')')
    out_struct = evalin('base', 'out');
    if isprop(out_struct, nombre) || isfield(out_struct, nombre)
        val = out_struct.(nombre);
    else
        error('No se encontró la variable "%s" dentro del objeto "out".', nombre);
    end
else
    error('No se encontró la variable "%s" ni el objeto "out" en el Workspace.', nombre);
end
end
% Carga de objetos Timeseries
sig_wm_NL  = obtener_datos('sim_omega_m_NL');
sig_iq_NL  = obtener_datos('sim_Iq_NL');
sig_wm_LTI = obtener_datos('sim_omega_m_LTI');
sig_iq_LTI = obtener_datos('sim_iq_LTI');

% Extracción de vectores de tiempo y datos
t_wm_NL = sig_wm_NL.Time;
wm_NL   = squeeze(sig_wm_NL.Data);
iq_NL   = squeeze(sig_iq_NL.Data);

t_wm_LTI = sig_wm_LTI.Time;
wm_LTI   = squeeze(sig_wm_LTI.Data);
iq_LTI   = squeeze(sig_iq_LTI.Data);

%% 2. Parámetros de la máquina
% Ajustar según los valores de placa de la cátedra si difieren
P = 4;           % Pares de polos
lambda_m = 0.08; % [Wb] Flujo magnético concatenado de imanes permanentes

% Cálculo de Te para NL y LTI (SPMSM: Te = 1.5 * P * lambda_m * iqs)
Te_NL  = 1.5 * P * lambda_m * iq_NL;
Te_LTI = 1.5 * P * lambda_m * iq_LTI;

%% 3. Generación del gráfico paramétrico
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

% Anotaciones dinámicas de los Cuadrantes
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