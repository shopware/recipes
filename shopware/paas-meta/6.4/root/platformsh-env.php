<?php

declare(strict_types=1);

namespace Platformsh\ShopwareBridge;

use Platformsh\ConfigReader\Config;

mapPlatformShEnvironment();

/**
 * Map Platform.Sh environment variables to the values Shopware expects expects.
 *
 * This is wrapped up into a function to avoid executing code in the global
 * namespace.
 *
 * Note: Most values are already handled by the Symfony Flex bridge. This file is just
 * for the additional variables required by Shopware.
 */
function mapPlatformShEnvironment() : void
{
    $config = new Config();

    if (!$config->inRuntime()) {
        return;
    }

    $config->registerFormatter('redis', __NAMESPACE__ . '\redisFormatter');
    $config->registerFormatter('elasticsearch', __NAMESPACE__ . '\elasticsearchFormatter');
    $config->registerFormatter('rabbitmq', __NAMESPACE__ . '\rabbitmqFormatter');

    // Set the URL based on the route.  This is a required route ID.
    setEnvVar('APP_URL', $config->getRoute('shopware')['url']);

    // Map services as feasible.
    mapPlatformShRedis('rediscache', $config);
    mapPlatformShElasticsearch('essearch', $config);
    mapPlatformShRabbitmq('rabbitmqqueue', $config);
}

/**
 * Sets an environment variable in all the myriad places PHP can store it.
 *
 * @param string $name
 *   The name of the variable to set.
 * @param null|string $value
 *   The value to set.  Null to unset it.
 */
function setEnvVar(string $name, $value) : void
{
    if (!putenv("$name=$value")) {
        throw new \RuntimeException('Failed to create environment variable: ' . $name);
    }
    $order = ini_get('variables_order');
    if (stripos($order, 'e') !== false) {
        $_ENV[$name] = $value;
    }
    if (stripos($order, 's') !== false) {
        if (strpos($name, 'HTTP_') !== false) {
            throw new \RuntimeException('Refusing to add ambiguous environment variable ' . $name . ' to $_SERVER');
        }
        $_SERVER[$name] = $value;
    }
}

/**
 * Maps the specified relationship to the REDIS_URL environment variable, if available.
 *
 * @param string $relationshipName
 *   The database relationship name.
 * @param Config $config
 *   The config object.
 */
function mapPlatformShRedis(string $relationshipName, Config $config) : void
{
    if (!$config->hasRelationship($relationshipName)) {
        return;
    }
    $redis_credentials = $config->credentials($relationshipName);
    setEnvVar('REDIS_HOST', (string)$redis_credentials['host']);
    setEnvVar('REDIS_PORT', $redis_credentials['port']);

    setEnvVar('REDIS_URL', $config->formattedCredentials($relationshipName, 'redis'));
}

function redisFormatter(array $credentials): string
{
    return "redis://{$credentials['host']}:{$credentials['port']}";
}

/**
 * Maps the specified relationship to the elasticsearch environment variables, if available.
 *
 * @param string $relationshipName
 *   The search index relationship name.
 * @param Config $config
 *   The config object.
 */
function mapPlatformShElasticsearch(string $relationshipName, Config $config) : void
{
    if (!$config->hasRelationship($relationshipName)) {
        return;
    }

    setEnvVar('SHOPWARE_ES_HOSTS', $config->formattedCredentials($relationshipName, 'elasticsearch'));
    setEnvVar('ELASTICSEARCH_URL', $config->formattedCredentials($relationshipName, 'elasticsearch'));
}

function elasticsearchFormatter(array $credentials): string
{
    return "http://{$credentials['host']}:{$credentials['port']}";
}

/**
 * Maps the specified relationship to the rabbitmq environment variables, if available.
 *
 * @param string $relationshipName
 *   The search index relationship name.
 * @param Config $config
 *   The config object.
 */
function mapPlatformShRabbitmq(string $relationshipName, Config $config) : void
{
    if (!$config->hasRelationship($relationshipName)) {
        return;
    }

    setEnvVar('RABBITMQ_URL', $config->formattedCredentials($relationshipName, 'rabbitmq'));
}

function rabbitmqFormatter(array $credentials): string
{
    return "amqp://{$credentials['username']}:{$credentials['password']}@{$credentials['host']}:{$credentials['port']}/%2F?connection_timeout=1000&heartbeat=100&auto_setup=false";
}