# TP DIR-ANNUAIRE

## MATHIS REGESTE


### 1 – Installation et premier contact

#### 1- Installation des paquetages nécessaires:
``` sh
apt-get install ldap-server ldap-client

```

#### 2- Vérifier que le service LDAP est en service:
1-
``` sh

ss -ltpn | grep 389
LISTEN    0         128                0.0.0.0:389              0.0.0.0:*        users:(("slapd",pid=10097,fd=8))
LISTEN    0         128                   [::]:389                 [::]:*        users:(("slapd",pid=10097,fd=9))

```
2-

``` sh
ps -e |  grep slapd
10097 ?        00:00:00 slapd
```

### 3- Déterminer  le contexte de votre serveur

1-
 ``` sh
 cat /etc/ldap/slapd.d/cn=config/olcDatabase=\{1\}mdb.ldif | grep Suffix
olcSuffix: dc=nodomain
```
2- lat ça marche pas, du coup on utilise jxplorer.

```sh
apt install jxplorer
````
Puis je ssh ma machine virtuelle avec l'option -X.

4-

``` sh
Simple view: displaying all attributes...

cn admin

description LDAP administrator

objectClass  simpleSecurityObject organizationalRole
```

5- Connection Utilisateur + password = cn=admin,dc=fromage

6-
```sh
cn: admin

description: LDAP administrator

objectClass: simpleSecurityObject organizationalRole


userPassword: {SSHA}zGbwdqd25eZhmV0aAP6llMTL3nLin98O
```

7-


``` sh
cat /etc/ldap/slapd.d/cn=config/olcDatabase=\{1\}mdb.ldif

olcAccess: {0}to attrs=userPassword by self write by anonymous auth by * none
olcAccess: {1}to attrs=shadowLastChange by self write by * read
olcAccess: {2}to * by * read


