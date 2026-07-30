# NÓVA — Estúdio Criativo Digital

Site institucional (single-file, HTML/CSS/JS puro, sem dependências externas).

## Deploy no Cloudflare Pages

### Deploy automatico
Todo push para `main` roda `.github/workflows/deploy.yml`, que:

1. publica o site no Cloudflare Pages;
2. garante o dominio `www.nvaestudio.com`;
3. cria/atualiza o DNS `www -> novaestudio.pages.dev`.

Secrets necessarios no GitHub:

```text
CLOUDFLARE_ACCOUNT_ID=a2cf92efff3b498bce86124be2ce4352
CLOUDFLARE_API_TOKEN=<token com Pages Edit + Zone DNS Edit>
```

O token Cloudflare deve ser escopado assim:

```text
Account permissions:
- Cloudflare Pages: Edit

Zone permissions:
- DNS: Edit

Zone resources:
- Include: nvaestudio.com
```

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
