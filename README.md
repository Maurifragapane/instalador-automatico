<h1 align="center">Un sistema de tickets completísimo basado en mensajes de WhatsApp.</h1> 


## Vamos a instalar?

ACTUALIZAMOS VPS
```bash
sudo apt update && sudo apt upgrade
```

DESCARGAR EL INSTALADOR E INICIAR LA PRIMERA INSTALACIÓN (UTILIZAR SÓLO PARA LA PRIMERA INSTALACIÓN):

```bash
sudo apt install -y git && git clone https://github.com/canalvemfazer/instalador install && sudo chmod -R 777 ./install && cd ./install && sudo ./install_primaria
```

ACCEDER AL DIRECTORIO DE INSTALADOR E INICIAR INSTALACIONES ADICIONALES (USE ESTE COMANDO PARA UNA SEGUNDA O MÁS INSTALACIÓN:
```bash
cd && cd ./install && sudo ./install_instancia
```


## Para la instalación necesita:

Un VPS Ubuntu 20.04 (Configuración recomendada: 3 VCPU's + 4 GB de RAM)

Subdominio para Frontend - Tu frontend

Subdominio para API: su backend

Correo electrónico válido para la certificación SSL
    