```
Nous avons 3 lignes olcAccess qui ont les règles d’affichage des userPassword pour les comptes.

### 2- Création d'objets

dc=fromage

#### 2.1 - Création d'une «unité organisationnelle»

1-

``` sh
vim ou-personnes.ldif
>
dn: ou=personnes,dc=fromage
changetype: add
objectclass: top
objectclass: organizationalUnit
ou: personnes
description: Unite organisationnelle dediee aux personnes physiques
```

2-

```sh
ldapmodify -v -x -D cn=admin,dc=fromage -W -h localhost -f ou-personnes.ldif
ldap_initialize( ldap://localhost )
Enter LDAP Password:
add objectclass:
	top
	organizationalUnit
add ou:
	personnes
add description:
	Unite organisationnel
adding new entry "ou=personnes,dc=fromage"
modify complete

```
Il a rajouté les informations du fichier ou-personnes.ldif


Le groupe personnes s'est crée dans jxplorer

3-
Je créer un autre fichier pour faire un modify
```sh
ldapmodify -v -x -D cn=admin,dc=fromage -W -h localhost -f ou-personnes-utf8.ldif
ldap_initialize( ldap://localhost )
Enter LDAP Password:
replace description:
	NOT ASCII (57 bytes)
modifying entry "ou=personnes,dc=fromage"
modify complete

```
Il remplace la description en UTF8 "not ASCII" dans "ou=personnes,dc=fromage"

La descritpion à bien été changé et les accents sont présents:

```
description:Unité organisationnelle dédiée aux personnes physiques

objectClass:top organizationalUnit

ou:personnes
 ```

 Page 72 : "LDAP V3 utilise le jeu de caractèresUnicode Transformation Format-8(UTF-8) pour les attributs de typetexte et lesDNs

UTF- 8 englobe tous les jeux de caractères (isoLatin, Shift- JLS...),"

Ldap-V3 est donc utilisé.

### 2.2 - Automatisation

``` sh
root@203-8 : /etc/ldap
# cat ldif-import.ldif

script:
#!/bin/bash
ldapmodify  -v  -x  -D  cn=admin,dc=fromage -w root -h localhost -f $1
```

result:
```sh
bash ldif-import ldap/ou-personnes-tel.ldif

ldap_initialize( ldap://localhost )
replace telephoneNumber:
	0605161098
modifying entry "ou=personnes,dc=fromage"
modify complete
```
Sur jxplorer
```
description:
Unité organisationnelle dédiée aux personnes physiques

objectClass:
top
organizationalUnit


ou:
personnes

telephoneNumber:
0605161098
```

3- ça marche déjà très bien.

### 2.3 - Importation massive


1-

```

Confer diapo 35 du cours.

Optionnal Attributes de InetorgPerson :
    audio
    businessCategory
    carLicense
    departmentNumber
    displayName
    employeeNumber
    employeeType
    givenName
    homePhone
    homePostalAddress
    initials
    jpegPhoto
    labeledURI
    mail
    manager
    mobile
    o
    pager
    photo
    roomNumber
    secretary
    uid
    userCertificate
    x500uniqueIdentifier
    preferredLanguage
    userSMIMECertificate
    userPKCS12
```

2-
``` sh
cat template.ldif
dn: cn=*2 *3,ou=personnes,dc=fromage
changetype: add
objectclass: inetOrgPerson
ou: personnes
cn: *2 *3
sn: *2
givenName: *3
telephoneNumber: *4
mail: *5
description: *1
 ```
```sh
scp /home/regeste/Téléchargements/anciens.cvs root@10.203.0.77:/root/ldap
```
3-
```` sh
sudo apt-get install libswitch-perl
perl makeldif.pl -t template.ldif -a anciens.cvs -o new.ldif

Generating LIDF document
========================================
Entries: 28
Attributes: 5
Seperator: ';'
LDIF file: new.ldif

````

4-

``` sh
bash ldif-import new.ldif
ldap_initialize( ldap://localhost )
add objectclass:
	inetOrgPerson
add ou:
	personnes
add cn:
	NOT ASCII (16 bytes)
add sn:
	ANGAMA
add givenName:
	NOT ASCII (9 bytes)
add telephoneNumber:
	00262 21 24 76
add mail:
...
...
```

5- Tout à été importé dans jxplorer.


## 3- Requêtes

#### 1- Recherche avec filtre simple

```sh
ldapsearch -LLL -x -b "dc=fromage" "cn=admin"

dn: cn=admin,dc=fromage
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
```


-L     Search results are display in LDAP Data Interchange Format  detailed  in  ldif(5).   A  single  -L
       restricts the output to LDIFv1.
        A second -L disables comments.  A third -L disables printing of the LDIF version.  The default is
       to use an extended version of LDIF.


-x     Use simple authentication instead of SASL.

-b searchbase Use searchbase as the starting point for the search instead of the default.



```sh
ldapsearch -LLL -x -b "dc=fromage" "(cn=admin)"
```
C'est exactement pareil mais ça respecte la RFC 2254

Les filtres de recherche (RFC 2254)

#### 2- Amélioration du fonctionnement de la commande de recherche.


1- je pense qu'il faut changer le base search par defaut dans le fichier /etc/ldap/ldap.conf

2- Dans ldap.conf , on rajoute cette ligne
```sh
BASE    dc=fromage
```

result:

``` sh
ldapsearch -LLL -x "cn=admin"
dn: cn=admin,dc=fromage
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
```
#### 3.   Ciblage d'attributs

ldapsearch -LLL -x "cn=admin" dn
dn: cn=admin,dc=fromage

Cela donne que le dn

ldapsearch -LLL -x "cn=admin" dn cn
dn: cn=admin,dc=fromage
cn: admin

cn + dn

ldapsearch -LLL -x "cn=admin" cn
dn: cn=admin,dc=fromage
cn: admin

Donne cn + dn
le dn est toujours donné.



le base est un scope qui recherche seulement à la base.
le onelevel search recherche sur le même niveau
subtree lui recherche tout ce qui ya en dessous de la base de recherche.

confer schéma cour.


Test avec subtree:

``` sh

ldapsearch -LLL -s subtree -x dn
dn: dc=fromage

dn: cn=admin,dc=fromage

dn: ou=personnes,dc=fromage

dn: cn=VIAUD Simon,ou=personnes,dc=fromage

dn: cn=MAURY Gilles,ou=personnes,dc=fromage

dn: cn=ASENCIO Jordi,ou=personnes,dc=fromage

dn: cn=OLIVES Lionel,ou=personnes,dc=fromage

dn: cn=PEREIRA Bruno,ou=personnes,dc=fromage

dn: cn=AZZOUZI Mounir,ou=personnes,dc=fromage

dn: cn=BIANCHI Julien,ou=personnes,dc=fromage

dn: cn=GATELAU Thomas,ou=personnes,dc=fromage

dn: cn=PLESSIS Adrien,ou=personnes,dc=fromage

dn: cn=PREVOST Thomas,ou=personnes,dc=fromage

dn: cn=HALLUIN Mathieu,ou=personnes,dc=fromage

dn: cn=JOSSET Benjamin,ou=personnes,dc=fromage

dn: cn=JUSTAFRE Julien,ou=personnes,dc=fromage

dn: cn=PERRINOT Thomas,ou=personnes,dc=fromage

...
```



#### 5-  Filtres avancés (pour simplifier le travail, n'afficher que le  « dn »)
