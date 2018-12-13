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

-- http://bloom.readthedocs.io

Yes, it's _designed_ to make package-building easier but falls far short of
that lofty goal. It's finicky, slow, and actively hostile to package
maintainers; more on that later.

At any rate, [project bloom][project-bloom] provides a `bloom-release` tool
that eats an "upstream" ROS project and produces a "release" git
repository. You don't get any of this for free, mind you; there are strict
constraints on what can be "bloomed" and doing it for a "fresh" package (one
for which the corresponding `-release` repository does not yet exist) is a
*lot* of preparatory work. The [first time][first-time] always hurts.

# Q. What's this "upstream repository"?

The thing holding the source code of interest; i.e., the ROS project you want
released and packaged. It usually lives in git, but I've heard you can also use
subversion and even tarballs. To play nice with `bloom-release`, the upstream
project needs to come correct *vis-a-vis* ROS standards -- your
`CMakeLists.txt` and `package.xml` files have to be tightly disciplined and the
whole thing must build and test cleanly.

# Q. What's this "release repository"?

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
--graph --oneline`, not unlike an infestation of maggots burrowing through
week-old roadkill.

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
