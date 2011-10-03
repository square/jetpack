Preflight prepares your (j)ruby project for jvm deployment.

1. Create config/preflight.yml in your project

Example config/preflight.yml:

    jruby: "http://mirrors.squareup.com/distfiles/jruby-complete-1.6.4.jar"
    jetty: "http://mirrors.squareup.com/distfiles/jetty-hightide-7.4.5.v20110725.zip"
    jruby-rack: "http://mirrors.squareup.com/distfiles/jruby-rack-1.0.10.jar"
    app_user: finance
    app_root: /usr/local/finance/finance

2. Running:

Instructions:

    [one day soon there will be a gem install]

    preflight [your project directory]
  

Of note, you'll now have:

* a bin directory, with scripts that run ruby and rake, using jruby and with the gems defined in your project.
* a vendor/jetty directory, containing everything necessary to run your app using jetty.
  * You can try your app out by cd'ing into vendor/jetty and running RAILS_ENV=development java -jar start.jar
  * vendor/jetty/jetty-init is an init script that starts your project. You should symlink /etc/init.d/[appuser]-jetty to this file, and then point monit at /etc/init.d/[appuser]-jetty
