FROM scratch

ENV enjoy-chain_CONFIG=/config/enjoy-chain.yml

VOLUME /config
EXPOSE 5000

COPY ./dist/linux-amd64/enjoy-chain /bin/enjoy-chain
COPY ./enjoy-chain.default.yml /config/enjoy-chain.yml

ENTRYPOINT ["/bin/enjoy-chain"]

# Run the HTTP server.
CMD ["-mongo.uri", "mongo/enjoy-chain", "http", "-host", "0.0.0.0"]
