#!/bin/bash

# Pequeno delay para garantir que a sessão gráfica já subiu completamente
sleep 1

# Reinicia o serviço x11vnc do usuário atual
systemctl --user restart x11vnc.service
