FROM bitnami/nginx:1.21.6

# Set the user to root to copy the files
USER 0

# Copy the nginx config (see below)
COPY nginx.conf /opt/bitnami/nginx/conf/server_blocks/noddy.conf

# Copy just the static files from the builder image
COPY . /app

# Set the user back to un un-priviledged one
USER 1001

