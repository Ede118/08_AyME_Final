function [t, v] = perfil_trapezoidal(t_total, t_acel, v_max, dt)
    % t_total: Tiempo total del perfil
    % t_acel: Tiempo de aceleración y desaceleración
    % v_max: Velocidad máxima
    % dt: Paso de tiempo

    t = 0:dt:t_total;  % Vector de tiempo
    v = zeros(size(t));  % Inicialización del perfil de velocidad

    % Definir las fases
    for i = 1:length(t)
        if t(i) < t_acel  % Fase de aceleración
            v(i) = (v_max / t_acel) * t(i);
        elseif t(i) < (t_total - t_acel)  % Fase de velocidad constante
            v(i) = v_max;
        else  % Fase de desaceleración
            v(i) = v_max - (v_max / t_acel) * (t(i) - (t_total - t_acel));
        end
    end

    % Graficar el perfil
    figure;
    plot(t, v, 'r', 'LineWidth', 2);
    xlabel('Tiempo (s)');
    ylabel('Velocidad');
    title('Perfil de velocidad trapezoidal');
    grid on;
end