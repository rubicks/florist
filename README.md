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

# Q. What's this "release"?

The release repository is embodiment for every release (thus far) of the
upstream repository. It's usually a git repository with an embarrassingly large
quantity of branches, each named for:

* packaging methodology (e.g., `rpm`, `debian`)
* ROS distribution (e.g., `indigo`, `kinetic`, `melodic`)
* operating system distribution (e.g., `trusty`, `xenial`, `bionic`)
* package name (e.g., `ros_comm`, `sns_ik`, `orocos_kdl`)

Within the given git repository ~~victim~~ destination, `bloom-release` will
produce a branch for each member of the cartesian expansion of the
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

[gh-sns-ik]:https://github.com/RethinkRobotics-opensource/sns_ik

# Q. How do I make a release repository?

Use the `upstream2bloom` script in this project.

    $ ./upstream2bloom -h
    Usage: upstream2bloom [OPTION]... UPSTREAM_URI
    Bloom the given UPSTREAM_URI into a local directory.

    Options
        -h               print this usage and return success
        -C DIR           run as if started in DIR (default: temporary directory)
        -R ROS_DISTRO    bloom the given ROS distribution (default: indigo)

    Example:
        upstream2bloom -C ~/code/ros_comm-release https://github.com/RethinkRobotics-opensource/ros_comm.git

# Q. How do I make debian artifacts?

Use the `bloom2deb` script in this project.

    $ ./bloom2deb -h
    Usage: bloom2deb [OPTION]... [-- [buildpackage option]...]
    Build debian package artifacts from local bloomed RELEASE_DIR.

    Options
        -h                print this usage and return success
        -C RELEASE_DIR    run as if started in RELEASE_DIR (default: $PWD)

    Notes:

        RELEASE_DIR must be a valid git checkout directory and the current branch
        name must be of the form

            "debian/${ROS_DISTRO}/${DISTRIBUTION}/${PACKAGE_NAME}"

        Examples:

            * debian/indigo/trusty/ros_comm
            * debian/kinetic/xenial/sns_ik
            * debian/melodic/bionic/orocos_kdl

    Example:
        bloom2deb -C ~/code/ros_comm-release -- --source-option=-Dvcs-ref=1.11.8

# Q. How do I bloom and package everything at once?

Use the `upstream2deb` script in this project; it wraps invocations to
`upstream2bloom` and `bloom2deb`. A word of warning: you may not want some the
assumed defaults.

    Usage: upstream2deb [OPTION]... UPSTREAM_URI
    Bloom the given UPSTREAM_URI into local directory (bare git repository).

    Options
        -h                          print this usage and return success
        -D DISTRIBUTION             ubuntu distribution codename (default: trusty)
        -R ROS_DISTRO               bloom the given ROS distribution (default: indigo)
        -b UPSTREAM_DEVEL_BRANCH    upstream devel branch (default: ${ROS_DISTRO}-devel)
        -V UPSTREAM_VERSION         upstream version (default: :{auto})

    Examples:
        $ upstream2deb \
        >     -b indigo-rethink \
        >     https://github.com/RethinkRobotics-opensource/ros_comm.git
        $ upstream2deb \
        >     -D trusty \
        >     -R indigo \
        >     -b indigo-devel \
        >     -V 0.2.1 \
        >     https://github.com/RethinkRobotics-opensource/sns_ik.git


[ros]:http://www.ros.org
[cmake]:https://cmake.org
[wiki-bloom]:http://wiki.ros.org/bloom
[project-bloom]:https://pypi.org/project/bloom
[first-time]:http://wiki.ros.org/bloom/Tutorials/FirstTimeRelease
[first-time-config]:https://wiki.ros.org/bloom/Tutorials/FirstTimeRelease#Configure_a_Release_Track
[git-submodule]:https://git-scm.com/book/en/v2/Git-Tools-Submodules
[git-lfs]:https://git-lfs.github.com/
[targz-specifically]:https://github.com/ros-infrastructure/bloom/commit/b3f59bfc03e00806451ad2b054819291a45844f2#diff-43085dccbe9f83cd09c4636a5543faacR288
