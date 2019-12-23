# Addendum

## Logstash to QRadar

Use Logstash to send log entries to QRadar via the Syslog protocol as Filebeat doesn't have a Syslog output provider.

### logstash-values.yaml

The `capkenr/logstash-with-syslog:7.5.1` images is the standard `docker.elastic.co/logstash/logstash:7.5.1` image with the Logstash Syslog output plugin installed. See the [Dockerfile](https://github.com/CapKenR/logstash-with-syslog/blob/master/Dockerfile).

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

```bash
$ helm install -n elastic-system --version 7.5.1 --values logstash-values.yaml logstash elastic/logstash
```
## Filebeat DaemonSet for ElasticSearch

Update the original Filebeat DaemonSet to add the System module to parse the `/var/log/syslog*` and `/var/log/auth.log*` files and the Log input type to parse the `/var/log/kern.log*` file.

```bash
$ helm upgrade -n elastic-system --version 7.5.1 --values filebeat-values.yaml filebeat elastic/filebeat
```

```bash
$ helm uninstall -n elastic-system filebeat
$ helm install -n elastic-system --version 7.5.1 --values filebeat-values.yaml filebeat elastic/filebeat
```

## Filebeat DaemonSet for QRadar

Create a second Filebeat DaemonSet that uses the System module to parse the `/var/log/syslog*` and `/var/log/auth.log*` files and the Log input type to parse the `/var/log/kern.log*` file. The entries are sent to Logstash for forwarding on to QRadar.

```bash
$ helm install -n elastic-system --version 7.5.1 --values filebeat-to-logstash-values.yaml filebeat-qradar elastic/filebeat
```

