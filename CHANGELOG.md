# 0.19.0
- FEATURE: allow setting ssh_keys (not relying on openssh config) (@denvera)
- FEATURE: fujitsupy model (@stokbaek)
- FEATURE: fiberdriver model (@emjemj)
- FEATURE: hpbladesystems model (@flokli)
- FEATURE: planetsgs model (@flokli)
- FEATURE: trango model (@rfdrake)
- FEATURE: casa model (@rfdrake)
- FEATURE: dlink model (@rfdrake)
- FEATURE: hatteras model (@rfdrake)
- FEATURE: ability to ignore SSL certs in http (@laf)
- FEATURE: awsns hooks, publish messages to AWS SNS topics (@natm)
- BUGFIX: pfsense, dnos, powerconnect, ciscosmb, eos, aosw

# 0.18.0
- FEATURE: APC model (by @davromaniak )
- BUGFIX: ironware, aosw
- BUGFIX: interpolate nil, false, true for node vars too

# 0 17.0
- FEATURE: "nil", "false" and "true" in source (e.g. router.db) are interpeted as nil, false, true. Empty is now always considered empty string, instead of in some cases nil and some cases empty string.
- FEATURE: support tftp as input model (@MajesticFalcon)
- FEATURE: add alvarion model (@MajesticFalcon)
- FEATURE: detect if ssh wants password terminal/CLI prompt or not
- FEATURE: node (group, model, username, password) resolution refactoring, supports wider range of use-cases
- BUGFIX: fetch for file output (@danilopopeye)
- BUGFIX: net-ssh version specification
- BUGFIX: routeros, catos, pfsense

# 0.16.3
- FEATURE: pfsense support (by @stokbaek)
- BUGFIX: cumulus prompt not working with default switch configs (by @nertwork)
- BUGFIX: disconnect ssh when prompt wasn't found (by @andir)
- BUGFIX: saos, asa, acos, timos updates, cumulus

# 0.16.2
- BUGFIX: when not using git (by @danilopopeye)
- BUGFIX: screenos update

# 0.16.1
- BUGFIX: unnecessary puts statement removed from git.rb

# 0.16.0
- FEATURE: support Gaia OS devices (by @totosh)
- BUGFIX: #fetch, #version fixes in nodes.rb (by @danilopopeye)
- BUGFIX: procurve

# 0.15.0
- FEATURE: disable periodic collection, only on demand (by Adam Winberg)
- FEATURE: allow disabling ssh exec mode always (mainly for oxidized-script) (by @nickhilliard)
- FEATURE: support mellanox devices (by @ham5ter)
- FEATURE: support firewireos devices (by @alexandre-io)
- FEATURE: support quanta devices (by @f0o)
- FEATURE: support tellabs coriant8800, coriant8600 (by @udhos)
- FEATURE: support brocade6910 (by @cardboardpig)
- BUGFIX: debugging, tests (by @ElvinEfendi)
- BUGFIX: nos, panos, acos, procurve, eos, edgeswitch, aosw, fortios updates

# 0.14.3
- BUGFIX: fix git when using multiple groups without single_repo

# 0.14.2
- BUGFIX: git expand path for all groups
- BUGFIX: git get_version, teletubbies do it again
- BUGFIX: comware, acos, procurve models

# 0.14.1
- BUGFIX: git get_version when groups and single_repo are used

# 0.14.0
- FEATURE: support supermicro swithes (by @funzoneq)
- FEATURE: support catos switches
- BUGFIX: git+groups+singlerepo (by @PANZERBARON)
- BUGFIX: asa, tmos, ironware, ios-xr
- BUGFIX: mandate net-ssh 3.0.x, don't accept 3.1 (numerous issues)

# 0.13.1
- BUGFIX: file permissions (Sigh...)

# 0.13.0
- FEATURE: http post for configs (by @jgroom33)
- FEATURE: support ericsson redbacks (by @roedie)
- FEATURE: support motorola wireless controllers (by @roadie)
- FEATURE: support citrix netscaler (by @roadie)
- FEATURE: support datacom devices (by @danilopopeye)
- FEATURE: support netonix devices
- FEATURE: support specifying ssh cipher and kex (by @roadie)
- FEATURE: rename proxy to ssh_proxy (by @roadie)
- FEATURE: support ssh keys on ssh_proxy (by @awix)
- BUGFIX: various (by @danilopopeye)
- BUGFIX: Node#repo with groups (by @danilopopeye)
- BUGFIX: githubrepohoook (by @danilopopeye)
- BUGFIX: fortios, airos, junos, xos, edgeswitch, nos, tmos, procurve, ipos models

# 0.12.2
- BUGFIX: more MRV model fixes (by @natm)

