## Source

### Source: CSV

One line per device, colon seperated. If `ip` isn't present, a DNS lookup will be done against `name`.  For large installations, setting `ip` will dramatically reduce startup time.

```
source:
  default: csv
  csv:
    file: /var/lib/oxidized/router.db
    delimiter: !ruby/regexp /:/
    map:
      name: 0
      ip: 1
      model: 2
      username: 3
      password: 4
    vars_map:
      enable: 5
```

Example csv `/var/lib/oxidized/router.db`:

```
rtr01.local,192.168.1.1,ios,oxidized,5uP3R53cR3T,T0p53cR3t
```

### Source: SQL
 Oxidized uses the `sequel` ruby gem. You can use a variety of databases that aren't explicitly listed. For more information visit https://github.com/jeremyevans/sequel Make sure you have the correct adapter!
### Source: MYSQL

`sudo apt-get install libmysqlclient-dev`

The values correspond to your fields in the DB such that ip, model, etc are field names in the DB

```
source:
  default: sql
  sql:
    adapter: mysql2
    database: oxidized
    table: nodes
    user: root
    password: rootpass
    map:
      name: ip
      model: model
      username: username
      password: password
    vars_map:
      enable: enable
```

### Source: SQLite

One row per device, filtered by hostname.

```
source:
  default: sql
  sql:
    adapter: sqlite
    database: "/var/lib/oxidized/devices.db"
    table: devices
    map:
      name: fqdn
      model: model
      username: username
      password: password
    vars_map:
      enable: enable
```

### Source: HTTP

One object per device.

HTTP Supports basic auth, configure the user and pass you want to use under the http: section.

```
source:
  default: http
  http:
    url: https://url/api
    scheme: https
    delimiter: !ruby/regexp /:/
    user: username
    pass: password
    map:
      name: hostname
      model: os
      username: username
      password: password
    vars_map:
      enable: enable
    headers:
      X-Auth-Token: 'somerandomstring'
```

You can also pass `secure: false` if you want to disable ssl certificate verification:

```
source:
  default: http
  http:
    url: https://url/api
    scheme: https
    secure: false
```