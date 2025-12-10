<h1 align="center">Instalador automático para Whaticket y similares</h1> 


## Primera Instalación

ACTUALIZAMOS VPS
```bash
sudo apt update && sudo apt upgrade
```

DESCARGAR EL INSTALADOR E INICIAR LA PRIMERA INSTALACIÓN (UTILIZAR SÓLO PARA LA PRIMERA INSTALACIÓN):

```bash
sudo apt install -y git && git clone https://github.com/Maurifragapane/instalador-automatico install && sudo chmod -R 777 ./install && cd ./install && sudo ./install.sh
```

ACCEDER AL DIRECTORIO DEL INSTALADOR E INICIAR INSTALACIONES ADICIONALES (USE ESTE COMANDO PARA UNA SEGUNDA O MÁS INSTALACIÓNES):
```bash
cd && cd ./install && sudo ./add-instance.sh
```


## Para la instalación necesita:

Un VPS Ubuntu 20.04 (Configuración recomendada: 3 VCPU's + 4 GB de RAM)

Subdominio para Frontend : Frontend

Subdominio para API: Backend

Correo electrónico válido para la certificación SSL