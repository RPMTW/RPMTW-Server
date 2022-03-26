# Use latest stable channel SDK.
FROM dart:stable AS build

# Resolve app dependencies.
WORKDIR /app
COPY pubspec.* ./
COPY .env ./
RUN apt-get update
RUN apt-get install wget unzip
RUN dart pub get

# Copy app source code (except anything in .dockerignore) and AOT compile app.
COPY . .
RUN wget $EXEC_DOWNLOAD_URL
RUN unzip server.zip
RUN mv server/server /bin

# Build minimal serving image from AOT-compiled `/server`
# and the pre-built AOT-runtime in the `/runtime/` directory of the base image.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Start server.
EXPOSE 2096
# For cosmic chat server
EXPOSE 2087
CMD ["/app/bin/server"]
