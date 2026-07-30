# NÓVA — Estúdio Criativo Digital

Site institucional (single-file, HTML/CSS/JS puro, sem dependências externas).

## Deploy no Cloudflare Pages

### Publicar via Wrangler
```bash
npx wrangler pages deploy . --project-name novaestudio --branch main --commit-dirty=true
```

### GitHub
```bash
git remote add origin https://github.com/garc90/nova-estudio.git
git push -u origin main
```

### Domínio customizado
O site usa:

```text
www.nvaestudio.com -> novaestudio.pages.dev
```

Para automatizar a configuração do Cloudflare Pages + DNS:

```bash
./scripts/cloudflare-domain.sh
```

O script espera um token Cloudflare com permissão `Zone / DNS / Edit` para a zona `nvaestudio.com`. Ele lê o token de `CLOUDFLARE_API_TOKEN` ou do Keychain do macOS:

```bash
security add-generic-password -a "$USER" -s cloudflare-dns-api-token -w 'PASTE_TOKEN_HERE' -U
```

## Estrutura
- `index.html` — o site completo
- `_headers` — headers de segurança/cache (Cloudflare Pages)
- `wrangler.toml` — config opcional p/ deploy via Wrangler CLI
- `scripts/cloudflare-domain.sh` — automação idempotente do domínio customizado
