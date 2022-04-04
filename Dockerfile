# Use latest alpine image
FROM alpine:latest
ARG EXEC_DOWNLOAD_URL

WORKDIR /app
# Install dependencies.
RUN apk add --no-cache wget gzip tar

# Cpoy the archive.
COPY main.tar.gz .
# Extract the executable archive.
RUN wget -O main.tar.gz $EXEC_DOWNLOAD_URL
RUN tar zxvf main.tar.gz
# Give execute permission to the executable.
RUN chmod +x bin/main

# Copy the executable.
FROM scratch
COPY --from=build /app/bin/main /app/bin/

# Start the program.
CMD ["/app/bin/main"]
