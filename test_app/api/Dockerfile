
# This should be updated to teh latest nodejs version. Try
# to use the alpine umage though as it's much smaller.
FROM node:17.9.0-alpine3.15

# Copy over the source files
COPY . /srv
WORKDIR /srv

# Run a clean install incase you have a local cached version.
RUN npm ci

# Set the user. "node" is UID 1000.
USER 1000

# Just have docker run the start command.
CMD ["npm", "run", "start"]

