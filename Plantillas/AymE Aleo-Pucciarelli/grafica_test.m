clc;
% Acceder a los datos desde la variable 'out' (Simulink.SimulationOutput)
velocidad = out.get('w_m');  % 'w_m' es el nombre de la señal para velocidad
corriente = out.get('i_q');  % 'i_q' es el nombre de la señal para corriente

% Obtener los datos de las señales
t = velocidad.Time;           % Tiempo asociado a las señales
velocidad_data = velocidad.Data;  % Datos de la velocidad
corriente_data = corriente.Data;  % Datos de la corriente

% Definir los tiempos de perturbación y el intervalo de análisis
perturbaciones = [0.1, 0.3, 0.5, 0.7, 0.9];
intervalo = 0.1;  % Intervalo de 0.1s después de cada perturbación
RT = [0.1, 0.9]; % Límites personalizados para el tiempo de subida

% Inicializar tablas vacías
resultados_wm = table; % Para velocidad
resultados_iq = table; % Para corriente

for i = 1:length(perturbaciones)
    t_inicio = perturbaciones(i);
    t_fin = t_inicio + intervalo;
    
    % Encontrar los índices dentro del intervalo deseado
    idx = find(t >= t_inicio & t <= t_fin);
    
    % Extraer los datos dentro del intervalo
    t_seg = t(idx) - t(idx(1)); % Restablecer tiempo relativo al inicio del intervalo
    velocidad_seg = velocidad_data(idx);
    corriente_seg = corriente_data(idx);
    
    % Calcular métricas con stepinfo usando RiseTimeLimits personalizado
    info_vel = stepinfo(velocidad_seg, t_seg, 'RiseTimeLimits', RT);
    info_corr = stepinfo(corriente_seg, t_seg, 'RiseTimeLimits', RT);
    
    % Calcular el valor de establecimiento (valor final del intervalo)
    valor_est_wm = velocidad_seg(end);
    valor_est_iq = corriente_seg(end);
    
    % Crear filas de tabla con métricas adicionales
    fila_wm = table(t_inicio, info_vel.RiseTime, info_vel.SettlingTime, info_vel.Overshoot, info_vel.Peak, valor_est_wm);
    fila_iq = table(t_inicio, info_corr.RiseTime, info_corr.SettlingTime, info_corr.Overshoot, info_corr.Peak, valor_est_iq);
    
    % Renombrar columnas
    fila_wm.Properties.VariableNames = {'Perturbacion', 'RiseTime', 'SettlingTime', 'Overshoot', 'Peak', 'ValorEstablecimiento'};
    fila_iq.Properties.VariableNames = {'Perturbacion', 'RiseTime', 'SettlingTime', 'Overshoot', 'Peak', 'ValorEstablecimiento'};

    % Agregar filas a las tablas correspondientes
    resultados_wm = [resultados_wm; fila_wm];
    resultados_iq = [resultados_iq; fila_iq];
end

% Mostrar resultados
disp('Resultados para Velocidad (w_m):');
disp(resultados_wm);

disp('Resultados para Corriente (i_q):');
disp(resultados_iq);



