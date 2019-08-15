florist
=======

Release and package stuff from a ROS project.

# Q. What is this?

It's a couple of ~~hacks~~ scripts that automate the drudgery of blooming,
building, and packaging (for debian) a given ROS project.

# Q. What's ROS?

[ROS][ros] is the robot operating system. In the ROS world, every package is a
little [cmake][cmake] project (with sundry other bits that are beyond this
discussion). To distribute your ROS-flavored thing in a way that pleases the
OSRF oligarchy, you need to release, build, and package it with ~~abhorrent~~
special ROS tools.

# Q. What tools?

[`bloom`][wiki-bloom] is the one that figures most prominently.

> Bloom is a release automation tool, designed to make generating platform
> specific release artifacts from source projects easier. Bloom is designed to
> work best with catkin projects, but can also accommodate other types of
> projects.

--- http://bloom.readthedocs.io

Yes, it's _designed_ to make package-building easier but falls far short of
that lofty goal. It's finicky, slow, and actively hostile to package
maintainers; more on that later.

At any rate, [project bloom][project-bloom] provides a `bloom-release`
tool. `bloom-release` takes an "upstream" and produces a "release". You don't
get any of this for free, mind you; there are strict constraints on what can be
"bloomed" and doing it for a "fresh" package (one for which the corresponding
`-release` repository does not yet exist) is a *lot* of preparatory work. The
[first time][first-time] always hurts.

# Q. What's this "upstream"?

The thing holding the source code of interest; i.e., the ROS project you want
released as a package --- or, more often, several packages. As of this writing,
the `bloom-release` tool [can support][first-time-config] an "Upstream URI" in
one of four forms:

    Upstream VCS Type:
      svn
        URI is a svn repository
      git
        Upstream URI is a git repository
      hg
        Upstream URI is a hg repository
      tar
        Upstream URI is a tarball
      ['git']:

