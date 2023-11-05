ARG GOOGLE_CLOUD_SDK_VERSION

FROM google/cloud-sdk:${GOOGLE_CLOUD_SDK_VERSION}-emulators

COPY setup.sh /

RUN curl -s -o /usr/bin/yq -LJO https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
    && curl -s -o /usr/bin/dumb-init -LJO https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 \
    && chmod +x /usr/bin/yq \
    && chmod +x /usr/bin/dumb-init \
    && chmod +x /setup.sh

EXPOSE 8085

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "/setup.sh & exec gcloud beta emulators pubsub start --project=${PUBSUB_PROJECT:-myproject} --host-port=0.0.0.0:${PUBSUB_PORT:-8085}"]