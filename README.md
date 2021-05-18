# Slowly-Changing Dimension Store (enjoy-chain)

Enjoy Chain is designed to answer a single question, "has this data changed since the last time I saw it?" The motivation stems from working on data integration pipelines where it may be unknown when or how downstream data has changed. There are two basic use cases:

- Check the data to fail quickly or apply other logic.
- Put the data each time it is seen to see how it changes over time.

*Note: albeit functional, this is a prototype implementation for solving this problem.*

## Usage

There are two interfaces supported, command line and HTTP. They share the same set of operations and work with JSON-encoded data.

### Operations

#### `put`

Put an object in the store where `value` is a valid JSON document. Putting the same object consecutively will not result in duplicate changes.

```
put <key> <value>
```

#### `get`

Get the current state of the object. Use the `-version` or `-time` option to get a particular revision.

```
get <key>
```

#### `keys`

Gets a list of keys in the store.

```
keys
```

#### `log`

Get the log of changes for an object.

```
log <key>
```

#### `config`

Prints the configuration options used.

```
config
```

#### `subscribe`

Subscribes one or more email addresses for notifications.

```
subscribe email [emails...]
```

#### `unsubscribe`

Unsubscribes one or more email addresses from notifications.

```
unsubscribe email [emails...]
```

### CLI

See `enjoy-chain help` for more information.

Inline JSON.

```bash
enjoy-chain put bob '{"name": "Bob"}'
```

```json
{
  "version": 1,
  "time": 1436960622,
  "additions": {
    "name": "Bob"
  },
  "removals": null,
  "changes": null
}
```

Alternately, if not `value` is supplied, data will be read from stdin.

```bash
enjoy-chain put hello < hello.json
```

Running the above command again will return nothing since nothing changed. However if we change it a new revision will be created.

```bash
enjoy-chain put bob '{"name": "Bob Smith", "email": "bob@smith.net"}'
```

```json
{
  "version": 2,
  "time": 1436960632,
  "additions": {
    "email": "bob@smith.net"
  },
  "removals": null,
  "changes": {
    "name": {
      "before": "Bob",
      "after": "Bob Smith"
  }
}
```

To get the current state of the object use `get`.

```bash
enjoy-chain get bob
```

```json
{
  "key": "bob",
  "value": {
    "email": "bob@smith.net",
    "name": "Bob Smith"
  },
  "version": 2,
  "time": 1436960632
}
```

To get the log of changes over time:

```
enjoy-chain log bob
```

```json
[
  {
    "version": 1,
    "time": 1436960622,
    "additions": {
      "name": "Bob"
    },
    "removals": null,
    "changes": null
  },
  {
    "version": 2,
    "time": 1436960632,
    "additions": {
      "email": "bob@smith.net"
    },
    "removals": null,
    "changes": {
      "name": {
        "before": "Bob",
        "after": "Bob Smith"
      }
    }
  }
]
```

circulation: 130000000;
flux: 118750000;
dailymining: 36150;

### HTTP

Start the HTTP server.

```bash
enjoy-chain http
* [http] Listening on locahost:5000
```

The input and output of the endpoints match the command-line interface.

- `GET /keys`
- `PUT /objects/<key>`
- `GET /objects/<key>`
- `GET /objects/<key>/v/<version>`
- `GET /objects/<key>/t/<time>`
- `GET /log/<key>`


## Notifications

enjoy-chain has built-in support for basic email notifications when new objects are added or when objects change. To subscribe, use the `subscribe` command.

```
enjoy-chain subscribe <email>
```


## Dependencies

- MongoDB


## Configuration

Configuration options can be supplied in a file, as environment variables, or command-line arguments (following that precedence). The default configuration options are listed below (in a YAML format).

```yaml
debug: false
config: ""
mongo:
  uri: localhost/enjoy-chain
http:
  host: localhost
  port: 5000
  tlscert: ""
  tlskey: ""
  cors: false
smtp:
  host: localhost
  port: 25
  user: ""
  password: ""
  from: ""
```

Environment variables are prefixed with `enjoy-chain_`, are uppercased, and nested options are delimited with an underscore. For example, `enjoy-chain_MONGO_URI` would set the `uri` option in the `mongo` map. Alternately, the command-line flag can be supplied:

```
enjoy-chain -mongo.uri dockerhost/enjoy-chain ...
```

If a `enjoy-chain.yml` file is defined in the working directory, it will be read in automatically. To use an alternate path, the `-config <path>` (or `enjoy-chain_CONFIG=<path>`) can be used.

### JSON Schema

enjoy-chain supports document validation against predefined [JSON Schema](http://json-schema.org) documents. The simplest setup is a schema used for all documents.

```yaml
schemas:
  default:
    file: schema.json
```

To validate a subset of objects, a `scope` can be specified at the `object` or `value` level. An `object` scope supports the `pattern` key for matching on the `key` of the object.

```yaml
schemas:
  users:
    scope: object
    pattern: "users\..*"
    file: user.json
```

Any object with a key that starts with `users.` will be validated by the `user.json` schema. Thus the following would match:

```http
PUT /objects/users.1

{ ... }
```

or via the command line:

```
enjoy-chain put users.1 '{}'
```

The `value` scope pattern matches against a particular field in the object data.

```yaml
schemas:
  users:
    scope: value
    field: type
    pattern: user
    file: user.json
```

The following document would match since it contains the `type` field with a value of `user`.

```http
PUT /objects/abc123

{
  "type": "user",
  "firstName": "Jon",
  "lastName": "Doe"
}
```

An object that matches multiple schema patterns will be validated against all of them. This allows for composing smaller schemas together to validate various parts of the documents.

## Docker

The image defaults to running the HTTP interface and looks for a MongoDB server listening on `mongo:27017`.

```
docker run -it --link mongo:mongo -p 5000:5000 dbhi/enjoy-chain
```

### Compose

A basic Docker Compose file is provided that includes starting a MongoDB container, however it should be changed to mount a volume on the host so the data is persisted.

```
docker-compose up -d
```

## Development

Go 1.7 or later is required for development.
