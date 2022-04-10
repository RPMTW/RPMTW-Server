# Use latest dart image
FROM dart:stable AS build
ARG EXEC_DOWNLOAD_URL

WORKDIR /app
# Install dependencies.
RUN apt-get update
RUN apt-get install -y wget gzip tar

# Extract the executable archive.
COPY . .
RUN wget -O main.tar.gz $EXEC_DOWNLOAD_URL
RUN tar zxvf main.tar.gz

# Give execute permission to the executable.
RUN chmod +x bin/main

# Copy the executable.
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/main /app/bin/

# Start the program.
CMD ["/app/bin/main"]
