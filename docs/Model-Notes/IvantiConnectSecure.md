### Ivanti Connect Secure (ICS)

#### Overview

This model provides support for Ivanti Connect Secure (ICS) appliances using REST API ([official documentation](https://help.ivanti.com/ps/help/en_US/ICS/22.x/22.7R2/22.xICSAG.pdf)).
ICS stores its configuration as a binary ZIP archive (with `system.cfg` and `user.cfg` files) which is retrieved using the `/api/v1/system/binary-configuration` endpoint.

The model performs an initial authentication against `/api/v1/realm_auth` using Basic Auth (`username`/`password`) and retrieves a temporary `api_key`.
This key is then used for all further API requests during the Oxidized collection cycle.

The model is designed to work with standard ICS deployments without requiring command-line access to the device.

#### How Configuration Is Retrieved

1. Oxidized authenticates using:

```bash
POST /api/v1/realm_auth
```

with:
- Basic Auth: `username` + `password`
- JSON body `{"realm": "<realm>"}`


2. ICS returns a temporary:

```json
{ "api_key": "<token>" }
```


3. The configuration is fetched from:

```bash
GET /api/v1/system/binary-configuration
```

with:
- `api_key` as `username`
- `''` as `password`

ICS responds with a BASE64-encoded ZIP archive containing the device configuration.
The model stores this BASE64 value as a single uninterrupted line.


#### Required Node Configuration

In source (CSV, HTTP, SQL, etc.), simply define:

```yaml
model: ivanti
username: <your username>
password: <your password>
vars:
  realm: <your realm>   # Optional, default = "Users"
```

The model will automatically handle authentication and obtain the API key as stated above.
