# Changelog

## Master

* FEATURE: add Dell EMC Networking OS10 support (@mmisslin)
* FEATURE: add Centec Networks CNOS (Fiberstore S5800/S5850) support via cnos model (@freddy36)
* FEATURE: include transceiver information in EdgeCOS model (@freddy36)
* FEATURE: add Telco Systems T-Marc 3306 support via telco model (@SkylerBlumer)
* FEATURE: add enable support to ciscosmb (@deesel)
* FEATURE: add Waystream iBOS model
* BUGFIX: use without-paging variant of print statement in routeros (@vkushnir)
* BUGFIX: include the commands in the output in EdgeCOS model (@freddy36)
* BUGFIX: update patterns for minor software version dependent differences in EdgeCOS model (@freddy36)
* BUGFIX: better login modalities for telnet in aos7 (@optimuscream)
* BUGFIX: better virtual domain detection in fortios (@agabellini)
* BUGFIX: allow any max length for username/password in GcomBNPS (@freddy36)
* BUGFIX: relax prompt requirements in ciscosmb (@Atroskelis)
* BUGFIX: fortios model strips uptime even without remove_secrets (@jplitza)
* MISC: more secret scrubbing in sonicos (@s-fu)
* MISC: openssh key scrubbing as secret in fortios (@agabellini)
* MISC: scrubs macsec key from Arista EOS (@krisamundson)
* MISC: rubocop dependency now ~> 0.80.0
* MISC: rugged dependency now ~> 0.28.0

## 0.27.0

* FEATURE: add automatic restart on failure for systemd (@deajan)
* FEATURE: add ZynOS GS1900 specific model support (@deajan)
* FEATURE: add PurityOS model support (@elliot64)
* FEATURE: add Ubiquiti Airfiber model support (@cchance27)
* FEATURE: add Icotera support (@funzoneq)
* FEATURE: include licensing information in aos model (@pozar)
* FEATURE: include chassis information in sros model (@raunz)
* FEATURE: add firelinuxos (FirePOWER) model (@rgnv)
* FEATURE: add sonicos model (@rgnv)
* FEATURE: add hpmsm model (@timwsuqld)
* FEATURE: include hardware and product information in oneos model (@raunz)
* FEATURE: add FastIron model (@ZacharyPuls)
* FEATURE: add Linuxgeneric model (@davama)
* FEATURE: include HA status info in fortios model (@raunz)
* FEATURE: add SpeedTouch model (@raunz)
* FEATURE: comware added device manuinfo to include serial number (@raunz)
* BUGFIX: prevent versionning on procurve switches by removing power usage output (@deajan)
* BUGFIX: improve procurve telnet support for older switches (@deajan)
* BUGFIX: voss model
* BUGFIX: cambium model should not consider timestamp for backup as unneeded, and causes diffs (@cchance27)
* BUGFIX: remove 'sh system' from ciscosmb model (@Exordian)
* BUGFIX: dlink model didn't support prompts with spaces in the model type (Extreme EAS 200-24p) (@cchance27)
* BUGFIX: routeros model does not collect configuration via telnet input (@hexdump0x0200)
* BUGFIX: add dependencies for net-ssh
* BUGFIX: don't log power module info on procurve model anymore
* BUGFIX: crash on some recent Ruby versions in the nagios check (@Kegeruneku)
* BUGFIX: remove stray whitespace in adtran model (@nickhilliard)
* BUGFIX: if input model returns subclassed string we may overwrite the string with an empty string
* BUGFIX: updated aosw.rb prompt. addresses issue #1254
* BUGFIX: update comware model to fix telnet login/password for HPE MSR954 and HPE5130. Issue #1886
* BUGFIX: filter out IOS configuration/NVRAM modified/changed timestamps to keep output persistent
* BUGFIX: update screenos model to reduce the amount of lines being stripped from beginning of cfg output
* BUGFIX: include colon in aosw prompt regexp in case it is a mac address (@raunz)
* BUGFIX: comware improvement for requesting HP 19x0 switches hidden CLI. Issues #1754 and #1447
* BUGFIX: fix variable inheritance when subclassing a model
* MISC: add pgsql support, mechanized and net-tftp to Dockerfile
* MISC: upgrade slop, net-telnet and rugged
* MISC: extra secret scrubbing in comware model (@bengels00)
* MISC: removed snmpd lines from linuxgeneric model
* MISC: moved show configuration command to the end in junos model (@raunz)
* MISC: filter pap and chap passwords in ios model (@matejv)

