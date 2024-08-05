# Sources

## Source: CSV

One line per device, colon separated. If `ip` isn't present, a DNS lookup will be done against `name`.  For large installations, setting `ip` will dramatically reduce startup time.

```yaml
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

```text
rtr01.local:192.168.1.1:ios:oxidized:5uP3R53cR3T:T0p53cR3t
```

If you would like to use a GPG encrypted file as the source then you can use the following example:

```yaml
source:
  default: csv
  csv:
    file: ~/.config/oxidized/router.db
    delimiter: !ruby/regexp /:/
    gpg: true
    gpg_password: 'password'
    map:
      name: 0
      model: 1
```

Please note, if you are running GPG v2 then you will be prompted for your gpg password on start up, if you use GPG >= 2.1 then you can add the following config to stop that behaviour:

Within `~/.gnupg/gpg-agent.conf`

```text
allow-loopback-pinentry
```

and within: `~/.gnupg/gpg.conf`

```text
pinentry-mode loopback
```

## Source: JSONFile

One object per device. Supports GPG encryption like the CSV Source.

```yaml
source:
  default: jsonfile
  jsonfile: 
    file: /var/lib/oxidized/router.json
    map:
      name: hostname
      model: os
      username: username
      password: password
    vars_map:
      enable: enable
```

## Source: SQL

 Oxidized uses the `sequel` ruby gem. You can use a variety of databases that aren't explicitly listed. For more information visit https://github.com/jeremyevans/sequel Make sure you have the correct adapter!

**NOTE** - Many database engines have reserved keywords that may conflict with Oxidized configuration field names (such as 'name', 'group', etc). Pay attention to any names that are used and observed proper quoting methods to avoid errors or unpredictable results.

## Source: MYSQL

`sudo apt-get install libmysqlclient-dev`

The values correspond to your fields in the DB such that ip, model, etc are field names in the DB

```yaml
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

### MySQL with TLS support
By default SSL is disabled, but if you would like enable connection via TLS add the following configuration:
```yaml
source:
  default: sql
  sql:
    ...
    with_ssl: true
    ssl_mode: <mode>
    ssl_ca: <path to CA certificate>
    ssl_cert: <path to client certificate>
    ssl_key: <path to client certificate key>
```
ssl_mode may be one of the next: disabled / preferred / required / verify_ca / verify_identity

For more information visit: https://github.com/brianmario/mysql2

## Source: SQLite

One row per device, filtered by hostname.

```yaml
source:
  default: sql
  sql:
    adapter: sqlite
    database: "/var/lib/oxidized/nodes.db"
    table: nodes
    map:
      name: fqdn
      model: model
      username: username
      password: password
    vars_map:
      enable: enable
```

## Custom SQL Query Support

You may also implement a custom SQL query to retrieve the nodelist using  SQL syntax with the `query:` configuration parameter under the `sql:` stanza.

### Custom SQL Query Examples

You may have a table named `nodes` which contains a boolean to indicate if the nodes should be enabled (fetched via oxidized). This can be used in the custom SQL query to avoid fetching from known impacted nodes.

In your configuration, you would add the `query:` parameter and specify the SQL query. Make sure to put this within the `sql:` configuration section.

```sql
query: "SELECT * FROM nodes WHERE enabled = True"
```

Since this is an SQL query, you can also provide a more advanced query to assist in more complicated oxidized deployments. The exact deployment is up to you on how you design your database and oxidized fetchers.

In this example we limit the nodes to two "POPs" of `mypop1` and `mypop2`. We also require the nodes to have the `enabled` boolean set to `True`.

```sql
query: "SELECT * FROM nodes WHERE pop IN ('mypop1','mypop2') AND enabled = True"
```

The order of the nodes returned will influence the order that nodes are fetched by oxidized. You can use standard SQL `ORDER BY` clauses to influence the node order.

You should always test your SQL query before using it in the oxidized configuration as there is no syntax or error checking performed before sending it to the database engine.

Consult your database documentation for more information on query language and table optimization.

## Source: HTTP

One object per device.

HTTP Supports basic auth, configure the user and pass you want to use under the http: section.

```yaml
source:
  default: http
  http:
    url: https://url/api
    scheme: https
    delimiter: !ruby/regexp /:/
    user: username
    pass: password
    read_timeout: 120
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

```yaml
source:
  default: http
  http:
    url: https://url/api
    scheme: https
    secure: false
```

HTTP source also supports pagination. Two settings must be enabled. (`pagination` as a bool and `pagination_key_name` as a string)
The `pagination_key_name` setting is the key name that an api returns to find the url of the next page.

**Disclaimer**: currently only tested with netbox as the source

```yaml
source:
  default: http
  http:
    pagination: true
    pagination_key_name: 'next'
```
