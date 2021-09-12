# Configuration

Use either the config.json or server configruation to set your parameters. If you wish to use server configuration, simply delete the `config.json`
and set the appropriate values.

### List of server configuration variables
---

|    Variable Name    |  Type  |    Default    |
| :-----------------: | :----: | :-----------: |
|   exsql_api_host    | string |   localhost   |
|   exsql_api_port    | number |     2000      |
|   exsql_api_route   | string | /external/api |
|  exsql_api_secret   | string | yoursecretkey |
| exsql_api_community | string |    testing    |
|    exsql_db_host    | string |   localhost   |
|    exsql_db_user    | string |     root      |
|  exsql_db_password  | string |               |
|  exsql_db_database  | string |      drp      |
|    exsql_devmode    | string |     false     |
|  exsql_createtoken  | string |     true      |

### Example server.cfg

```
... other config

set exsql_db_host "my.db.host"
set exsql_db_user "mydbuser"
set exsql_db_password "mydbpass"
```



# LICENSE

<a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-nd/4.0/88x31.png" /></a><br />This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by-nc-nd/4.0/">Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License</a>.
