# Applicazioni esterne

## OWASP Juice Shop

- Upstream: `https://github.com/juice-shop/juice-shop.git`
- Integrazione: Git submodule
- Percorso: `apps/juice-shop`
- Release: `v20.4.0`
- Commit: `266448aba68cd8ba5915f526a128da4fa7bc3f9f`
- Licenza upstream: MIT

La repository principale registra soltanto il commit del submodule: la storia Git di Juice Shop non viene incorporata nella storia del progetto I.N.P.S.

## Regole operative

- Non sviluppare direttamente sul checkout upstream.
- Se servono modifiche applicative, creare prima un fork del team e aggiornare l'URL del submodule con una decisione esplicita.
- Aggiornare Juice Shop soltanto tramite una release scelta e testata, mai seguendo automaticamente `master`.
- Eseguire l'applicazione solo nell'ambiente di laboratorio autorizzato.

## Aggiornamento controllato

```bash
git -C apps/juice-shop fetch --tags origin
git -C apps/juice-shop checkout <tag-o-commit-approvato>
git add apps/juice-shop
```

Registrare nel commit della repository principale la nuova versione, il commit upstream e le verifiche eseguite.
