# NÓVA — Estúdio Criativo Digital

Site institucional (single-file, HTML/CSS/JS puro, sem dependências externas).

## Deploy no Cloudflare Pages

### Opção A — Direct Upload (mais rápido, sem GitHub)
1. Acesse dash.cloudflare.com → **Workers & Pages** → **Create** → **Pages** → **Upload assets**.
2. Nome do projeto: `novaestudio`.
3. Arraste os arquivos desta pasta (ou o zip) e clique em **Deploy**.
4. Em **Custom domains**, adicione `novaestudio.com` (o Cloudflare configura o DNS automaticamente se o domínio estiver na sua conta).

### Opção B — GitHub + Pages (deploy automático a cada push)
```bash
# nesta pasta:
git remote add origin https://github.com/SEU_USUARIO/novaestudio-site.git
git push -u origin main
```
Depois: Cloudflare Pages → **Connect to Git** → selecione o repo → Build command: (vazio) → Output dir: `/` → **Deploy**.

## Estrutura
- `index.html` — o site completo
- `_headers` — headers de segurança/cache (Cloudflare Pages)
- `wrangler.toml` — config opcional p/ deploy via Wrangler CLI