## 0.26.3

* BUGFIX: regression in git.rb version method where we check if Rugged::Diff has any deltas/patches

## 0.26.2

* BUGFIX: suppress net-ssh 5 deprecation warnings by moving from :paranoid to :verify_host_key

## 0.26.1

* BUGFIX: force file permissions in rubygems

## 0.26.0

* FEATURE: add Cisco VPN3000 model (@baznikin)
* FEATURE: add NetGear PROSafe Smart switches model (@baznikin)
* FEATURE: Added possibility to pass root logs directory as environment variable (@Glorf)
* FEATURE: add OneAccess TDRE (1645) model (@starrsl)
* FEATURE: add Audiocodes MediaPack MP-1xx and Mediant 1000 model (@pedjaj)
* FEATURE: add raisecom RAX model (@vitalisator)
* FEATURE: add huawei smartax model (@nyash)
* FEATURE: add grandstream model
* BUGFIX: in git comparison we might mistakenly always detect change due to !utf8 vs. utf8 encoding of a char
* MISC: prompt updates in siklu, netonix, netscaler models
* MISC: minimal supported ruby is now 2.3, net-ssh dependency ~> 5, rubocop ~> 0.65.0

## 0.25.0

* FEATURE: add viptela model (@bobthebutcher)
* FEATURE: add ECI Telecom Appolo platform bij arien.vijn@linklight.nl
* FEATURE: ssh keepalive now configurable per node with ssh_no_keepalive boolean
* FEATURE: add Comtrol model (@RobbFromIT)
* FEATURE: add Dell X-series model (@RobbFromIT)
* FEATURE: add privilege escalation to the cumulus model (@user4574)
* FEATURE: add adtran model (@CFUJoshWeepie)
* FEATURE: add firebrick model (@lewisvive)
* BUGFIX: netgear telnet password prompt not detected
* BUGFIX: xos model should not modify config on legacy Extreme Networks devices (@sq9mev)
* BUGFIX: model dlink, edgecos, ciscosmb, openbsd
* BUGFIX: hide 'lighttpd_ls_password' as potential secret in pfsense model (@dra)
* BUGFIX: ciscospark hook error when diff is set to false
* MISC: bump Dockerfile phusion/baseimage:0.10.0 -> 0.11, revert to one-stage build
* MISC: add sqlite3 and mysql2 drivers for sequel to Dockerfile
* MISC: Added verbiage to set OXIDIZED_HOME correctly under Debian 8.8 w/systemd
* MISC: add gpgme and sequel gems to Dockerfile for sources
* MISC: eos model removes user secrets and BGP secrets (@yzguy)
* MISC: add secret filtering to netscaler (@shepherdjay)
* MISC: capture ZebOS configuration for TMOS model (@yzguy)
* MISC: additional secret filters in ios, asa, procurve, ciscosmb models (@hexdump0x0200)
* MISC: remove volatile uptime data in nos model (@f0rkz)

## 0.24.0

* FEATURE: add frr support to cumulus model (@User4574 / @bobthebutcher)
* FEATURE: honour MAX_STAT in mtime, to store last N mtime
* FEATURE: configurable stats history size
* FEATURE: model callback enhancements for customizing existing models (@ytti)
* BUGFIX: models ciscosmb, dlink

## 0.23.0

