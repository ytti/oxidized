# How to release a new version of Oxidized?
This document is targeted at oxidized maintainers. It describes the release process.

## Review changes
Run `git diff 0.30.0..master` (where `0.30.0` is to be changed to the last release) and review
all the changes that have been done. Have a specific look at changes you don't understand.

For a graphical compare, use `git difftool -d 0.30.0..master`.

## Test, test test!
Test the git code and the container against as much device types an environments as you can.

Do not integrate late PRs into master if they do not fix issues for the release. The must wait for the next release.

## Version numbering
Oxidized versions are nummered like major.minor.patch
- currently, the major version is 0.
- minor is incremented when releasing new features.
- patch is incremented when releasing fixes only.

## Prepare the release in your working repository
1. Checkout the master branch of oxidized. Make sure you are up to date with origin.
2. Change the version in lib/oxidized/version.rb
3. Change CHANGELOG.md to replace [Unreleased] with [0.xx.yy – 202Y-MM-DD]
4. Run `git diff` to check your changes
5. Commit the changes to the local git repository with a commit message “chore(release): release version 0.xx.yy”
6. Tag the commit with `git tag -a 0.xx.yy -m "Release 0.xx.yy"`
7. Build the gem with ‘rake build’
8. Run `git diff` to check if there have been more changes (there shouldn't)
9. Install an test the gem locally
```
gem install --user-install pkg/oxidized-0.30.0.gem
~/.local/share/gem/ruby/3.1.0/bin/oxidized
```

## Release in github
Push the change and the tag to github:
```
git push
git push origin 0.xx.yy
```

Make a release from the tag in github
- Thank the contributors
- Only describe major changes, and refer to CHANGELOG.md
- List new contributors (generated automatically)

## Release in rubygems
Push the gem with ‘rake push’

## Release in docker.io
The OCI-Containter is automatically build and pushed to docker.io by github

## Update CHANGELOG.md for next release
Add
```
## [Unreleased]

### Added

### Changed

### Fixed

```
