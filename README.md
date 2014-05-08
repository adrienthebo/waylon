# waylon
Waylon is a dashboard to display the status of your Jenkins builds.

  * Project page: http://rogerignazio.com/projects/waylon
  * Source code: https://github.com/rji/waylon

## Overview
  * Displays only the desired jobs from one or more Jenkins instances
  * Displays build stability for each job (sunny, cloudy, raining)
  * Groups jobs by building, failed, and successful, and displays job counts for each
  * Mark a failed build as 'under investigation' (requires the
  [description-setter](https://wiki.jenkins-ci.org/display/JENKINS/Description+Setter+Plugin)
  plugin)
  * Multiple views allows for multiple teams to utilize a single Waylon install
  * Nirvana mode displays a calming image of Oregon if all your jobs are green

## Setup
Clone the repo:

```
git clone https://github.com/rji/waylon
```

Modify `waylon_config.yml` to point to your Jenkins install, and enter any
job names that you wish to display. For the most part, it's self-explanatory,
but here's an example for a few of [Puppet Labs](http://www.puppetlabs.com)'
FOSS projects:

```yaml
---
config:
    - refresh_interval: 30  # page refresh interval (in seconds)
views:
    - 'Puppet Labs - FOSS':
        - https://jenkins.puppetlabs.com:
            - username: 'YOUR_USERNAME'
            - password: 'YOUR_PASSWORD'
            - jobs:
                - 'Puppet-Specs-master'
                - 'Facter-Specs-master'
                - 'Hiera-Specs-master'
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

## Screenshots
![Waylon radiator screenshot (builds)](http://rogerignazio.com/projects/waylon/waylon-screenshot-builds.png)
![Waylon radiator screenshot (nirvana)](http://rogerignazio.com/projects/waylon/waylon-screenshot-nirvana.png)

## Credits
This application makes use of and/or re-distributes the following open source
software:
  * [Sinatra](http://www.sinatrarb.com)
  * [Bootstrap](http://getbootstrap.com)
  * [jQuery](http://jquery.com)
  * [jenkins_api_client](https://github.com/arangamani/jenkins_api_client)

This application also includes the following content that was released under the
[Creative Commons Attribution (CC BY)](http://creativecommons.org/licenses/)
license:
  * [GLYPHICONS](http://glyphicons.com/)
  * [Day 105: Oregon Coast Range](https://www.flickr.com/photos/lorenkerns/8651732785) by Loren Kerns
  * [Mt. Hood, Oregon](https://www.flickr.com/photos/tsaiproject/9943809254) by tsaiproject
  * [Multnomah Falls](https://www.flickr.com/photos/johnniewalker/12660211844) by John Tregoning
  * [101_1812](https://www.flickr.com/photos/randall-booth/9060319329) by Randall Booth
  * [Central Oregon Landscape](https://www.flickr.com/photos/ex_magician/3196286183) by Michael McCullough
  * [Oregon Autumn Part 4](https://www.flickr.com/photos/31246066@N04/4030400633) by Ian Sane
  * [Astoria, Oregon](https://www.flickr.com/photos/goingslo/11522920406) by Linda Tanner

