# __Virtualiseringsnivåer (Godkänt och Väl Godkänt)__

Repository: https://github.com/03timnor/Azure_MOV25

*Tim Noreliusson Lingestedt, 2026-09-30*

Veckans uppgift går ut på att det finns fler sätt att köra en applikation än en VM. Den här veckan ska man undersöka de olika virtualiseringsnivåerna, VM, containers och serverless, genom att köra en del av kundtjänsten på en alternativ nivå och jämföra dem.

## *__1. Skapa upp miljön__*

## *__2. Jämför nivåerna__*

| | *__VM__* | *__Container__* | *__Serverless__* |
|---|---|---|---| 
| __Man levererar__ | Hela operativsystemet | Applikationen och dess beroenden | Bara källkod / funktionen |
| __Man ansvarar för__ | Mest drift | Medel drift | Minst drift |
| __Drift__ | Mest | Medel | Minst |
| __Kontroll__ | Manuell skalning eller via regler (exempelvis Scale Sets) | Automatisk skalning på en plattform som skalat (exempelvis AKS, Container Apps) | Direkt inbyggd automatisk skalning |
| __Kostnadsmodell__ | Kostnad per timme/sekund så länge den är i drift | Kostnad per sekund för CPU/RAM (Container Apps) eller för noderna (AKS) | Kostnad per körning |
| __Exempel i Azure__ | Virtual Machines | AKS, ACI och Container Apps | Azure Functions |

## *__3. Verifiering__*

## *__4. Dokumentation__*

## *__5. Motivering (VG)__*

