# Scripts to create Azure resources 

## cosmos-db.ps1

Creates cosmos db database and assigns readonly access for an azure app service.

Requires a config.psd1 file with the following structure
```
@{
    ACCOUNT_NAME = ""
    RESOURCE_GROUP = ""
    DATABASE_NAME = ""
    CONTAINER_NAME = ""
    APP_NAME = ""
    RBAC_ROLE_NAME = ""
}
```

If local debugging is required then the default azure credential can be used for authentication, but the user must be added to RBAC with the same read permission.

For any write access the `Cosmos DB Built-in Data Reader` access level should be used

Data reader role id is `00000000-0000-0000-0000-000000000001`
Date contributor role is `00000000-0000-0000-0000-000000000002`