#!/bin/bash
#
# functions for setting up app backend
#######################################
# creates REDIS db using docker
# Arguments:
#   None
#######################################
backend_redis_create() {
  print_banner
  printf "${WHITE} 💻 Creando Redis y Base de Datos Postgres...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  usermod -aG docker deploy
  docker run --name redis-${instancia_add} -p ${redis_port}:6379 --restart always --detach redis redis-server --requirepass ${mysql_root_password}
  
  sleep 2
  sudo su - postgres
  createdb ${instancia_add};
  psql
  CREATE USER ${instancia_add} SUPERUSER INHERIT CREATEDB CREATEROLE;
  ALTER USER ${instancia_add} PASSWORD '${mysql_root_password}';
  \q
  exit
EOF

sleep 2

}

#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variables de entorno (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url

sudo su - deploy << EOF
  cat <<[-]EOF > /home/deploy/${instancia_add}/backend/.env
NODE_ENV=
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=${backend_port}

DB_HOST=localhost
DB_DIALECT=postgres
DB_USER=${instancia_add}
DB_PASS=${mysql_root_password}
DB_NAME=${instancia_add}
DB_PORT=5432

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}

REDIS_URI=redis://:${mysql_root_password}@127.0.0.1:${redis_port}
REDIS_OPT_LIMITER_MAX=1
REGIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=${max_user}
CONNECTIONS_LIMIT=${max_whats}
CLOSED_SEND_BY_ME=true



