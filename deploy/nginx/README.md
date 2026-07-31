# nginx / TLS on the EC2 box

Copies of the reverse-proxy config that terminates TLS for `api.nowlii.com` (Django `:8000`)
and `ai.nowlii.com` (nowli-ai `:8001`). Captured from the box on **2026-07-31**, the day HTTPS
went live.

**These files are a backup, not a deploy mechanism.** nginx runs on the host, not in Docker, and
`git archive` only ships `nowli-backend/` and `nowli-ai/` — so nothing here reaches the box
automatically. Without this directory the whole setup existed in exactly one place.

## Where each file lives on the box

| Repo | Box |
|---|---|
| `api.nowlii.com.conf` | `/etc/nginx/sites-available/api.nowlii.com` (symlinked into `sites-enabled/`) |
| `ai.nowlii.com.conf` | `/etc/nginx/sites-available/ai.nowlii.com` (symlinked into `sites-enabled/`) |
| `snippets/upgrade-map.conf` | `/etc/nginx/conf.d/upgrade-map.conf` |
| `snippets/apple-domain-assoc.conf` | `/etc/nginx/snippets/apple-domain-assoc.conf` |

## Things that are load-bearing, not cosmetic

- **`ai` needs `proxy_buffering off` + long timeouts.** `/api/v1/chat-stream` is **SSE**; with
  buffering on, nginx withholds the stream until the response completes and the AI appears to
  hang, then dump everything at once.
- **`client_max_body_size 25m`** on both — media uploads (Django) and recorded audio posted to
  `detect-emotion` (nowli-ai). The 1 MB default silently 413s them.
- **`apple-domain-assoc.conf` uses an exact-match (`location =`)** so it cannot shadow
  `/.well-known/acme-challenge/`. A prefix match there would break certificate renewal — the
  failure would surface ~60 days later, as an expiry.
- The `listen 443` / `ssl_certificate` lines marked `# managed by Certbot` were added by
  `certbot --nginx` **into the existing server block** (it does not create a second one).
- Issued with **`--no-redirect` on purpose.** A forced HTTP→HTTPS redirect is wrong until
  `:8000`/`:8001` are closed, because pre-HTTPS app builds still talk plain HTTP to them.

## Rebuilding this from scratch

```bash
sudo apt-get install -y nginx certbot python3-certbot-nginx
# copy the files to the paths in the table above, then:
sudo ln -s /etc/nginx/sites-available/api.nowlii.com /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/ai.nowlii.com  /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d api.nowlii.com -d ai.nowlii.com --agree-tos -m nowliiapp@gmail.com --no-redirect
```

Prerequisites that are **not** in this repo: the `api`/`ai` A records at GoDaddy pointing to the
box, and ports 80/443 open in the security group (Console only — the `Nowlii` IAM keys are
S3-only and cannot touch EC2). See `docs/deploy-aws.md`.
