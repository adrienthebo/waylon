# waylon
Waylon is a dashboard to display the status of your Jenkins builds.

  * Project page: http://rogerignazio.com/projects/waylon
  * Source code: https://github.com/rji/waylon

## Overview
  * Displays only the desired jobs from multiple Jenkins instances
  * Displays failures above successes, and both in alphabetical order
  * "Nirvana mode" displays a calming image of Oregon if all your jobs were
  successful

## Setup
Clone the repo:

```
git clone https://github.com/rji/waylon
```

Modify `waylon_config.yml` to point to your Jenkins install, and enter any
job names that you wish to display. For Puppet Labs, this might be:

```yaml
jobs:
    - https://jenkins.puppetlabs.com:
        - Facter-Specs-master
        - Hiera-Specs-master
        - Puppet-Specs-master
```

## Deploy
You can deploy locally, on your LAN, or if you have a public Jenkins instance,
push the whole thing to Heroku. If deployed locally, the application will make
use of the Thin webserver, and run on port 9292 (by default).

```
$ bundle exec rackup
Thin web server (v1.6.2 codename Doc Brown)
Maximum connections set to 1024
Listening on 0.0.0.0:9292, CTRL+C to stop
```

## Credits
This application makes use of and/or re-distributes the following open source
software:
  * [Sinatra](http://www.sinatrarb.com)
  * [Bootstrap](http://getbootstrap.com)
  * [JQuery](http://jquery.com)
  * [jenkins_api_client](https://github.com/arangamani/jenkins_api_client)

This application also includes the following images that were released under
[Creative Commons Attribution (CC BY)](http://creativecommons.org/licenses/)
licenses:
  * [Day 105: Oregon Coast Range](https://www.flickr.com/photos/lorenkerns/8651732785) by Loren Kerns
  * [Mt. Hood, Oregon](https://www.flickr.com/photos/tsaiproject/9943809254) by tsaiproject
  * [Multnomah Falls](https://www.flickr.com/photos/johnniewalker/12660211844) by John Tregoning
  * [101_1812](https://www.flickr.com/photos/randall-booth/9060319329) by Randall Booth
  * [Central Oregon Landscape](https://www.flickr.com/photos/ex_magician/3196286183) by Michael McCullough
  * [Oregon Autumn Part 4](https://www.flickr.com/photos/31246066@N04/4030400633) by Ian Sane
  * [Astoria, Oregon](https://www.flickr.com/photos/goingslo/11522920406) by Linda Tanner
