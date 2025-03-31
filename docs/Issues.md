# Writing good issues
If you're experiencing a problem with Oxidized or need a new feature, you can
[submit an issue on github](https://github.com/ytti/oxidized/issues). We have
a great community where users help each other through the issue system.

This guide provides tips on writing your issue to make it easier for the
community and developers to understand and respond effectively.

Why write good issues?
- A clear and detailed issue improves the chances of getting your problem
  resolved.
- By spending time to write a good issue, you save developers time, contributing
  to Oxidized’s progress without writing a line of code.

## Rules
The project receives too many incomplete issues, unnecessarily taking time that
could be invested in new code. Therefore, issues will be worked on with the
following rules:

- Use the predefined templates for bugs, feature requests and support requests.
- If you don't provide the necessary information (read this file, fill in the
  questions in the templates), expect your issue to be closed without a comment.
- Inactive issues will be marked "stale" automatically after 90 days. Issues
  are not closed automatically; this is a manual action by a maintainer.
- A feature request may be closed after some time of inactivity, as obviously
  no one has found the time to implement it. Consider contributing code in a
  Pull Request instead.
- While it is OK to ask for help (using the support request template), don't be
  disappointed if no one finds the time to answer your question. Stale questions
  (after 90 days) will be closed without a comment.

## Submit to the correct project
Choose the appropriate GitHub project based on your issue:

- For issues with the web frontend or REST API, go to
  [oxidized-web](https://github.com/ytti/oxidized-web/).
- For issues with oxidized-script, use
  [oxidized-script](https://github.com/ytti/oxidized-script). (note: as of
  November 2024, oxidized-script is not actively maintained).
- For issues with third-party software relying on Oxidized, open an issue in
  that specific project.
- For issues with Oxidized itself, go to
  [oxidized](https://github.com/ytti/oxidized).

## Use the latest version
If you are using an old version of oxidized, you may encounter issues that have
been solved. No support will be provided for older versions of oxidized.

If you can, please also test against the latest git version, or at least read
[CHANGELOG.md](/CHANGELOG.md) to see if your problem has been solved on master.

## Format your issue
- Use [GitHub Markdown](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) to format your issue.
- Preview your text before submitting to ensure it renders correctly.
- Avoid screenshots of text. Instead, use [code formating](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#quoting-code) for any relevant code snippets.

## Choose your title well
Keep the title brief yet descriptive. Aim to summarize the main issue or request in a few words.

## Provide detailled informations
Include as many relevant details as possible. At a minimum, specify:

- Oxidized version and operating system.
- Which model (oxidized name AND Manufacturer name) is the issue about.
- Relevant parts of your Oxidized configuration and a brief explanation of your setup.
- Output of the error, if relevant.
- For issues related to specific devices, consider creating a YAML Simulation file (instructions below).

Also, provide clear steps to reproduce the issue, if applicable.

## Making feature requests
Feature requests are welcome, but please understand that unaddressed requests
may be closed after some time. If you need a feature urgently, consider
contributing code via a pull request (PR) or hiring a developer.

## Sumbit a YAML Simulation File
To help developers troubleshoot device-specific issues, you may be asked to submit a
[YAML simulation file](/docs/DeviceSimulation.md#creating-a-yaml-file-with-device2yamlrb) for your device.

Here's a brief overview how to do it, you can find more details in the link
above.
- Fork Oxidized on github
- Install dependencies (git and Ruby's Net::SSH):
```
# Adapt when not using a debian-based distro
sudo apt install git ruby-net-ssh
```
- Clone your forked Oxidized repository:
```
git clone git@github.com:<your github user>/oxidized.git
```
- run the `extra/device2yaml.rb` script (you’ll be provided with the command to
run) from the repository root:

```
extra/device2yaml.rb oxidized@r61 -c "terminal length 0
terminal width 0
show version
show vtp status
show inventory
show running-config
exit" -o spec/model/data/ios:C8200L_16.12.1:simulation.yaml
```

- The script waits 5 seconds between commands, and outputs the response of the
  device. You can press "ESC" if you see the prompt and want to pass to next
  command without waiting for the timeout.
- The result will be stored in `spec/model/data/`.
- Replace any sensitive information with placeholder values in the output file.
- Commit & push the file to github
```
git add spec/model/data/ios:C8200L_16.12.1:simulation.yaml
git commit -m "Device simulation for C8200L"
git push
```
- Create a pull request (PR) in GitHub, referencing the issue number (e.g.,
  "YAML simulation file for issue #1234").






