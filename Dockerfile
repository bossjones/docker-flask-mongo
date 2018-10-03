FROM tiangolo/uwsgi-nginx-flask:python3.6

LABEL maintainer "Jarvis <jarvis@theblacktonystark.com>"

COPY ./virtualization/docker/nginx.conf /etc/nginx/nginx.conf
COPY ./virtualization/docker/nginx-custom.conf /etc/nginx/conf.d/nginx.conf
# Copy the base uWSGI ini file to enable default dynamic uwsgi process number
COPY ./virtualization/docker/uwsgi.ini /etc/uwsgi/

# # Copy the entrypoint that will generate Nginx additional configs
# COPY ./virtualization/docker/entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh

# Copy start.sh script that will check for a /app/prestart.sh script and run it before starting the app
COPY ./virtualization/docker/start.sh /start.sh
RUN chmod +x /start.sh

# Copy the entrypoint that will generate Nginx additional configs
COPY ./virtualization/docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Custom Supervisord config
COPY ./virtualization/docker/supervisord.ini /etc/supervisor/conf.d/supervisord.conf

RUN set -ex \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    jq \
    less \
    libjpeg-dev \
    nfs-common \
    unzip \
    && \
    apt-get install -y build-essential curl git && \
    apt-get install -y zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev bash-completion vim tree sudo python2.7-dev net-tools ngrep tcpdump arpwatch strace socat psmisc && \
    apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD requirements.txt /tmp/requirements.txt
ADD requirements-dev.txt /tmp/requirements-dev.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    pip install --no-cache-dir -r /tmp/requirements-dev.txt && \
    pip install --no-cache-dir python-Consul==0.7.0 uwsgitop ngxtop uwsgi-tools

COPY ./src /app
WORKDIR /app


# https://easyengine.io/tutorials/nginx/troubleshooting/emerg-bind-failed-98-address-already-in-use/
# [emerg]: bind() to 0.0.0.0:80 failed (98: Address already in use)
# fuser -k 80/tcp

# Add consul agent
RUN export CONSUL_VERSION=1.0.6 \
    && export CONSUL_CHECKSUM=bcc504f658cef2944d1cd703eda90045e084a15752d23c038400cf98c716ea01 \
    && curl --retry 7 --fail -vo /tmp/consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
    && echo "${CONSUL_CHECKSUM}  /tmp/consul.zip" | sha256sum -c \
    && unzip /tmp/consul -d /usr/local/bin \
    && rm /tmp/consul.zip \
    && mkdir -p /opt/consul/config

# Add ContainerPilot and set its configuration file path
ENV CONTAINERPILOT_VER 3.7.0
ENV CONTAINERPILOT /etc/containerpilot.json5
RUN export CONTAINERPILOT_CHECKSUM=b10b30851de1ae1c095d5f253d12ce8fe8e7be17 \
    && curl -Lso /tmp/containerpilot.tar.gz \
        "https://github.com/joyent/containerpilot/releases/download/${CONTAINERPILOT_VER}/containerpilot-${CONTAINERPILOT_VER}.tar.gz" \
    && echo "${CONTAINERPILOT_CHECKSUM}  /tmp/containerpilot.tar.gz" | sha1sum -c \
    && tar zxf /tmp/containerpilot.tar.gz -C /usr/local/bin \
    && rm /tmp/containerpilot.tar.gz

# By default, Nginx listens on port 80.
# To modify this, change LISTEN_PORT environment variable.
# (in a Dockerfile or with an option for `docker run`)
# ENV LISTEN_PORT 8080

# EXPOSE 8080

# Note: You propably need to pass the timezone via an environment variable e.g.
# by adding -e TZ=UTC. This prevents an UnknownTimeZoneError(zone)
# exception (pytz.exceptions.UnknownTimeZoneError: 'local') when
# generating the pages.
ENV TZ 'UTC'
# These go last to preserve the build cache.
# add app info as environment variables
ARG GIT_COMMIT
ENV GIT_COMMIT $GIT_COMMIT
ARG BUILD_TIMESTAMP
ENV BUILD_TIMESTAMP $BUILD_TIMESTAMP
