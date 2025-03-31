# Oxidized - Contributing Guide
You can contribute to [Oxidized](https://github.com/ytti/oxidized/) in many ways, and first of all we'd like to thank you for taking your time to improve this great project!

> ## Legal Notice
> When submitting content to this project, you must agree that you have authored 100%
> of the content, that you have the necessary rights to the content and that the
> content you contribute may be provided under the project license.
>
> If you are employed, you probably need the permission from your employer to
> contribute to open source projects.


## Contribute as a user
A great place for users to get involved is the [GitHub issues](https://github.com/ytti/oxidized/issues).
Through the issues, you can interact with maintainers and other users. You can open an issue
if you need help, but you can also help other users by reviewing their issues and commenting on them.

Before writing an issue, please read our documentation on
[how to write good issues](/docs/Issues.md).


## Contribute some content
Content contributions are always welcome. You do not need to be a maintainer for this.
You even do not need to be a ruby programmer, as an example, the documentation always needs some
enhancements :-)

Contributions can be submitted through pull requests in github. For a full explanation how to
contribute some content, see [How to contribute content](#how-to-contribute-content).


## Help Needed

As things stand right now, `oxidized` is maintained by a few people. A great
many [contributors](https://github.com/ytti/oxidized/graphs/contributors) have
helped further the software, however contributions are not the same as ongoing
owner- and maintainer-ship. It appears that many companies use the software to
manage their network infrastructure, this is great news! But without additional
help to maintain the software and put out releases, the future of oxidized
might be less bright. The current pace of development and the much needed
refactoring simply are not sustainable if they are to be driven by a few
persons.

## Model maintainers
Oxidized supports more than [150 different devices](docs/Supported-OS-Types.md), and there is no way a person
maintaining the infrastructure code ([Oxidized maintainers](#oxidized-maintainers))
has any ability to have complete understanding of each model and validity of changes upon them.

On the other hand, we have a lot of great users with a detailed understanding of *their*
favorite hardware and a technical background which is plenty sufficient to support
*their*" model in oxidized. The model maintainer role is designed to have a very low
entry barrier, low maintenance burden and needs no long-term commitment.

### Model maintainer tasks
A model maintainer has the following tasks:

* Monitor and comment any model changes in a reasonable time (up to 3 weeks)
* Monitor, comment and fix issues related to the model in a reasonable time (up to 3 weeks)
* Note that Oxidized has a very liberal approach to changes: if someone needed it,
I need good reason to reject it.
* When a model maintainer comments a Pull Request as ready to merge into main,
an [Oxidized maintainer](#oxidized-maintainers) will merge it without any
further checks. If nothing happens, the model maintainer should trigger an Oxidized maintainer directly ;-).
* If there are multiple model maintainers for a model, they should agree among themselves
how they want to collaborate
* Please remove yourself as maintainer, if you no longer wish to respond on changes related to the model. We may remove unresponsive model maintainers, but it is nicer if you let us know.
* If a model maintainer is unresponsive, the person pushing the change may be a good candidate as a new model maintainer ;-)

### How to add / remove yourself as a model maintainer?

The model maintainers are listed in [docs/Supported.OS-Types.md]. Add or remove yourself in the table and push the change to github (pull request). Don't know how? Have a look at [How to contribute content](#how-to-contribute-content).

## Oxidized maintainers
### Become a maintainer for Oxidized
If you would like to be a maintainer for Oxidized then please read through the below and see if it's something you would like to help with. It's not a requirement that you can tick all the boxes below but it helps :)

* Triage on issues, review pull requests and help answer any questions from users.
* Above average knowledge of the Ruby programming language.
* Professional experience with both oxidized and some other config backup tool (like rancid).
* Ability to keep a cool head, and enjoy interaction with end users! :)
* A desire and passion to help drive `oxidized` towards its `1.x.x` stage of life
  * Help refactor the code
  * Rework the core infrastructure
* Permission from your employer to contribute to open source projects

### YES, I WANT TO HELP
Awesome! Simply send an e-mail to Saku Ytti at <saku@ytti.fi>.

### Further reading
Brian Anderson (from Rust fame) wrote an [excellent
post](http://brson.github.io/2017/04/05/minimally-nice-maintainer) on what it
means to be a maintainer.

### Current maintainers
Current active maintainer of Oxidized are:
* Saku Ytti (@ytti) - he is the original author of Oxidized
* Alexander Schaber (@aschaber1)
* Robert Chéramy (@robertcheramy)


## How to contribute content
Content can be code, but also documentation and other things.

### Fork the repository
Fork this repository to your GitHub account by clicking the "Fork" button at the top right. This creates a personal copy of the project you can work on.

### Clone your fork
Clone your forked repository to your local machine using the `git clone` command:
```bash
git clone git@github.com:##yourname##/oxidized.git
```

### Create a new branch
Create a new branch for your contribution. Choose a concise name for your branch. If your contribution refers to an issue, you may prepend the number of the issue to the branch name.
```bash
git checkout -b 1234-your-branch-name
```

### Create a ruby bundle
You need [Bundler](https://bundler.io/) to install ruby dependencies locally. If it is not already
installed on your system, it should be prepackaged in your favorite Linux or
Ruby distribution. On Debian Bookworm, you can install Bundler with `sudo apt install ruby-bundler`

```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

Note: if you need to install rugged with ssh support, you can tell bundler so with `bundle config build.rugged --with-ssh`. Reinstall rugged with `bundle pristine rugged`

### Run your code
```bash
bundle exec bin/oxidized
```

### Use a custom oxidized configuration
If you don't want to use the configuration under `~/.config/oxidized/`, you can set the path to your specific configuration with the environement variable `OXIDIZED_HOME': `export OXIDIZED_HOME=~/oxidized-config/`.

### Code like a ruby professional
rubocop will help you to respect our coding conventions (which are ruby coding conventions).
```bash
bundle exec rubocop
```

### Run tests
Oxidized has integrated tests, that should be run before submitting your work.
```bash
bundle exec rake test
```

### Commit your work
You can save your changes anytime to the branch. These changes are saved locally and not pushed upstream:
```bash
git status
git diff
git add <changed files here>
git commit
```
You can also use a git GUI like [Git Cola](https://git-cola.github.io/) for a better overview of your changes.

The commits will be seen in the pull request, so be concise and remember that someone will try to
understand what you have done.

### Push your work to your github repository
With this step, your commits will be seen on github. You are pushing the branch you created before (in this example 1234-your-branch-name`) into your fork of Oxidized.

```bash
git push -u origin 1234-your-branch-name
```

You can push as often as you wish. If you already opened a pull request, your pushed commits will automatically get updated there.

### Open a pull request
Go to your github repository, and github will propose to create a pull request
and will guide you.

We are happy that you are contributing to Oxidized. If something is not as it
should be, a maintainer will probably ask you to change it when reviewing the
pull request. And if your pull request breaks something, this can be fixed, so
don't be shy, submit your code ;-)

Note: if the github CI fail on your pull request, fix the problems.
A pull request with failed CI won't be merged into master, so maintainers may
only review pull requests that have passed the CIs.

### Delete the branch from your repository
When the pull request has been merged into main, github will ask if you want to delete your branch. Clean up and delete it, so that you can keep your fork clean and ready for new contributions.

## One last word
Have fun, and don't forget to congratulate yourself for your great contribution to [Oxidized](https://github.com/ytti/oxidized/)!
