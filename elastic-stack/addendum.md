# Addendum

## Logstash to QRadar

Use Logstash to send log entries to QRadar via the Syslog protocol as Filebeat doesn't have a Syslog output provider.

### logstash-values.yaml

The `capkenr/logstash-with-syslog:7.5.1` image is the standard `docker.elastic.co/logstash/logstash:7.5.1` image with the Logstash Syslog output plugin installed. See the [Dockerfile](https://github.com/CapKenR/logstash-with-syslog/blob/master/Dockerfile).

In `logstash.conf` the host is the DNS name or IP address of you Syslog (or, in this case, QRadar) server. Your messages can conform to either RFC3164 or RFC5424.

```
      syslog {
        host => "syslog-ng"
        port => 514
        protocol => "tcp"
        rfc => "rfc3164"
      }
```

For more details, see [Syslog output plugin](https://www.elastic.co/guide/en/logstash/current/plugins-outputs-syslog.html).

### Install Logstash

```bash
$ helm install -n elastic-system --version 7.5.1 --values logstash-values.yaml logstash elastic/logstash
```
## Filebeat DaemonSet for ElasticSearch

Update the original Filebeat DaemonSet to add the System module to parse the `/var/log/syslog*` and `/var/log/auth.log*` files and the Log input type to parse the `/var/log/kern.log*` file.

You can either upgrade an existing install.

```bash
$ helm upgrade -n elastic-system --version 7.5.1 --values filebeat-values.yaml filebeat elastic/filebeat
```

Or, you can uninstall and reinstall.

```bash
$ helm uninstall -n elastic-system filebeat
$ helm install -n elastic-system --version 7.5.1 --values filebeat-values.yaml filebeat elastic/filebeat
```

## Filebeat DaemonSet for QRadar

Create a second Filebeat DaemonSet that uses the System module to parse the `/var/log/syslog*` and `/var/log/auth.log*` files and the Log input type to parse the `/var/log/kern.log*` file. The entries are sent to Logstash for forwarding on to QRadar.

```bash
$ helm install -n elastic-system --version 7.5.1 --values filebeat-to-logstash-values.yaml filebeat-qradar elastic/filebeat
```

## Two Filebeat sidescars

[tomcat-with-2-filebeats.yaml](./tomcat-with-2-filebeats.yaml) is an example of a Tomcat application with two Filebeat sidecars. The first sidecar sends all of the Tomcat logs along with the system logs to Elastsearch. The second sidecar sends the Tomcat access logs and the system logs to Logstash (which forwards them on to QRadar).