[-]EOF
EOF

  sleep 2
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependencias del backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Verificar que npm esté disponible y encontrar su ruta
  if [ -f "/root/.nvm/versions/node/v20.19.5/bin/npm" ]; then
    npm_cmd="/root/.nvm/versions/node/v20.19.5/bin/npm"
  elif [ -f "/usr/local/bin/npm" ] && [ -x "/usr/local/bin/npm" ]; then
    npm_cmd="/usr/local/bin/npm"
  elif [ -f "/usr/bin/npm" ] && [ -x "/usr/bin/npm" ]; then
    npm_cmd="/usr/bin/npm"
  elif command -v npm &> /dev/null; then
    npm_cmd="npm"
  else
    printf "${RED} ❌ npm no se encuentra instalado!${GRAY_LIGHT}\n"
    printf "${RED} Por favor, ejecute primero la instalación de Node.js.${GRAY_LIGHT}\n"
    exit 1
  fi

  # Intentar primero con npm install normal
  printf "${WHITE} 💻 Intentando instalación estándar...${GRAY_LIGHT}\n"
  
  output=$(sudo -u deploy bash -c "
    set -e
    export PATH=\"/usr/local/bin:/usr/bin:/root/.nvm/versions/node/v20.19.5/bin:\$PATH\"
    cd /home/deploy/${instancia_add}/backend
    ${npm_cmd} install
  " 2>&1)
  
  exit_code=$?
  
  if [ $exit_code -eq 0 ]; then
    printf "${GREEN} ✅ Dependencias instaladas correctamente.${GRAY_LIGHT}\n\n"
  else
    printf "${YELLOW} ⚠️  La instalación estándar falló. Intentando con --legacy-peer-deps...${GRAY_LIGHT}\n"
    
    output=$(sudo -u deploy bash -c "
      set -e
      export PATH=\"/usr/local/bin:/usr/bin:/root/.nvm/versions/node/v20.19.5/bin:\$PATH\"
      cd /home/deploy/${instancia_add}/backend
      ${npm_cmd} install --legacy-peer-deps
    " 2>&1)
    
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
      printf "${GREEN} ✅ Dependencias instaladas con --legacy-peer-deps.${GRAY_LIGHT}\n\n"
    else
      printf "${RED} ❌ Error al instalar dependencias del backend.${GRAY_LIGHT}\n"
      printf "${RED} Mensaje de error:${GRAY_LIGHT}\n"
      echo "$output" | sed 's/^/   /'
      exit 1
    fi
  fi

  sleep 2
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando el código del backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Encontrar npm
  if [ -f "/root/.nvm/versions/node/v20.19.5/bin/npm" ]; then
    npm_cmd="/root/.nvm/versions/node/v20.19.5/bin/npm"
  elif [ -f "/usr/local/bin/npm" ] && [ -x "/usr/local/bin/npm" ]; then
    npm_cmd="/usr/local/bin/npm"
  elif [ -f "/usr/bin/npm" ] && [ -x "/usr/bin/npm" ]; then
    npm_cmd="/usr/bin/npm"
  else
    npm_cmd="npm"
  fi

  sudo -u deploy bash -c "
    export PATH=\"/usr/local/bin:/usr/bin:/root/.nvm/versions/node/v20.19.5/bin:\$PATH\"
    cd /home/deploy/${instancia_add}/backend
    ${npm_cmd} run build
  "

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_update() {
  print_banner
  printf "${WHITE} 💻 Actualizando el backend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${empresa_atualizar}
  pm2 stop ${empresa_atualizar}-backend
  git pull
  cd /home/deploy/${empresa_atualizar}/backend
  
  # Intentar instalación estándar primero
  if ! npm install; then
    echo "Instalación estándar falló, intentando con --legacy-peer-deps..."
    npm install --legacy-peer-deps || exit 1
  fi
  
  npm update -f
  npm install @types/fs-extra --legacy-peer-deps || npm install @types/fs-extra
  rm -rf dist 
  npm run build
  npx sequelize db:migrate
  npx sequelize db:seed
  pm2 start ${empresa_atualizar}-backend
  pm2 save 
EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Ejecutando db:migrate...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Encontrar npx
  if [ -f "/root/.nvm/versions/node/v20.19.5/bin/npx" ]; then
    npx_cmd="/root/.nvm/versions/node/v20.19.5/bin/npx"
  elif [ -f "/usr/local/bin/npx" ] && [ -x "/usr/local/bin/npx" ]; then
    npx_cmd="/usr/local/bin/npx"
  elif [ -f "/usr/bin/npx" ] && [ -x "/usr/bin/npx" ]; then
    npx_cmd="/usr/bin/npx"
  else
    npx_cmd="npx"
  fi

  sudo -u deploy bash -c "
    export PATH=\"/usr/local/bin:/usr/bin:/root/.nvm/versions/node/v20.19.5/bin:\$PATH\"
    cd /home/deploy/${instancia_add}/backend
    ${npx_cmd} sequelize db:migrate
  "

  sleep 2
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Ejecutando db:seed...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Encontrar npx
  if [ -f "/root/.nvm/versions/node/v20.19.5/bin/npx" ]; then
    npx_cmd="/root/.nvm/versions/node/v20.19.5/bin/npx"
  elif [ -f "/usr/local/bin/npx" ] && [ -x "/usr/local/bin/npx" ]; then
    npx_cmd="/usr/local/bin/npx"
  elif [ -f "/usr/bin/npx" ] && [ -x "/usr/bin/npx" ]; then
    npx_cmd="/usr/bin/npx"
  else
    npx_cmd="npx"
  fi

  sudo -u deploy bash -c "
    export PATH=\"/usr/local/bin:/usr/bin:/root/.nvm/versions/node/v20.19.5/bin:\$PATH\"
    cd /home/deploy/${instancia_add}/backend
    ${npx_cmd} sequelize db:seed:all
  "

  sleep 2
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando PM2 (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - deploy <<EOF
  cd /home/deploy/${instancia_add}/backend
  pm2 start dist/server.js --name ${instancia_add}-backend
EOF

  sleep 2
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando Nginx (backend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${instancia_add}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${backend_port};
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
ln -s /etc/nginx/sites-available/${instancia_add}-backend /etc/nginx/sites-enabled
EOF

  sleep 2
}
