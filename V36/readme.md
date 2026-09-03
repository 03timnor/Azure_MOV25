# *__Nätverk och säkerhet (Godkänt)__*

__Repository:__ https://github.com/03timnor/Azure_MOV25

_Tim Noreliusson Lingestedt, 2026-08-20_

Veckans uppgift är att bygga ett säkert nätverkslager runt lösningen. Själva ärendeformuläret ska vara publikt nåbart, medan den känsliga delen, lagringen där ärenden
och bilagor senare hamnar, ska ligga skyddad i ett privat subnät. Defense in depth skall tillämpas så att bara nödvändig trafik släpps igenom.

### *__1. Bygg det virtuella nätverket__*

v-net `vnet-novatrix` via *__Azure__* portalen, address space är `10.0.0.0/16`
![alt text](vnet-novatrix.png)

Subnät `snet-web` har skapats i `vnet-novatrix` med address space `10.0.1.0/24`.
![alt text](snet-web.png)

Subnät `snet-db` har skapats i `vnet-novatrix` med address space `10.0.2.0/24`.
![alt text](snet-db.png)

### *__2. Säkra trafiken__*

### *__3. Placera lösningen i nätverket__*

### *__4 Verifiera och dokumentera__*