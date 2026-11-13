# AWS Learner Lab — configurazione e limiti verificati

Stato: `Snapshot operativo verificato`
Data verifica: `2026-11-13`
Repository: `dev` allineato a `origin/dev` (`a8e0e1c`)
Ambiente: AWS Learner Lab, regione `us-east-1`

Questo documento descrive ciò che è stato osservato via AWS CLI con il profilo locale `learnerlab`. Non contiene credenziali e non costituisce autorizzazione al deploy. I valori riferiti all'account o alle risorse temporanee devono essere ricontrollati prima di ogni finestra di lavoro.

## 1. Accesso e igiene delle credenziali

Il profilo usa credenziali temporanee AWS Academy/Learner Lab:

```bash
aws sts get-caller-identity --profile learnerlab
aws configure list --profile learnerlab
```

L'identità osservata è un ruolo assunto `voclabs`. Le credenziali scadono e devono includere access key, secret key e session token. Non inserire valori credenziali, token, output completi di STS o file `.tfstate` nella repository.

Per evitare di usare accidentalmente un altro account:

```bash
export AWS_PROFILE=learnerlab
export AWS_DEFAULT_REGION=us-east-1
aws sts get-caller-identity
```

Prima di ogni `plan` o `apply` verificare nuovamente l'identità. Il profilo non va memorizzato in file di progetto o in pipeline condivise.

## 2. Snapshot osservato

| Area | Risultato osservato | Implicazione |
| --- | --- | --- |
| Regione | `us-east-1` | Usare la regione del profilo, non una regione hardcoded diversa |
| Availability Zone | `us-east-1a` … `us-east-1f` disponibili | Sono possibili profili multi-AZ, ma il lab può restare single-AZ |
| VPC | Solo default VPC `172.31.0.0/16` | Nessuna VPC di progetto esistente |
| Subnet | Sei subnet default, tutte con public IP automatico | Non sono subnet private di progetto |
| EC2 | Nessuna istanza esistente | Il laboratorio parte da zero |
| Elastic IP | Nessun indirizzo allocato | Non ci sono residui di sessioni precedenti |
| NAT Gateway | Nessuno | Il costo/necessità va deciso prima di creare il primo |
| SSM managed nodes | Nessun nodo registrato | Non esiste ancora un canale operativo verso istanze |
| Key pair | `vockey` presente | Disponibile, ma non è il canale amministrativo preferito |
| Instance profile | `LabInstanceProfile` presente | È il profilo da valutare per tutte le EC2 |
| IAM role | `LabRole` presente | Include `AmazonSSMManagedInstanceCore` |
| Budget | Nessun budget restituito dalla CLI | Non assumere che esista una soglia di spesa AWS |
| CloudWatch | Nessun allarme restituito; presenti log group preesistenti di laboratorio | Separare risorse del progetto da risorse preesistenti |

Le risorse e i log preesistenti non sono del progetto e non devono essere modificati o cancellati.

## 3. Quote e disponibilità verificate

Le Service Quotas interrogate restituiscono:

| Quota | Valore osservato |
| --- | ---: |
| On-Demand Standard (A, C, D, H, I, M, R, T, Z) | 256 vCPU |
| EC2-VPC Elastic IP | 5 |
| VPC per regione | 5 |
| NAT Gateway per Availability Zone | 5 |
| NAT Gateway per VPC | 5 |
| Subnet per VPC | 200 |
| Route table per VPC | 200 |
| Interface VPC endpoint per VPC | 50 |

Le quote non sono un budget e non provano che ogni azione sia consentita dal ruolo. Sono soltanto il limite di servizio esposto dall'account al momento della verifica.

## 4. Permessi misurati senza creare risorse

Sono stati eseguiti test EC2/VPC con `--dry-run`. Il risultato AWS `DryRunOperation` significa che la richiesta sarebbe stata autorizzata, ma non è stata eseguita.

Risultano autorizzate in dry-run:

- creazione VPC e subnet;
- creazione e attach di Internet Gateway;
- creazione route table e route;
- creazione e modifica di security group;
- allocazione Elastic IP;
- creazione di VPC endpoint;
- creazione di NAT Gateway;
- avvio di una `t3.small` Ubuntu 24.04;
- uso di `LabInstanceProfile` tramite `iam:PassRole`.

Il dry-run EC2 con `LabInstanceProfile` è quindi il preflight di riferimento per il team.

### Limiti IAM

Il ruolo `voclabs` non può leggere alcune policy IAM proprie: `iam:GetRole` e `iam:GetPolicy` risultano negati da una policy esplicita del Learner Lab. Non si deve tentare di aggirare il limite né creare ruoli temporanei solo per testarlo.

Conseguenza operativa: il codice deve usare il profilo preesistente `LabInstanceProfile`. La creazione di un ruolo e di un instance profile custom non è una premessa valida per il Learner Lab e resta non approvata finché il team non dispone di un'autorizzazione esplicita.

## 5. Comandi di ricognizione riproducibili

I comandi seguenti sono read-only, salvo il blocco EC2 indicato esplicitamente come dry-run.

