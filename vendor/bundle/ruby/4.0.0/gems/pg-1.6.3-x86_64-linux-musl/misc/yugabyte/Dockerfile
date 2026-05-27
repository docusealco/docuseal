FROM yugabytedb/yugabyte:2024.1.0.0-b129

WORKDIR /app

RUN yugabyted cert generate_server_certs --hostnames=127.0.0.1 --base_dir=.

ENTRYPOINT ["yugabyted"]
CMD ["start", "--background", "false", "--ui", "false", "--tserver_flags", "use_client_to_server_encryption=true,cert_node_filename=127.0.0.1,certs_dir=/app/generated_certs/127.0.0.1"]
VOLUME /app
