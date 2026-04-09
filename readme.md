Scripts to create Azure Cosmos DB resources and allow read access of an azure app service.

Requires a config.psd1 file with the following structure
```
@{
    ACCOUNT_NAME = ""
    RESOURCE_GROUP = ""
    DATABASE_NAME = ""
    CONTAINER_NAME = ""
    APP_NAME = ""
}
```