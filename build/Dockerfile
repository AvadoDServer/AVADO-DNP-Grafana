FROM --platform=linux/amd64 grafana/grafana:12.4.11

COPY grafana.ini /etc/grafana/grafana.ini
COPY provisioning/ /etc/grafana/provisioning/
COPY dashboards/ /var/lib/grafana-dashboards/
COPY avado-entrypoint.sh /avado-entrypoint.sh

ENTRYPOINT ["/avado-entrypoint.sh"]
