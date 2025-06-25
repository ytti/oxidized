# Outputs

## Output: File

Parent directory needs to be created manually, one file per device, with most recent running config.

```yaml
output:
  file:
    directory: /var/lib/oxidized/configs
```

### Groups
If you use groups, the nodes will be stored in directories named after the
groups. The directories are stored one level above the directory for configurations
without groups.

Example:
```
/var/lib/oxidized/
+ configs/     # Configurations of groupless nodes
+ group1/      # Configurations of nodes in group1
+ group2/      # Configurations of nodes in group2
```

### Clean obsolete nodes
The `file` output can automatically remove the configuration of nodes no
longer present in the [source](Sources.md).

> :warning: **Warning:** this might be a dangerous operation: oxidized
> will remove **any** file not matching the hostname of the nodes configured
> in the source.

When using groups, it will remove any files not matching the hostnames of the
nodes from the groups directories (which are on the same level as the default
directory). As a safety measure, oxidized will only clean configuration out of
active groups. If the group `example` isn't used anymore, oxidized won't clean
the configurations out of the directory `../example/`.

Configuration:

```yaml
output:
  default: file
  clean_obsolete_nodes: true
  file:
    directory: "~/.config/oxidized/configs/default"
```


## Output: Git

This uses the rugged/libgit2 interface. So you should remember that normal Git
hooks will not be executed.

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

### Git performance issues with large device counts
When you use git to store your configurations, the size of your repository will
grow over time. This growth may lead to performance issues. If you encounter
such issues, you should perform a Git garbage collection on your repository.

Follow these steps to do so:

1. Stop oxidized (no one should access the git repository while running garbage
   collection)
2. Make a backup of your oxidized data, especially the Git repository
3. Change directory your oxidized git repository (as configured in oxidized
   configuration file)
4. Execute the command `git gc` to run the garbage collection
5. Restart oxidized - you're done!


### Clean obsolete nodes
The `git` output can automatically remove the configuration of nodes no
longer present in the [source](Sources.md).

> :warning: **Limitations**
> - this currently only works with `single_repo: true`
> - it will ignore configurations saved as [output types](#output-types) in
>   a separate repository.
> - oxidized will refuse to remove old configurations
>   when saving  [output types](#output-types) in a subdirectory of the git
>   repository (`type_as_directory: true`), or it would remove the output
>   type directories

Oxidized will remove **any** file within the git repository not matching the
group and hostname of the nodes configured in the source and will then commit
the change into git.

Configuration:

```yaml
output:
  default: git
  clean_obsolete_nodes: true
  git:
    single_repo: true
    repo: "~/.config/oxidized/devices.git"
```

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
