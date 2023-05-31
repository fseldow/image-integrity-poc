FROM bitnami/kubectl:latest as kubectl
FROM mcr.microsoft.com/azure-cli

WORKDIR /scripts

COPY . .
COPY ./bin/ /usr/local/bin/

COPY --from=kubectl /opt/bitnami/kubectl/bin/kubectl /usr/local/bin/

CMD bash prepare_cluster_only.sh
