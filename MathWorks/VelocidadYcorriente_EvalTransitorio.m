%% Script de Posprocesamiento Completo - Inciso 6.b (PGI Control PMSM)
% Criterio settling time: +-1%, rise time: 10% a 90%
clc;
close all;
clearvars -except sim_omega_m_NL sim_Iq_NL sim_omega_m_LTI sim_iq_LTI out

%% 1. Extracción de variables
sim_omega_m_NL  = obtener_var_workspace('sim_omega_m_NL');
sim_Iq_NL       = obtener_var_workspace('sim_Iq_NL');
sim_omega_m_LTI = obtener_var_workspace('sim_omega_m_LTI');
sim_iq_LTI      = obtener_var_workspace('sim_iq_LTI');

t_wm_NL  = sim_omega_m_NL.Time;
wm_NL    = squeeze(sim_omega_m_NL.Data);

t_iq_NL  = sim_Iq_NL.Time;
iq_NL    = squeeze(sim_Iq_NL.Data);

t_wm_LTI = sim_omega_m_LTI.Time;
wm_LTI   = squeeze(sim_omega_m_LTI.Data);

t_iq_LTI = sim_iq_LTI.Time;
iq_LTI   = squeeze(sim_iq_LTI.Data);

%% 2. Definición única y centralizada de TODOS los eventos
t_final_sim = max([t_wm_NL(end), t_wm_LTI(end)]);

% Tiempos de disparo (ciclo positivo + ciclo negativo)
t_eventos = [0.1, 0.3, 0.5, 0.7, 0.9, 1.1, 1.3, 1.5, 1.7, 1.9];
% Filtrar por si tu simulación dura menos de 1.9 s
t_eventos = t_eventos(t_eventos < t_final_sim);

etiquetas_cortas = {'+Vqs*', '+Tl', '-Tl', 'Vqs*=0', 'Tl=0', ...
                    '-Vqs*', '+Tl', '-Tl', 'Vqs*=0', 'Tl=0'};
etiquetas_cortas = etiquetas_cortas(1:length(t_eventos));

nombres_tramos = arrayfun(@(k) sprintf('%d) %s (t=%.1fs)', k, etiquetas_cortas{k}, t_eventos(k)), ...
                          1:length(t_eventos), 'UniformOutput', false);

t_steps = [t_eventos, t_final_sim];
num_tramos = length(t_eventos);

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

%% 5. Gráficas Comparativas (con TODOS los eventos marcados)
figure('Name', 'Inciso 6.b: NL Desacoplado vs LTI Aumentado', 'Color', 'w', 'Position', [100 100 1000 680]);

subplot(2,1,1);
plot(t_wm_NL, wm_NL, 'b-', 'LineWidth', 1.6, 'DisplayName', 'NL Desacoplado');
hold on;
plot(t_wm_LTI, wm_LTI, 'r--', 'LineWidth', 1.4, 'DisplayName', 'LTI Equivalente');
grid on;
xline(t_eventos, 'k:', etiquetas_cortas, ...
      'LabelVerticalAlignment', 'bottom', 'LabelOrientation', 'aligned', 'HandleVisibility', 'off');
ylabel('\omega_m [rad/s]', 'FontWeight', 'bold');
title('Respuesta Temporal de Velocidad y Corriente', 'FontSize', 11);
legend('Location', 'best');
xlim([0, t_final_sim]);

subplot(2,1,2);
plot(t_iq_NL, iq_NL, 'b-', 'LineWidth', 1.6, 'DisplayName', 'NL Desacoplado');
hold on;
plot(t_iq_LTI, iq_LTI, 'r--', 'LineWidth', 1.4, 'DisplayName', 'LTI Equivalente');
grid on;
xline(t_eventos, 'k:', 'HandleVisibility', 'off');
xlabel('Tiempo [s]', 'FontWeight', 'bold');
ylabel('i_{qs}^r [A]', 'FontWeight', 'bold');
legend('Location', 'best');
xlim([0, t_final_sim]);

%% 6. Exportar a código LaTeX listo para pegar en el informe
t_event_col = t_eventos(:);

exportar_tabla_latex('Resultados dinámicos de la velocidad $\omega_m$ (Modelo NL Desacoplado)', ...
    '\text{rad/s}', t_event_col, res_wm_NL);

exportar_tabla_latex('Resultados dinámicos de la velocidad $\omega_m$ (Modelo LTI Aumentado)', ...
    '\text{rad/s}', t_event_col, res_wm_LTI);

exportar_tabla_latex('Resultados dinámicos de la corriente $i_{qs}^r$ (Modelo NL Desacoplado)', ...
    '\text{A}', t_event_col, res_iq_NL);

exportar_tabla_latex('Resultados dinámicos de la corriente $i_{qs}^r$ (Modelo LTI Aumentado)', ...
    '\text{A}', t_event_col, res_iq_LTI);


