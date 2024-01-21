import Doc from "../Doc"
import CodeOutput from "../CodeOutput"

const reactDockerfile = `
# A seperate builder image builds the static files
FROM node:17.9.0-alpine3.15 AS builder

# Copy all files into a working directory
COPY . /opt
WORKDIR /opt

# Run the install in Docker to ensure a consistent build
RUN npm ci && npm run build

# Now we create the "real" image
FROM bitnami/nginx:1.21.6

# Set the user to root to copy the files
USER 0

# Copy the nginx config (see below)
COPY nginx.conf /opt/bitnami/nginx/conf/server_blocks/react.conf

# Copy just the static files from the builder image
COPY --from=builder /opt/build /app

# Set the user back to un un-priviledged one
USER 1001
`

const reactNginxConf = `
server {
  listen 8080;
  location / {
    root   /app;
    index  index.html;
    try_files $uri $uri/ /index.html;
  }
  error_page 500 502 503 504 /50x.html;
  location = /50x.html {
    root  /app;
  }
}
`

const nodeDockerfile = `
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
`

export default function DockerDocumentation() {
	return (
		<Doc title="Docker" >
			<p>
				Here are some basic docker builds that you can use in your project.
			</p>

			<Doc title="React" >

				<p>
				For react, or any prebuilt ui, devops recommends running as a non-root
				nginx image. By building the static files during the docker build we 
				can find any issues during the CI rather than at runtime. Nginx typically
				requires some local caching so we cannot use a read-only filesystem.
				</p>

				<CodeOutput language="dockerfile" >{reactDockerfile}</CodeOutput>

				<p>
				When using react-router-* or equivalent, we will need to tell nginx to return
				the index.html instead of responding 404 for any unmatched files. Put this in
				<code> nginx.conf </code> in your application's root directory and have the
				Dockerfile copy it into place.
				</p>

				<CodeOutput language="nginx" >{reactNginxConf}</CodeOutput>
			</Doc>

			<Doc title="NodeJs" >
				<p>
					NodeJs docker images can be quite simple. The important thing is to copy
					the files as root then switch to a non-priviledged user. This stops any
					attacker from overwriting code.
				</p>
				<p>
					Devops also recommends that the <code> npm run start </code> script
					runs the service as this simplifies local development.
				</p>
				<CodeOutput language="dockerfile" >{nodeDockerfile}</CodeOutput>
			</Doc>
		</Doc>
	)
}
