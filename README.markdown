# Jetpack

[![Build Status](https://travis-ci.org/square/jetpack.svg?branch=master)](https://travis-ci.org/square/jetpack)

jet.pack: package your JRuby webapp for Jetty.

There are already many tools in existence that help developers run JRuby webapps on popular servlet containers,
such as [trinidad](https://github.com/trinidad/trinidad), [warbler](https://github.com/jruby/warbler), [mizuno](https://github.com/matadon/mizuno), and [kirk](https://github.com/strobecorp/kirk).
Jetpack is not fundamentally different from these tools: like the rest of them it uses the [jruby-rack](https://github.com/jruby/jruby-rack) jar as a foundation. The key differences are stylistic.

Jetpack:

* Uses [Jetty](http://jetty.codehaus.org/jetty/)... in all of its
  out-of-the-box, XML-configuration-file glory.
* Uses bundler to "vendor" all of your gems.
* Uses the [jruby-complete jar](http://jruby.org/download), and provides
  convenience wrapper scripts (`bin/ruby` and `bin/rake`) in your project.
* Does not attempt to run Jetty in a ruby-first, embedded manner.
* Does not assume JRuby is already installed in your server environment (a
  basic JRE will do just fine).
* Does not force your ruby webapp to load files from a jar or war.

In short, Jetpack creates a little self-contained JRuby/Jetty/vendored-gem world around your ruby project,
which you only need to transport to a server and fire up using a JRE.

Jetpack's implementation mainly consists of an [honest, proletarian, bash-like ruby script](https://github.com/square/jetpack/blob/master/bin/jetpack).

## Install

Deploys need to be performed using MRI. Here is a sample section of a project Gemfile:

    platforms :mri do
      gem 'jetpack'
    end


Create `config/jetpack.yml` in your project:

    jruby: "http://jruby.org.s3.amazonaws.com/downloads/1.7.12/jruby-complete-1.7.12.jar"
    jetty: "http://dist.codehaus.org/jetty/jetty-hightide-8.1.15/jetty-hightide-8.1.15.v20140411.zip"
    jruby-rack: "http://repository.codehaus.org/org/jruby/rack/jruby-rack/1.1.14/jruby-rack-1.1.14.jar"
    app_user: "myapp"
    app_root: "/usr/local/myapp/myapp"

Some other settings you might care about:

    java_options: "-Xmx2048m"
    http_port: 4080
    https_port: 4443
    max_concurrent_connections: 50
    ruby_version: 1.8
    app_type: rack
    keystore_type: JCEKS
    keystore: /data/app/secrets/mystore.jceks
    keystore_password: sekret
    bundle_without: [test, development]

Run Jetpack:

    bundle exec jetpack .

Of note, you'll now have:

* a `bin` directory, with scripts that run ruby and rake, using jruby and with the gems defined in your project.
* a `vendor/jetty directory`, containing everything necessary to run your app using jetty.
  * You can try your app out by cd'ing into `vendor/jetty` and running `RAILS_ENV=development java -jar start.jar`
  * `vendor/jetty/jetty-init` is an init script that starts your project. You should symlink `/etc/init.d/[appuser]-jetty` to this file, and then point monit at `/etc/init.d/[appuser]-jetty`
