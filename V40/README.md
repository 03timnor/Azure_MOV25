# __Virtualiseringsnivåer (Godkänt och Väl Godkänt)__

Repository: https://github.com/03timnor/Azure_MOV25

*Tim Noreliusson Lingestedt, 2026-09-30*

Veckans uppgift går ut på att det finns fler sätt att köra en applikation än en VM. Den här veckan ska man undersöka de olika virtualiseringsnivåerna, VM, containers och serverless, genom att köra en del av kundtjänsten på en alternativ nivå och jämföra dem.

## *__1. Skapa upp miljön__*

## *__2. Jämför nivåerna__*

| | *__VM__* | *__Container__* | *__Serverless__* |
|---|---|---|---| 
| __Man levererar__ | Hela operativsystemet | Applikationen och dess beroenden | Bara källkod / funktionen |
| __Man ansvarar för__ | Operativsystems-patchar, säkerhet och konfiguration | Image och dess innehåll, plattformen sköter servrarna | Endast koden och dess inställningar |
| __Drift__ | Mest | Medel | Minst |
| __Kontroll__ | Mest | Medel | Minst |
| __Skalning__ | Manuell skalning eller via regler (exempelvis Scale Sets) | Automatisk skalning på en plattform som skalar (exempelvis AKS, Container Apps) | Direkt inbyggd automatisk skalning |
| __Kostnadsmodell__ | Kostnad per timme/sekund så länge den är i drift | Kostnad per sekund för CPU/RAM (Container Apps) eller för noderna (AKS) | Kostnad per körning |
| __Exempel i Azure__ | Virtual Machines | AKS, ACI och Container Apps | Azure Functions |

## *__3. Verifiering__*

Resursgrupp med innehåll skapas:

![alt text](resource_group.png)

![alt text](resource_group_contents.png)

Hemsidan kan nås:

![alt text](novatrix_website.png)

Hemsidan kan skicka ärenden till storage:

![alt text](ticket_sent.png)

![alt text](container_contents_1.png)

![alt text](container_contents_2.png)

Flödet från V39 fungerar fortfarande (exempel på ett steg, mail till kund):

![alt text](flow.png)

![alt text](flow_example.png)

## *__4. Dokumentation__*

## *__5. Motivering (VG)__*

