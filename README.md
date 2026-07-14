# docker-tomcat

Imagen Docker de [Apache Tomcat](https://tomcat.apache.org/) con OpenJDK 21,
disponible sobre **AlmaLinux 9** y **Rocky Linux 9**, diferenciadas por tag.

Imagen en Docker Hub: [`davidpenya77/tomcat`](https://hub.docker.com/r/davidpenya77/tomcat)

> Este proyecto sustituye a [`davidpenya77/centos7-tomcat`](https://hub.docker.com/r/davidpenya77/centos7-tomcat)
> (CentOS 7 + Tomcat 8 + Java 7), que queda **deprecated**: CentOS 7 alcanzó su
> fin de vida en junio de 2024.

## Tags disponibles

| Tag | Base | Tomcat | Java |
|---|---|---|---|
| `latest`, `11`, `11-alma9`, `11.0.24-alma9` | AlmaLinux 9 minimal | 11.0.x | OpenJDK 21 |
| `11-rocky9`, `11.0.24-rocky9` | Rocky Linux 9 minimal | 11.0.x | OpenJDK 21 |

Ambas variantes se construyen desde el mismo `Dockerfile`; solo cambia la
imagen base (`--build-arg BASE_IMAGE=...`). Funcionalmente son equivalentes.

## Uso

```bash
# AlmaLinux 9 (por defecto)
docker run -d --name tomcat -p 8080:8080 davidpenya77/tomcat:11-alma9

# Rocky Linux 9
docker run -d --name tomcat -p 8080:8080 davidpenya77/tomcat:11-rocky9
```

Desplegar una aplicación:

```bash
docker run -d -p 8080:8080 \
  -v $(pwd)/miapp.war:/opt/tomcat/webapps/miapp.war:ro \
  davidpenya77/tomcat:11-alma9
```

### Habilitar el Manager

Por seguridad la imagen **no trae usuarios activos** (nada de admin/admin).
Crea tu propio `tomcat-users.xml` y móntalo:

```bash
docker run -d -p 8080:8080 \
  -v $(pwd)/tomcat-users.xml:/opt/tomcat/conf/tomcat-users.xml:ro \
  davidpenya77/tomcat:11-alma9
```

## Construcción local

```bash
# AlmaLinux 9
docker build -t davidpenya77/tomcat:11-alma9 .

# Rocky Linux 9
docker build --build-arg BASE_IMAGE=rockylinux/rockylinux:9-minimal \
             -t davidpenya77/tomcat:11-rocky9 .

# Otra versión de Tomcat (ejemplo: Tomcat 9 para apps javax.* legacy)
docker build --build-arg TOMCAT_MAJOR=9 --build-arg TOMCAT_VERSION=9.0.120 \
             -t davidpenya77/tomcat:9-alma9 .
```

## Migración desde Tomcat 8/9 (javax → jakarta)

Tomcat 10 y posteriores implementan Jakarta EE: el paquete de las APIs cambió
de `javax.*` a `jakarta.*`, por lo que las aplicaciones escritas para
Tomcat 9 o anteriores **no funcionan sin cambios**. Opciones:

- Recompilar la aplicación para Jakarta EE (recomendado).
- Copiar el WAR antiguo en `/opt/tomcat/webapps-javaee/`: Tomcat lo convierte
  automáticamente con la [migration tool](https://tomcat.apache.org/migration-11.0.html).
- Usar una build con Tomcat 9 (ver ejemplo de construcción anterior).

## Características

- Tomcat se descarga en tiempo de build desde `archive.apache.org` con
  verificación de checksum SHA-512 (sin binarios en el repositorio).
- Se ejecuta como usuario sin privilegios `tomcat`, no como root.
- Variante *minimal* de la base (`microdnf`) para reducir el tamaño.
- `HEALTHCHECK` incluido.
- Multi-arch: `linux/amd64` y `linux/arm64`.
- Rebuild automático semanal vía GitHub Actions para recoger parches del SO.

## Licencia

GPL-3.0. Se agradecen comentarios, issues y pull requests.
