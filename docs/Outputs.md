# Outputs

## Output: File

Parent directory needs to be created manually, one file per device, with most recent running config.

```yaml
output:
  file:
    directory: /var/lib/oxidized/configs
```

## Output: Git

This uses the rugged/libgit2 interface. So you should remember that normal Git hooks will not be executed.

For a single repository containing all devices:

```yaml
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/devices.git"
```

And for group-based repositories:

```yaml
output:
  default: git
  git:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/git-repos/default.git"
```

Oxidized will create a repository for each group in the same directory as the `default.git`. For
example:

```csv
host1:ios:first
host2:nxos:second
```

This will generate the following repositories:

```bash
$ ls /var/lib/oxidized/git-repos

default.git first.git second.git
```

If you would like to use groups and a single repository, you can force this with the `single_repo` config.

```yaml
output:
  default: git
  git:
    single_repo: true
    repo: "/var/lib/oxidized/devices.git"

```

Over time, your Git repository will expand, potentially leading to performance issues. For instructions on how to address this, see [git performance issues with large device counts](Troubleshooting.md#git-performance-issues-with-large-device-counts).

## Output: Git-Crypt

This uses the gem git and system git-crypt interfaces. Have a look at [GIT-Crypt](https://www.agwa.name/projects/git-crypt/) documentation to know how to install it.
Additionally to user and email informations, you have to provide the users ID that can be a key ID, a full fingerprint, an email address, or anything else that uniquely identifies a public key to GPG (see "HOW TO SPECIFY A USER ID" in the gpg man page).

For a single repository containing all devices:

```yaml
output:
  default: gitcrypt
  gitcrypt:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/devices"
    users:
      - "0x0123456789ABCDEF"
      - "<user@example.com>"
```

And for group-based repositories:

```yaml
output:
  default: gitcrypt
  gitcrypt:
    user: Oxidized
    email: o@example.com
    repo: "/var/lib/oxidized/git-repos/default"
    users:
      - "0xABCDEF0123456789"
      - "0x0123456789ABCDEF"
```

Oxidized will create a repository for each group in the same directory as the `default`. For
example:

```csv
host1:ios:first
host2:nxos:second
```

This will generate the following repositories:

```bash
$ ls /var/lib/oxidized/git-repos

default.git first.git second.git
```

If you would like to use groups and a single repository, you can force this with the `single_repo` config.

```yaml
output:
  default: gitcrypt
  gitcrypt:
    single_repo: true
    repo: "/var/lib/oxidized/devices"
    users:
      - "0xABCDEF0123456789"
      - "0x0123456789ABCDEF"

```

Please note that user list is only updated once at creation.

## Output: Http

The HTTP output will POST a config to the specified HTTP URL. Basic username/password authentication is supported.

Example HTTP output configuration:

```yaml
output:
  default: http
  http:
    user: admin
    password: changeit
    url: "http://192.168.162.50:8080/db/coll"
```

## Output types

If you prefer to have different outputs in different files and/or directories, you can easily do this by modifying the corresponding model. To change the behaviour for IOS, you would edit `lib/oxidized/model/ios.rb` (run `gem contents oxidized` to find out the full file path).

For example, let's say you want to split out `show version` and `show inventory` into separate files in a directory called `nodiff` which your tools will not send automated diffstats for. You can apply a patch along the lines of

```text
-  cmd 'show version' do |cfg|
-    comment cfg.lines.first
+  cmd 'show version' do |state|
+    state.type = 'nodiff'
+    state

-  cmd 'show inventory' do |cfg|
-    comment cfg
+  cmd 'show inventory' do |state|
+    state.type = 'nodiff'
+    state
+  end

-  cmd 'show running-config' do |cfg|
-    cfg = cfg.each_line.to_a[3..-1].join
-    cfg.gsub! /^Current configuration : [^\n]*\n/, ''
-    cfg.sub! /^(ntp clock-period).*/, '! \1'
-    cfg.gsub! /^\ tunnel\ mpls\ traffic-eng\ bandwidth[^\n]*\n*(
+  cmd 'show running-config' do |state|
+    state = state.each_line.to_a[3..-1].join
+    state.gsub! /^Current configuration : [^\n]*\n/, ''
+    state.sub! /^(ntp clock-period).*/, '! \1'
+    state.gsub! /^\ tunnel\ mpls\ traffic-eng\ bandwidth[^\n]*\n*(
                   (?:\ [^\n]*\n*)*
                   tunnel\ mpls\ traffic-eng\ auto-bw)/mx, '\1'
-    cfg
+    state = Oxidized::String.new state
+    state.type = 'nodiff'
+    state
```

which will result in the following layout

```text
diff/$FQDN--show_running_config
nodiff/$FQDN--show_version
nodiff/$FQDN--show_inventory
```
