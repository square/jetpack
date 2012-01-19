# Jetpack

Jetpack prepares your (j)ruby project for jvm deployment.

Jetpack, as much as possible, uses standard ruby-world tools to prepare the app for deployment, and then presents the ruby app to jetty as a Java EE web application.

## Install

Deploys need to be performed using MRI. Here is a sample section of a project Gemfile:

    platforms :ruby_19 do
      gem 'jetpack'
    end


Create `config/jetpack.yml` in your project:

    jruby: "http://jruby.org.s3.amazonaws.com/downloads/1.6.5.1/jruby-complete-1.6.5.1.jar"
    jetty: "http://dist.codehaus.org/jetty/jetty-hightide-7.4.5/jetty-hightide-7.4.5.v20110725.zip"
    jruby-rack: "http://repository.codehaus.org/org/jruby/rack/jruby-rack/1.0.10/jruby-rack-1.0.10.jar"
    app_user: "myapp"
    app_root: "/usr/local/myapp/myapp"

Run jetpack:

    bundle exec jetpack .

Of note, you'll now have:

* a `bin` directory, with scripts that run ruby and rake, using jruby and with the gems defined in your project.
* a `vendor/jetty directory`, containing everything necessary to run your app using jetty.
  * You can try your app out by cd'ing into `vendor/jetty` and running `RAILS_ENV=development java -jar start.jar`
  * `vendor/jetty/jetty-init` is an init script that starts your project. You should symlink `/etc/init.d/[appuser]-jetty` to this file, and then point monit at `/etc/init.d/[appuser]-jetty`
