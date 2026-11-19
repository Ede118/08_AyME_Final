%% Perfil S-Curve a partir de un trapezoidal (filtrado FIR)


%% 1. Perfil trapezoidal original (consigna)
t_trap = [0, 2, 7, 9, 14, 16];      % [s]
p_trap = [0, 0, 2*pi, 2*pi, 0, 0];  % [rad]

%% 2. Muestreo fino del perfil original (interpolación lineal)
Ts = 0.001;                          % periodo de muestreo [s] (ajusta según tu lazo)
t = 0:Ts:t_trap(end);
p_orig = interp1(t_trap, p_trap, t, 'linear');

%% 3. Cálculo de velocidad y aceleración del original
v_orig = gradient(p_orig, Ts);
a_orig = gradient(v_orig, Ts);

%% 4. Filtro FIR (media móvil) para suavizar -> S-Curve
% El orden N del filtro se elige según el jerk máximo admisible:
%   N = a_max / (j_max * Ts) - 1
% Con a_max ~ pi rad/s^2 (aprox. del trapezoidal) y j_max deseado.
a_max_trap = max(abs(a_orig));       % aceleración máx del trapezoidal
j_max_deseado = 700;                    % [rad/s^3] AJUSTA este valor
N = round(a_max_trap / (j_max_deseado * Ts) - 1);
N = max(N, 2);                        % al menos orden 2
if mod(N,2)==0, N = N+1; end          % forzar impar para simetría (opcional)

% Filtro de media móvil de N puntos (coeficientes 1/N)
b = ones(1,N)/N;
a = 1;

% Aplicar filtro a la posición (filtfilt evita desfase)
p_s = filtfilt(b, a, p_orig);

%% 5. Derivadas del perfil suavizado
v_s = gradient(p_s, Ts);
a_s = gradient(v_s, Ts);
j_s = gradient(a_s, Ts);

%% 6. Gráficas comparativas


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
%   - t_lut  -> Breakpoints 1
%   - p_lut  -> Table data
t_lut = t(:);        % vector de tiempo (breakpoints)
p_lut = p_s(:);      % posición suavizada (table data)

% (Opcional) vectores extra para feedforward en el lazo del motor
v_lut = v_s(:);      % velocidad suavizada
a_lut = a_s(:);      % aceleración suavizada

% Enviar al workspace base para que Simulink los vea
assignin('base','t_lut',t_lut);
assignin('base','p_lut',p_lut);
assignin('base','v_lut',v_lut);
assignin('base','a_lut',a_lut);

% (Opcional) guardar en .mat para reutilizar sin recalcular
save('perfil_lut.mat','t_lut','p_lut','v_lut','a_lut');

% Resumen en consola
fprintf('\n✅ Vectores exportados al workspace base:\n');
fprintf('   t_lut : %d puntos, de %.3f a %.3f s\n', numel(t_lut), t_lut(1), t_lut(end));
fprintf('   p_lut : %d puntos, de %.3f a %.3f rad\n', numel(p_lut), p_lut(1), p_lut(end));
fprintf('   v_lut : %d puntos, |v|max = %.3f rad/s\n', numel(v_lut), max(abs(v_lut)));
fprintf('   a_lut : %d puntos, |a|max = %.3f rad/s^2\n', numel(a_lut), max(abs(a_lut)));
fprintf('   Archivo guardado: perfil_lut.mat\n');
hold on
plot(t_lut,p_lut)
plot(t_lut,p_orig)
p_lut