The default, `git`, works really well --- as long as you don't use [`git
submodule`][git-submodule] and/or [`git lfs`][git-lfs]. Because non-trivial
software projects often rely on submodules and LFS, this document hereafter
assumes the Upstream URI references a tarball. By "tarball", what the `bloom`
maintainers [specifically mean][targz-specifically] is a `gzip`-compressed
`tar`-archive with a `.tar.gz` file extension.

> This repository can be hosted anywhere (even locally) and can be ... an
> archive (tar.gz only for now, but there are plans for tar.bz and zip).

--- https://wiki.ros.org/bloom/Tutorials/FirstTimeRelease#Preparing_for_Release

Yep, can't wait for that forthcoming support for `tar.bzip` and `zip`. At any
rate, to play nice with `bloom-release`, your upstream needs to come correct
*vis-a-vis* ROS standards. Your `CMakeLists.txt` and `package.xml` files have
to be tightly disciplined and the whole thing must build and test cleanly ---
preferrably with `catkin`.

[git-submodule]:https://git-scm.com/book/en/v2/Git-Tools-Submodules
[git-lfs]:https://git-lfs.github.com/
[targz-specifically]:https://github.com/ros-infrastructure/bloom/commit/b3f59bfc03e00806451ad2b054819291a45844f2#diff-43085dccbe9f83cd09c4636a5543faacR288


# Q. What's this "release"?

The release repository is embodiment for every release (thus far) of the
upstream repository. It's usually a [**bare** git repository][git-init-bare]
with an embarrassingly large quantity of branches, each named for:

* packaging methodology (e.g., `rpm`, `debian`)
* ROS distribution (e.g., `indigo`, `kinetic`, `melodic`)
* operating system distribution (e.g., `trusty`, `xenial`, `bionic`)
* package name (e.g., `ros_comm`, `sns_ik`, `orocos_kdl`)

Within the given git repository ~~victim~~ destination, `bloom-release` will
produce a branch for each element of the _cartesian expansion_ of the
aforementioned attributes.

Worse still, for a given package, every _sub-project_ gets its own branch,
too. For example, if you've bloomed [`sns_ik`][gh-sns-ik] for ROS `indigo` to
produce `sns_ik-release`, then the latter will contain the following branches:

* `debian/indigo/trusty/sns_ik`
* `debian/indigo/trusty/sns_ik_examples`
* `debian/indigo/trusty/sns_ik_kinematics_plugin`
* `debian/indigo/trusty/sns_ik_lib`

The result is a teeming plague of branches writhing over the `git log --all
--graph --oneline` output, not unlike an infestation of maggots burrowing
through a week-old roadkill.

[git-init-bare]:https://git-scm.com/docs/git-init#Documentation/git-init.txt---bare
[gh-sns-ik]:https://github.com/RethinkRobotics-opensource/sns_ik

# Q. How do I make a release repository?

Use the `origtar2bloom` script in this project.

    $ ./origtar2bloom -h
    Usage: ./origtar2bloom [OPTION]... ORIG_TARBALL
    Bloom the given ORIG_TARBALL into a local bare git release repository.
    
    Options
        -h                 print this usage and return success
        -C RELEASE_BARE    bloom into RELEASE_BARE (default: ${ORIG_TARBALL%.orig.tar*}.git)
        -R ROS_DISTRO      bloom for ROS_DISTRO (default: kinetic)
        -P PACKAGE_NAME    override package name (default: ${ORIG_TARBALL%%_*})
        -V FAKE_VERSION    override fake version (default: $(echo ${ORIG_TARBALL} | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'))
    
    Examples:
    
        $ ./origtar2bloom rapidplan_0.1.2-118-gd75c1a7.orig.tar.gz
    
        $ ./origtar2bloom \
        >      -C rapidplan-release_0.1.2-118-gd75c1a7.git \
        >      rapidplan_0.1.2-118-gd75c1a7.orig.tar.gz
    
        $ ./origtar2bloom \
        >      -C rapidplan-release_0.1.2-118-gd75c1a7.git \
        >      -R kinetic \
        >      rapidplan_0.1.2-118-gd75c1a7.orig.tar.gz
    
        $ ./origtar2bloom \
        >      -C rapidplan-release_0.1.2-118-gd75c1a7.git \
        >      -R kinetic \
        >      -V 0.1.2 \
        >      rapidplan_0.1.2-118-gd75c1a7.orig.tar.gz

# Q. How do I make debian artifacts?

Use the `bloom2debs` script in this project.

    $ ./bloom2debs -h
    Usage: ./bloom2debs [OPTION]... [CATKIN_PKG]...
    Build debian package artifacts from a local "release".
    
    Options
        -h                 print this usage and return success
        -l                 list catkin packages in build order
        -U                 unsafe, sacrifice isolation to go faster
        -C RELEASE_BARE    run as if started in RELEASE_BARE (default: $PWD)
        -D DISTRIBUTION    override distribution (default: inferred from RELEASE_BARE)
        -R ROS_DISTRO      override ros_distro (default: inferred from RELEASE_BARE)
        -V NEW_VERSION     override the bloom-release version (default: inferred from RELEASE_BARE)
    
    Notes:
    
        RELEASE_BARE must be a valid git work tree directory and must contain
        branches of the form
    
            "debian/${ROS_DISTRO}/${DISTRIBUTION}/${DEBIAN_PKG}"
    
        Examples:
    
            * debian/kinetic/xenial/ros_comm
            * debian/kinetic/xenial/sns_ik
            * debian/melodic/bionic/orocos_kdl
    
        Debian artifacts will be produced in /home/neil/code/florist
    
    Examples:
    
        $ ./bloom2debs -C rapidplan_1.1.0-237-ge3abac7.git
    
        $ ./bloom2debs -U -C rapidplan_1.1.0-237-ge3abac7.git

[ros]:http://www.ros.org
[cmake]:https://cmake.org
[wiki-bloom]:http://wiki.ros.org/bloom
[project-bloom]:https://pypi.org/project/bloom
[first-time]:http://wiki.ros.org/bloom/Tutorials/FirstTimeRelease
[first-time-config]:https://wiki.ros.org/bloom/Tutorials/FirstTimeRelease#Configure_a_Release_Track
