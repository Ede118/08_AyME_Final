%% Script de Posprocesamiento - Inciso 6.b (PGI Control PMSM)
% Criterio settling time: +-1%, rise time: 10% a 90%
clc;
close all;

%% 1. Extracción de variables (compatibilidad directa o dentro del objeto 'out')
sim_omega_m_NL  = obtener_var_workspace('sim_omega_m_NL');
sim_Iq_NL       = obtener_var_workspace('sim_Iq_NL');
sim_omega_m_LTI = obtener_var_workspace('sim_omega_m_LTI');
sim_iq_LTI      = obtener_var_workspace('sim_iq_LTI');

% Extracción de vectores de tiempo y datos desde los Timeseries
t_wm_NL  = sim_omega_m_NL.Time;
wm_NL    = squeeze(sim_omega_m_NL.Data);

t_iq_NL  = sim_Iq_NL.Time;
iq_NL    = squeeze(sim_Iq_NL.Data);

t_wm_LTI = sim_omega_m_LTI.Time;
wm_LTI   = squeeze(sim_omega_m_LTI.Data);

t_iq_LTI = sim_iq_LTI.Time;
iq_LTI   = squeeze(sim_iq_LTI.Data);

%% 2. Tramos de los transitorios según la consigna
% tstep1 = 0.1 s (+Vqs*), tstep2 = 0.3 s (+Tl), tstep3 = 0.5 s (-Tl),
% tstep4 = 0.7 s (Vqs*=0), tstep5 = 0.9 s (Tl=0)
t_final_sim = max([t_wm_NL(end), t_wm_LTI(end)]);
t_steps = [0.1, 0.3, 0.5, 0.7, 0.9, t_final_sim];

nombres_tramos = {
    '1) +Vqs* (t=0.1s)', ...
    '2) +Tl_max (t=0.3s)', ...
    '3) -Tl_max (t=0.5s)', ...
    '4) Vqs*=0 (t=0.7s)', ...
    '5) Tl=0 (t=0.9s)'
};

num_tramos = length(nombres_tramos);

%% 3. Cálculo de métricas tramo por tramo
res_wm_NL  = cell(num_tramos, 1);
res_wm_LTI = cell(num_tramos, 1);
res_iq_NL  = cell(num_tramos, 1);
res_iq_LTI = cell(num_tramos, 1);

for k = 1:num_tramos
    t_ini = t_steps(k);
    t_fin = t_steps(k+1);
    
    res_wm_NL{k}  = procesar_stepinfo(t_wm_NL, wm_NL, t_ini, t_fin);
    res_wm_LTI{k} = procesar_stepinfo(t_wm_LTI, wm_LTI, t_ini, t_fin);
    
    res_iq_NL{k}  = procesar_stepinfo(t_iq_NL, iq_NL, t_ini, t_fin);
    res_iq_LTI{k} = procesar_stepinfo(t_iq_LTI, iq_LTI, t_ini, t_fin);
end

%% 4. Tablas en Consola
imprimir_tabla('VELOCIDAD MECÁNICA \omega_m [rad/s]', nombres_tramos, res_wm_NL, res_wm_LTI);
fprintf('\n');
imprimir_tabla('CORRIENTE EN CUADRATURA i_{qs}^r [A]', nombres_tramos, res_iq_NL, res_iq_LTI);

%% 5. Gráficas Comparativas
figure('Name', 'Inciso 6.b: NL Desacoplado vs LTI Aumentado', 'Color', 'w', 'Position', [100 100 950 650]);

subplot(2,1,1);
plot(t_wm_NL, wm_NL, 'b-', 'LineWidth', 1.6, 'DisplayName', 'NL Desacoplado');
hold on;
plot(t_wm_LTI, wm_LTI, 'r--', 'LineWidth', 1.4, 'DisplayName', 'LTI Equivalente');
grid on;
xline(t_steps(1:5), 'k:', {'+Vqs*', '+Tl', '-Tl', 'Vqs*=0', 'Tl=0'}, ...
      'LabelVerticalAlignment', 'bottom', 'HandleVisibility', 'off');
ylabel('\omega_m [rad/s]', 'FontWeight', 'bold');
title('Respuesta Temporal de Velocidad y Corriente', 'FontSize', 11);
legend('Location', 'best');
xlim([0, t_final_sim]);

subplot(2,1,2);
plot(t_iq_NL, iq_NL, 'b-', 'LineWidth', 1.6, 'DisplayName', 'NL Desacoplado');
hold on;
plot(t_iq_LTI, iq_LTI, 'r--', 'LineWidth', 1.4, 'DisplayName', 'LTI Equivalente');
grid on;
xline(t_steps(1:5), 'k:', 'HandleVisibility', 'off');
xlabel('Tiempo [s]', 'FontWeight', 'bold');
ylabel('i_{qs}^r [A]', 'FontWeight', 'bold');
legend('Location', 'best');
xlim([0, t_final_sim]);


