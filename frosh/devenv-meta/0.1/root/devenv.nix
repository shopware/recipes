{ pkgs, config, lib, ... }:

{
  packages = [
    pkgs.jq
  ];

  languages.javascript.enable = lib.mkDefault true;
  languages.javascript.package = lib.mkDefault pkgs.nodejs-16_x;
  env.NODE_OPTIONS = lib.mkDefault "--openssl-legacy-provider";

  languages.php.enable = lib.mkDefault true;
  languages.php.package = lib.mkDefault (pkgs.php.buildEnv {
    extensions = { all, enabled }: with all; enabled ++ [ amqp redis ];
    extraConfig = ''
      memory_limit = 2G
      pdo_mysql.default_socket = ''${MYSQL_UNIX_PORT}
      mysqli.default_socket = ''${MYSQL_UNIX_PORT}
      realpath_cache_ttl = 3600
      session.gc_probability = 0
      session.save_handler = redis
      session.save_path = "tcp://127.0.0.1:6379/0"
      display_errors = On
      error_reporting = E_ALL
      assert.active = 0
      opcache.memory_consumption = 256M
      opcache.interned_strings_buffer = 20
      zend.assertions = 0
      short_open_tag = 0
      zend.detect_unicode = 0
      realpath_cache_ttl = 3600
    '';
  });

  languages.php.fpm.pools.web = lib.mkDefault {
    settings = {
      "clear_env" = "no";
      "pm" = "dynamic";
      "pm.max_children" = 10;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 10;
    };
  };

  services.caddy.enable = lib.mkDefault true;
  services.caddy.virtualHosts.":8000" = lib.mkDefault {
    extraConfig = ''
      root * public
      php_fastcgi unix/${config.languages.php.fpm.pools.web.socket}
      encode zstd gzip
      file_server
      log {
      	output stderr
      	format console
      	level ERROR
      }
    '';
  };

  services.mysql.enable = lib.mkDefault true;
  services.mysql.initialDatabases = lib.mkDefault [{ name = "shopware"; }];
  services.mysql.ensureUsers = lib.mkDefault [
    {
      name = "shopware";
      password = "shopware";
      ensurePermissions = { "shopware.*" = "ALL PRIVILEGES"; };
    }
  ];

  services.redis.enable = lib.mkDefault true;
  services.adminer.enable = lib.mkDefault true;
  services.adminer.listen = lib.mkDefault "127.0.0.1:8010";
  services.mailhog.enable = lib.mkDefault true;

  #services.rabbitmq.enable = true;
  #services.rabbitmq.managementPlugin.enable = true;
  #elasticsearch.enable = true;

  # Environment variables
  env.DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@localhost:3306/shopware";

  processes.entryscript = {
    exec = (pkgs.writeShellScript "complex-process" ''
        PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"

        composer install --prefer-dist --no-progress --no-scripts --no-interaction

        if [ ! -f "install.lock" ]; then
          bin/console system:install --basic-setup
        fi

        echo "—————————————————————————————————————"
        echo "💙 Your Shopware instance is ready 💙"
        echo "—————————————————————————————————————"
        sleep infinity
    '').outPath;
  };

  # Shopware 6 related scripts
  scripts.build-js.exec = lib.mkDefault "bin/build-js.sh";
  scripts.build-storefront.exec = lib.mkDefault "bin/build-storefront.sh";
  scripts.watch-storefront.exec = lib.mkDefault "bin/watch-storefront.sh";
  scripts.build-administration.exec = lib.mkDefault "bin/build-administration.sh";
  scripts.watch-administration.exec = lib.mkDefault "bin/watch-administration.sh";
  scripts.theme-refresh.exec = lib.mkDefault "bin/console theme-refresh";
  scripts.theme-compile.exec = lib.mkDefault "bin/console theme-compile";

  # Symfony related scripts
  scripts.cc.exec = lib.mkDefault "bin/console cache:clear";
}
