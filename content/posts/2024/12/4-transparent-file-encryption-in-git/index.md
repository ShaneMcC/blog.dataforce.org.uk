---
title: "Transparent file encryption in git"
author: Dataforce
url:  /2024/12/transparent-file-encryption-in-git/
image: git.png
description: Transparently encrypting files in git
type: post
date: 2024-12-04T11:41:47Z
category:
  - Code
  - Git
---

I've blogged [before](/2018/08/advent-of-code-benchmarking/) about [Advent of Code](https://adventofcode.com/) and how I've been doing it each year since it began in 2015 and wrote a benchmarking tool for it - [AoCBench](https://github.com/shanemcc/aocbench).

A few years ago when I first wrote AoCBench, there was limited formal guidelines from Eric with regards to repo content, specifically, the closest thing to "offical" guidelines for commiting inputs to repos was a couple of social media posts that essentially stated that it was fine, but just don't go collecting them all:

> In general I ask people not to publish their inputs, just to make it harder for someone to try to steal the whole site. The answer is probably fine, but also probably not very interesting since they vary per person.
>
> -- <cite>https://x.com/ericwastl/status/1465805354214830081</cite>

> I don't mind having a few of the inputs posted, please don't go on a quest to collect many or all of the inputs for every puzzle. Doing so makes it that much easier for someone to clone and steal the whole site. I put tons of time and money into Advent of Code, and the many inputs are one way I prevent people from copying the content.
>
> -- <cite>https://www.reddit.com/r/adventofcode/comments/7lesj5/comment/drlt9am/</cite>

And also [other comments](https://www.reddit.com/r/adventofcode/comments/e7khy8/comment/fa13hb9/) where it wasn't actively discouraged, but preferred not to.

So AoCBench was designed around all the participants including their own inputs in the repo and this allowed nice things like testing of solutions against different inputs to ensure validity (something you otherwise can't really do.)

However sometime last year shortly after the start of the month this policy changed ([Before](https://web.archive.org/web/20231203054710/https://adventofcode.com/about) / [After](https://web.archive.org/web/20231206142838/https://adventofcode.com/about)) and an explicit request was added to the site not to:

> If you're posting a code repository somewhere, please don't include parts of Advent of Code like the puzzle text or your inputs.

This policy was also codified on the official [subreddit](https://reddit.com/r/adventofcode) and moderators (and other users) started actively (and often aggressively) checking the repos of anyone who posted and insisting they immediately remove any inputs (and purge them from git history) and sometimes resulting in users being banned for not complying. This also hurt a bit with debugging solutions where sometimes different inputs have different properties that may trip some people up.

I don't want to get too much into any legal technicalities around this and if the inputs are or aren't copyrightable, or how it has been handled and the negatives around it. I just want to continue enjoying Advent of Code each year with my friends and our benchmarking tool, and if I can respect the request then I'll do that as well.

For the first year (last year) we continued as-is, but this year people using AoCBench felt stronger about not including inputs in the repos. So how can we do this?

<!--more-->

The first thought that came to mind was to just stick the inputs in a separate (private) git repo and AoCBench could pull from that.

This approach is easy on the surface, but has a number of problems:

1) Submodules really suck - you now have to remember to commit the data to the new submodule, and then update the submodule in the parent repo (unless you use `--remote`)
2) This requires that AoCBench has a user account on each platform (Mainly because github is dumb and makes deploykeys unique across the entire site.)
3) When a user is added to a repo on github, the user has to confirm they want access to the repo, which is a lot more annoying for me
4) This probably scales badly to non-github/gitlab repos. I don't want to have an account everywhere.

Even with these flaws, this was the approach taken by the first few people who wished to hide their inputs.

But after implementing support for it for AoCBench, I was unconvinced by it for my own repo, so I looked for alternatives. My first thought was something like [ansible-vault](https://docs.ansible.com/ansible/latest/vault_guide/index.html#encrypting-unencrypted-files) would do the trick but I imagined a number of problems with it. I could handle decryption within AoCBench just fine, but then it becomes fiddly to use from a repo point of view. You'd have to make sure you only commited encrypted versions of files and that would make locally-running things more annoying.

I found an old [blog post](https://leucos.github.io/articles/transparent-vault-revisited/) around using git's smudge/clean filters along with vault, but this was very manual, but also as pointed out on [stackoverflow](https://stackoverflow.com/questions/37660094/git-clean-smudge-filters-for-ansible-vault-secrets) prone to a problem in that vault's encryption is not idempotent, the file changes each time so git thinks it changed. No Good.

The next thing I discovered was [git-crypt](https://github.com/AGWA/git-crypt). This works with clean/smudge filters as well, and seemed almost perfect but one thing that really irked me about it was that it uses GPG Keys for giving access to repos (or passing around a non-ascii key file) and I hated the idea of creating and managing an AoCBench GPG key even more than having to create dedicated accounts on github/gitlab. So I ignored this option for now (I'm not ruling out using it in future, but please no)

The next one I discovered was [transcrypt](https://github.com/elasticdog/transcrypt) - this seemed to work like I wanted. It works the same way as the previous one, but files are encrypted/decrypted using an ascii key (that I can store in my AoCBench config) rather using a gpg key and everything happens mostly transparently. Lets give this a try.

Firstly, [installing it is easy](https://github.com/elasticdog/transcrypt/blob/main/INSTALL.md), checkout the git repo, then symlink it into your PATH:

```sh
git clone https://github.com/elasticdog/transcrypt.git
cd transcrypt/
sudo ln -s ${PWD}/transcrypt /bin/transcrypt
```

One thing I also reccomend at this point is cherry-picking a few commits from the `suppress-openssl-pbkdf2-warnings` [branch](https://github.com/elasticdog/transcrypt/compare/main...suppress-openssl-pbkdf2-warnings):

```sh
git cherry-pick 01d79239ce5974b0e8b0fa093557635b69ce1b0a
git cherry-pick 4dca9c2934e63886072ed339f69138295af247cd
```

Without this, a bunch of warnings happen any time it is invoked to encrypt/decrypt a file:

```
*** WARNING : deprecated key derivation used.
Using -iter or -pbkdf2 would be better.
```

These might be a problem in some environments, but for my use case this is fine. They are also [working on fixing this](https://github.com/elasticdog/transcrypt/pull/162) but development has stalled a bit on that front. This works for now.


The next step is to then encrypt a repo (I recommend taking a backup copy of the repo before doing this so that it's easier to revert if anything goes wrong by just force-pushing it back), this is easy, we can go into the repo and run a simple command:
```sh
$ transcrypt -p 'some password' -y
The repository has been successfully configured by transcrypt.
$
```

But this doesn't actually encrypt any files yet, we tell it which files to encrypt by using `.gitattributes`, so we can encrypt our input files like so:

```sh
echo "*/input.txt  filter=crypt diff=crypt merge=crypt" >> .gitattributes
```

And if we commited this, then this will work fine... from then onwards, but it's day 4 - we have git history from the last 4 days that will include the data we're trying not to include, can we fix that?

Since the change, the AOC subreddit has a number of posts on it this year and last year with people helpfully telling everyone else how to clear out the files from the repo using [git-filter-branch](http://www.kernel.org/pub/software/scm/git/docs/git-filter-branch.html) or [git-filter-repo](https://github.com/newren/git-filter-repo). We could delete the files, then add them freshly-encrypted. But that messes with the flow of the repo and causes it to be weirdly input-less from Day 1-4.

Instead, we can use `git filter-branch` and edit all of our previous commits to encrypt the files as if they were encrypted all along!

Assuming that you've never had a `.gitattributes` file until now then the following will encrypt all the `input.txt` files in a repo from the beginning (This will need modified if you have other files you wish to encrypt or have had an existing .gitattributes file)

```sh
rm .gitattributes
git filter-branch --tree-filter 'if [ ! -e .gitattributes ]; then echo "*/input.txt  filter=crypt diff=crypt merge=crypt" >> .gitattributes; fi; for file in $(bash -c "ls */input.txt"); do if [ -e ${file} ]; then git rm --cached -- ${file} && git add -- ${file}; fi; done'
```

Then the repo can be force-pushed back upstream:

```sh
git push --force origin
```

After doing this, you'll see that the file is now encrypted on the upstream repo, but locally the files are still plain and useable as normal.

We can also still use this repo on other machines, we just need to re-run the `transcrypt -p` command after we first check the repo out, here we can see how this looks:

```sh
$ head -n 3 1/input.txt
U2FsdGVkX18hTX6ugrpokGoHJy0GtfWkPABh02fvfpHMH13LAXcYzsCTEmFGhNbU
QuYNuSvrBrbVfyG6LKdr7Q8Tx46jwR1ikWTz6d+rO6h5eoyV1fDHQhv1g0+ohoaR
CFfiMq5SxjRRTll0v1YI80FpCO1aoWVyDCqNNHwh50XKFgdCUQnrcN6c37G2zfsV
$ transcrypt -p 'some password' -y
The repository has been successfully configured by transcrypt.
$ head -n 3 1/input.txt
37033   48086
80098   34930
88073   69183
$
```

It is also possible to undo this, we can do a similar filter-branch command as before to revert it. (This again assumes there is nothing else of worth in `.gitattributes`) - and will require the `sponge` command from `moreutils` to work:

```sh
git filter-branch --tree-filter 'if [ -e .gitattributes ]; then rm .gitattributes; fi;' -f
git filter-branch --tree-filter 'for file in $(bash -c "ls */input.txt"); do if [ -e ${file} ]; then git rm --cached -- ${file} && cat ${file} | transcrypt smudge context=default | sponge ${file} && git add -- ${file}; fi; done' -f
git push origin --force
```

This essentially reverses the previous filter-branch command. It seems to need to run in 2 passes to be reliable, I assume this is to ensure that the `.gitattributes` file is gone from everywhere to stop it cleaning it again after we smudge it.

and once you have confirmed that the upstream is now decrypted, you can remove the transcrypt config:
```sh
transcrypt --flush-credentials
```

Since this seemed to behave as expected, I've also added for support for this into AoCBench


If you did want to use `git-crypt` instead, then the initial `filter-branch` command should work with a modification to what gets added into the `.gitattributes` file - but I've not yet tested a working revert.
