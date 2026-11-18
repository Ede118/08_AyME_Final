function actualizar_parametros_controlador_digital(modelo) %#ok<INUSD>
% Callback de inicializacion: reutiliza los parametros vigentes del workspace.
p = parametros_controlador_digital();
assignin('base','p_control',p);
end
