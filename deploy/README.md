# Despliegue MVP

Plantilla Swarm sin datos de infraestructura ni credenciales. Una réplica SQLite
fijada al nodo de datos. El volumen local no ofrece failover automático.

Definir fuera de Git `DOCUSEAL_DATA_NODE`, `DOCUSEAL_PROXY_NETWORK`,
`DOCUSEAL_IMAGE` (tag inmutable o digest) y, si procede, `DOCUSEAL_SECRET_NAME`.
Construir desde un commit limpio con `bash scripts/build-image.sh`: el contexto
solo contiene archivos versionados, evitando empaquetar archivos locales.
Crear el secreto mediante un canal seguro, sin imprimirlo ni incorporarlo a
argumentos de shell. La imagen debe existir en el nodo de datos o en un registry
accesible. Validar con `docker stack config -c deploy/stack.yml` y desplegar en un
stack nuevo y aislado. Nunca reutilizar nombres de stacks existentes.

El proxy debe terminar HTTPS y enrutar al alias `dielca-docuseal:3000`, conservar
Host, X-Forwarded-For y X-Forwarded-Proto, permitir carga de PDF y WebSocket. No
publicar el puerto 3000 en interfaces del host. No activar FORCE_SSL sin HTTPS.
El healthcheck exige respuesta 200 del endpoint local `/up`; complementar con una sonda
HTTPS externa y una comprobación de login. Revisar la descarga del código fuente
tras cada actualización.

## Backups

Guardar todo el volumen `/data`: SQLite, archivos, certificados y Redis. Para una
copia completa coherente, detener únicamente la aplicación de este stack,
archivar el volumen con permisos privados y reanudarla incluso si falla la copia.
Verificar SQLite y restaurar en un volumen aislado antes de considerar válido el
backup. Programar copias, retención y una segunda copia fuera del nodo de datos
mediante el sistema de backups de infraestructura. Cifrar copias que contengan
credenciales o documentos. No guardar backups en Git ni en el contexto Docker.

## Monitorización

cAdvisor ofrece CPU, memoria y reinicios; usar el label de servicio de Swarm para
filtrar el nuevo servicio en Grafana. Añadir una sonda blackbox HTTPS en Prometheus
al dominio elegido y alertas de caída, reinicios y falta de backups. Validar las
configuraciones antes de recargar servicios compartidos. No se añade un endpoint
de métricas de negocio ni una dependencia de monitorización al MVP.

## Acceso

Login de serie. El primer acceso permite crear al administrador: completar este
paso mediante acceso restringido antes de abrir el portal a la subred. Los grupos
de Authentik no se sincronizan en el MVP. Invitaciones y recuperación por correo
necesitan SMTP; configurarlo desde las opciones existentes sin subir secretos.
