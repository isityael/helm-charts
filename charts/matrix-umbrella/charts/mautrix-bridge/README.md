---
title: "mautrix-bridge"

description: "A Matrix puppeting bridge mautrix."

---

# mautrix-bridge

![Version: 0.0.33](https://img.shields.io/badge/Version-0.0.33-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

A Matrix puppeting bridge mautrix.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| WrenIX |  | <https://wrenix.eu> |

For use of the bridge:
* **signal**, use the `./bridge-values/signal/values.yaml`
* **slack**, use the `./bridge-values/slack/values.yaml`

## Usage

Helm must be installed and setup to your kubernetes cluster to use the charts.
Refer to Helm's [documentation](https://helm.sh/docs) to get started.
Once Helm has been set up correctly, fetch the charts as follows:

```bash
helm pull oci://codeberg.org/wrenix/helm-charts/mautrix-bridge
```

You can install a chart release using the following command:

```bash
helm install mautrix-bridge-release oci://codeberg.org/wrenix/helm-charts/mautrix-bridge --values values.yaml
```

To uninstall a chart release use `helm`'s delete command:

```bash
helm uninstall mautrix-bridge-release
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| config.appservice.address | string | `"http://localhost:29328"` | The address that the homeserver can use to connect to this appservice. |
| config.appservice.as_token | string | `""` |  |
| config.appservice.async_transactions | bool | `false` | Should incoming events be handled asynchronously? This may be necessary for large public instances with lots of messages going through. However, messages will not be guaranteed to be bridged in the same order they were sent in. |
| config.appservice.bot.avatar | string | `"mxc://maunium.net/wPJgTQbZOtpBFmDNkiNEMDUp"` |  |
| config.appservice.bot.displayname | string | `"Signal bridge bot"` | Display name and avatar for bot. Set to "remove" to remove display name/avatar, leave empty to leave display name/avatar as-is. |
| config.appservice.bot.username | string | `"signalbot"` | Username of the appservice bot. |
| config.appservice.ephemeral_events | bool | `true` | Whether or not to receive ephemeral events via appservice transactions. Requires MSC2409 support (i.e. Synapse 1.22+). |
| config.appservice.hostname | string | `"0.0.0.0"` | The hostname and port where this appservice should listen. |
| config.appservice.hs_token | string | `""` |  |
| config.appservice.id | string | `"signal"` | The unique ID of this appservice. |
| config.appservice.port | int | `29328` |  |
| config.appservice.public_address | string | `nil` |  |
| config.appservice.username_template | string | `"signal_{{.}}"` | Localpart template of MXIDs for Signal users. {{.}} is replaced with the internal ID of the Signal user. |
| config.backfill.enabled | bool | `false` | Whether to do backfilling at all. |
| config.backfill.max_catchup_messages | int | `500` | Maximum number of missed messages to backfill after bridge restarts. |
| config.backfill.max_initial_messages | int | `50` | Maximum number of messages to backfill in empty rooms. |
| config.backfill.queue.batch_delay | int | `20` | Delay between batches in seconds. |
| config.backfill.queue.batch_size | int | `100` | Number of messages to backfill in one batch. |
| config.backfill.queue.enabled | bool | `false` | Should the backfill queue be enabled? |
| config.backfill.queue.max_batches | int | `-1` | Maximum number of batches to backfill per portal. If set to -1, all available messages will be backfilled. |
| config.backfill.queue.max_batches_override | object | `{}` | Optional network-specific overrides for max batches. Interpretation of this field depends on the network connector. |
| config.backfill.threads.max_initial_messages | int | `50` | Maximum number of messages to backfill in a new thread. |
| config.backfill.unread_hours_threshold | int | `720` | If a backfilled chat is older than this number of hours, mark it as read even if it's unread on the remote network. |
| config.bridge.bridge_matrix_leave | bool | `false` | Should leaving Matrix rooms be bridged as leaving groups on the remote network? |
| config.bridge.cleanup_on_logout.bad_credentials.private | string | `"nothing"` |  |
| config.bridge.cleanup_on_logout.bad_credentials.relayed | string | `"nothing"` |  |
| config.bridge.cleanup_on_logout.bad_credentials.shared_has_users | string | `"nothing"` |  |
| config.bridge.cleanup_on_logout.bad_credentials.shared_no_users | string | `"nothing"` |  |
| config.bridge.cleanup_on_logout.enabled | bool | `false` | Should cleanup on logout be enabled at all? |
| config.bridge.cleanup_on_logout.manual.private | string | `"nothing"` | Action for private portals which will never be shared with other Matrix users. |
| config.bridge.cleanup_on_logout.manual.relayed | string | `"nothing"` | Action for portals with a relay user configured. |
| config.bridge.cleanup_on_logout.manual.shared_has_users | string | `"nothing"` | Action for portals which have other logged-in Matrix users. |
| config.bridge.cleanup_on_logout.manual.shared_no_users | string | `"nothing"` | Action for portals which may be shared, but don't currently have any other Matrix users. |
| config.bridge.command_prefix | string | `"!bridge"` | The prefix for commands. Only required in non-management rooms. |
| config.bridge.mute_only_on_create | bool | `true` | Should room mute status only be synced when creating the portal? Like tags, mutes can't currently be synced back to the remote network. |
| config.bridge.permissions | object | `{"*":"relay","@admin:example.com":"admin","example.com":"user"}` | Permissions for using the bridge. Permitted values:    relay - Talk through the relaybot (if enabled), no access otherwise commands - Access to use commands in the bridge, but not login.     user - Access to use the bridge with puppeting.    admin - Full access, user level with some additional administration tools. Permitted keys:        * - All Matrix users   domain - All users on that homeserver     mxid - Specific user |
| config.bridge.personal_filtering_spaces | bool | `true` | Should the bridge create a space for each login containing the rooms that account is in? |
| config.bridge.private_chat_portal_meta | bool | `false` | Whether the bridge should set names and avatars explicitly for DM portals. This is only necessary when using clients that don't support MSC4171. |
| config.bridge.relay.admin_only | bool | `true` | Should only admins be allowed to set themselves as relay users? |
| config.bridge.relay.default_relays | list | `[]` | List of user login IDs which anyone can set as a relay, as long as the relay user is in the room. |
| config.bridge.relay.displayname_format | string | `"{{ .DisambiguatedName }}"` | For networks that support per-message displaynames (i.e. Slack and Discord), the template for those names. This has all the Sender variables available under message_formats (but without the .Sender prefix). Note that you need to manually remove the displayname from message_formats above. |
| config.bridge.relay.enabled | bool | `false` | Whether relay mode should be allowed. If allowed, `!wa set-relay` can be used to turn any authenticated user into a relaybot for that chat. |
| config.bridge.relay.message_formats | object | `{"m.audio":"<b>{{ .Sender.DisambiguatedName }}</b> sent an audio file{{ if .Caption }}: {{ .Caption }}{{ end }}","m.emote":"* <b>{{ .Sender.DisambiguatedName }}</b> {{ .Message }}","m.file":"<b>{{ .Sender.DisambiguatedName }}</b> sent a file{{ if .Caption }}: {{ .Caption }}{{ end }}","m.image":"<b>{{ .Sender.DisambiguatedName }}</b> sent an image{{ if .Caption }}: {{ .Caption }}{{ end }}","m.location":"<b>{{ .Sender.DisambiguatedName }}</b> sent a location{{ if .Caption }}: {{ .Caption }}{{ end }}","m.notice":"<b>{{ .Sender.DisambiguatedName }}</b>: {{ .Message }}","m.text":"<b>{{ .Sender.DisambiguatedName }}</b>: {{ .Message }}","m.video":"<b>{{ .Sender.DisambiguatedName }}</b> sent a video{{ if .Caption }}: {{ .Caption }}{{ end }}"}` | The formats to use when sending messages via the relaybot. Available variables:   .Sender.UserID - The Matrix user ID of the sender.   .Sender.Displayname - The display name of the sender (if set).   .Sender.RequiresDisambiguation - Whether the sender's name may be confused with the name of another user in the room.   .Sender.DisambiguatedName - The disambiguated name of the sender. This will be the displayname if set,                               plus the user ID in parentheses if the displayname is not unique.                               If the displayname is not set, this is just the user ID.   .Message - The `formatted_body` field of the message.   .Caption - The `formatted_body` field of the message, if it's a caption. Otherwise an empty string.   .FileName - The name of the file being sent. |
| config.bridge.tag_only_on_create | bool | `true` | Should room tags only be synced when creating the portal? Tags mean things like favorite/pin and archive/low priority. Tags currently can't be synced back to the remote network, so a continuous sync means tagging from Matrix will be undone. |
| config.database.max_conn_idle_time | string | `nil` | Maximum connection idle time and lifetime before they're closed. Disabled if null. Parsed with https://pkg.go.dev/time#ParseDuration |
| config.database.max_conn_lifetime | string | `nil` |  |
| config.database.max_idle_conns | int | `2` |  |
| config.database.max_open_conns | int | `20` | Maximum number of connections. Mostly relevant for Postgres. |
| config.database.type | string | `"postgres"` | The database type. "sqlite3-fk-wal" and "postgres" are supported. |
| config.database.uri | string | `"postgres://user:password@host/database?sslmode=disable"` | The database URI.   SQLite: A raw file path is supported, but `file:<path>?_txlock=immediate` is recommended.           https://github.com/mattn/go-sqlite3#connection-string   Postgres: Connection string. For example, postgres://user:password@host/database?sslmode=disable             To connect via Unix socket, use something like postgres:///dbname?host=/var/run/postgresql |
| config.direct_media.allow_proxy | bool | `true` | If the remote network supports media downloads over HTTP, then the bridge will use MSC3860/MSC3916 media download redirects if the requester supports it. Optionally, you can force redirects and not allow proxying at all by setting this to false. This option does nothing if the remote network does not support media downloads over HTTP. |
| config.direct_media.enabled | bool | `false` | Should custom mxc:// URIs be used instead of reuploading media? |
| config.direct_media.media_id_prefix | string | `nil` | Optionally specify a custom prefix for the media ID part of the MXC URI. |
| config.direct_media.server_key | string | `""` | Matrix server signing key to make the federation tester pass, same format as synapse's .signing.key file. This key is also used to sign the mxc:// URIs to ensure only the bridge can generate them. |
| config.direct_media.server_name | string | `"discord-media.example.com"` | The server name to use for the custom mxc:// URIs. This server name will effectively be a real Matrix server, it just won't implement anything other than media. You must either set up .well-known delegation from this domain to the bridge, or proxy the domain directly to the bridge. |
| config.direct_media.well_known_response | string | `nil` | Optionally a custom .well-known response. This defaults to `server_name:443` |
| config.double_puppet.allow_discovery | bool | `false` | Whether to allow client API URL discovery for other servers. When using this option, users on other servers can use double puppeting even if their server URLs aren't explicitly added to the servers map above. |
| config.double_puppet.secrets | object | `{"example.com":"as_token:foobar"}` | Shared secrets for automatic double puppeting. See https://docs.mau.fi/bridges/general/double-puppeting.html for instructions. |
| config.double_puppet.servers | object | `{"example.com":"https://example.com"}` | Servers to always allow double puppeting from. This is only for other servers and should NOT contain the server the bridge is on. |
| config.encryption.allow | bool | `false` | Allow encryption, work in group chat rooms with e2ee enabled |
| config.encryption.allow_key_sharing | bool | `false` | Enable key sharing? If enabled, key requests for rooms where users are in will be fulfilled. You must use a client that supports requesting keys from other users to use this feature. |
| config.encryption.appservice | bool | `false` | Whether to use MSC2409/MSC3202 instead of /sync long polling for receiving encryption-related data. |
| config.encryption.default | bool | `false` | Default to encryption, force-enable encryption in all portals the bridge creates This will cause the bridge bot to be in private chats for the encryption to work properly. |
| config.encryption.delete_keys | object | `{"delete_fully_used_on_decrypt":false,"delete_on_device_delete":false,"delete_outbound_on_ack":false,"delete_outdated_inbound":false,"delete_prev_on_new_session":false,"dont_store_outbound":false,"periodically_delete_expired":false,"ratchet_on_decrypt":false}` | Options for deleting megolm sessions from the bridge. |
| config.encryption.delete_keys.delete_fully_used_on_decrypt | bool | `false` | Delete fully used keys (index >= max_messages) after decrypting messages. |
| config.encryption.delete_keys.delete_on_device_delete | bool | `false` | Delete megolm sessions received from a device when the device is deleted. |
| config.encryption.delete_keys.delete_outbound_on_ack | bool | `false` | Beeper-specific: delete outbound sessions when hungryserv confirms that the user has uploaded the key to key backup. |
| config.encryption.delete_keys.delete_outdated_inbound | bool | `false` | Delete inbound megolm sessions that don't have the received_at field used for automatic ratcheting and expired session deletion. This is meant as a migration to delete old keys prior to the bridge update. |
| config.encryption.delete_keys.delete_prev_on_new_session | bool | `false` | Delete previous megolm sessions from same device when receiving a new one. |
| config.encryption.delete_keys.dont_store_outbound | bool | `false` | Don't store outbound sessions in the inbound table. |
| config.encryption.delete_keys.periodically_delete_expired | bool | `false` | Periodically delete megolm sessions when 2x max_age has passed since receiving the session. |
| config.encryption.delete_keys.ratchet_on_decrypt | bool | `false` | Ratchet megolm sessions forward after decrypting messages. |
| config.encryption.pickle_key | string | `nil` |  |
| config.encryption.plaintext_mentions | string | `nil` |  |
| config.encryption.require | bool | `false` | Require encryption, drop any unencrypted messages. |
| config.encryption.rotation.disable_device_change_key_rotation | bool | `false` | Disable rotating keys when a user's devices change? You should not enable this option unless you understand all the implications. |
| config.encryption.rotation.enable_custom | bool | `false` | Enable custom Megolm room key rotation settings. Note that these settings will only apply to rooms created after this option is set. |
| config.encryption.rotation.messages | int | `100` | The maximum number of messages that should be sent with a given a session before changing it. The Matrix spec recommends 100 as the default. |
| config.encryption.rotation.milliseconds | int | `604800000` | The maximum number of milliseconds a session should be used before changing it. The Matrix spec recommends 604800000 (a week) as the default. |
| config.encryption.verification_levels.receive | string | `"unverified"` | Minimum level for which the bridge should send keys to when bridging messages from Signal to Matrix. |
| config.encryption.verification_levels.send | string | `"unverified"` | Minimum level that the bridge should accept for incoming Matrix messages. |
| config.encryption.verification_levels.share | string | `"cross-signed-tofu"` | Minimum level that the bridge should require for accepting key requests. |
| config.homeserver.address | string | `"https://matrix.example.com"` | The address that this appservice can use to connect to the homeserver. |
| config.homeserver.async_media | bool | `false` | Does the homeserver support https://github.com/matrix-org/matrix-spec-proposals/pull/2246? |
| config.homeserver.domain | string | `"example.com"` | The domain of the homeserver (also known as server_name, used for MXIDs, etc). |
| config.homeserver.message_send_checkpoint_endpoint | string | `nil` | Endpoint for reporting per-message status. |
| config.homeserver.ping_interval_seconds | int | `0` | How often should the websocket be pinged? Pinging will be disabled if this is zero. |
| config.homeserver.public_address | string | `nil` |  |
| config.homeserver.software | string | `"standard"` | What software is the homeserver running? Standard Matrix homeservers like Synapse, Dendrite and Conduit should just use "standard" here. |
| config.homeserver.status_endpoint | string | `nil` | The URL to push real-time bridge status to. If set, the bridge will make POST requests to this URL whenever a user's Signal connection state changes. The bridge will use the appservice as_token to authorize requests. |
| config.homeserver.websocket | bool | `false` | Should the bridge use a websocket for connecting to the homeserver? The server side is currently not documented anywhere and is only implemented by mautrix-wsproxy, mautrix-asmux (deprecated), and hungryserv (proprietary). |
| config.homeserver.websocket_proxy | string | `""` |  |
| config.logging.min_level | string | `"warn"` |  |
| config.logging.writers[0].format | string | `"json"` |  |
| config.logging.writers[0].type | string | `"stdout"` |  |
| config.management_room_text.additional_help | string | `""` | Optional extra text sent when joining a management room. |
| config.management_room_text.welcome | string | `"Hello, I'm a Signal bridge bot."` | Sent when joining a room. |
| config.management_room_text.welcome_connected | string | `"Use `help` for help."` | Sent when joining a management room and the user is already logged in. |
| config.management_room_text.welcome_unconnected | string | `"Use `help` for help or `login` to log in."` | Sent when joining a management room and the user is not logged in. |
| config.matrix.delivery_receipts | bool | `false` | Should the bridge send a read receipt from the bridge bot when a message has been sent to Signal? |
| config.matrix.federate_rooms | bool | `true` | Whether or not created rooms should have federation enabled. If false, created portal rooms will never be federated. |
| config.matrix.message_error_notices | bool | `true` | Whether the bridge should send error notices via m.notice events when a message fails to bridge. |
| config.matrix.message_status_events | bool | `false` | Whether the bridge should send the message status as a custom com.beeper.message_send_status event. |
| config.matrix.sync_direct_chat_list | bool | `false` | Should the bridge update the m.direct account data event when double puppeting is enabled. Note that updating the m.direct event is not atomic (except with mautrix-asmux) and is therefore prone to race conditions. |
| config.provisioning.debug_endpoints | bool | `false` | Enable debug API at /debug with provisioning authentication. |
| config.provisioning.prefix | string | `"/_matrix/provision"` | Prefix for the provisioning API paths. |
| config.provisioning.shared_secret | string | `"generate"` | Shared secret for authentication. If set to "generate", a random secret will be generated, or if set to "disable", the provisioning API will be disabled. |
| config.public_media.enabled | bool | `false` | Should public media be enabled at all? The public_address field under the appservice section MUST be set when enabling public media. |
| config.public_media.expiry | int | `0` | Number of seconds that public media URLs are valid for. If set to 0, URLs will never expire. |
| config.public_media.hash_length | int | `32` | Length of hash to use for public media URLs. Must be between 0 and 32. |
| config.public_media.signing_key | string | `"generate"` | A key for signing public media URLs. If set to "generate", a random key will be generated. |
| config.signal.device_name | string | `"mautrix-signal"` | Default device name that shows up in the Signal app. |
| config.signal.displayname_template | string | `"{{ printf \"%s (%s) %s\" (or .ProfileName .ContactName \"Unknown user\") (or .PhoneNumber \"Unknown number\" (or .AboutEmoji \"\")}}"` | Displayname template for Signal users. This is also used as the room name in DMs if private_chat_portal_meta is enabled. {{.ProfileName}} - The Signal profile name set by the user. {{.ContactName}} - The name for the user from your phone's contact list. This is not safe on multi-user instances. {{.PhoneNumber}} - The phone number of the user. {{.UUID}} - The UUID of the Signal user. {{.AboutEmoji}} - The emoji set by the user in their profile. |
| config.signal.location_format | string | `"https://www.openstreetmap.org/?mlat=%[1]s&mlon=%[2]s"` |  |
| config.signal.note_to_self_avatar | string | `"mxc://maunium.net/REBIVrqjZwmaWpssCZpBlmlL"` |  |
| config.signal.number_in_topic | bool | `true` | Should the Signal user's phone number be included in the room topic in private chat portal rooms? |
| config.signal.sync_contacts_on_startup | bool | `true` | Should the bridge request the user's contact list from the phone on startup? |
| config.signal.use_contact_avatars | bool | `false` | Should avatars from the user's contact list be used? This is not safe on multi-user instances. |
| config.signal.use_outdated_profiles | bool | `false` | Should the bridge sync ghost user info even if profile fetching fails? This is not safe on multi-user instances. |
| fullnameOverride | string | `""` |  |
| global.image.pullPolicy | string | `nil` | if set it will overwrite all pullPolicy |
| global.image.registry | string | `nil` | if set it will overwrite all registry entries |
| image.pullPolicy | string | `"IfNotPresent"` | This sets the pull policy for images. (could be overwritten by global.image.pullPolicy) |
| image.registry | string | `"dock.mau.dev"` | image registry (could be overwritten by global.image.registry) |
| image.repository | string | `""` | image repository |
| image.tag | string | `""` | image tag |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| livenessProbe.httpGet.path | string | `"/_matrix/mau/live"` |  |
| livenessProbe.httpGet.port | string | `"http"` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| persistence.accessMode | string | `"ReadWriteOnce"` | accessMode |
| persistence.annotations | object | `{}` |  |
| persistence.enabled | bool | `true` | Enable persistence using Persistent Volume Claims ref: http://kubernetes.io/docs/user-guide/persistent-volumes/ |
| persistence.existingClaim | string | `nil` | A manually managed Persistent Volume and Claim Requires persistence.enabled: true If defined, PVC must be created manually before volume will be bound |
| persistence.hostPath | string | `nil` | Do not create an PVC, direct use hostPath in Pod |
| persistence.size | string | `"10Gi"` | size |
| persistence.storageClass | string | `nil` | Persistent Volume Storage Class If defined, storageClassName: <storageClass> If set to "-", storageClassName: "", which disables dynamic provisioning If undefined (the default) or set to null, no storageClassName spec is   set, choosing the default provisioner.  (gp2 on AWS, standard on   GKE, AWS & OpenStack) |
| podAnnotations | object | `{}` |  |
| podLabels | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| readinessProbe.httpGet.path | string | `"/_matrix/mau/ready"` |  |
| readinessProbe.httpGet.port | string | `"http"` |  |
| registration."de.sorunome.msc2409.push_ephemeral" | bool | `true` |  |
| registration.namespaces.users[0].exclusive | bool | `true` |  |
| registration.namespaces.users[0].regex | string | `"^@signalbot:example.org$"` |  |
| registration.namespaces.users[1].exclusive | bool | `true` |  |
| registration.namespaces.users[1].regex | string | `"^@signal_.*:example.org$"` |  |
| registration.push_ephemeral | bool | `true` |  |
| registration.rate_limited | bool | `false` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext | object | `{}` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.automount | bool | `false` |  |
| serviceAccount.create | bool | `false` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |
| volumeMounts | list | `[]` |  |
| volumes | list | `[]` |  |

Autogenerated from chart metadata using [helm-docs](https://github.com/norwoodj/helm-docs)
