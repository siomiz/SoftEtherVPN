# A simple<sup>*</sup> [SoftEther VPN][1] server Docker image

`:latest` = [![Travis](https://img.shields.io/travis/siomiz/SoftEtherVPN/master.svg?style=flat-square)](https://travis-ci.org/siomiz/SoftEtherVPN)

<sup>*</sup> "Simple" as in no configuration parameter is needed for a single-user SecureNAT setup.

## Image Tags
Base OS Image | Latest Stable ([v4.28-9669-beta](https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/tree/v4.28-9669-beta)) | [v4.25-9656-rtm](https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/tree/v4.25-9656-rtm)
------------- | -- | --
`centos:7` | **`:latest`**, `:centos`, `:9669`, `:4.28`, `:9669-centos`, `:4.28-centos` | `:9656`, `:4.25`, `:9656-centos`, `4.25-centos`
`debian:9-slim` | `:debian`, `:9669-debian`, `:4.28-debian` | `:9656-debian`, `:4.25-debian`
`alpine:3.7` | `:alpine`, `:9669-alpine`, `:4.28-alpine` | `:9656-alpine`, `:4.25-alpine`
`ubuntu:18.04` | `:ubuntu`, `:9669-ubuntu`, `:4.28-ubuntu` | -

## Setup
 - L2TP/IPSec PSK + OpenVPN
 - SecureNAT enabled
 - Perfect Forward Secrecy (DHE-RSA-AES256-SHA)
 - make'd from [the official SoftEther VPN GitHub Stable Edition Repository][2].

`docker run -d --cap-add NET_ADMIN -p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp -p 1194:1194/udp -p 5555:5555/tcp siomiz/softethervpn`

Connectivity tested on Android + iOS devices. It seems Android devices do not require L2TP server to have port 1701/tcp open.

The above example will accept connections from both L2TP/IPSec and OpenVPN clients at the same time.

Mix and match published ports: 
- `-p 500:500/udp -p 4500:4500/udp -p 1701:1701/tcp` for L2TP/IPSec
- `-p 1194:1194/udp` for OpenVPN.
- `-p 443:443/tcp` for OpenVPN over HTTPS.
- `-p 5555:5555/tcp` for SoftEther VPN (recommended by vendor).
- `-p 992:992/tcp` is also available as alternative.

Any protocol supported by SoftEther VPN server is accepted at any open/published port (if VPN client allows non-default ports).

## Credentials

All optional:

- `-e PSK`: Pre-Shared Key (PSK), if not set: "notasecret" (without quotes) by default.
- `-e USERS`: Multiple usernames and passwords may be set with the following pattern: `username:password;user2:pass2;user3:pass3`. Username and passwords are separated by `:`. Each pair of `username:password` should be separated by `;`. If not set a single user account with a random username ("user[nnnn]") and a random weak password is created.
- `-e SPW`: Server management password. :warning:
- `-e HPW`: "DEFAULT" hub management password. :warning:

Single-user mode (usage of `-e USERNAME` and `-e PASSWORD`) is still supported.

See the docker log for username and password (unless `-e USERS` is set), which *would look like*:

    # ========================
    # user6301
    # 2329.2890.3101.2451.9875
    # ========================
Dots (.) are part of the password. Password will not be logged if specified via `-e USERS`; use `docker inspect` in case you need to see it.

:warning: if not set a random password will be set but not displayed nor logged. If specifying read the notice below.

#### Notice ####

If you specify credentials using environment variables (`-e`), they may be revealed via the process list on host (ex. `ps(1)` command) or `docker inspect` command. It is recommended to mount an already-configured SoftEther VPN config file at `/opt/vpn_server.config`, which contains hashed passwords rather than raw ones. The initial setup will be skipped if this file exists at runtime (in entrypoint script). You can obtain this file from a running container using [`docker cp` command](https://docs.docker.com/engine/reference/commandline/cp/).

## Configurations ##

To make the server configurations persistent beyond the container lifecycle (i.e. to make the config survive a restart), mount a complete config file at `/usr/vpnserver/vpn_server.config`. If this file is mounted the initial setup will be skipped.
To obtain a config file template, `docker run` the initial setup with Server & Hub passwords, then `docker cp` out the config file:

    $ docker run --name vpnconf -e SPW=<serverpw> -e HPW=<hubpw> siomiz/softethervpn echo
    $ docker cp vpnconf:/usr/vpnserver/vpn_server.config /path/to/vpn_server.config
    $ docker rm vpnconf
    $ docker run ... -v /path/to/vpn_server.config:/usr/vpnserver/vpn_server.config siomiz/softethervpn

Refer to [SoftEther VPN Server Administration manual](https://www.softether.org/4-docs/1-manual/3._SoftEther_VPN_Server_Manual/3.3_VPN_Server_Administration) for more information.

## Server & Hub Management Commands ##

Management commands can be executed just before the server & hub admin passwords are set via:
- `-e VPNCMD_SERVER`: `;`-separated [Server management commands](https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.3_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Entire_Server)).
- `-e VPNCMD_HUB`: `;`-separated [Hub management commands](https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.4_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Virtual_Hub)) (currently only for `DEFAULT` hub).

Example: Set MTU via [`NatSet`](https://www.softether.org/4-docs/1-manual/6._Command_Line_Management_Utility_Manual/6.4_VPN_Server_%2F%2F_VPN_Bridge_Management_Command_Reference_(For_Virtual_Hub)#6.4.97_.22NatSet.22:_Change_Virtual_NAT_Function_Setting_of_SecureNAT_Function) Hub management command:
`-e VPNCMD_HUB='NatSet /MTU:1500'`

Note that commands run only if the config file is not mounted. Some commands (like `ServerPasswordSet`) will cause problems.

## OpenVPN ##

`docker run -d --cap-add NET_ADMIN -p 1194:1194/udp siomiz/softethervpn`

The entire log can be saved and used as an `.ovpn` config file (change as needed).

Server CA certificate will be created automatically at runtime if it's not set. You can supply _a self-signed 1024-bit RSA certificate/key pair_ created locally OR use the `gencert` script described below. Feed the keypair contents via `-e CERT` and `-e KEY` ([use of `--env-file`][3] is recommended). X.509 markers (like `-----BEGIN CERTIFICATE-----`) and any non-BASE64 character (incl. newline) can be omitted and will be ignored.

Examples (assuming bash; note the double-quotes `"` and backticks `` ` ``):

* ``-e CERT="`cat server.crt`" -e KEY="`cat server.key`"``
* `-e CERT="MIIDp..b9xA=" -e KEY="MIIEv..x/A=="`
* `--env-file /path/to/envlist`

`env-file` template can be generated by:

`docker run --rm siomiz/softethervpn gencert > /path/to/envlist`

The output will have `CERT` and `KEY` already filled in. Modify `PSK`/`USERS`.

Certificate volumes support (like `-v` or `--volumes-from`) will be added at some point...

## License ##

[MIT License][4].

  [1]: https://www.softether.org/
  [2]: https://github.com/SoftEtherVPN/SoftEtherVPN_Stable
  [3]: https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables-e-env-env-file
  [4]: https://github.com/siomiz/SoftEtherVPN/raw/master/LICENSE
