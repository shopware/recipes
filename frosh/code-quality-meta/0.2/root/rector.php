<?php

declare(strict_types=1);

use Frosh\Rector\Set\ShopwareSetList;
use Rector\CodeQuality\Rector\Class_\InlineConstructorDefaultToPropertyRector;
use Rector\Config\RectorConfig;
use Rector\Php74\Rector\LNumber\AddLiteralSeparatorToNumberRector;
use Rector\PostRector\Rector\NameImportingPostRector;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\Symfony\Twig134\Rector\Return_\SimpleFunctionAndFilterRector;
use Rector\Symfony\Set\SymfonySetList;

return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->symfonyContainerXml(__DIR__ . '/var/cache/phpstan_dev/Shopware_Core_DevOps_StaticAnalyze_StaticAnalyzeKernelPhpstan_devDebugContainer.xml');

    $rectorConfig->paths([
        __DIR__ . '/custom/static-plugins/*/src',
        __DIR__ . '/custom/plugins/*/src',
    ]);

    $rectorConfig->bootstrapFiles([
        __DIR__ . '/vendor/autoload.php',
    ]);

    $rectorConfig->rule(InlineConstructorDefaultToPropertyRector::class);
    $rectorConfig->rule(NameImportingPostRector::class);
    $rectorConfig->rule(SimpleFunctionAndFilterRector::class);

    $rectorConfig->sets([
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SymfonySetList::SYMFONY_54,
        SymfonySetList::SYMFONY_60,
        SymfonySetList::SYMFONY_61,
        SymfonySetList::SYMFONY_62,
        SymfonySetList::SYMFONY_CODE_QUALITY,
        SymfonySetList::ANNOTATIONS_TO_ATTRIBUTES,
        LevelSetList::UP_TO_PHP_81,
        ShopwareSetList::SHOPWARE_6_5_0,
        ShopwareSetList::SHOPWARE_6_6_0,
    ]);

    $rectorConfig->skip([
        AddLiteralSeparatorToNumberRector::class => [
            __DIR__ . '/custom/plugins/*/src/Migration',
            __DIR__ . '/custom/static-plugins/*/src/Migration'
        ]
    ]);
};
