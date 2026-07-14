# davidpenya77/tomcat
# Apache Tomcat sobre AlmaLinux 9 o Rocky Linux 9, con OpenJDK 21.
#
# La base se elige con un build-arg, un solo Dockerfile para ambas variantes:
#
#   AlmaLinux 9 (por defecto):
#     docker build -t davidpenya77/tomcat:11-alma9 .
#
#   Rocky Linux 9:
#     docker build --build-arg BASE_IMAGE=rockylinux/rockylinux:9-minimal \
#                  -t davidpenya77/tomcat:11-rocky9 .
#
#   Otra versión de Tomcat:
#     docker build --build-arg TOMCAT_MAJOR=9 --build-arg TOMCAT_VERSION=9.0.120 \
#                  -t davidpenya77/tomcat:9-alma9 .

ARG BASE_IMAGE=almalinux:9-minimal
FROM ${BASE_IMAGE}

ARG TOMCAT_MAJOR=11
ARG TOMCAT_VERSION=11.0.24

LABEL org.opencontainers.image.title="tomcat" \
      org.opencontainers.image.description="Apache Tomcat ${TOMCAT_VERSION} con OpenJDK 21 sobre EL9 (AlmaLinux/Rocky Linux)" \
      org.opencontainers.image.authors="davidochobits" \
      org.opencontainers.image.source="https://github.com/davidochobits/docker-tomcat" \
      org.opencontainers.image.licenses="GPL-3.0"

# Paquetes mínimos: JRE headless + utilidades para extraer el tar
RUN microdnf -y update && \
    microdnf -y install java-21-openjdk-headless tar gzip shadow-utils && \
    microdnf clean all && \
    rm -rf /var/cache/dnf /var/cache/yum

# Usuario sin privilegios para ejecutar Tomcat
RUN groupadd -r tomcat && \
    useradd -r -M -s /sbin/nologin -g tomcat -d /opt/tomcat tomcat

# Descarga de Tomcat en build (nada de binarios en Git) + verificación SHA-512
RUN set -eux; \
    curl -fsSL -o /tmp/tomcat.tar.gz \
      "https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"; \
    curl -fsSL -o /tmp/tomcat.tar.gz.sha512 \
      "https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz.sha512"; \
    cd /tmp; \
    awk '{print $1"  tomcat.tar.gz"}' tomcat.tar.gz.sha512 > check.sha512; \
    sha512sum -c check.sha512; \
    tar -xzf /tmp/tomcat.tar.gz -C /opt; \
    mv "/opt/apache-tomcat-${TOMCAT_VERSION}" /opt/tomcat; \
    rm -rf /tmp/tomcat.tar.gz* /tmp/check.sha512 \
           /opt/tomcat/webapps/docs \
           /opt/tomcat/webapps/examples; \
    chown -R tomcat:tomcat /opt/tomcat; \
    chmod -R g+r /opt/tomcat/conf; \
    chmod g+x /opt/tomcat/conf

# Configuración de usuarios de Tomcat (sin credenciales activas por defecto)
COPY --chown=tomcat:tomcat tomcat-users.xml /opt/tomcat/conf/tomcat-users.xml

ENV JAVA_HOME=/usr/lib/jvm/jre \
    CATALINA_HOME=/opt/tomcat \
    CATALINA_BASE=/opt/tomcat \
    CATALINA_PID=/opt/tomcat/temp/tomcat.pid \
    PATH="/opt/tomcat/bin:${PATH}"

USER tomcat
WORKDIR /opt/tomcat

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fs http://localhost:8080/ >/dev/null || exit 1

CMD ["catalina.sh", "run"]
