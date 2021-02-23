const sv_configKeys = {
    exsql_api_host: {
        name: "api.host",
        type: "string",
        default: "localhost"
    },
    exsql_api_port: {
        name: "api.port",
        type: "number",
        default: 2000
    },
    exsql_api_route: {
        name: "api.route",
        type: "string",
        default: "/external/api"
    },
    exsql_api_secret: {
        name: "api.secret",
        type: "string",
        default: "yoursecretkey"
    },
    exsql_api_community: {
        name: "api.community",
        type: "string",
        default: "testing"
    },
    exsql_db_connectionLimit: {
        name: "database.connectionLimit",
        type: "number",
        default: 100
    },
    exsql_db_host: {
        name: "database.host",
        type: "string",
        default: "localhost"
    },
    exsql_db_port: {
        name: "database.port",
        type: "number",
        default: 3306
    },
    exsql_db_user: {
        name: "database.user",
        type: "string",
        default: "root"
    },
    exsql_db_password: {
        name: "database.password",
        type: "string",
        default: ""
    },
    exsql_devmode: {
        name: "devmodeactive",
        type: "boolean",
        default: false
    },
    exsql_createtoken: {
        name: "createtokenonstart",
        type: "boolean",
        default: true
    }
};

const regex = /(\w+).?(\w+)?/gm;

const config = {
    data: {
        api: {
            host: "",
            port: 0,
            route: "",
            secret: "",
            community: ""
        },
        database: {
            connectionLimit: 0,
            host: "",
            port: 0,
            user: "",
            password: "",
            database: ""
        },
        devmodeactive: false,
        createtokenonstart: true
    },
    load() {
        let config = {};
        const configString = LoadResourceFile(GetCurrentResourceName(), "config.json");
        if(configString === "" || !configString) {
            console.log(`^3[${GetCurrentResourceName()}]^7: ^4config.json not detected, loading from server config^7`);
            for(const [key, info] of Object.entries(sv_configKeys)) {
                const defaultValue = typeof info.default === "boolean" ? info.default === true ? "true" : "false" : info.default;
                const value = GetConvar(key, defaultValue);
                try {
                    const parsedValue = this.castType(info.type, value);
                    this.setConfigValue(info.name, parsedValue);
                } catch(e) {
                    console.log(`^1[${GetCurrentResourceName()}]: ${e.message}^7`);
                }
            }
        } else {
            try {
                config = JSON.parse(configString);
                this.data = config;
                console.log(`^2[${GetCurrentResourceName()}]^7:^2 successfully loaded config.json^7`);
            } catch(e) {
                console.log(`^1[${GetCurrentResourceName()}]^7: ^3failed to parse config.json. ${e.message}^7`);
            }
        }

        setImmediate(() => {
            emit('ExternalSQL:ConfigLoaded', this.data);
        });
    },
    /**
     *
     * @param {string} key
     * @param {any} value
     */
    setConfigValue(key, value) {
        const results = key.matchAll(regex)
        for(const match of results) {
            const matched = [...match];
            if(matched.length !== 3) {
                continue;
            }
            if(matched[2] === undefined) {
                const targetKey = matched[1];
                this.data[targetKey] = value;
                Object.defineProperty(this.data, targetKey, {
                    configurable: true,
                    enumerable: true,
                    value,
                    writable: true
                });
            } else {
                const targetParent = matched[1];
                const targetKey = matched[2];
                this.data[targetParent][targetKey] = value;
                if(!this.data[targetParent]) {
                    Object.defineProperty(this.data, targetParent, {
                        configurable: true,
                        enumerable: true,
                        value: {},
                        writable: true
                    });
                }
                Object.defineProperty(this.data[targetParent], targetKey, {
                    configurable: true,
                    enumerable: true,
                    value,
                    writable: true
                });
            }
        }
    },
    /**
     * 
     * @param {string} type 
     * @param {any[]} value 
     */
    castType(type, value) {
        let tmpValue;
        switch(type) {
            case "string":
                return String(value);
            case "number":
                tmpValue = Number(value);
                if(isNaN(tmpValue)) {
                    throw new Error(`failed to convert ${value} to a number`);
                }
                return tmpValue;
            case "boolean":
                if(value !== "true" && value !== "false") {
                    throw new Error(`type specified for boolean must be either "true" or "false"`);
                }
                return value == "true";
            default:
                throw new Error(`no handler set for type ${type}`);
        }
    }
}

module.exports = config;