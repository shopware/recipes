{ pkgs, lib, config, ... }:

let
  # devenv allocates a free port when the default one is taken, so connection
  # strings have to follow the port the service actually listens on.
  port = process: name: toString config.processes.${process}.ports.${name}.value;
in
{
  packages = [
    pkgs.jq
    pkgs.gnupatch
  ];

  dotenv.disableHint = true;
  devenv.warnOnNewVersion = false;

  languages.javascript = {
    enable = lib.mkDefault true;
    package = lib.mkDefault pkgs.nodejs_22;
  };

  languages.php = {
    enable = lib.mkDefault true;
    version = lib.mkDefault "8.4";

    extensions =
      lib.optionals config.services.redis.enable [ "redis" ]
      ++ lib.optionals config.services.rabbitmq.enable [ "amqp" ];

    ini = ''
      memory_limit = 2G
      realpath_cache_ttl = 3600
      session.gc_probability = 0
      ${lib.optionalString config.services.redis.enable ''
      session.save_handler = redis
      session.save_path = "tcp://127.0.0.1:${port "redis" "main"}/0"
      ''}
      display_errors = On
      error_reporting = E_ALL
      zend.assertions = -1
      opcache.memory_consumption = 256M
      opcache.interned_strings_buffer = 20
      short_open_tag = 0
    '';

    fpm.pools.web = lib.mkDefault {
      settings = {
        "clear_env" = "no";
        "pm" = "dynamic";
        "pm.max_children" = 10;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 1;
        "pm.max_spare_servers" = 10;
      };
    };
  };

  services.caddy = {
    enable = lib.mkDefault true;

    virtualHosts.":8000" = lib.mkDefault {
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
  };

  services.mysql = {
    enable = true;
    package = pkgs.mysql84;
    initialDatabases = lib.mkDefault [{ name = "shopware"; }];
    ensureUsers = lib.mkDefault [
      {
        name = "shopware";
        password = "shopware";
        ensurePermissions = {
          "shopware.*" = "ALL PRIVILEGES";
          "shopware_test.*" = "ALL PRIVILEGES";
        };
      }
    ];
    settings = {
      mysqld = {
        log_bin_trust_function_creators = 1;
      };
    };
  };

  services.redis.enable = lib.mkDefault true;
  services.adminer.enable = lib.mkDefault true;
  services.adminer.listen = lib.mkDefault "127.0.0.1:8010";
  services.mailpit.enable = lib.mkDefault true;

  #services.rabbitmq.enable = true;
  #services.rabbitmq.managementPlugin.enable = true;
  #services.opensearch.enable = true;

  cachix.enable = false;

  # Environment variables
  env = lib.mkMerge [
    (lib.mkIf config.services.mysql.enable {
      DATABASE_URL = lib.mkDefault "mysql://shopware:shopware@127.0.0.1:${port "mysql" "main"}/shopware";
    })
    (lib.mkIf config.services.mailpit.enable {
      MAILER_DSN = lib.mkDefault "smtp://127.0.0.1:${port "mailpit" "smtp"}";
    })
    (lib.mkIf config.services.rabbitmq.enable {
      MESSENGER_TRANSPORT_DSN = lib.mkDefault "amqp://guest:guest@127.0.0.1:${port "rabbitmq" "main"}/%2f/messages";
    })
    (lib.mkIf config.services.opensearch.enable {
      OPENSEARCH_URL = lib.mkDefault "http://127.0.0.1:${port "opensearch" "http"}";
      SHOPWARE_ES_ENABLED = lib.mkDefault "1";
      SHOPWARE_ES_INDEXING_ENABLED = lib.mkDefault "1";
    })
  ];

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