%% ========================================================================
%% FUNCIONES AUXILIARES
%% ========================================================================

function val = obtener_var_workspace(nombre)
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

function m = procesar_stepinfo(t, y, t_ini, t_fin)
    idx = (t >= t_ini) & (t < t_fin);
    t_seg = t(idx) - t_ini;
    y_seg = y(idx);
    
    if isempty(y_seg) || length(y_seg) < 5
        m = struct('y_ini', NaN, 'y_ss', NaN, 'tr', NaN, 'ts', NaN, 'Mp', NaN);
        return;
    end
    
    y_ini = y_seg(1);
    y_ss  = y_seg(end);
    delta = y_ss - y_ini;
    
    if abs(delta) < 1e-4
        m = struct('y_ini', y_ini, 'y_ss', y_ss, 'tr', 0, 'ts', 0, 'Mp', 0);
        return;
    end
    
    % Normalización canónica (0 a 1) para evaluar escalones positivos y negativos por igual
    y_norm = (y_seg - y_ini) / delta;
    
    S = stepinfo(y_norm, t_seg, 1, 0, ...
                 'RiseTimeLimits', [0.10, 0.90], ...
                 'SettlingTimeThreshold', 0.01);
             
    m.y_ini = y_ini;
    m.y_ss  = y_ss;
    m.tr    = S.RiseTime;
    m.ts    = S.SettlingTime;
    m.Mp    = S.Overshoot;
end

function imprimir_tabla(titulo, nombres, datos_NL, datos_LTI)
    fprintf('=======================================================================================================\n');
    fprintf(' %s\n', titulo);
    fprintf('=======================================================================================================\n');
    fprintf('%-22s | %-16s | %-16s | %-16s | %-16s\n', ...
            'Transitorio', 'y_ss (NL / LTI)', 'tr [s] (NL / LTI)', 'ts [s] (NL / LTI)', 'Mp [%] (NL / LTI)');
    fprintf('-------------------------------------------------------------------------------------------------------\n');
    
    for i = 1:length(nombres)
        nl = datos_NL{i};
        lti = datos_LTI{i};
        
        str_yss = sprintf('%6.2f / %-6.2f', nl.y_ss, lti.y_ss);
        str_tr  = sprintf('%6.4f / %-6.4f', nl.tr, lti.tr);
        str_ts  = sprintf('%6.4f / %-6.4f', nl.ts, lti.ts);
        str_mp  = sprintf('%5.1f%% / %-5.1f%%', nl.Mp, lti.Mp);
        
        fprintf('%-22s | %-16s | %-16s | %-16s | %-16s\n', ...
                nombres{i}, str_yss, str_tr, str_ts, str_mp);
    end
    fprintf('=======================================================================================================\n');
end

%% ========================================================================
%% GENERACIÓN DE TABLAS (Formato Informe LaTeX / Cátedra)
%% ========================================================================

% Tiempos de disparo de cada evento (t_event)
t_event = [0.1; 0.3; 0.5; 0.7; 0.9];

%% 1. TABLA: Velocidad Mecánica \omega_m (Modelo NL Desacoplado)
y0_wm_NL = cellfun(@(x) x.y_ini, res_wm_NL);
yf_wm_NL = cellfun(@(x) x.y_ss,  res_wm_NL);
tr_wm_NL = cellfun(@(x) x.tr,    res_wm_NL);
ts_wm_NL = cellfun(@(x) x.ts,    res_wm_NL);
mp_wm_NL = cellfun(@(x) x.Mp,    res_wm_NL);

Tabla_wm_NL = table(t_event, y0_wm_NL, yf_wm_NL, tr_wm_NL, ts_wm_NL, mp_wm_NL, ...
    'VariableNames', {'t_event_s', 'y0_rad_s', 'yf_rad_s', 'RiseTime_10_90_s', 'SettlingTime_1pct_s', 'Overshoot_pct'});

%% 2. TABLA: Velocidad Mecánica \omega_m (Modelo LTI Aumentado)
y0_wm_LTI = cellfun(@(x) x.y_ini, res_wm_LTI);
yf_wm_LTI = cellfun(@(x) x.y_ss,  res_wm_LTI);
tr_wm_LTI = cellfun(@(x) x.tr,    res_wm_LTI);
ts_wm_LTI = cellfun(@(x) x.ts,    res_wm_LTI);
mp_wm_LTI = cellfun(@(x) x.Mp,    res_wm_LTI);

Tabla_wm_LTI = table(t_event, y0_wm_LTI, yf_wm_LTI, tr_wm_LTI, ts_wm_LTI, mp_wm_LTI, ...
    'VariableNames', {'t_event_s', 'y0_rad_s', 'yf_rad_s', 'RiseTime_10_90_s', 'SettlingTime_1pct_s', 'Overshoot_pct'});

