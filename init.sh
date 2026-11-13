#!/bin/sh
set -e

# Tomar el nombre del proyecto dinámicamente
NODE_NAME="${PROJECT_NAME}"
APP_PORT=${PORT:-8000}
WORKERS=${GUNICORN_WORKERS:-3}
SUPERUSER_EMAIL=${DJANGO_SUPERUSER_EMAIL:-"support@smartquail.io"}

echo "=== SmartQuail Core: Iniciando contenedor para el proyecto $NODE_NAME con Gunicorn ==="

# 1. Aplicar migraciones
echo "Aplicando migraciones a la base de datos..."
python3 manage.py migrate --settings=$NODE_NAME.settings.prod --noinput

# 2. Crear el superusuario si no existe
echo "Verificando superusuario..."
python3 manage.py createsuperuser \
    --username="${DJANGO_SUPERUSER_USERNAME:-admin}" \
    --email="$SUPERUSER_EMAIL" \
    --noinput 2>/dev/null || echo "El superusuario ya existe o fue omitido."

# 3. Recolectar archivos estáticos
echo "Recolectando archivos estáticos..."
python3 manage.py collectstatic --noinput --settings=$NODE_NAME.settings.prod

# 4. Iniciar Gunicorn usando la variable dinámica del proyecto
echo "Iniciando servidor Gunicorn en el puerto $APP_PORT..."
# Exportar la variable de entorno que Django y Gunicorn leen internamente
export DJANGO_SETTINGS_MODULE="${PROJECT_NAME}.settings.prod"

# Ejecutar Gunicorn correctamente sin el argumento --settings
exec gunicorn ${PROJECT_NAME}.wsgi:application \
    --bind 0.0.0.0:${APP_PORT:-8000} \
    --workers ${WORKERS:-3} \
    --timeout 120 \
    --access-logfile '-' \
    --error-logfile '-'