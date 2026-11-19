%% Perfil S-Curve a partir de un trapezoidal (filtrado FIR)


%% 1. Perfil trapezoidal original (consigna)
t_trap = [0, 2, 7, 9, 14, 16];      % [s]
p_trap = [0, 0, 2*pi, 2*pi, 0, 0];  % [rad]

%% 2. Muestreo fino del perfil original (interpolación lineal)
Ts_perfil = 0.001;                   % resolucion temporal del perfil; no modifica Ts del controlador
t = 0:Ts_perfil:t_trap(end);
p_orig = interp1(t_trap, p_trap, t, 'linear');

%% 3. Cálculo de velocidad y aceleración del original
v_orig = gradient(p_orig, Ts_perfil);
a_orig = gradient(v_orig, Ts_perfil);

%% 4. Filtro FIR (media móvil) para suavizar -> S-Curve
% El orden N del filtro se elige según el jerk máximo admisible:
%   N = a_max / (j_max * Ts_perfil) - 1
% Con a_max ~ pi rad/s^2 (aprox. del trapezoidal) y j_max deseado.
a_max_trap = max(abs(a_orig));       % aceleración máx del trapezoidal
j_max_deseado = 5000;                    % [rad/s^3] AJUSTA este valor
N = round(a_max_trap / (j_max_deseado * Ts_perfil) - 1);
N = max(N, 2);                        % al menos orden 2
if mod(N,2)==0, N = N+1; end          % forzar impar para simetría (opcional)

% Filtro de media móvil de N puntos (coeficientes 1/N)
b = ones(1,N)/N;
a = 1;

% Aplicar filtro a la posición (filtfilt evita desfase)
p_s = filtfilt(b, a, p_orig);

%% 5. Derivadas del perfil suavizado
v_s = gradient(p_s, Ts_perfil);
a_s = gradient(v_s, Ts_perfil);
j_s = gradient(a_s, Ts_perfil);

%% 6. Gráficas comparativas


figure('Name','Consigna de movimiento','Color','w');
plot(t, p_orig, 'b--', 'LineWidth',1.2); hold on;
plot(t, p_s, 'r-', 'LineWidth',1.5);
grid on; ylabel('Posición [rad]');
legend('Trapezoidal','S-Curve (FIR)','Location','best');
title('Posición');

figure('Name','Consigna de movimiento','Color','w');
plot(t, p_orig, 'b--', 'LineWidth',1.2); hold on;
plot(t, p_s, 'r-', 'LineWidth',1.5);
grid on; ylabel('Posición [rad]');
legend('Trapezoidal','S-Curve (FIR)','Location','best');
title('Posición');

figure('Name','velocidad','Color','w');
plot(t, v_orig, 'b--', 'LineWidth',1.2); hold on;
plot(t, v_s, 'r-', 'LineWidth',1.5);
grid on; ylabel('Velocidad [rad/s]');
legend('Trapezoidal','S-Curve (FIR)','Location','best');
title('Velocidad');

figure('Name','Aceleracíon','Color','w');
plot(t, a_orig, 'b--', 'LineWidth',1.2); hold on;
plot(t, a_s, 'r-', 'LineWidth',1.5);
grid on; xlabel('Tiempo [s]'); ylabel('Aceleración [rad/s^2]');
legend('Trapezoidal','S-Curve (FIR)','Location','best');
title('Aceleración');

%% 7. Verificación del jerk
figure('Name','Jerk','Color','w');
plot(t, j_s, 'k-', 'LineWidth',1.2); grid on;
xlabel('Tiempo [s]'); ylabel('Jerk [rad/s^3]');
title(sprintf('Jerk del perfil suavizado (|j|max = %.2f rad/s^3)', max(abs(j_s))));

%% 8. (Opcional) Guardar el perfil suavizado para usarlo en el lazo
% perfil.t = t; perfil.p = p_s; perfil.v = v_s; perfil.a = a_s;
% save('perfil_scurve.mat','-struct','perfil');

%% ===== EXPORTAR VECTORES PARA LOOKUP TABLE DE SIMULINK =====
% Vectores para el bloque 1-D Lookup Table:
%   Posicion: Breakpoints 1 = consigna_t; Table data = consigna_p.
%   Velocidad: Breakpoints 1 = consigna_t; Table data = consigna_v.
%   El Clock entra por el puerto de cada tabla (entrada en segundos).
consigna_t = t(:);        % vector de tiempo (breakpoints)
consigna_p = p_s(:);      % posición suavizada (table data)

% (Opcional) vectores extra para feedforward en el lazo del motor
consigna_v = v_s(:);      % velocidad suavizada
a_lut = a_s(:);      % aceleración suavizada

% Enviar al workspace base para que Simulink los vea
assignin('base','consigna_t',consigna_t);
assignin('base','consigna_p',consigna_p);
assignin('base','consigna_v',consigna_v);
assignin('base','a_lut',a_lut);

% (Opcional) guardar en .mat para reutilizar sin recalcular
save('perfil_lut.mat','consigna_t','consigna_p','consigna_v','a_lut');

% Resumen en consola
fprintf('\n✅ Vectores exportados al workspace base:\n');
fprintf('   t_lut : %d puntos, de %.3f a %.3f s\n', numel(consigna_t), consigna_t(1), consigna_t(end));
fprintf('   p_lut : %d puntos, de %.3f a %.3f rad\n', numel(consigna_p), consigna_p(1), consigna_p(end));
fprintf('   v_lut : %d puntos, |v|max = %.3f rad/s\n', numel(consigna_v), max(abs(consigna_v)));
fprintf('   a_lut : %d puntos, |a|max = %.3f rad/s^2\n', numel(a_lut), max(abs(a_lut)));
fprintf('   Archivo guardado: perfil_lut.mat\n');
hold on
plot(consigna_t,consigna_p)
plot(consigna_t,p_orig)
consigna_p;
