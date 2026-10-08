# DIELCA · Portal de firmas

MVP visual basado exclusivamente en DocuSeal Open Source. Se mantienen el login
Devise, la firma, las autorizaciones y la atribución original de DocuSeal.
Admins, Responsables, Trabajadores y Gerencia son perfiles previstos; este MVP
no implementa nuevos roles ni habilita funcionalidades Pro.

## Subir la identidad corporativa

1. Colocar el logo PNG en `public/dielca/logo.png`, preferiblemente transparente.
   Sin archivo, se muestra el nombre DIELCA como texto. No usar documentos reales
   como material de ejemplo ni incluir imágenes con información confidencial.
2. La paleta corporativa usa azul `#2B2F88`, blanco y ámbar `#B45309`
   para el contraste. Está definida en `tailwind.config.js` y
   `public/dielca/theme.css`. El logo conserva el verde de Renovables.
   El archivo incluido procede de `https://www.dielca.com/images/logo/logo_dielca.png`
   y se conserva sin modificaciones. Comprobar contraste al cambiar la paleta.
3. La cabecera corporativa se encuentra en `app/views/dielca/_identity.html.erb`.
4. Reconstruir la imagen para aplicar archivos nuevos. No se requieren nuevas
   dependencias ni cambios en la base de datos.

Las cuentas nuevas se configuran en español (`DIELCA_LOCALE=es-ES` por defecto).
Puede definirse `DIELCA_LOCALE=en-US` para conservar el idioma original.
La suite upstream usa este último valor porque sus pruebas visuales esperan
etiquetas inglesas; la regresión DIELCA se ejecuta aparte en español.
`CAPYBARA_MAX_WAIT_TIME` permite ampliar la espera de pruebas en contenedores
con CPU limitada; no cambia el comportamiento de la aplicación. Las cuentas existentes conservan su
idioma; puede cambiarse desde los ajustes de cuenta. El primer administrador se
crea mediante el asistente de configuración de DocuSeal; no hay credenciales
predeterminadas del proyecto.

## Arquitectura y actualizaciones

La identidad usa partials de `app/views/dielca/`, archivos estáticos en
`public/dielca/`, el tema DaisyUI y un initializer de idioma. La cabecera,
los títulos y metadatos presentan DIELCA. Hay puntos de integración pequeños en
layouts upstream y una etapa adicional de Docker para publicar el código fuente.
No se cambia la arquitectura Rails ni el dominio de firma. Vue 3, Turbo,
Shakapacker/Webpack y Tailwind/DaisyUI siguen intactos.

Origen oficial: `https://github.com/docusealco/docuseal` (remoto `upstream`).
Trabajar en ramas por tarea, Conventional Commits y PR; el propietario realiza
el merge manual. CI existente: RSpec, RuboCop, ERB lint, ESLint y Brakeman.

## Licencia y código correspondiente

Conservar `LICENSE`, `LICENSE_ADDITIONAL_TERMS`, la marca y atribución originales
en las interfaces. El portal conserva el nombre y símbolo originales de DocuSeal
en un pie visible junto a la descarga del código. Los avisos y atribuciones de
la firma, los documentos y los correos no se eliminan ni se ocultan.
No se habilitan opciones Pro ni se reutiliza código de la edición comercial.

Construir con `bash scripts/build-image.sh` desde un commit limpio; este script
exporta solo archivos versionados. El Dockerfile crea `/dielca/source.tar.gz` con el contexto de compilación filtrado
por `.dockerignore`. El portal ofrece su descarga sin coste. El contexto debe
contener el código completo de la versión y únicamente archivos publicables:
sin secretos, documentos empresariales, estado persistente o configuraciones
privadas. Revisar el contenido del archivo antes de desplegar cada imagen.
La descarga debe estar disponible a todos los usuarios de la versión modificada,
incluidos firmantes si se habilitan nuevos accesos. Para desarrollo local, generar
el archivo desde un commit limpio con `git archive --format=tar.gz HEAD -o
public/dielca/source.tar.gz`. Los avisos originales del formulario siguen visibles.

## Producción

El MVP puede usar SQLite y archivos en `/data`, con una sola réplica fijada a un
nodo y copias consistentes. No necesita PostgreSQL ni servicios externos para
iniciar sesión. SMTP es opcional para invitaciones y recuperación por correo.
Authentik queda fuera del MVP: no se habilita SSO/SAML Pro.

La configuración operativa se mantiene en el repositorio privado de
infraestructura. Antes de publicar: completar
dominio/DNS, ruta HTTPS, almacenamiento, backups y validación. No actualizar el
proxy compartido ni monitorización sin comprobar continuidad de los servicios.
