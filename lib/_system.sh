#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Ahora, vamos a crear el usuario para la instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Verificar si el usuario ya existe
  if id "deploy" &>/dev/null; then
    printf "${YELLOW} ⚠️  El usuario 'deploy' ya existe. Verificando configuración...${GRAY_LIGHT}\n"
    
    # Verificar y asegurar que esté en el grupo sudo
    output=$(sudo bash -c "
    set -e
    if ! groups deploy | grep -q sudo; then
      usermod -aG sudo deploy
      echo 'Usuario añadido al grupo sudo'
    else
      echo 'Usuario ya está en el grupo sudo'
    fi
    
    # Asegurar que el usuario tenga shell bash
    usermod -s /bin/bash deploy
    
    # Actualizar la contraseña usando chpasswd
    echo 'deploy:${mysql_root_password}' | chpasswd
    " 2>&1)
    
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
      printf "${GREEN} ✅ Usuario 'deploy' configurado correctamente.${GRAY_LIGHT}\n\n"
    else
      printf "${RED} ❌ Error al configurar el usuario 'deploy'.${GRAY_LIGHT}\n"
      echo "$output" | sed 's/^/   /'
      exit 1
    fi
  else
    # Crear el usuario si no existe
    printf "${WHITE} 💻 Creando usuario 'deploy'...${GRAY_LIGHT}\n"
    
    # Crear usuario sin contraseña primero, luego establecerla
    output=$(sudo bash -c "
    set -e
    # Crear usuario sin contraseña
    useradd -m -s /bin/bash -G sudo deploy
    
    # Establecer contraseña usando chpasswd
    echo 'deploy:${mysql_root_password}' | chpasswd
    
    echo 'Usuario creado exitosamente'
    " 2>&1)
    
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
      printf "${GREEN} ✅ Usuario 'deploy' creado exitosamente.${GRAY_LIGHT}\n\n"
    else
      printf "${RED} ❌ Error al crear el usuario 'deploy'.${GRAY_LIGHT}\n"
      echo "$output" | sed 's/^/   /'
      exit 1
    fi
  fi

  sleep 2
}

#######################################
# clones repostories using git
# Arguments:
#   None
#######################################
system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Descargando el código...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Verificar si el directorio ya existe
  if sudo su - deploy -c "test -d /home/deploy/${instancia_add}"; then
    printf "${RED} ⚠️  El directorio /home/deploy/${instancia_add} ya existe!${GRAY_LIGHT}\n"
    printf "${WHITE} 💻 ¿Desea eliminar y clonar nuevamente? (s/n):${GRAY_LIGHT}"
    read -p "> " respuesta
    if [[ "$resposta" == "s" || "$resposta" == "S" ]]; then
      sudo su - deploy <<EOF
      rm -rf /home/deploy/${instancia_add}
EOF
    else
      printf "${RED} ❌ Operación cancelada.${GRAY_LIGHT}\n"
      exit 1
    fi
  fi

  # Verificar si git está instalado
  if ! command -v git &> /dev/null; then
    printf "${RED} ❌ Git no está instalado!${GRAY_LIGHT}\n"
    exit 1
  fi

  # Ejecutar git clone con manejo de errores
  printf "${WHITE} 💻 Clonando repositorio...${GRAY_LIGHT}\n"
  
  # Capturar salida y código de error
  output=$(sudo su - deploy <<EOF 2>&1
  git clone ${link_git} /home/deploy/${instancia_add}/
EOF
  )
  exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    printf "${GREEN} ✅ Repositorio clonado con éxito!${GRAY_LIGHT}\n\n"
  else
    printf "${RED} ❌ Error al clonar el repositorio!${GRAY_LIGHT}\n"
    printf "${RED} Mensaje de error:${GRAY_LIGHT}\n"
    echo "$output" | sed 's/^/   /'
    printf "\n${YELLOW} 💡 Verifique que:${GRAY_LIGHT}\n"
    printf "${YELLOW}    - El enlace del repositorio sea correcto${GRAY_LIGHT}\n"
    printf "${YELLOW}    - Si el repositorio es privado, necesita usar token en la URL${GRAY_LIGHT}\n"
    printf "${YELLOW}    - Formato correcto para privado: https://token@github.com/usuario/repo.git${GRAY_LIGHT}\n"
    printf "${YELLOW}    - O use: https://usuario:token@github.com/usuario/repo.git${GRAY_LIGHT}\n"
    exit 1
  fi

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos a actualizar el sistema...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt -y update
  sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
EOF

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos a eliminar la instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container rm redis-${empresa_delete} --force
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  
  sleep 2

  sudo su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

sudo su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-frontend ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Eliminación de la Instancia/Empresa ${empresa_delete} realizada con éxito...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

}

#######################################
# bloquear system
# Arguments:
#   None
#######################################
configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos a bloquear la instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 stop ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueo de la Instancia/Empresa ${empresa_bloquear} realizado con éxito...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}


#######################################
# desbloquear system
# Arguments:
#   None
#######################################
configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos a desbloquear la instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 start ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueo de la Instancia/Empresa ${empresa_desbloquear} realizado con éxito...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# alter dominio system
# Arguments:
#   None
#######################################
configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Vamos a modificar los dominios de la instancia...${GRAY_LIGHT}"
  printf "\n\n"

sleep 2

  sudo su - root <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-backend
EOF