# 0.12.1
- BUGFIX: set term to vty100
- BUGFIX: MRV model fixes (by @natm)

# 0.12.0
- FEATURE: enhance AOSW (by @mikebryant)
- FEATURE: F5 TMOS support (by @mikebryant)
- FEATURE: Opengear support (by @mikebryant)
- FEATURE: EdgeSwitch support (by @doogieconsulting)
- BUGFIX: rename input debug log files
- BUGFIX: powerconnect model fixes (by @Madpilot0)
- BUGFIX: fortigate model fixes (by @ElvinEfendi)
- BUGFIX: various (by @mikebryant)
- BUGFIX: write SSH debug to file without buffering
- BUGFIX: fix IOS XR prompt handling

# 0.11.0
- FEATURE: ssh proxycommand (by @ElvinEfendi)
- FEATURE: basic auth in HTTP source (by @laf)
- BUGFIX: do not inject string to output before model gets it
- BUGFIX: store pidfile in oxidized root

# 0.10.0
- FEATURE: Various refactoring (by @ElvinEfendi)
- FEATURE: Ciena SOAS support (by @jgroom33)
- FEATURE: support group variables (by @supertylerc)
- BUGFIX: various ((orly))  (by @marnovdm, @danbaugher, @MrRJ45, @asynet, @nickhilliard)

# 0.9.0
- FEATURE: input log now uses devices name as file, instead of string from config (by @skoef)
- FEATURE: Dell Networkign OS (dnos) support (by @erefre)
- BUGFIX: CiscoSMB, powerconnect, comware, xos, ironware, nos fixes

# 0.8.1
- BUGFIX: restore ruby 1.9.3 compatibility

# 0.8.0
- FEATURE: hooks (by @aakso)
- FEATURE: MRV MasterOS support (by @kwibbly)
- FEATURE: EdgeOS support (by @laf)
- FEATURE: FTP input and Zyxel ZynOS support (by @ytti)
- FEATURE: version and diffs API For oxidized-web (by @FlorianDoublet)
- BUGFIX: aosw, ironware, routeros, xos models
- BUGFIX: crash with 0 nodes
- BUGFIX: ssh auth fail without keyboard-interactive
- Full changelog https://github.com/ytti/oxidized/compare/0.7.1...HEAD

# 0.7.0
- FEATURE: support http source (by @laf)
- FEATURE: support Palo Alto PANOS (by @rixxxx)
- BUGFIX:  screenos fixes (by @rixxxx)
- BUGFIX:  allow 'none' auth in ssh (spotted by @SaldoorMike, needed by ciscosmb+aireos)

# 0.6.0
- FEATURE: support cumulus linux (by @FlorianDoublet)
- FEATURE: support HP Comware SMB siwtches (by @sid3windr)
- FEATURE: remove secret additions (by @rodecker)
- FEATURE: option to put all groups in single repo (by @ytti)
- FEATURE: expand path in source: csv: (so that ~/foo/bar works) (by @ytti)
- BUGFIX: screenos fixes (by @rixxxx)
- BUGFIX: ironware fixes (by @FlorianDoublet)
- BUGFIX: powerconnect fixes (by @sid3windr)
- BUGFIX: don't ask interactive password in new net/ssh (by @ytti)

# 0.5.0
- FEATURE: Mikrotik RouterOS model (by @emjemj)
- FEATURE: add support for Cisco VSS (by @MrRJ45)
- BUGFIX: general fixes to powerconnect model (by @MrRJ45)
- BUGFIX: fix initial commit issues with rugged (by @MrRJ45)
- BUGFIX: pager error for old dell powerconnect switches (by @emjemj)
- BUGFIX: logout error for old dell powerconnect switches (by @emjemj)

# 0.4.1
- BUGFIX: handle missing output file (by @brandt)
- BUGFIX: fix passwordless enable on Arista EOS model (by @brandt)

# 0.4.0
- FEATURE: allow setting IP address in addition to name in source (SQL/CSV)
- FEATURE: approximate how long it takes to get node from larger view than 1
- FEATURE: unconditionally start new job if too long has passed since previous start
- FEATURE: add enable to Arista EOS model
- FEATURE: add rugged dependency in gemspec
- FEATURE: log prompt detection failures
- BUGFIX: xos while using telnet (by @fhibler)
- BUGFIX: ironware logout on some models (by @fhibler)
- BUGFIX: allow node to be removed while it is being collected
- BUGFIX: if model returns non string value, return empty string
- BUGFIX: better prompt for Arista EOS model (by @rodecker)
- BUGFIX: improved configuration handling for Arista EOS model (by @rodecker)

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
