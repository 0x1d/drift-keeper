version: '3'

services:
  keeper:
    image: ${docker_image}
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./config.yaml:/app/config.yaml