sleep 2

  sudo su - deploy <<EOF
  cd && cd /home/deploy/${empresa_dominio}/frontend
  sed -i "1c\REACT_APP_BACKEND_URL=https://${alter_backend_url}" .env
  cd && cd /home/deploy/${empresa_dominio}/backend
  sed -i "2c\BACKEND_URL=https://${alter_backend_url}" .env
  sed -i "3c\FRONTEND_URL=https://${alter_frontend_url}" .env 
EOF

sleep 2
   
   backend_hostname=$(echo "${alter_backend_url/https:\/\/}")

 sudo su - root <<EOF
  cat > /etc/nginx/sites-available/${empresa_dominio}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-backend /etc/nginx/sites-enabled
EOF

sleep 2

frontend_hostname=$(echo "${alter_frontend_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${empresa_dominio}-frontend << 'END'
server {
  server_name $frontend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -s /etc/nginx/sites-available/${empresa_dominio}-frontend /etc/nginx/sites-enabled
EOF

 sleep 2

 sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Modificación de dominio de la Instancia/Empresa ${empresa_dominio} realizada con éxito...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Node.js 20.19.5...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Instalar dependencias necesarias
  printf "${WHITE} 💻 Instalando dependencias...${GRAY_LIGHT}\n"
  sudo apt-get update -y
  sudo apt-get install -y curl build-essential
  
  # Instalar nvm (Node Version Manager) para root de forma no interactiva
  printf "${WHITE} 💻 Descargando e instalando nvm...${GRAY_LIGHT}\n"
  sudo bash -c 'export NVM_DIR="/root/.nvm" && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | PROFILE=/dev/null bash'
  
  # Esperar a que se complete la instalación de nvm
  sleep 2
  
  # Instalar Node.js 20.19.5 usando nvm
  printf "${WHITE} 💻 Instalando Node.js 20.19.5...${GRAY_LIGHT}\n"
  sudo bash -c '
    export NVM_DIR="/root/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install 20.19.5
    nvm use 20.19.5
    nvm alias default 20.19.5
  '
  
  # Esperar a que se complete la instalación
  sleep 3
  
  # Verificar que Node.js se instaló correctamente
  if [ -d "/root/.nvm/versions/node/v20.19.5" ]; then
    # Hacer que Node.js esté disponible globalmente para todos los usuarios
    printf "${WHITE} 💻 Configurando enlaces simbólicos...${GRAY_LIGHT}\n"
    sudo ln -sf /root/.nvm/versions/node/v20.19.5/bin/node /usr/local/bin/node
    sudo ln -sf /root/.nvm/versions/node/v20.19.5/bin/npm /usr/local/bin/npm
    sudo ln -sf /root/.nvm/versions/node/v20.19.5/bin/npx /usr/local/bin/npx
    
    # Actualizar npm a la última versión
    printf "${WHITE} 💻 Actualizando npm...${GRAY_LIGHT}\n"
    sudo bash -c '
      export NVM_DIR="/root/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      npm install -g npm@latest
    '
    
    printf "${GREEN} ✅ Node.js 20.19.5 instalado correctamente.${GRAY_LIGHT}\n\n"
  else
    printf "${RED} ❌ Error: Node.js no se instaló correctamente.${GRAY_LIGHT}\n"
    exit 1
  fi
  
  sleep 2
  
  # Instalar PostgreSQL
  printf "${WHITE} 💻 Instalando PostgreSQL...${GRAY_LIGHT}\n"
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update -y && sudo apt-get -y install postgresql
  
  sleep 2
  
  # Configurar zona horaria
  sudo timedatectl set-timezone Europe/Madrid

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y apt-transport-https \
                 ca-certificates curl \
                 software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

  apt install -y docker-ce
EOF

  sleep 2
}

#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteer_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependencias de Puppeteer...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get install -y libxshmfence-dev \
                      libgbm-dev \
                      wget \
                      unzip \
                      fontconfig \
                      locales \
                      gconf-service \
                      libasound2 \
                      libatk1.0-0 \
                      libc6 \
                      libcairo2 \
                      libcups2 \
                      libdbus-1-3 \
                      libexpat1 \
                      libfontconfig1 \
                      libgcc1 \
                      libgconf-2-4 \
                      libgdk-pixbuf2.0-0 \
                      libglib2.0-0 \
                      libgtk-3-0 \
                      libnspr4 \
                      libpango-1.0-0 \
                      libpangocairo-1.0-0 \
                      libstdc++6 \
                      libx11-6 \
                      libx11-xcb1 \
                      libxcb1 \
                      libxcomposite1 \
                      libxcursor1 \
                      libxdamage1 \
                      libxext6 \
                      libxfixes3 \
                      libxi6 \
                      libxrandr2 \
                      libxrender1 \
                      libxss1 \
                      libxtst6 \
                      ca-certificates \
                      fonts-liberation \
                      libappindicator1 \
                      libnss3 \
                      lsb-release \
                      xdg-utils
EOF

  sleep 2
}

#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando PM2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  npm install -g pm2

EOF

  sleep 2
}

#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Snapd...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get remove certbot
  snap install --classic certbot
  ln -s /snap/bin/certbot /usr/bin/certbot
EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y nginx
  rm /etc/nginx/sites-enabled/default
EOF

  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 Reiniciando Nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando Nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF

cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END

EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando Certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  sudo su - root <<EOF
  certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain

EOF

  sleep 2
}
