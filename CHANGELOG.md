# 0.4.0
- FEATURE: allow setting IP address in addition to name in source (SQL/CSV)
- FEATURE: approximate how long it takes to get node from larger view than 1
- FEATURE: unconditionally start new job if too long has passed since previous start
- FEATURE: add enable to Arista EOS model
- FEATURE: add rugged dependency in gemspec
- BUGFIX: xos while using telnet (by @fhibler)
- BUGFIX: ironware logout on some models (by @fhibler)
- BUGFIX: allow node to be removed while it is being collected
- BUGFIX: if model returns non string value, return empty string

# 0.3.0
- FEATURE: *FIXME* bunch of stuff I did for richih, docs needed
- FEATURE: ComWare model (by erJasp)
- FEATURE: Add comment support for router.db file
- FEATURE: Add input debugging and related configuration options
- BUGFIX: Fix ASA model prompt
- BUGFIX: Fix Aruba model display
- BUGFIX: Fix changing output in PowerConnect model

# 0.2.4
- FEATURE: Cisco SMB (Nikola series VxWorks) model by @thetamind
- FEATURE: Extreme Networks XOS model (access by sjm)
- FEATURE: Brocade NOS (Network Operating System) (access by sjm)
- BUGFIX: Match exactly to node[:name] if node[name] is an ip address.

# 0.2.3
- BUGFIX: rescue @ssh.close when far end closes disgracefully (ALU ISAM)
- BUGFIX: bugfixes to models
- FEATURE: Alcatel-Lucent ISAM 7302/7330 model added by @jalmargyyk
- FEATURE: Huawei VRP model added by @jalmargyyk
- FEATURE: Ubiquiti AirOS added by @willglyn
- FEATURE: Support 'input' debug in config, ssh/telnet use it to write session log

# 0.2.2
- BUGFIX: mark node as failure if unknown error is raised

# 0.2.1
- BUGFIX: vars variable resolving for main level vars

# 0.2.0
- FEATURE: Force10 model added by @lysiszegerman
- FEATURE: ScreenOS model added by @lysiszegerman
- FEATURE: FabricOS model added by @thakala
- FEATURE: ASA model added by @thakala
- FEATURE: Vyattamodel added by @thakala
- BUGFIX: Oxidized::String convenience methods for models fixed

# 0.1.1
- BUGFIX: vars needs to return value of r, not value of evaluation
