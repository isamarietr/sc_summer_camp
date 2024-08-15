# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to non-interactive
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && \
    apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    curl

# Add MongoDB Enterprise GPG key and repository for version 7.0
RUN wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
RUN echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.com/apt/ubuntu jammy/mongodb-enterprise/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-enterprise-7.0.list

# Install MongoDB Enterprise 7.0
RUN apt-get update && \
    apt-get install -y mongodb-enterprise 

# Copy the MongoDB configuration file to the container
# COPY mongod.conf /etc/mongod.conf

# Create the data directory for MongoDB
RUN mkdir -p /data/db

# Set the volume mount point
VOLUME ["/data/db"]

# Expose the MongoDB port
EXPOSE 27017

CMD ["mongod", "--config", "/etc/mongod.conf"]
# CMD ["systemctl", "start", "mongod"]
