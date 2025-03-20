<?php

declare(strict_types=1);

use Frosh\Rector\Set\ShopwareSetList;
use Rector\Config\RectorConfig;
use Rector\Php83\Rector\ClassMethod\AddOverrideAttributeToOverriddenMethodsRector;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Symfony\Set\SymfonySetList;
use Rector\Symfony\Twig134\Rector\Return_\SimpleFunctionAndFilterRector;

return RectorConfig::configure()
    ->withSymfonyContainerXml(__DIR__ . '/var/cache/phpstan_dev/Shopware_Core_DevOps_StaticAnalyze_StaticAnalyzeKernelPhpstan_devDebugContainer.xml')
    ->withBootstrapFiles([
        __DIR__ . '/vendor/autoload.php',
    ])
    ->withPaths([
        __DIR__ . '/custom/static-plugins/*/src',
        __DIR__ . '/custom/plugins/*/src',
    ])
    ->withFileExtensions(['php'])
    ->withSkip([
        __DIR__ . '/custom/plugins/*/src/Migration',
        __DIR__ . '/custom/static-plugins/*/src/Migration',

        '**/vendor/*',
        '**/node_modules/*',
        '**/Resources/*',

        AddOverrideAttributeToOverriddenMethodsRector::class,
    ])
    ->withRules([
        SimpleFunctionAndFilterRector::class,
    ])
    ->withSets([
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SymfonySetList::SYMFONY_CODE_QUALITY,
        SymfonySetList::ANNOTATIONS_TO_ATTRIBUTES,
        LevelSetList::UP_TO_PHP_83,
        ShopwareSetList::SHOPWARE_6_5_0,
        ShopwareSetList::SHOPWARE_6_6_0,
    ]);
