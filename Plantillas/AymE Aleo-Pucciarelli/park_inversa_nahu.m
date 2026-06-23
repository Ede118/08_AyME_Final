function [a, b, c] = park_inversa(q, d, zero, theta)
    % Transformación de Park Inversa
    % Entradas:
    %   d, q, z: Coordenadas en el marco rotatorio
    %   theta: Ángulo en radianes
    % Salidas:
    %   a, b, c: Valores trifásicos reconstruidos
    
    % Constantes
    alpha = 2 * pi / 3; % Desplazamiento angular entre fases
    
    % Cálculo de valores trifásicos
    a = d * cos(theta) - q * sin(theta) + zero;
    b = d * cos(theta - alpha) - q * sin(theta - alpha) + zero;
    c = d * cos(theta + alpha) - q * sin(theta + alpha) + zero;
end