* FEATURE: support arbitrary user/password/prompt detection in telnet, same behaviour as ssh
* FEATURE: manager refactor, support local loading of input, output, source, not just model and hook
* FEATURE: store modification time in node stats
* BUGFIX: model edgecos does not trigger false positives due to uptime and memory utilization (@sq9mev)
* BUGFIX: Use SECRET-DATA hints for hiding secrets in JunOS (@Zmegolaz)
* BUGFIX: comware (@adamboutcher)

## 0.22.0

* FEATURE: openbsd model (@amarti2038)
* FEATURE: comnet model (@jaylik)
* FEATURE: stoneos model (@macaty)
* FEATURE: openwrt model (@z00nx)
* FEATURE: arbos model (@jsynack)
* FEATURE: ndms model (@yuri-zubov)
* FEATURE: openwert model (@z00nx)
* FEATURE: stoneos model (@macaty)
* FEATURE: comnetms model (@jaylik)
* FEATURE: openbsd model (@amarti2038)
* FEATURE: cambium model
* FEATURE: ssh key passphrase (@wk)
* FEATURE: cisco spark hook (@rgnv)
* FEATURE: added support for setting ssh auth methods (@laf)
* BUGFIX: models procurve, br6910, vyos, fortios, edgeos, vyatta, junos, powerconnect, supermicro, fortios, firewareos, aricentiss, dnos, nxos, hpbladesystem, netgear, xos, boss, opengear, pfsense, asyncos

## 0.21.0

* FEATURE: routeros include system history (@InsaneSplash)
* FEATURE: vrp added support for removing secrets (@bheum)
* FEATURE: hirschmann model (@OCangrand)
* FEATURE: asa added multiple context support (@marnovdm)
* FEATURE: procurve added additional output (@davama)
* FEATURE: Updated git commits to bare repo + drop need for temp dir during clone (@asenci)
* FEATURE: asyncos model (@cd67-usrt)
* FEATURE: ciscosma model (@cd67-usrt)
* FEATURE: procurve added transceiver info (@davama)
* FEATURE: routeros added remove_secret option (@spinza)
* FEATURE: Updated net-ssh version (@Fauli83)
* FEATURE: audiocodes model (@Fauli83)
* FEATURE: Added docs for Huawei VRP devices (@tuxis-ie)
* FEATURE: ciscosmb added radius key detection (@davama)
* FEATURE: radware model (@sfini)
* FEATURE: enterasys model (@koenvdheuvel)
* FEATURE: weos model (@ignaqui)
* FEATURE: hpemsa model (@aschaber1)
* FEATURE: Added nodes_done hook (@danilopopeye)
* FEATURE: ucs model (@WiXZlo)
* FEATURE: acsw model (@sfini)
* FEATURE: aen model (@ZacharyPuls)
* FEATURE: coriantgroove model (@nickhilliard)
* FEATURE: sgos model (@seekerOK)
* FEATURE: powerconnect support password removal (@tobbez)
* FEATURE: Added haproxy example for Ubuntu (@denvera)
* BUGFIX: fiberdriver remove configuration generated on from diff (@emjemj)
* BUGFIX: Fix email pass through (@ZacharyPuls)
* BUGFIX: iosxr suppress timestamp (@ja-frog)
* BUGFIX: ios allow lowercase user/pass prompt (@deepseth)
* BUGFIX: Use git show instead of git diff (@asenci)
* BUGFIX: netgear fixed sending enable password and exit/quit (@candlerb)
* BUGFIX: ironware removed space requirement from password prompt (@crami)
* BUGFIX: dlink removed uptime from diff (@rfdrake)
* BUGFIX: planet removed temp from diff (@flokli)
* BUGFIX: ironware removed fan, temp and flash from diff (@Punicaa)
* BUGFIX: panos changed exit to quit (@goebelmeier)
* BUGFIX: fortios remove FDS address from diffs (@bheum)
* BUGFIX: fortios remove additional secrets from diffs (@brunobritocarvalho)
* BUGFIX: fortios remove IPS URL DB (@brunobritocarvalho)
* BUGFIX: voss remove temperature, power and uptime from diff (@ospfbgp)

## 0.20.0