%% ========================================================================
%% FUNCIONES AUXILIARES
%% ========================================================================

function val = obtener_var_workspace(nombre)
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
        m = struct('y_ini', NaN, 'y_ss', NaN, 'y_pico', NaN, 'tr', NaN, 'ts', NaN, 'Mp', NaN);
        return;
    end
    
    y_ini = y_seg(1);
    y_ss  = y_seg(end);
    delta = y_ss - y_ini;
    
    [~, idx_max_dev] = max(abs(y_seg - y_ini));
    y_pico = y_seg(idx_max_dev);
    
    if abs(delta) < 1e-3
        m.y_ini  = y_ini;
        m.y_ss   = y_ss;
        m.y_pico = y_pico;
        m.tr     = t_seg(idx_max_dev);
        m.Mp     = 0;
        banda    = 0.01 * max(abs(y_seg - y_ini));
        idx_out  = find(abs(y_seg - y_ss) > banda, 1, 'last');
        if isempty(idx_out)
            m.ts = 0;
        else
            m.ts = t_seg(min(idx_out+1, end));
        end
        return;
    end
    
    y_norm = (y_seg - y_ini) / delta;
    S = stepinfo(y_norm, t_seg, 1, 0, ...
                 'RiseTimeLimits', [0.10, 0.90], ...
                 'SettlingTimeThreshold', 0.01);
             
    m.y_ini  = y_ini;
    m.y_ss   = y_ss;
    m.y_pico = y_pico;
    m.tr     = S.RiseTime;
    m.ts     = S.SettlingTime;
    
    if sign(y_pico - y_ini) ~= sign(delta)
        m.Mp = 0;
    else
        m.Mp = S.Overshoot;
    end
end

function imprimir_tabla(titulo, nombres, datos_NL, datos_LTI)
    fprintf('===================================================================================================================\n');
    fprintf(' %s\n', titulo);
    fprintf('===================================================================================================================\n');
    fprintf('%-22s | %-16s | %-16s | %-16s | %-16s | %-16s\n', ...
            'Transitorio', 'y_ss (NL / LTI)', 'y_pico (NL/LTI)', 'tr [s] (NL/LTI)', 'ts [s] (NL/LTI)', 'Mp [%] (NL/LTI)');
    fprintf('-------------------------------------------------------------------------------------------------------------------\n');
    
    for i = 1:length(nombres)
        nl = datos_NL{i};
        lti = datos_LTI{i};
        
        str_yss  = sprintf('%6.2f / %-6.2f', nl.y_ss, lti.y_ss);
        str_pico = sprintf('%6.2f / %-6.2f', nl.y_pico, lti.y_pico);
        str_tr   = sprintf('%6.4f / %-6.4f', nl.tr, lti.tr);
        str_ts   = sprintf('%6.4f / %-6.4f', nl.ts, lti.ts);
        str_mp   = sprintf('%5.1f%% / %-5.1f%%', nl.Mp, lti.Mp);
        
        fprintf('%-22s | %-16s | %-16s | %-16s | %-16s | %-16s\n', ...
                nombres{i}, str_yss, str_pico, str_tr, str_ts, str_mp);
    end
    fprintf('===================================================================================================================\n');
end

function exportar_tabla_latex(caption_str, unidad_str, t_ev, res_cell)
    y0   = cellfun(@(x) x.y_ini,  res_cell);
    yf   = cellfun(@(x) x.y_ss,   res_cell);
    yp   = cellfun(@(x) x.y_pico, res_cell);
    tr   = cellfun(@(x) x.tr,     res_cell);
    ts   = cellfun(@(x) x.ts,     res_cell);
    mp   = cellfun(@(x) x.Mp,     res_cell);

    fprintf('\n%% Código LaTeX para: %s\n', caption_str);
    fprintf('\\begin{table}[htbp]\n');
    fprintf('\\centering\n');
    fprintf('\\caption{%s}\n', caption_str);
    fprintf('\\begin{tabular}{|c|c|c|c|c|c|c|}\n');
    fprintf('\\hline\n');
    fprintf('$t_{event}$ (s) & $y_0$ (%s) & $y_f$ (%s) & $y_{pico}$ (%s) & $\\text{RiseTime}_{10-90}$ (s) & $\\text{SettlingTime}_{\\pm 1\\%%}$ (s) & $\\text{Overshoot}$ (\\%%) \\\\\n', ...
            unidad_str, unidad_str, unidad_str);
    fprintf('\\hline\n');
    for i = 1:length(t_ev)
        fprintf('%.1f & %.3f & %.3f & %.3f & %.4f & %.4f & %.2f \\\\\n', ...
            t_ev(i), y0(i), yf(i), yp(i), tr(i), ts(i), mp(i));
        fprintf('\\hline\n');
    end
    fprintf('\\end{tabular}\n');
    fprintf('\\end{table}\n\n');
end