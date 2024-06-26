<?php

declare(strict_types=1);

use Frosh\Rector\Set\ShopwareSetList;
use Rector\CodeQuality\Rector\Class_\InlineConstructorDefaultToPropertyRector;
use Rector\Config\RectorConfig;
use Rector\Php74\Rector\LNumber\AddLiteralSeparatorToNumberRector;
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
    ->withSkip([
        AddLiteralSeparatorToNumberRector::class => [
            __DIR__ . '/custom/plugins/*/src/Migration',
            __DIR__ . '/custom/static-plugins/*/src/Migration'
        ]
    ])
    ->withRules([
        InlineConstructorDefaultToPropertyRector::class,
        SimpleFunctionAndFilterRector::class,
    ])
    ->withSets([
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SymfonySetList::SYMFONY_54,
        SymfonySetList::SYMFONY_60,
        SymfonySetList::SYMFONY_61,
        SymfonySetList::SYMFONY_62,
        SymfonySetList::SYMFONY_63,
        SymfonySetList::SYMFONY_64,
        SymfonySetList::SYMFONY_CODE_QUALITY,
        SymfonySetList::ANNOTATIONS_TO_ATTRIBUTES,
        LevelSetList::UP_TO_PHP_81,
        LevelSetList::UP_TO_PHP_82,
        LevelSetList::UP_TO_PHP_83,
        ShopwareSetList::SHOPWARE_6_5_0,
        ShopwareSetList::SHOPWARE_6_6_0,
    ]);
