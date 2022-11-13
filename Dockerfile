# Use latest dart image
FROM dart:stable AS build

ARG EXEC_DOWNLOAD_URL
ARG USE_BINARY

WORKDIR /app
# Install dependencies.
RUN apt-get update
RUN apt-get install -y wget gzip tar

COPY . .

RUN if [ "${USE_BINARY}" = "true" ]; then \
    # Extract the executable archive.
    wget -O main.tar.gz $EXEC_DOWNLOAD_URL ; \
    tar zxvf main.tar.gz ; \
    rm main.tar.gz ; \
    else \
    # Compile the source code.
    dart pub get ; \
    dart compile exe bin/main.dart -o bin/main ; \ 
    fi

# Give execute permission to the executable.
RUN chmod +x bin/main

# Copy the executable.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/ /app/

# For api server.
EXPOSE 2096
# For universe chat server
EXPOSE 2087

# Start the program.
CMD ["/app/bin/main"]
