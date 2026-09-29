---
name: Bug report
about: Create a report to help us improve oxidized
title: ''
labels: bug
assignees: ''

---
<!--
Thanks for helping improve Oxidized!

Please read docs/Issues.md on how to write a good issue:
https://github.com/ytti/oxidized/blob/master/docs/Issues.md
-->

> By submitting content here (especially YAML simulation files), I agree that it
> may be integrated into the project under its license (Apache-2.0).

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Configure '...'
2. Use model '....'
3. Run '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Configuration**
```
If applicable, publish your configuration.
```

**Logs**
```
If applicable, add logs to help explain your problem.
```

**Running environment (please complete the following information):**
<!-- complete the following information and add further details if needed.
Always test the latest version of oxidized.
Tip: run `oxidized --support` as the same user and in the same environment as
the regular Oxidized process. With Docker, use
`docker exec --user oxidized <container-name> oxidized --support`. Remove any
sensitive data before sharing the output. -->
- OS: [e.g. Debian Bookworm, official container version xxx, ...]
- oxidized version: [e.g. 0.32.2]
- oxidized-web version: [e.g. 0.15.1, if applicable]
- Manufacturer model and software version:
- oxidized model name:

**Device simulation (for model-specific issues)**
<!--
If your issue is about a specific device/model, a YAML simulation file helps us
a lot. When the issue can be reproduced with the current Oxidized model
unchanged, the easiest way is to enable the yaml debug option in your input
section:

    input:
      debug: yaml

Reproduce the backup, then attach the generated file from
~/.config/oxidized/logs/. See docs/DeviceSimulation.md for details, and remember
to remove sensitive data (passwords, IP addresses, serial numbers).
-->

**Additional context**
Add any other context about the problem here.
