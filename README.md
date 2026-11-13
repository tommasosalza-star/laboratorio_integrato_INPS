# Laboratorio Integrato I.N.P.S.

Repository condivisa del gruppo 5 per il progetto Cloud Security & DevSecOps su AWS.

## Documentazione operativa

- [AWS Learner Lab — configurazione e limiti verificati](docs/LEARNER_LAB_SANDBOX.md): snapshot AWS CLI, permessi misurati in dry-run, quote e prossimi passi.

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

## Infrastruttura AWS con OpenTofu

La configurazione in `terraform/` crea un ambiente di laboratorio composto da:

- una VPC con subnet pubblica e Internet Gateway;
- una EC2 Ubuntu 24.04 LTS per il WAF, con Nginx e ModSecurity, che inoltra il traffico a Juice Shop;
- una EC2 Ubuntu 24.04 LTS per il SIEM, con Wazuh all-in-one;
- una EC2 Ubuntu 24.04 LTS per Juice Shop, eseguito in Docker;
- security group separati per limitare il traffico tra i tre ruoli;
- IAM instance profile con accesso ad AWS Systems Manager (SSM).

I file OpenTofu sono organizzati per responsabilità:

- `versions.tf`: versione OpenTofu/provider AWS;
- `variables.tf`: regione, CIDR amministrativo, chiave EC2 e tipi di istanza;
- `data.tf`: AMI Ubuntu e dati AWS;
- `network.tf`: VPC, subnet, routing e Internet Gateway;
- `security.tf`: security group;
- `iam.tf`: ruolo e instance profile per SSM;
- `instances.tf`: le tre istanze EC2 e i relativi script di bootstrap;
- `outputs.tf`: indirizzi IP risultanti.

### Prerequisiti

- OpenTofu installato;
- credenziali AWS configurate, ad esempio tramite AWS CLI profile o variabili d'ambiente;
- una regione AWS con disponibilità per `t3.small` e `t3.large`;
- facoltativamente, una key pair EC2 per accesso SSH.

### Configurazione e deploy

Eseguire i comandi dalla directory `terraform/`:

```bash
tofu init
tofu fmt
tofu validate
tofu plan -var='admin_cidr=IP_PUBBLICO/32' -var='key_name=NOME_KEY_PAIR'
tofu apply -var='admin_cidr=IP_PUBBLICO/32' -var='key_name=NOME_KEY_PAIR'
```

`admin_cidr` controlla gli accessi SSH. Sostituire `IP_PUBBLICO/32` con il proprio indirizzo IP, evitando di lasciare `0.0.0.0/0` in un ambiente non isolato. `key_name` è opzionale se si utilizza SSM.

Dopo il deploy, ottenere gli indirizzi con:

```bash
tofu output
```

L'indirizzo `waf_public_ip` è il punto di ingresso per Juice Shop. Il servizio applicativo non è esposto direttamente a Internet: la porta 3000 accetta traffico soltanto dal security group del WAF.

Per rimuovere tutte le risorse create dal laboratorio:

```bash
tofu destroy -var='admin_cidr=IP_PUBBLICO/32' -var='key_name=NOME_KEY_PAIR'
```

La configurazione usa un WAF software su EC2, non AWS WAF gestito. Il laboratorio è intenzionalmente esposto a componenti vulnerabili e deve essere utilizzato soltanto in un account AWS autorizzato e con costi monitorati.
