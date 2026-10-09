# Login throttling and bot protection

Use Hermes's built-in password login with a Cloudflare login-endpoint rate limit. Cloudflare Access remains optional; you do not need another identity login to use the rate limit.

## What current upstream Hermes provides

The upstream password-login route inspected for this project, `POST /auth/password-login`, has these protections:

| Protection | Behavior |
|---|---|
| Login attempt limit | 10 attempts per client IP in a rolling 60-second window |
| Over-limit response | HTTP `429`, “Too many login attempts. Try again shortly.” |
| Password verification | Scrypt hashing and timing-resistant comparisons |
| Authentication audit log | Successful logins, failed logins, and rate-limit events |

All attempts count, not just failures. The limiter is per dashboard process, stored in memory, and resets on restart. Attempts become available as older entries expire from the window. It is not a permanent account lockout, and attackers using different IPs receive separate attempt budgets.

The inspected password-login flow does not include CAPTCHA, Turnstile, or dedicated bot detection. These behaviors come from upstream Hermes, not new code added by this repository. Rebuild an existing Hermes image from the updated upstream checkout before relying on the current implementation; see [Cloudflare Tunnel hosting](cloudflare-tunnel.md#3-deploy). If pinning an older upstream revision, verify its implementation separately.

## Add a Cloudflare rate-limiting rule

Configure this in the Cloudflare dashboard for your domain, under **Security → Security rules → Rate limiting rules**. Dashboard navigation can vary. Ansible does not create this rule or manage your manual connector.

Create a rule called **Hermes login burst limit** with these starting values:

| Setting | Value |
|---|---|
| Match | Request path equals `/auth/password-login` |
| Count by | Client IP |
| Threshold | 5 requests in 10 seconds |
| Action | Block |
| Duration | 10 seconds |

This counts login requests, not whether their passwords were wrong. It limits rapid bursts at Cloudflare before they reach Hermes; Hermes also applies its longer rolling window. Apply this to the login endpoint only, so normal dashboard traffic and chat WebSockets are not counted by this rule.

### Free plan expression

Cloudflare's current Free plan supports one rate-limiting rule, an IP counter, and 10-second counting/block periods. Its filter fields do not include hostname or request method. Use:

```text
(http.request.uri.path eq "/auth/password-login")
```

The rule applies to that path across proxied hostnames in the domain. Check whether another application uses the same path before enabling it. Do not add a hostname or POST-method condition to a Free-plan rate-limiting rule if the dashboard does not offer those fields.

### Plans supporting hostname matching

On Pro or higher, restrict the rule to the Hermes hostname as well. Replace the example domain with your actual public hostname in Cloudflare:

```text
(http.host eq "hermes.example.com" and http.request.uri.path eq "/auth/password-login")
```

Use the same threshold/action above as a starting point. Available fields and periods depend on the plan; consult Cloudflare's current availability table below. Edge rate limiting is not an exact request budget: counter propagation can allow additional requests through before enforcement.

Use **Block** for the login endpoint rather than inserting a browser challenge into its background form submission; a challenge response there can interfere with login. Enable the rule after confirming an ordinary Hermes login works, then test one again after enabling it.

## Optional bot detection

Cloudflare **Bot Fight Mode** detects and challenges traffic matching known bot patterns. It is separate from Cloudflare Access and is not enabled by this project.

On the Free plan it applies across the domain, can challenge legitimate API/automated clients, and cannot be skipped by a per-path WAF rule. Start with the targeted login rate limit. If enabling Bot Fight Mode later, verify your other applications, dashboard login, and chat connections still work.

Cloudflare Access is another optional layer: it adds an outer identity gate, whereas rate limiting restricts request frequency. See [Cloudflare Tunnel hosting](cloudflare-tunnel.md#optional-add-cloudflare-access-later) if you decide to add it later.

## Verify on the deployed VM

After a login or a deliberately incorrect login, inspect the audit log:

```bash
sudo tail -n 30 /srv/hermes/logs/dashboard-auth.log
```

The default data mount places the log there. Look for `login_success`, `login_failure`, and the `ip` field. A throttled attempt is logged as a login failure with reason `rate_limited`. This log is separate from `docker compose logs`.

The client IP should represent the visitor, not always `127.0.0.1` or the connector address. Hermes trusts loopback proxy connections by default in authenticated mode; the tunnel should forward client IP and HTTPS scheme information. If visitors are all recorded under one connector IP, investigate forwarding before relying on per-visitor throttling. Do not add wildcard trusted proxies.

Use Cloudflare's Security Events view to inspect edge rule blocks. Several users sharing a public IP also share an IP-based request budget. If you hit a limit during testing, wait for its window/block period to expire; do not remove authentication to regain access.

A short password is allowed by the hash helper for testing, but use a long, unique password for the public dashboard. Scrypt and rate limits do not replace password strength. [Dashboard hashes and Ansible Vault](dashboard-auth.md) explains password changes and session invalidation.

## Sources

- [Hermes password-login route and throttle](https://github.com/NousResearch/hermes-agent/blob/main/hermes_cli/dashboard_auth/routes.py)
- [Hermes password provider](https://github.com/NousResearch/hermes-agent/blob/main/plugins/dashboard_auth/basic/__init__.py)
- [Cloudflare rate limiting and plan availability](https://developers.cloudflare.com/waf/rate-limiting-rules/)
- [Cloudflare Bot Fight Mode](https://developers.cloudflare.com/bots/get-started/bot-fight-mode/)