* FEATURE: gpg support for CSV source (@elmobp)
* FEATURE: slackdiff (@natm)
* FEATURE: gitcrypt output model (@clement-parisot)
* FEATURE: model specific credentials (@davromaniak)
* FEATURE: hierarchical json in http source model
* FEATURE: next-adds-job config toggle (to add new job when ever /next is called)
* FEATURE: netgear model (@aschaber1)
* FEATURE: zhone model (@rfdrake)
* FEATURE: tplink model (@mediumo)
* FEATURE: oneos model (@crami)
* FEATURE: cisco NGA model (@udhos)
* FEATURE: voltaire model (@clement-parisot)
* FEATURE: siklu model (@bdg-robert)
* FEATURE: voss model (@ospfbgp)
* BUGFIX: ios, cumulus, ironware, nxos, fiberdiver, aosw, fortios, comware, procurve, opengear, timos, routeros, junos, asa, aireos, mlnxos, pfsense, saos, powerconnect, firewareos, quantaos

## 0.19.0

* FEATURE: allow setting ssh_keys (not relying on openssh config) (@denvera)
* FEATURE: fujitsupy model (@stokbaek)
* FEATURE: fiberdriver model (@emjemj)
* FEATURE: hpbladesystems model (@flokli)
* FEATURE: planetsgs model (@flokli)
* FEATURE: trango model (@rfdrake)
* FEATURE: casa model (@rfdrake)
* FEATURE: dlink model (@rfdrake)
* FEATURE: hatteras model (@rfdrake)
* FEATURE: ability to ignore SSL certs in http (@laf)
* FEATURE: awsns hooks, publish messages to AWS SNS topics (@natm)
* BUGFIX: pfsense, dnos, powerconnect, ciscosmb, eos, aosw

## 0.18.0

* FEATURE: APC model (by @davromaniak )
* BUGFIX: ironware, aosw
* BUGFIX: interpolate nil, false, true for node vars too

## 0 17.0

* FEATURE: "nil", "false" and "true" in source (e.g. router.db) are interpeted as nil, false, true. Empty is now always considered empty string, instead of in some cases nil and some cases empty string.
* FEATURE: support tftp as input model (@MajesticFalcon)
* FEATURE: add alvarion model (@MajesticFalcon)
* FEATURE: detect if ssh wants password terminal/CLI prompt or not
* FEATURE: node (group, model, username, password) resolution refactoring, supports wider range of use-cases
* BUGFIX: fetch for file output (@danilopopeye)
* BUGFIX: net-ssh version specification
* BUGFIX: routeros, catos, pfsense

## 0.16.3

* FEATURE: pfsense support (by @stokbaek)
* BUGFIX: cumulus prompt not working with default switch configs (by @nertwork)
* BUGFIX: disconnect ssh when prompt wasn't found (by @andir)
* BUGFIX: saos, asa, acos, timos updates, cumulus

## 0.16.2

* BUGFIX: when not using git (by @danilopopeye)
* BUGFIX: screenos update

## 0.16.1

* BUGFIX: unnecessary puts statement removed from git.rb

## 0.16.0

* FEATURE: support Gaia OS devices (by @totosh)
* BUGFIX: #fetch, #version fixes in nodes.rb (by @danilopopeye)
* BUGFIX: procurve

## 0.15.0

* FEATURE: disable periodic collection, only on demand (by Adam Winberg)
* FEATURE: allow disabling ssh exec mode always (mainly for oxidized-script) (by @nickhilliard)
* FEATURE: support mellanox devices (by @ham5ter)
* FEATURE: support firewireos devices (by @alexandre-io)
* FEATURE: support quanta devices (by @f0o)
* FEATURE: support tellabs coriant8800, coriant8600 (by @udhos)
* FEATURE: support brocade6910 (by @cardboardpig)
* BUGFIX: debugging, tests (by @ElvinEfendi)
* BUGFIX: nos, panos, acos, procurve, eos, edgeswitch, aosw, fortios updates

## 0.14.3

* BUGFIX: fix git when using multiple groups without single_repo

