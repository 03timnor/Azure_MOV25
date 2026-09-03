# __Nätverk och säkerhet (Godkänt)__

__Repository:__ https://github.com/03timnor/Azure_MOV25

_Tim Noreliusson Lingestedt, 2026-08-20_

Veckans uppgift är att bygga ett säkert nätverkslager runt lösningen. Själva ärendeformuläret ska vara publikt nåbart, medan den känsliga delen, lagringen där ärenden
och bilagor senare hamnar, ska ligga skyddad i ett privat subnät. Defense in depth skall tillämpas så att bara nödvändig trafik släpps igenom.

### *__1. Bygg det virtuella nätverket__*

*__VNet__* `vnet-novatrix` via *__Azure__* portalen, address space är `10.0.0.0/16`.

![alt text](vnet-novatrix.png)

Subnät `snet-web` har skapats i `vnet-novatrix` med address space `10.0.1.0/24`.

![alt text](snet-web.png)

Subnät `snet-db` har skapats i `vnet-novatrix` med address space `10.0.2.0/24`.

![alt text](snet-db.png)

### *__2. Säkra trafiken__*

*__Network Security Group (NSG)__* `nsg-web` har skapats.

![alt text](nsg-web.png)

Regler har skapats i `nsg-web` för att släppa igenom TCP trafik på portar 80 och 443 samt att släppa igenom trafik från host datorns IP-adress på port 22 för *__SSH__*.

![alt text](nsg-rules.png)

### *__3. Placera lösningen i nätverket__*

`nsg-web` associeras med `vnet-novatrix` och subnät `snet-web`.

![alt text](nsg-web+vnet-novatrix.png)

Tog bort befintlig VM men inte disken som var kopplad till den. Detta då man ej kunde knyta VM till rätt vnet / subnät annars.

Skapade en ny VM och kopplade den till `vnet-novatrix/snet-web` och använder samma disk som till den tidigare VM.

![alt text](vm-novatrix-web.png)


### *__4 Verifiering__*

Hemsidan kan nås:

![alt text](novatrix-website.png)

![alt text](ip-flow-verify-http-80-success.png)

![alt text](ip-flow-verify-https-443-success.png)

Kan ansluta via *__SSH__* från host dator:

![alt text](ssh-login-success.png)

![alt text](ip-flow-verify-ssh-22-success.png)

Kan inte via *__SSH__* ansluta ifrån annan dator:

![alt text](ssh-login-failed.png)

![alt text](ip-flow-verify-ssh-22-failed.png)

### *__5. Dokumentation och motivering__*

*__VNet__* `vnet-novatrix` address space är `10.0.0.0/16`
*__VNet__* används för att ge möjligheten att segmentera resurser i olika subnät. Resurserna kan även få en privat IP istället för en pubik och bli mindre sårbara.

Subnät `snet-web` finns i `vnet-novatrix` med address space `10.0.1.0/24`. `VM-Novatrix-WEB` använder detta subnät. 

Subnät `snet-db` finns i `vnet-novatrix` med address space `10.0.2.0/24`. Används inte just nu, skapats som förberedelse inför nästa veckas uppgift.

Subnät används för att segmentera nätverket, man kan till exempel applicera olika *__Network Security Group (NSG)__* på olika subnät.

I *__Network Security Group (NSG)__* `nsg-web` finns följande regler:

`allow-web` - Tillåter inkommande TCP trafik på portar 80 och 443. Detta behövs för att komma åt *__Novatrix__* hemsdia.

`allow-ssh-admin` - Tillåter endast *__SSH__* inloggning ifrån host datorn. Begränsar till exempel brute force och minskar attackytan. Bidrar till en säkrare miljö.

*__Network Security Group (NSG)__* används som en brandvägg där man kan skapa regler för att reglera nätverkstrafiken in och ut till resurser. Man kan basera regerlna på till exempel port, protokoll och IP.

![alt text](blueprint.png)