### Identità, regione e stato risorse

```bash
aws sts get-caller-identity --profile learnerlab
aws configure list --profile learnerlab

aws ec2 describe-availability-zones \
  --profile learnerlab \
  --region us-east-1 \
  --filters Name=state,Values=available \
  --query 'AvailabilityZones[].ZoneName' \
  --output table

aws ec2 describe-vpcs \
  --profile learnerlab \
  --region us-east-1 \
  --query 'Vpcs[].{Id:VpcId,Cidr:CidrBlock,Default:IsDefault,State:State}' \
  --output table

aws ec2 describe-instances \
  --profile learnerlab \
  --region us-east-1 \
  --query 'Reservations[].Instances[].{Id:InstanceId,State:State.Name,Type:InstanceType,Subnet:SubnetId}' \
  --output table

aws ssm describe-instance-information \
  --profile learnerlab \
  --region us-east-1 \
  --query 'InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Agent:AgentVersion}' \
  --output table
```

### Quote e componenti IAM disponibili

```bash
aws service-quotas list-service-quotas \
  --profile learnerlab \
  --region us-east-1 \
  --service-code ec2 \
  --query 'Quotas[?contains(QuotaName,`vCPU`) || contains(QuotaName,`Elastic IP`) || contains(QuotaName,`On-Demand`)].{Name:QuotaName,Value:Value,Code:QuotaCode}' \
  --output table

aws iam get-instance-profile \
  --profile learnerlab \
  --instance-profile-name LabInstanceProfile \
  --query 'InstanceProfile.{Name:InstanceProfileName,Arn:Arn,Roles:Roles[].RoleName}'

aws ec2 describe-key-pairs \
  --profile learnerlab \
  --region us-east-1 \
  --query 'KeyPairs[].KeyName' \
  --output table
```

### Preflight EC2 senza creazione

Ricavare dinamicamente VPC, subnet, security group e AMI. Il parametro `--count` è quello supportato dalla versione AWS CLI installata nel workspace.

```bash
lab_vpc=$(aws ec2 describe-vpcs \
  --profile learnerlab --region us-east-1 \
  --filters Name=is-default,Values=true \
  --query 'Vpcs[0].VpcId' --output text)

lab_subnet=$(aws ec2 describe-subnets \
  --profile learnerlab --region us-east-1 \
  --filters Name=vpc-id,Values="$lab_vpc" \
  --query 'Subnets[0].SubnetId' --output text)

lab_sg=$(aws ec2 describe-security-groups \
  --profile learnerlab --region us-east-1 \
  --filters Name=vpc-id,Values="$lab_vpc" Name=group-name,Values=default \
  --query 'SecurityGroups[0].GroupId' --output text)

lab_ami=$(aws ec2 describe-images \
  --profile learnerlab --region us-east-1 \
  --owners 099720109477 \
  --filters \
    'Name=name,Values=ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*' \
    'Name=state,Values=available' \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)

aws ec2 run-instances \
  --profile learnerlab \
  --region us-east-1 \
  --dry-run \
  --image-id "$lab_ami" \
  --instance-type t3.small \
  --subnet-id "$lab_subnet" \
  --security-group-ids "$lab_sg" \
  --iam-instance-profile Name=LabInstanceProfile \
  --count 1 \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=learnerlab-preflight}]'
```

Il successo atteso è `DryRunOperation`. Un `UnauthorizedOperation`, `AccessDenied` o `InvalidParameter` va registrato come risultato del preflight, non aggirato cambiando arbitrariamente la topologia.

## 6. Implicazioni per i prossimi passi

### Da fare nella repository

1. adattare il Terraform a `LabInstanceProfile`, senza creare IAM custom;
2. rimuovere l'assunzione che `admin_cidr` e SSH siano il canale standard;
3. decidere se il primo lab usa default VPC o una VPC dedicata;
4. scegliere tra un NAT Gateway singolo e VPC endpoint per il bootstrap delle subnet private;
5. mantenere Juice Shop, WAF e SIEM separati per security group;
6. fissare la versione dell'immagine Juice Shop e la versione Wazuh;
7. eseguire validazione locale e produrre un plan revisionabile.

### Da fare nel Learner Lab

1. verificare nuovamente identità e regione;
2. eseguire il preflight dry-run;
3. applicare soltanto il profilo approvato dal team;
4. verificare SSM e il percorso applicativo prima di qualunque test offensivo;
5. raccogliere evidenze sanificate;
6. distruggere le risorse del progetto e verificare l'inventario post-cleanup.

## 7. Limiti ancora non verificati

- creazione di ruoli IAM custom: non testata e non da testare creando risorse;
- permessi completi di creazione log group, allarmi e budget;
- retention e costo effettivo del Learner Lab;
- comportamento di Ansible verso istanze SSM senza un host di controllo;
- compatibilità runtime di Wazuh, ModSecurity e OWASP CRS nell'immagine bootstrap;
- policy del docente per la modalità baseline e il retest.

Finché questi punti non sono chiusi, il documento supporta la preparazione e il preflight, non una dichiarazione di ambiente pronto.
