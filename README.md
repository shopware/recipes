# Symfony Flex Recipes

This repository is hosting Symfony Flex Recipes for Shopware 6.

## Install

- Require `symfony/flex` in your project

- Add custom endpoint to your composer.json

```json
"extra": {
  "symfony": {
      "allow-contrib": true,
      "endpoint": [
        "https://raw.githubusercontent.com/shopware/recipes/flex/main/index.json",
        "flex://defaults"
    ]
  }
}
```