## 0.14.2

* BUGFIX: git expand path for all groups
* BUGFIX: git get_version, teletubbies do it again
* BUGFIX: comware, acos, procurve models

## 0.14.1

* BUGFIX: git get_version when groups and single_repo are used

## 0.14.0

* FEATURE: support supermicro swithes (by @funzoneq)
* FEATURE: support catos switches
* BUGFIX: git+groups+singlerepo (by @PANZERBARON)
* BUGFIX: asa, tmos, ironware, ios-xr
* BUGFIX: mandate net-ssh 3.0.x, don't accept 3.1 (numerous issues)

## 0.13.1

* BUGFIX: file permissions (Sigh...)

## 0.13.0

* FEATURE: http post for configs (by @jgroom33)
* FEATURE: support ericsson redbacks (by @roedie)
* FEATURE: support motorola wireless controllers (by @roadie)
* FEATURE: support citrix netscaler (by @roadie)
* FEATURE: support datacom devices (by @danilopopeye)
* FEATURE: support netonix devices
* FEATURE: support specifying ssh cipher and kex (by @roadie)
* FEATURE: rename proxy to ssh_proxy (by @roadie)
* FEATURE: support ssh keys on ssh_proxy (by @awix)
* BUGFIX: various (by @danilopopeye)
* BUGFIX: Node#repo with groups (by @danilopopeye)
* BUGFIX: githubrepohoook (by @danilopopeye)
* BUGFIX: fortios, airos, junos, xos, edgeswitch, nos, tmos, procurve, ipos models

## 0.12.2

* BUGFIX: more MRV model fixes (by @natm)

## 0.12.1

* BUGFIX: set term to vty100
* BUGFIX: MRV model fixes (by @natm)

## 0.12.0

* FEATURE: enhance AOSW (by @mikebryant)
* FEATURE: F5 TMOS support (by @mikebryant)
* FEATURE: Opengear support (by @mikebryant)
* FEATURE: EdgeSwitch support (by @doogieconsulting)
* BUGFIX: rename input debug log files
* BUGFIX: powerconnect model fixes (by @Madpilot0)
* BUGFIX: fortigate model fixes (by @ElvinEfendi)
* BUGFIX: various (by @mikebryant)
* BUGFIX: write SSH debug to file without buffering
* BUGFIX: fix IOS XR prompt handling

## 0.11.0

* FEATURE: ssh proxycommand (by @ElvinEfendi)
* FEATURE: basic auth in HTTP source (by @laf)
* BUGFIX: do not inject string to output before model gets it
* BUGFIX: store pidfile in oxidized root

## 0.10.0

* FEATURE: Various refactoring (by @ElvinEfendi)
* FEATURE: Ciena SOAS support (by @jgroom33)
* FEATURE: support group variables (by @supertylerc)
* BUGFIX: various ((orly))  (by @marnovdm, @danbaugher, @MrRJ45, @asynet, @nickhilliard)

## 0.9.0

* FEATURE: input log now uses devices name as file, instead of string from config (by @skoef)
* FEATURE: Dell Networkign OS (dnos) support (by @erefre)
* BUGFIX: CiscoSMB, powerconnect, comware, xos, ironware, nos fixes

## 0.8.1

* BUGFIX: restore ruby 1.9.3 compatibility

## 0.8.0

* FEATURE: hooks (by @aakso)
* FEATURE: MRV MasterOS support (by @kwibbly)
* FEATURE: EdgeOS support (by @laf)
* FEATURE: FTP input and Zyxel ZynOS support (by @ytti)
* FEATURE: version and diffs API For oxidized-web (by @FlorianDoublet)
* BUGFIX: aosw, ironware, routeros, xos models
* BUGFIX: crash with 0 nodes
* BUGFIX: ssh auth fail without keyboard-interactive
* Full changelog https://github.com/ytti/oxidized/compare/0.7.1...HEAD

## 0.7.0

