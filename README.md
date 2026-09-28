# AVADO-DNP-Grafana

[Grafana](https://grafana.com) monitoring package for AVADO.

Installing it from the DappStore also installs its dependencies:

- [Prometheus](https://github.com/AvadoDServer/AVADO-DNP-Prometheus) (`prometheus.avado.dappnode.eth`),
  which collects the metrics,
- [Node exporter](https://github.com/AvadoDServer/AVADO-DNP-Node-exporter) (`node-exporter.avado.dappnode.eth`),
  which exposes the AVADO's CPU, memory, disk and network metrics, and
- [SMART disk stats](https://github.com/AvadoDServer/AVADO-DNP-Smartctl-exporter) (`smartctl-exporter.avado.dappnode.eth`),
  which reads the health, temperature and wear of the AVADO's drives.

Open Grafana with the **Open** button in the AVADO admin UI, or go to
http://grafana.my.ava.do:3000 from a device connected to the AVADO network.
No ports are published on the host (nothing is opened on your router).

## Dashboards

The dashboards are provisioned from the image into the **AVADO** folder (they are read-only
and are updated together with the package; save a copy to customise one):

| Dashboard | Source | Licence |
|-----------|--------|---------|
| Host | `host-grafana-dashboard.json` from [DAppNode DMS](https://github.com/dappnode/DAppNodePackage-DMS) | GPL-3.0 |
| Teku | ConsenSys' Teku dashboard ([grafana.com 13457](https://grafana.com/grafana/dashboards/13457)), as shipped in [DAppNodePackage-teku-generic](https://github.com/dappnode/DAppNodePackage-teku-generic) | Apache-2.0 |
| Nimbus | Status' Nimbus dashboard from [status-im/nimbus-eth2 `grafana/`](https://github.com/status-im/nimbus-eth2/tree/unstable/grafana), as shipped in [DAppNodePackage-nimbus-generic](https://github.com/dappnode/DAppNodePackage-nimbus-generic) | Apache-2.0 / MIT |
| Prysm | `prysm-grafana-dashboard.json` from [DAppNodePackage-prysm-generic](https://github.com/dappnode/DAppNodePackage-prysm-generic) | GPL-3.0 |
| Disk health | Richard Durso's SMARTctl Exporter Dashboard ([grafana.com 22604](https://grafana.com/grafana/dashboards/22604)) from [reefland/grafana-dashboards](https://github.com/reefland/grafana-dashboards/tree/main/smartctl-exporter) | MIT, Copyright (c) 2025 Richard Durso (full notice in [build/dashboards/disks.LICENSE](build/dashboards/disks.LICENSE)) |

Thanks to DAppNode, ConsenSys, Status and Richard Durso for these dashboards. Changes made for AVADO:
datasource references point to the provisioned `Prometheus` datasource (uid `prometheus`),
label selectors use the job names of the AVADO Prometheus configuration (`node`, `teku`,
`nimbus`, `prysm-beacon`, `prysm-validator`), the Nimbus `container` variable was removed and
cAdvisor's `machine_cpu_cores` was replaced with `count(node_cpu_seconds_total{mode="idle"})`,
and the Host dashboard gained a **Drive Temp** stat and a **Temperature** graph built on
node-exporter's `hwmon` collector (NVMe composite temperature, SATA drives through the
`drivetemp` module, CPU and mainboard sensors where the board exposes them).
The Disk health dashboard keeps the upstream panels and queries; for AVADO the datasource
picker was removed, the uid/title/tags were set (`avado-disks`, "Disk health"), the
`<instance>` prefix was dropped from legends (one AVADO per Prometheus), the Media Errors and
Critical Warnings panels say "None" instead of "No data" when there are none, and a
**Health details** row was added: SMART status per drive, spare capacity left (NVMe) and NVMe
error log entries.

The Teku and Nimbus dashboards need Teku >= 0.0.73 / Nimbus >= 0.0.48 packages, which enable
the clients' metrics endpoints.

## Access and admin password

- Anyone on the AVADO network can view the dashboards without logging in (anonymous
  `Viewer`). Sign-up is disabled.
- On the first start the package generates a random password for the `admin` user, prints it
  once in the package log (AVADO admin UI -> Packages -> Grafana -> Logs, look for
  `Grafana admin login`) and stores it in `/var/lib/grafana/avado-admin-password` on the data
  volume. To read it later:

  ```sh
  docker exec DAppNodePackage-grafana.avado.dappnode.eth cat /var/lib/grafana/avado-admin-password
  ```

  When upgrading from 0.0.2 (which used `admin`/`admin`), the admin password is replaced by
  the generated one on the first start of 0.0.3.
- To choose your own password, set `GF_SECURITY_ADMIN_PASSWORD` in the package's environment
  variables. It is applied on every start and the generated password file is removed. If you
  clear the variable again, a new random password is generated and printed.

## Configuration

- [build/grafana.ini](build/grafana.ini): port 3000, anonymous viewers, no sign-up, no
  analytics reporting or update checks, Host dashboard as home page.
- [build/provisioning](build/provisioning): the Prometheus datasource
  (`http://prometheus.my.ava.do:9090`) and the dashboard provider.
- [build/dashboards](build/dashboards): the dashboards, copied to `/var/lib/grafana-dashboards`.
  The Disk health dashboard reads the `smartctl_*` metrics of the SMART disk stats package
  (Prometheus job `smartctl`, Prometheus package 0.0.3 or newer).
  The Host dashboard's temperature panels come from node-exporter's `hwmon` collector, so
  they show whatever sensors the mainboard exposes; a box with no readable sensor shows N/A.
- Other Grafana settings can be changed with `GF_<SECTION>_<KEY>` environment variables.
