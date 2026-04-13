# Scripts to create Azure resources 

## Cosmos DB

### cosmos-db.ps1

Creates cosmos db database and container.

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

### cosmos-db-access.ps1

Authentication is through RBAC control, with the API given readonly access. The same config file is used.

If local debugging is required then the default azure credential can be used for authentication, but the user must be added to RBAC with the same read permission.

For any write access the `Cosmos DB Built-in Data Reader` access level should be used

Data reader role id is `00000000-0000-0000-0000-000000000001`
Date contributor role is `00000000-0000-0000-0000-000000000002`

## VNET

### vnet.ps1

Creation of vnet containing two subnets for webapp and api. The api will then only accept requests from the flask subnet.

Requires a config.psd1 file with the following structure
```
@{
    VNET_NAME = ""
    FLASK_SUBNET_NAME = ""
    API_SUBNET_NAME = ""
    RESOURCE_GROUP = ""
    FLASK_APP_NAME = ""
    API_APP_NAME = ""
}
```