%% 3. TABLA: Corriente en Cuadratura i_qs^r (Modelo NL Desacoplado)
y0_iq_NL = cellfun(@(x) x.y_ini, res_iq_NL);
yf_iq_NL = cellfun(@(x) x.y_ss,  res_iq_NL);
tr_iq_NL = cellfun(@(x) x.tr,    res_iq_NL);
ts_iq_NL = cellfun(@(x) x.ts,    res_iq_NL);
mp_iq_NL = cellfun(@(x) x.Mp,    res_iq_NL);

Tabla_iq_NL = table(t_event, y0_iq_NL, yf_iq_NL, tr_iq_NL, ts_iq_NL, mp_iq_NL, ...
    'VariableNames', {'t_event_s', 'y0_A', 'yf_A', 'RiseTime_10_90_s', 'SettlingTime_1pct_s', 'Overshoot_pct'});

%% 4. TABLA: Corriente en Cuadratura i_qs^r (Modelo LTI Aumentado)
y0_iq_LTI = cellfun(@(x) x.y_ini, res_iq_LTI);
yf_iq_LTI = cellfun(@(x) x.y_ss,  res_iq_LTI);
tr_iq_LTI = cellfun(@(x) x.tr,    res_iq_LTI);
ts_iq_LTI = cellfun(@(x) x.ts,    res_iq_LTI);
mp_iq_LTI = cellfun(@(x) x.Mp,    res_iq_LTI);

Tabla_iq_LTI = table(t_event, y0_iq_LTI, yf_iq_LTI, tr_iq_LTI, ts_iq_LTI, mp_iq_LTI, ...
    'VariableNames', {'t_event_s', 'y0_A', 'yf_A', 'RiseTime_10_90_s', 'SettlingTime_1pct_s', 'Overshoot_pct'});

% Visualizar tablas en consola
disp('--- TABLA DINÁMICA: \omega_m (NL) ---');
disp(Tabla_wm_NL);

disp('--- TABLA DINÁMICA: \omega_m (LTI) ---');
disp(Tabla_wm_LTI);

disp('--- TABLA DINÁMICA: i_qs^r (NL) ---');
disp(Tabla_iq_NL);

disp('--- TABLA DINÁMICA: i_qs^r (LTI) ---');
disp(Tabla_iq_LTI);

%% 5. Exportar a código LaTeX listo para pegar en el informe
exportar_tabla_latex('Resultados dinámicos de la velocidad $\omega_m$ (Modelo NL Desacoplado)', ...
    '\text{rad/s}', t_event, y0_wm_NL, yf_wm_NL, tr_wm_NL, ts_wm_NL, mp_wm_NL);

exportar_tabla_latex('Resultados dinámicos de la velocidad $\omega_m$ (Modelo LTI Aumentado)', ...
    '\text{rad/s}', t_event, y0_wm_LTI, yf_wm_LTI, tr_wm_LTI, ts_wm_LTI, mp_wm_LTI);

exportar_tabla_latex('Resultados dinámicos de la corriente $i_{qs}^r$ (Modelo NL Desacoplado)', ...
    '\text{A}', t_event, y0_iq_NL, yf_iq_NL, tr_iq_NL, ts_iq_NL, mp_iq_NL);

exportar_tabla_latex('Resultados dinámicos de la corriente $i_{qs}^r$ (Modelo LTI Aumentado)', ...
    '\text{A}', t_event, y0_iq_LTI, yf_iq_LTI, tr_iq_LTI, ts_iq_LTI, mp_iq_LTI);


%% Función auxiliar para generar el bloque LaTeX
function exportar_tabla_latex(caption_str, unidad_str, t_ev, y0, yf, tr, ts, mp)
fprintf('\n%% Código LaTeX para: %s\n', caption_str);
fprintf('\\begin{table}[htbp]\n');
fprintf('\\centering\n');
fprintf('\\caption{%s}\n', caption_str);
fprintf('\\begin{tabular}{|c|c|c|c|c|c|}\n');
fprintf('\\hline\n');
fprintf('$t_{event}$ (s) & $y_0$ (%s) & $y_f$ (%s) & $\\text{RiseTime}_{10-90}$ (s) & $\\text{SettlingTime}_{\\pm 1\\%%}$ (s) & $\\text{Overshoot}$ (\\%%) \\\\\n', unidad_str, unidad_str);
fprintf('\\hline\n');
for i = 1:length(t_ev)
    fprintf('%.1f & %.3f & %.3f & %.4f & %.4f & %.2f \\\\\n', ...
        t_ev(i), y0(i), yf(i), tr(i), ts(i), mp(i));
    fprintf('\\hline\n');
end
fprintf('\\end{tabular}\n');
fprintf('\\end{table}\n\n');
end