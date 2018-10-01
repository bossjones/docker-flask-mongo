#! /usr/bin/env sh
set -e

# If there's a prestart.sh script in the /app directory, run it before starting
PRE_START_PATH=/app/prestart.sh
echo "Checking for script in $PRE_START_PATH"
if [ -f $PRE_START_PATH ] ; then
    echo "Running script $PRE_START_PATH"
    source $PRE_START_PATH
else
    echo "There is no script $PRE_START_PATH"
fi

# NOTE: Something like this will be useful
# echo '--------------------------------------------------------------------------------------------'
# echo "App Directory: $APP_DIR"
# ls "$APP_DIR"
# echo '--------------------------------------------------------------------------------------------'

# echo "WSGI_PATH=$WSGI_PATH"
# echo "WSGI_MODULE=$WSGI_MODULE"
# echo "UWSGI_LOG_FILE=$UWSGI_LOG_FILE"
# echo "UWSGI_NUM_PROCESSES=$UWSGI_NUM_PROCESSES"
# echo "UWSGI_NUM_THREADS=$UWSGI_NUM_THREADS"
# echo "UWSGI_MAX_REQUEST=$UWSGI_MAX_REQUEST"
# echo "UWSGI_HARAKIRI=$UWSGI_HARAKIRI"
# echo "UWSGI_HTTP_TIMEOUT=$UWSGI_HTTP_TIMEOUT"
# echo '-------------------------------------------------------

# Start Supervisor, with Nginx and uWSGI
exec /usr/bin/supervisord
