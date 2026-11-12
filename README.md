# Laboratorio Integrato I.N.P.S.

Repository condivisa del gruppo 5 per il progetto Cloud Security & DevSecOps su AWS.

## Dipendenza applicativa

OWASP Juice Shop è incluso come submodule Git in `apps/juice-shop` e fissato a una release verificata. La provenienza e la procedura di aggiornamento sono documentate in `apps/README.md`.

Clonazione completa:

```bash
git clone --recurse-submodules https://github.com/tommasosalza-star/laboratorio_integrato_INPS.git
```

Inizializzazione dopo un clone già esistente:

```bash
git submodule update --init --recursive
```

Juice Shop è intenzionalmente vulnerabile. Deve essere eseguito esclusivamente in un ambiente di laboratorio isolato e autorizzato.
