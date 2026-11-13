# How to release a new version of Oxidized?
This document is targeted at oxidized maintainers. It describes the release process.

## Version numbering
Oxidized versions are numbered like major.minor.patch
- currently, the major version is 0.
- minor is incremented when releasing new features.
- patch is incremented when releasing fixes only.

## Overview
The release is done in two steps, each with its own branch:
1. A review branch, where all the fixes are made. Once it is merged into
   master, GitHub automatically builds a container image, which is used for
   testing.
2. A release branch, which only bumps the version and finalizes the
   CHANGELOG.

## Step 1: Review branch
### Create a review branch
Name the review branch `review-for-0.xx.yy`

### Review changes
Run `git diff 0.30.0` (where `0.30.0` is to be changed to the last release) and review
all the changes that have been done. Have a specific look at changes you don't understand.

For a graphical compare, use `git difftool -d 0.30.0`.

Commit fixes to the review branch

### Update the gem dependencies to the latest versions
```
bundle outdated
bundle update
bundle outdated
```

### Update rubocup .rubocop_todo.yml
Run `bundle exec rubocop --auto-gen-config`,
and make sure `bundle exec rake` passes after it.


### Make sure the file permissions are correct
Run `bundle exec rake chmod`, then `git status`

### Merge the review branch
Upload the branch to github, make a Pull Request for it and make sure it passes
all GitHub CI. Merge it into master.

GitHub automatically builds the container image from master.

## Step 2: Tests
Test the git code (master) and the container image built from master against
as much device types and environments as you can.

If you need to fix something, do it in a new review branch (go back to
Step 1).

## Step 3: Release branch
### Create a release branch
Name the release branch `release/0.xx.yy`

### Bump the version
Update CHANGELOG.md:
- review it
- add release notes
- set the new version (replace `[Unreleased]` with `[0.xx.yy – 202Y-MM-DD]`)

Change the version in `lib/oxidized/version.rb`

Upload the branch to github, make a Pull Request for it.

### Make sure you pass all GitHub CI
They test different ruby versions an run security checks on the code (codeql).

### Prepare the release in your working repository
1. Merge the Pull Request into master with the commit message
   `chore(release): release version 0.3x.y`
2. `git pull` on master
3. Tag the commit with `git tag -a 0.xx.yy -m "Release 0.xx.yy"` or `rake tag`
4. Build the gem with ‘rake build’
5. Run `git diff` to check if there have been more changes (there shouldn't)
6. Install an test the gem locally
```shell
gem install --user-install pkg/oxidized-0.xx.yy.gem
~/.local/share/gem/ruby/3.3.0/bin/oxidized
```

## Step 4: Publish the release
### Release in github
Push the tag to github:
```
git push origin 0.xx.yy
```

Make a release from the tag in github.
- Name the release `0.xx.yy`
- Generate release notes
- Remove `## What's changed`
- Take the release notes from CHANGELOG.md
- List new contributors (generated automatically)
- Keep the Full Changelog (generated automatically)
- Preview
- Publish

Close the corresponding milestone in github.

### Release in rubygems
Push the gem with `rake push`

### Release in docker.io
The OCI-Containter is automatically build and pushed to docker.io by github

### Update CHANGELOG.md for next release
Add
```
## [Unreleased]

### Added

### Changed

### Fixed

```