* FEATURE: support http source (by @laf)
* FEATURE: support Palo Alto PANOS (by @rixxxx)
* BUGFIX:  screenos fixes (by @rixxxx)
* BUGFIX:  allow 'none' auth in ssh (spotted by @SaldoorMike, needed by ciscosmb+aireos)

## 0.6.0

* FEATURE: support cumulus linux (by @FlorianDoublet)
* FEATURE: support HP Comware SMB siwtches (by @sid3windr)
* FEATURE: remove secret additions (by @rodecker)
* FEATURE: option to put all groups in single repo (by @ytti)
* FEATURE: expand path in source: csv: (so that ~/foo/bar works) (by @ytti)
* BUGFIX: screenos fixes (by @rixxxx)
* BUGFIX: ironware fixes (by @FlorianDoublet)
* BUGFIX: powerconnect fixes (by @sid3windr)
* BUGFIX: don't ask interactive password in new net/ssh (by @ytti)

## 0.5.0

* FEATURE: Mikrotik RouterOS model (by @emjemj)
* FEATURE: add support for Cisco VSS (by @MrRJ45)
* BUGFIX: general fixes to powerconnect model (by @MrRJ45)
* BUGFIX: fix initial commit issues with rugged (by @MrRJ45)
* BUGFIX: pager error for old dell powerconnect switches (by @emjemj)
* BUGFIX: logout error for old dell powerconnect switches (by @emjemj)

## 0.4.1

* BUGFIX: handle missing output file (by @brandt)
* BUGFIX: fix passwordless enable on Arista EOS model (by @brandt)

## 0.4.0

* FEATURE: allow setting IP address in addition to name in source (SQL/CSV)
* FEATURE: approximate how long it takes to get node from larger view than 1
* FEATURE: unconditionally start new job if too long has passed since previous start
* FEATURE: add enable to Arista EOS model
* FEATURE: add rugged dependency in gemspec
* FEATURE: log prompt detection failures
* BUGFIX: xos while using telnet (by @fhibler)
* BUGFIX: ironware logout on some models (by @fhibler)
* BUGFIX: allow node to be removed while it is being collected
* BUGFIX: if model returns non string value, return empty string
* BUGFIX: better prompt for Arista EOS model (by @rodecker)
* BUGFIX: improved configuration handling for Arista EOS model (by @rodecker)

## 0.3.0

* FEATURE: *FIXME* bunch of stuff I did for richih, docs needed
* FEATURE: ComWare model (by erJasp)
* FEATURE: Add comment support for router.db file
* FEATURE: Add input debugging and related configuration options
* BUGFIX: Fix ASA model prompt
* BUGFIX: Fix Aruba model display
* BUGFIX: Fix changing output in PowerConnect model

## 0.2.4

* FEATURE: Cisco SMB (Nikola series VxWorks) model by @thetamind
* FEATURE: Extreme Networks XOS model (access by sjm)
* FEATURE: Brocade NOS (Network Operating System) (access by sjm)
* BUGFIX: Match exactly to node[:name] if node[name] is an ip address.

## 0.2.3

* BUGFIX: rescue @ssh.close when far end closes disgracefully (ALU ISAM)
* BUGFIX: bugfixes to models
* FEATURE: Alcatel-Lucent ISAM 7302/7330 model added by @jalmargyyk
* FEATURE: Huawei VRP model added by @jalmargyyk
* FEATURE: Ubiquiti AirOS added by @willglyn
* FEATURE: Support 'input' debug in config, ssh/telnet use it to write session log

## 0.2.2

* BUGFIX: mark node as failure if unknown error is raised

## 0.2.1

* BUGFIX: vars variable resolving for main level vars

## 0.2.0

* FEATURE: Force10 model added by @lysiszegerman
* FEATURE: ScreenOS model added by @lysiszegerman
* FEATURE: FabricOS model added by @thakala
* FEATURE: ASA model added by @thakala
* FEATURE: Vyattamodel added by @thakala
* BUGFIX: Oxidized::String convenience methods for models fixed

## 0.1.1

* BUGFIX: vars needs to return value of r, not value of evaluation
