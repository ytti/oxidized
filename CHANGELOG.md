# 0.2.3
- BUGFIX: rescue @ssh.close when far end closes disgracefully (ALU ISAM)
- FEATURE: Alcatel-Lucent ISAM 7302/7330 model added by @jalmargyyk
- FEATURE: Huawei VRP model added by @jalmargyyk
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
