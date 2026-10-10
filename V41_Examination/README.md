# __Examination (Godkänt och Väl Godkänt)__

Repository: https://github.com/03timnor/Azure_MOV25

*Tim Noreliusson Lingestedt, 2026-10-10*

Examinationen går ut på att skapa en hyresgästportal via *Azure* åt företaget *Nordvik Fastigheter AB*. Hyresgästerna skall kunna logga in i portalen och skicka en felanmälan. Förvaltarna skall kunna hantera ärendena och ekonomi har läsande insyn. Portalen skall ha kontrollerad åtkomst. Miljön ska provisioneras som kod. Det skall även finnas automatiserat arbetsflöde kopplat till Nordsviks Microsoft 365.

## __Del A__

*Del A* av examinationen går ut på att man skall redogöra för de centrala *Azure* inom *Compute*, *Network* och *Storage*. Förklara virtualiseringsnivåerna *Virtual Machines (VM)*, *Containers* och *Serverless*. Man skall även beskriva vilken nivå man valt och varför.

### *__Compute__*

*Compute* är processor (*vCPU*), minne som programkoden körs på.

*Compute* kör program, bearbetar data och hanterar anrop. *Compute* innefattar tjänster som *Container*, *Virtual Machines (VM)* samt *Azure Functions*.

### *__Network__*

Skickar trafik mellan tjänster, internet och användare. Avgör vilka som får prata med vilka och på vilken väg.

I *Azure* / molnet så är nätverket programerbart. Vilket kan bidra till förbättrad säkerhet med olika regler och så vidare.

### *__Storage__*

I *Storage* lagras data som skall finnas kvar när koden inte körs.

Lagringen är skild från *Compute*, detta gör det möjligt att till exempel starta om eller byta ut en app utan att datan går förlorad.

### *__VM / Container / Serverless__*

| | *__VM__* | *__Container__* | *__Serverless__* |
|---|---|---|---| 
| __Man levererar__ | Hela operativsystemet | Applikationen och dess beroenden | Bara källkod / funktionen |
| __Man ansvarar för__ | Operativsystems-patchar, säkerhet och konfiguration | Image och dess innehåll, plattformen sköter servrarna | Endast koden och dess inställningar |
| __Drift__ | Mest | Medel | Minst |
| __Kontroll__ | Mest | Medel | Minst |
| __Skalning__ | Manuell skalning eller via regler (exempelvis Scale Sets) | Automatisk skalning på en plattform som skalar (exempelvis AKS, Container Apps) | Direkt inbyggd automatisk skalning |
| __Kostnadsmodell__ | Kostnad per timme/sekund så länge den är i drift | Kostnad per sekund för CPU/RAM (Container Apps) eller för noderna (AKS) | Kostnad per körning |
| __Exempel i Azure__ | Virtual Machines | AKS, ACI och Container Apps | Azure Functions |

### *__Val av nivå för Nordvik Fastigheter AB__*

#### __Varför inte Virtual Machine (VM)?__

Kostnaden består för en *Virtual Machine (VM)* även när ingen använder den. *Nordvik Fastigheter AB* har ett krav på att tåla att en instans faller behöver man minst två maskiner inklusive lastbalanserare.

En *Virtual Machine (VM)* betalar man för så länge den är i drift, även om den inte används. En *Container* betalar man för per använd sekund för *CPU* och *RAM* (till exempel *ACI* eller *Container* Apps med Consumption-profil) eller för antal noder (till exempel *AKS*). *Nordvik Fastigheter AB* använder *Container Apps* med Consumption-profil. *Container Apps* lösningen blir även billigare, främst för att *Bastion* inte behövs.

*Virtual Machine (VM)* kräver mer drift / ansvar. Operativsystem, skalning, härdning och certifikat blir *Nordvik Fastigheter AB* ansvar. Det passar en organisation med 40 förvaltare och 6 anställda på ekonomi dåligt. De har heller inte någon uttalad IT-avdelning (enligt uppgiftsbeskrivningen).

Bastion bör används för inloggning till en *Virtual Machine (VM)* på grund av att göra miljön säkrare. Bastion behövs inte då det inte finns någon *Virtual Machine (VM)* att logga in på. Bastion har en hög kostnad. Att använda *Container* medför inte denna kostnad och säkerheten påverkas ej negativt.

Ingen tung resurskrävande applikation används. Den kräver heller inte att man har full kontroll på plattformen den körs på. Då passar *Container* bättre än *Virtual Machine (VM)*. En *Virtual Machine (VM)* blir lite "overkill" i detta fallet.

#### __Varför inte Serverless (Azure Functions)__

En *Container* image kan flyttas mellan till exempel *Container Apps*, *AKS* eller *ACI*. Om man istället använder *Functions* så är den koden huvudsakligen bunden till *Functions*-värden. *Container* lösningen har därför en fördel här om man väljer att byta plattform eller om man vill köra appen på flera ställen.

Functions är skapat främst för kod som körs när något händer, exempelvis en HTTP-request eller att en ny blob har skapats. Appen som används i denna miljö är mer än så. Appen består bland annat av ett formulär, backend och endpoint. En *Container* lösning kan hantera allt detta på samma gång. Därav passar det bättre.

#### __Gemensam anledning__

Container är en mittpunkt mellan *Virtual Machines (VM)* och *Serverless (Azure Functions)*. En mittpunkt i bland annat kontroll och drift. Det är därför den bästa utgångspunkten att börja ifrån för att sedan utvärdera miljöns behov.

Man kan alltid planera för och försöka göra en hypotes vad man tror en mlijö kommer kräva eller kosta. Men man vet det aldrig säkert förrän man driftsatt miljön i praktiken.

Container har därför en fördel då det är en mittpunkt mellan de två andra alternativen. Det gör det enklare att börja utvärdera och en logisk startpunkt.

#### __Slutsats__

*Container* är den nivå som bäst uppfyller kraven som ställs. Det är inte billigast eller enklast på varje punkt. Men *Container* ger den bästa balansen mellan kostnad, arbetskraft samt tid.

- __Kostnad__

*Container* skalar ned till noll utanför kontorstid. Detta uppfyller kravet om att inte betala för kapacitet som inte används under nattetid. Lösningen bör hamna under 2 500 kr med god marginal. Detta bör dock utvärderas över några veckor när *Azure* kostnadsprognos är mer säker och har data ifrån fler dagar. Även om budgeten skulle överskridas så finns går det automatiskt ett mail till ekonomiavdelningen angående detta.

- __Arbetskraft__

*Container* lösningen sköter plattformen operativsystem och servrar. *Nordvik Fastigheter AB*. Detta passar ett företag utan en IT-avdelning (enligt uppgiftsbeskrivningen). Den drift som dock kvarstår är till exempel att bygga om imagen om ändringar uppstår, följa upp loggar och kostnader.

- __Tid__

Hela miljön skrivs som kod med *Bicep* och *Dockerfile*. En ny test eller demomiljö skapas med några kommandon. Det gör så att kravet om att kunna resa en likadan / demo miljö vid behov.

- __Avvägningar__

Lösningen är inte helt perfekt på alla sätt. Till exempel kan regionen sakna kapacitet vilket i sin tur leder till deployment problem under uppbyggnaden och första anropet efter att miljön skalat ned utanför kontorstid kan få en kort kallstart.

## __Del B__

### *__1. Skapa upp miljön (IaC)__*

Miljön skapas upp med hjälp av all kod och script som finns i *V41_Examination* mappen i *GitHub*. (Alla script och all kod kommer finnas längst ner i *README* filen. Det finns även i *V41_Examination* mappen som enskilda filer).

Produktionsmiljön skapas upp med dessa komandon (kör dem i den ordningen de är listade, mappstruktur måste vara likadan som i *V41_Examination* mappen i *GitHub*, förutom bilderna):

Gör alla scriptfiler i mappen körbara:
```bash
chmod +x *.sh
```

Om man skall koppla ett PowerAutomate flöde med HTTP-trigger anger man det här inom ' tecknen:
```bash
export FLOW_URL='https://...' 
```

Skapar miljön (Produktion):
```bash
NOTIS_TRIGGER=schedule ./V41_deploy.sh
```

Läser in användarna och behörigheter:
```bash
./V41_seed_users.sh V41_users.csv V41_properties.csv
```

För att starta en demomiljö kör man:

```bash
ENVIRONMENT_TYPE=demo DEMO_MODE=true ./V41_deploy.sh
```

*__OBS!__* Fyll i uppgifter i *V41_main.biceparm* där det behövs. Där kan man även ändra olika parametrar för att ändra hur miljön ska se ut och så vidare. Parameter *param delatBrevladaMail* skall inte fyllas i då *PowerAutomate* flöde används istället.

*__OBS!__* Fyll i uppgifter i *V41_users.csv* och *V41_properties.csv*. (*V41_users.csv* skapar inte användare, de måste finnas i *Entra* innan det körs).

### *__2. IAM__*

Portalen har en *Managed Identity* som används av både webbappen och notisjobbet.

![alt text](images/managed_id.png)

#### __Rolltilldelningar, poralens *Managed Identity*:__

| Resurs | Roll | Scope (var rollen gäller) | Vad portalen gör med den | Varför behövs den? |
|---|---|---|---|---|
| Container `felanmalan` (bilder) | Storage Blob Data Contributor | Bara den containern | Sparar och läser felanmälningsbilder | Hyresgäster laddar upp foton, och förvaltare ser dem. Rollen ges på containern, inte på hela lagringskontot, så att den inte når kontrakten. |
| Container `avtal` (kontrakt) | Storage Blob Data Reader | Bara den containern | Läser kontrakt och protokoll åt rätt användare | Portalen ska bara visa dokument och aldrig ändra eller radera dem. Läsrätt räcker, så det blir least privilege. |
| Tabeller (`Arenden`, `Anvandare`, `Fastigheter`) | Storage Table Data Contributor | Hela lagringskontot | Skapar och uppdaterar ärenden, läser användare och fastigheter | Ärendena sparas som rader i tabellen och statusen uppdateras av förvaltare. Rollen kan inte begränsas till enskilda tabeller. |
| Köer (`notiser`, `notiser-poison`) | Storage Queue Data Contributor | Hela lagringskontot | Lägger notiser i kön, och jobbet läser och tar bort dem | Kön kopplar ihop en ny anmälan med utskick av e-post och flöde. Den gör att anmälan inte blockeras om utskicket misslyckas. |
| Container Registry | AcrPull | Registret | Hämtar containerbilden vid start | Container Apps måste kunna hämta appens image utan lösenord. Rollen tillåter bara att hämta, inte att ladda upp eller ändra. |
| Azure Communication Services (e-post) | Communication and Email Service Owner | Bara ACS-resursen | Skickar akuta och vanliga notismejl | Notisjobbet skickar e-post till förvaltare och den delade brevlådan. Rollen behövs för att få skicka via tjänsten. |

Lagringskontot = `allowedSharedKeyAccess: false` vilket innebär att nycklar inte kan läcka. Koden loggar in med `DefaultAzureCredential` och `AZURE_CLIENT_ID`.

Storage konto *IAM*:

![alt text](images/storage_iam.png)

#### __Rolltilldelningar, personal och hyresgäster:__

| Roll | Vad de får | Hur det framtvingas |
|---|---|---|
| **Hyresgäst** | Skapa och se sina egna anmälningar och dokument i sin egen lägenhet | **1. Inloggning:** användaren loggar in med sitt Entra-konto (*UPN*) och måste finnas i användartabellen `Anvandare`.<br>**2. Rollkontroll:** bara rollen hyresgäst får skapa en anmälan (`needs_roles("hyresgast")`). Andra roller får 403.<br>**3. Egen data:** ärendelistan filtreras på hyresgästens egen fastighet och eget användar-ID. Andras ärenden syns aldrig, och försöker man öppna ett annat ärende får man 404.<br>**4. Dokument:** bara filer under den egna sökvägen `fastighet/lägenhet/` kan läsas.<br>**5. Azure:** hyresgästen har ingen Azure-roll och når aldrig lagringen direkt, bara via portalen. |
| **Förvaltare** | Se ärenden för sina fastigheter, sätta status och skriva lösning, läsa dokument för sina fastigheter | **1. Inloggning:** som ovan, med rad i `Anvandare`.<br>**2. Rollkontroll:** bara rollen förvaltare får ändra status och skriva lösning (`needs_roles("forvaltare")`). Hyresgäster och ekonomi får 403.<br>**3. Fastighetskontroll:** förvaltaren kommer bara åt ärenden i fastigheterna i sin egen rad i `Anvandare` (kolumnen `fastigheter`, till exempel `F1;F2`). Ärenden i andra fastigheter syns inte i listan, och försök att ändra dem ger 404.<br>**4. Dokument:** bara filer under de egna fastigheternas sökvägar kan läsas, med skydd mot sökvägstrick som `..`.<br>**5. Azure:** Entra-gruppen för förvaltare kan ges Blob Contributor på containern `avtal` för att ladda upp kontrakt. |
| **Ekonomi** | Läsande insyn i anonym statistik, samt kostnadsuppföljning i Azure | **1. Inloggning:** som ovan, med rad i `Anvandare`.<br>**2. Begränsad åtkomst:** ekonomi får bara anropa statistik (`/api/statistik`), som visar sammanställda siffror utan namn eller ärendetexter.<br>**3. Spärr på känsliga anrop:** alla anrop till enskilda ärenden och dokument ger 403.<br>**4. Azure:** Entra-gruppen för ekonomi får rollen Cost Management Reader på resursgruppen, så att de kan se kostnader men inte läsa data. |

#### __Least-privilege__

Portalen kommer åt lagringen via en *Managed Identity* utan att behöva använda nycklar. Rollerna är begränsade till *Container* eller tabbellnivå. Hyresgäster har inga *Azure* roller alls utan ser bara sina egna ärenden via portalen. Förvaltarna ser hanterar endasy ärenden som är kopplade till deras fastigheter. Ekonomi har enbart läsande insyn i form av anonym statistik och *Cost Management Reader* för att se *Azure* kostnader (endast för resursgruppen). 

### *__3. Nätverk och säkerhet__*

Nätverket implementerar *Defence in depth*. Portalen nås publikt via HTTPS och är samtidigt skyddad via inloggning med *Entra* konto. Lagringskontot nås av portalen via *Private endpoints* i ett eget virtuellt nätverk som innehåller privata DNS-zoner. När miljön skapas upp är en administratörs IP-adress tillåten publik åtkomst till lagringen. Detta bör dock tas bort och publik åtkomst bör stängas av helt när man inte behöver det längre. Lagringskontot har delade nycklar avstängt har TLS 1.2 som krav. Portalen når lagringen via *Managed Identity* och applikationen kontrollerar roll och fastighet vid varje anrop.

#### __Lager__

| Lager | Åtgärd | Vad det skyddar mot |
|---|---|---|
| **1. Perimeter (internet till portalen)** | Bara HTTPS. Appen är skyddad av Entra-inloggning (Easy Auth). Oinloggade omdirigeras till inloggning, och bara `/health` är undantagen. | Anonym åtkomst till portalen och API:et |
| **2. Applikationen** | Rollkontroll (`needs_roles`), filtrering per fastighet och per hyresgäst, CSRF-skydd via sidhuvud `X-Requested-With`, säkerhetsrubriker (`X-Content-Type-Options: nosniff`, `Content-Security-Policy`), uppladdningsgräns på 10 MB, skydd mot `..` i sökvägar | Obehörig dataåtkomst, CSRF och uppladdningsmissbruk |
| **3. Nätverk** | Eget virtuellt nätverk (VNet) med två subnät: ett delegerat till Container Apps och ett för private endpoints. Miljön är integrerad i VNet:et. | Att trafik mellan portal och lagring går över internet |
| **4. Privat anslutning till lagring** | Private endpoints för blob, table och queue, med privata DNS-zoner (`privatelink.*`) länkade till VNet:et. Portalens anrop till lagringen får en privat IP-adress. | Att lagringen måste nås via publik slutpunkt |
| **5. Lagringskontots nätverksregler** | **Normalläge (prod):** publik nätverksåtkomst avstängd (`Disabled`), så lagringen nås bara via private endpoints.<br>**Installationsläge:** publik åtkomst är aktiverad men begränsad till valda nätverk (`defaultAction: Deny`) med en enda tillåten IP-adress (`allowedIpAddress`), så att data kan läggas in från en administratörs dator. IP-regeln bör tas bort när installationen är klar.<br>I båda lägena gäller även: ingen publik blobåtkomst, delade nycklar avstängda, TLS 1.2 som lägsta version, bara HTTPS. | Åtkomst utifrån, läckta nycklar, anonym läsning, svag kryptering |
| **6. Identitet** | Managed identity utan nycklar, med roller på container- eller kontonivå (least privilege) | Att stulna hemligheter ger åtkomst |
| **7. Datasäkerhet och drift** | Soft delete på blobbar i 14 dagar, ZRS i prod, livscykelregler, taggar | Oavsiktlig radering och driftstörning |

*Private Endpoints:*

![alt text](images/private_endpoint.png)

### *__4. Storage__*

Portalens dokument och bilder lagras i ett *Azure* storage konto med två huvudsakliga blob containrar. *avtal* för dokument, *felanmalan* för bilder och ärendena sparas i en tabell (*arenden*). Om en hyresgäst skickar in en felanmälan med en bild så sparar portalen först bilden i *felanmalan* under en sökväg som baseras på fastighet och ärende-id. Efter detta sparas ärendet som en rad i tabellen (*arenden*). Till sist läggs ett meddelande i en kö som utlöser notiser.
Lagringen är skyddad via saker som har nämts i de tidigare punkterna som exempelvis  avstängda delade nycklar, avstängd publik åtkomst (efter installation), *Private Endpoints*, TLS 1.2 och att portalen når storge via en *Managed Identity*.

#### __Struktur__

| Del | Namn | Innehåll |
|---|---|---|
| Blob-container | `felanmalan` | Bilder från felanmälningar |
| Blob-container | `avtal` | Dokument: kontrakt och besiktningsprotokoll |
| Tabell | `arenden` | Själva felanmälan (fält och sökväg till bilden) |
| Tabell | `anvandare` | Användare, roller och koppling till fastighet och enhet |
| Tabell | `fastigheter` | Fastigheter och förvaltarens e-postadress |
| Kö | `notiser` | Notiser som skickas efter att en anmälan sparats |
| Kö | `notiser-poison` | Notiser som misslyckats upprepade gånger (efter 5 försök) |

#### __Hur lagringen säkras__

| Område | Åtgärd |
|---|---|
| **Åtkomst** | Bara portalens managed identity, med roller på container- eller kontonivå. Delade nycklar är avstängda (`allowSharedKeyAccess: false`) och OAuth är förvalt. |
| **Nätverk** | Private endpoints för blob, table och queue. Publik åtkomst är avstängd i normalläge och begränsad till en IP-adress under installation. |
| **Publik läsning** | Publik blobåtkomst är avstängd (`allowBlobPublicAccess: false`). Containrarna har ingen anonym åtkomst. |
| **Kryptering** | Data krypteras i vila (Azure standard). Bara HTTPS och TLS 1.2 som lägsta version. |
| **Uppdelning** | Bilder och dokument ligger i separata containrar. Portalen får skriva bilder men bara läsa dokument. |
| **Återställning** | Soft delete på blobbar och containrar i 14 dagar. Tabeller har ingen soft delete. |
| **Redundans** | ZRS i prod (tål att en zon faller), LRS i test och demo. |
| **Kostnad** | Livscykelregler flyttar dokument till svalare lagring (cool) efter 90 dagar och bilder efter 180 dagar. |
| **Uppföljning** | Lagringskontot har samma taggar som övriga resurser, så kostnaden kan följas upp. Applikationsloggar samlas separat i en Log Analytics-workspace med 30 dagars lagring. |

#### __Hur det sparas__

| Steg | Vad som händer | Var det sparas |
|---|---|---|
| 1. Kontroll | Portalen kontrollerar att användaren är hyresgäst med fastighet, och att kategori och beskrivning finns | – |
| 2. Validering av bild | Filändelsen måste vara JPG, PNG, WEBP eller HEIC, och bilden får vara högst 8 MB | – |
| 3. Bilden sparas | Sökvägen byggs av fastighet och ärende-id (`fastighet/ärende-id/bild.ext`). Användarens eget filnamn används aldrig. | Containern `felanmalan` |
| 4. Ärendet sparas | Fälten och sökvägen till bilden sparas som en rad | Tabellen `arenden` |
| 5. Notis köas | Ett meddelande läggs i kön och startar notisjobbet. Misslyckas det är anmälan ändå sparad. | Kön `notiser` |

### *__6. Automation och integration__*

Om en felanmälan skapas så lägger portalen ett meddelande i en kö. Ett *Container Apps*-jobb läser kön och gör två saker. Om kategorin på ärendet klassas som akut skickar det ett mail direkt till förvaltarens epost via *Azure Communications Services*. Oavsätt om kategorin är akut eller inte så anropas ett *PowerAutomate* flöde via en *HTTP*-trigger. Flödet skapar en post i en *SharePoint* lista, skickar mail om att en ny felanmälan till en delad brevlåda som förvaltarna har tillgång till och skickar ett mail till hyresgästen som anmälde att felanmälan har skapats.

__Flödet från anmälan till notis__

| Steg | Vad som händer | Var |
|---|---|---|
| 1. Anmälan sparas | Hyresgästen skickar felanmälan. Bilden sparas i `felanmalan` och ärendet som en rad i tabellen `arenden`. | Portalen och lagringskontot |
| 2. Notis köas | Portalen lägger ett meddelande i kön `notiser`. Anmälan är redan sparad, så ett köfel stoppar den inte. | Kön `notiser` |
| 3. Jobbet plockar upp | Ett Container Apps-jobb (schemalagt, kör varje minut) läser kön. | Container Apps-jobb |
| 4. Akutmail först | Vid akuta kategorier skickar jobbet direkt e-post via Azure Communication Services till ansvarig förvaltare. Detta sker före och oberoende av flödet. | Azure Communication Services |
| 5. Flödet anropas | Jobbet gör ett HTTP POST med ärendets data (inklusive hyresgästens e-post och bilden) till PowerAutomate-flödets URL. | Power Automate |
| 6. Post i SharePoint | Flödet skapar en post i en SharePoint-lista (`Maintenance_requests`) med ärendets uppgifter. | SharePoint |
| 7. Mail till den delade brevlådan | Flödet skickar ett mail om den nya felanmälan till en delad brevlåda som förvaltarna har tillgång till. | Outlook (delad brevlåda) |
| 8. Bekräftelse till hyresgästen | Flödet skickar ett mail till den hyresgäst som anmälde felet, med besked om att felanmälan har skapats. | Outlook |
| 9. Resultat sparas | Jobbet skriver `mailSkickad`, `flowSkickad`, `notis` och `notisFel` på ärenderaden, så att man kan se vad som hänt. | Tabellen `arenden` |

#### __Akutmail-lösningen__

| Egenskap | Lösning |
|---|---|
| **Syfte** | Akuta ärenden ska ge ett omedelbart mail till ansvarig förvaltare, även om PowerAutomate eller Microsoft 365 har problem. |
| **Vad som är akut** | Kategorin avgör (`akut: true` på kategorin), inte hyresgästens val. |
| **Mottagare** | Ansvarig förvaltare (från tabellen `Fastigheter`).
| **Vanliga ärenden** | Inget mail från Azure. De hanteras helt av PowerAutomate (delad brevlåda och bekräftelse till hyresgästen). Parametrarna `SHARED_MAILBOX` och `delatBrevladaMail` lämnas tomma. |
| **Avsändare** | Azure Communication Services med en Azure-hanterad domän (en `DoNotReply`-adress), inte hyresgästens eller någon persons adress. |
| **Oberoende av flödet** | Mailet skickas före flödesanropet. Ett trasigt flöde stoppar alltså aldrig ett akutmail. |
| **Autentisering** | Portalens managed identity (roll på ACS-resursen). Inga lösenord eller SMTP-nycklar. |
| **Hastighetsbegränsning** | Den Azure-hanterade domänen har låga sändningsgränser. Svarar tjänsten med 429 försöker jobbet igen senare (10 minuter), och det räknas inte som ett misslyckande. |
| **Fel och återförsök** | Efter 5 vanliga misslyckanden hamnar meddelandet i `notiser-poison`. Felet sparas i `notisFel`. |
| **Ingen dubbelsändning** | Fältet `mailSkickad` sätts när mailet gått iväg, så ett återförsök skickar det inte igen. |

Flöde (*nordvik_maintenance_request*):

![alt text](images/flow.png)

Flödets *JSON* data finns tillsammans med övrig kod längst ned i *README* filen.

### *__7. Nordvik Fastigheter AB:s behov__*

Hur miljön uppfyller Nordvik Fastigheter AB:s behov:

#### __Trafik och skalning__

- Cron-regel (*kontorstid*, måndag till fredag 06:00 till 21:00 Europa/Stockholm) ger två instanser på dagtid i produktion. All övrig tid skalar appen ned till 0. Detta gör att ingen kapacitet står oanvänd under natten.

- Efter nedskalning till noll blir första anropet långsamare (kallstart) detta är ett medvetet val för att hålla nere kostnaden.

- En HTTP-skalningsregel lägger till instanser vid 20 samtidiga anrop per instans upp till 10 instanser. Detta ger utrymme till över 120 samtidiga användare.

#### __Anmälningar och akuta fel__

- För varje anmälan sparas uppgifter och bild, en rad skapas i tabellen *arenden* och *PowerAutomate* skpar en post i *SharePoint* listan och mailar.

- För varje akut anmälan så går det mail direkt till förvaltaren via *Azure Communication Services*, oberoende av flödet.

#### __Bilder och dokument__

- Blob containern som innehåller bilder byter lagringstyp från *Hot* till *Cool* efter 180 dagar.

- Kontrakt och protokoll får lagringstyp *Cool* efter 90 dagar.

#### __Tillgänglighet__

- Åtminstone 2 instanser i prod på kontorstid (bör klara 99,5% tillgänglighet på kontorstid, men är inte mätt exakt).

- Med minst 2 instanser i prod tål miljön att en faller (kontorstid), miljön är zonredundant i prod och lagringen är *ZRS*.

#### __Kostnad__

- Riktvärdet är 2 500 kr och detta bör inte överskridas. Det gäller dock att ha ett öga på *Azure Cost Management* när prognosen har mer data och blir mer pålitligt.

- Budget på 2 500 kr är skapad med en mailvarning till ekonomiavdelningen om den överskrids.

#### __Tillväxt, test eller demomiljö__

- Om fastigheter tillkommer så läggs de in som rader i tabbellen *fastigheter*. Ingen ny infrastruktur behövs.

- Demomiljö kan startas upp `ENVIRONMENT_TYPE=demo`.

### __Säkerhet__

- Lagringen är ej publik åtkomligt (stäng av efter installation / konfiguration). Ingen anonym blob-åtkomst och delade nycklar är av.

- Åtkomst per roll. Hyresgäst, förvaltare och ekonomi styrs i appen (rollkontroll och filtrering per fastighet). Portalen kommer åt lagringen via *Managed Identity*.

- Personuppgifter, inte publika. Bara inloggade användare med en roll når data.

#### __Taggar och uppföljning__

- Alla resurser är taggade.

- Ekonomi kommer åt kan läsa *Azure Cost Management* på resursgruppen och kan följa dess *Azure* kostnader.

#### __Namngivning__

- Följer mönstret *typ-företag-syfte* till exempel *rg-nordvik-prod*.

- Slumpar löpnummer om det behövs till exempel för lagringskontot *stnordvikLÖPNUMMER*

### *__8. Dokumentation__*

Hur miljön har dokumenterats och beskrivts i tidigare steg. Men en kortfattad tabell om innehållet finns nedan.


#### __Miljöns innehåll (kortfattat)__

| Resurs | Namn (prod) | Syfte |
|---|---|---|
| Resursgrupp | `rg-nordvik-prod` | Samlar alla resurser, med kostnadstaggar |
| Virtuellt nätverk | `vnet-nordvik-prod` | Två subnät: `snet-aca` (appmiljön) och `snet-pe` (private endpoints) |
| Container Apps-miljö | `cae-nordvik-prod` | Kör portalen, zonredundant i prod |
| Container App | `ca-nordvik-portal-prod` | Portalen, med Entra-inloggning och skalning 0–10 instanser |
| Container Apps-jobb | `caj-nordvik-notis-prod` | Läser notiskön, skickar akutmail och anropar Power Automate |
| Container Registry | `acrnordvik…` | Lagrar portalens containerbild |
| Lagringskonto | `stnordvik…` | Containrarna `felanmalan` och `avtal`, tabellerna `Arenden`, `Anvandare` och `Fastigheter`, köerna `notiser` och `notiser-poison` |
| Private endpoints och privata DNS-zoner | – | Blob, table och queue, så att lagringen inte nås publikt |
| Managed identity | `id-ca-nordvik-portal-prod` | Portalens åtkomst till lagring, registret och e-posttjänsten, utan nycklar |
| Azure Communication Services (e-post) | – | Akutmail till förvaltare |
| Log Analytics-workspace | – | Loggar, 30 dagars lagring |
| Budget och kostnadsroll (valfria) | – | Budgetvarning samt Cost Management Reader för ekonomi |
| Utanför Azure | – | Power Automate-flöde (SharePoint-lista, mail till delad brevlåda och till hyresgästen) och Entra-appregistrering för inloggning |

Miljön planerades i största del utifrån *Nordvik Fastigheter AB:s*  behov och önskemål. Sen behövde jag ha i åtankte vad jag realistiskt kunde hinna med på cirka 7 dagar. Det finns saker man hade kunnat utveckla om man hade mer tid, ett exempel kan vara en bättre lösning på hur avtal och dokument laddas upp till storage. I dagsläget måste man gå in i bloben och göra det, och det är det bara jag som kan göra (på grund av behörgheter). Man hade kunnat integrera detta i applikationen / webbsidan, men detta fick prioriteras bort då *Nordvik Fastigheter AB:s* uttryckta behov och önskemål gick före och tog upp den tid som fanns tillgänglig.

Lösningen implementeras som IaC som beskrevs i steg 1 av del B. Efter lösningen är implementerad bör den utvärderas under en tid. Man bör ställa frågor som: Kan den optimeras, bli säkrare och håller den kostanden inom bugetens ram . Efter en tids utvärdering kanske man till och med kommer fram till att man behöver en annan nivå (*Virtual Machines (VM)* eller *Serverless*).

Lösningen återskpas även med kod, kod som har parametrar om något behövs ändras tills nästa gång. Skall resursgruppen ha ett annat namn? Ändra parametern i *V41_main.biceparm*. Koden finns versionshanterad i GitHub (om det är i skarp miljö kanske den dock inte ens GitHub Repository skall vara publikt).

### *__9. Verifiering__*

Hyresgäst kan skicka felanmälningar:

![alt text](images/urgent_maintenance_request_with_attachment.png)

![alt text](images/urgent_maintenance_request_with_attachment_sent.png)

Felanmälan tas emot av förvatare och dyker upp på hemsidan för dem:

![alt text](images/urgent_maintenance_request_with_attachment_received.png)

Om felanmälan har en brådskande kategori så skickas mail direkt till förvaltaren:

![alt text](images/urgent_maintenance_request_email_employee.png)

*PowerAutomate* flödet triggas:

![alt text](images/flow_successful.png)

*PowerAutomate* flödet skapar en post i en *SharePoint* lista:

![alt text](images/sharepoint_list_with_attachment.png)

![alt text](images/sharepoint_attachment.png)

Flödet skickar e-postbekräftelse till hyresgästen:

![alt text](images/maintenance_request_email_customer.png)

Flödet skickar mail till en delad mailbox som alla förvaltare kan läsa. Oavsätt om felanmälan är akut eller inte:

![alt text](images/not_ungent_maintenance_request_email_employee.png)

Om en förvaltare löser ett ärende så uppdateras det även för hyresgästerna:

![alt text](images/maintenance_request_done_employee.png)

![alt text](images/maintenance_request_done_customer.png)

Hyresgästerna ser bara sina egna ärenden, de tidigare felanmälningarna gjordes av Eric. På nedan bild är vi inloggad med Emmas konto:

![alt text](images/different_customer_website_view.png)

Samma sak gäller för förvaltarna. De ser bara felanmälningar som är kopplade till deras fastigheter.

Billys är förvaltare för lägenheter (den som Erik har):

![alt text](images/billy_apartments.png)

Rickard är förvaltare för lägenheter (den som Ella har):

![alt text](images/rickard_apartments.png)

Billys vy fanns i tidigare bilder, men detta är Rickards vy:

![alt text](images/different_employee_website_view.png)

Ekonomi ser endast statistik på hemsidan:

![alt text](images/economy_website_view.png)

Dokument kan laddas upp och syns på hemsidan:

![alt text](images/upload_contract.png)

![alt text](images/contract_website.png)

![alt text](images/contract_website_contents.png)

Inloggningssidan:

![alt text](images/website_login.png)

Resursgruppen:

![alt text](images/resource_group.png)

Resursgruppens innehåll:

![alt text](images/resource_group_contents.png)

Taggar:

![alt text](images/tags_2.png)

Konto från ekonomi kan använda taggarna, men kommer inte åt annan info:

![alt text](images/tag_example.png)

![alt text](images/tags.png)

![alt text](images/economy_scope.png)

Tabeller:

![alt text](images/tables.png)

![alt text](images/table_anvandare_contents.png)

![alt text](images/table_arenden_contents.png)

![alt text](images/table_fastigheter_contents.png)

Köer:

![alt text](images/queues.png)

Demomiljön fungerar:

![alt text](images/demo_1.png)

![alt text](images/demo_2.png)

![alt text](images/demo_3.png)

Lifecycle management:

![alt text](images/lifecycle_management.png)

### *__10. Kod__*

#### __Dockerfile__

```Dockerfile
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY V41_requirements.txt .
RUN pip install --no-cache-dir -r V41_requirements.txt

COPY V41_common.py V41_app.py V41_worker.py ./
COPY static ./static

# Run as a non-root user.
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# gunicorn instead of Flask's development server. The Container Apps ingress
# terminates HTTPS and forwards traffic here on port 8000.
# gthread: several uploads (2-5 MB photos) can be in flight per worker.
# The notification job reuses this image and overrides the command with
# "python V41_worker.py" (see V41_resources.bicep).
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "4", "--worker-class", "gthread", "--timeout", "60", "V41_app:app"]
```

#### __V41_app.py__

```python
# Nordvik tenant portal (container version).
# Tenants report faults and follow their own tickets, property managers handle
# tickets for their properties, finance sees anonymous statistics only.
#
# Storage (managed identity, no account keys):
#   Blob   felanmalan  photos, path <property>/<ticket id>/bild.<ext>
#   Blob   avtal       contracts / protocols, path <property>/<unit>/<file>
#   Table  Arenden     one row per ticket (PartitionKey = property)
#   Queue  notiser     work for the notification job (Power Automate + urgent e-mail)
#
# Sign-in is handled by Container Apps built-in authentication ("Easy Auth") against
# your Entra ID tenant. It passes the signed-in user's UPN in X-MS-CLIENT-PRINCIPAL-NAME.
# Role, property and unit come from the Anvandare table (RowKey = lower-case UPN).
# Without that header every API call is rejected.

import base64
import functools
import json
import logging
import os
import time
import uuid
from datetime import datetime, timedelta, timezone

from azure.core.exceptions import ResourceNotFoundError
from azure.data.tables import UpdateMode
from azure.storage.blob import ContentSettings
from flask import Flask, Response, g, jsonify, redirect, request, send_from_directory

import V41_common as c

STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
MAX_IMAGE_BYTES = 8 * 1024 * 1024
IMAGE_TYPES = {
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".webp": "image/webp", ".heic": "image/heic",
}

app = Flask(__name__, static_folder=None)
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024
app.logger.setLevel(logging.INFO)


# --------------------------------------------------------------------------
# Helpers: errors, security headers, authentication
# --------------------------------------------------------------------------
def _err(status, message):
    return jsonify({"fel": message}), status


@app.errorhandler(413)
def _too_large(_):
    return _err(413, "Filen är för stor (max 10 MB).")


@app.before_request
def _csrf_guard():
    # Easy Auth uses cookies, so state-changing calls must carry a header that a
    # cross-site form cannot set.
    if request.method in ("POST", "PUT", "PATCH", "DELETE"):
        if request.headers.get("X-Requested-With") != "nordvik-portal":
            return _err(403, "Ogiltig begäran.")


@app.after_request
def _headers(resp):
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["Referrer-Policy"] = "same-origin"
    if request.path.startswith("/api/"):
        resp.headers.setdefault("Cache-Control", "no-store")
    if request.path == "/":
        resp.headers["Cache-Control"] = "no-store"
        resp.headers["Content-Security-Policy"] = (
            "default-src 'self'; img-src 'self' blob:; style-src 'self'; "
            "script-src 'self'; frame-ancestors 'none'"
        )
    return resp


def _principal_id():
    if c.AUTH_MODE == "demo":
        key = request.cookies.get("demo_user", "hyresgast")
        return key if key in c.DEMO_USERS else None
    # Easy Auth passes the signed-in user's claims base64-encoded. The Anvandare table
    # is keyed by the lower-case UPN (claim preferred_username); the name header is
    # the fallback.
    raw = request.headers.get("X-MS-CLIENT-PRINCIPAL", "")
    if raw:
        try:
            claims = json.loads(base64.b64decode(raw + "=" * (-len(raw) % 4))).get("claims", [])
            for want in ("preferred_username",
                         "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"):
                for cl in claims:
                    if cl.get("typ") == want and cl.get("val"):
                        return cl["val"].strip().lower()
        except (ValueError, TypeError):
            pass
    return request.headers.get("X-MS-CLIENT-PRINCIPAL-NAME", "").strip().lower() or None


def needs_roles(*roles):
    def deco(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            uid = _principal_id()
            if not uid:
                return _err(401, "Du måste logga in.")
            user = c.get_user(uid)
            if not user or user["roll"] not in c.ROLES:
                return _err(403, "Ditt konto är inte kopplat till någon roll i portalen.")
            if roles and user["roll"] not in roles:
                return _err(403, "Du saknar behörighet.")
            g.user = user
            return fn(*args, **kwargs)
        return wrapper
    return deco


# --------------------------------------------------------------------------
# Helpers: tickets
# --------------------------------------------------------------------------
def _public_ticket(e, role):
    out = {
        "id": e["RowKey"],
        "fastighet": e["PartitionKey"],
        "enhet": e.get("enhet", ""),
        "kategori": e.get("kategori", ""),
        "kategoriNamn": e.get("kategoriNamn", ""),
        "akut": bool(e.get("akut", False)),
        "rubrik": e.get("rubrik", ""),
        "beskrivning": e.get("beskrivning", ""),
        "status": e.get("status", "ny"),
        "skapad": e.get("skapad", ""),
        "uppdaterad": e.get("uppdaterad", ""),
        "harBild": bool(e.get("bild", "")),
        "losning": e.get("losning", ""),
        "losningTid": e.get("losningTid", ""),
    }
    if role == "forvaltare":
        out["losningAv"] = e.get("losningAv", "")
        out["hyresgastNamn"] = e.get("hyresgastNamn", "")
        out["hyresgastMail"] = e.get("hyresgastMail", "")
    return out


def _get_ticket(user, ticket_id):
    """Returns the ticket entity if this user may see it, else None."""
    if user["roll"] == "hyresgast":
        partitions = [user["fastighet"]]
    elif user["roll"] == "forvaltare":
        partitions = user["fastigheter"]
    else:
        return None
    for pid in partitions:
        try:
            e = c.table(c.TICKETS_TABLE).get_entity(pid, ticket_id)
        except ResourceNotFoundError:
            continue
        if user["roll"] == "hyresgast" and e.get("hyresgastId") != user["id"]:
            return None
        return e
    return None


# --------------------------------------------------------------------------
# Pages
# --------------------------------------------------------------------------
@app.get("/")
def index():
    return send_from_directory(STATIC_DIR, "V41_index.html")


@app.get("/static/<path:filename>")
def static_files(filename):
    return send_from_directory(STATIC_DIR, filename, max_age=3600)


@app.get("/demo/byt")
def demo_switch():
    # Persona switcher, only available in test/demo environments.
    if c.AUTH_MODE != "demo":
        return _err(404, "Finns inte.")
    key = request.args.get("roll", "hyresgast")
    resp = redirect("/")
    if key in c.DEMO_USERS:
        resp.set_cookie("demo_user", key, samesite="Lax", httponly=True, secure=True)
    return resp


# --------------------------------------------------------------------------
# API
# --------------------------------------------------------------------------
@app.get("/api/me")
@needs_roles()
def me():
    u = g.user
    props = c.list_properties()
    if u["roll"] == "hyresgast":
        scope = [u["fastighet"]]
    elif u["roll"] == "forvaltare":
        scope = u["fastigheter"]
    else:
        scope = list(props.keys())
    return jsonify({
        "id": u["id"], "namn": u["namn"], "roll": u["roll"],
        "fastighet": u["fastighet"], "enhet": u["enhet"],
        "fastigheter": [{"id": p, "namn": props.get(p, {}).get("namn", p)} for p in scope],
        "demo": c.AUTH_MODE == "demo",
        "kategorier": c.CATEGORIES,
    })


@app.post("/api/arenden")
@needs_roles("hyresgast")
def create_ticket():
    u = g.user
    cat = c.CATEGORY_BY_ID.get(request.form.get("kategori", ""))
    beskrivning = request.form.get("beskrivning", "").strip()[:4000]
    rubrik = request.form.get("rubrik", "").strip()[:120] or (cat["namn"] if cat else "")
    if not cat or not beskrivning:
        return _err(400, "Välj kategori och beskriv felet.")
    if not u["fastighet"]:
        return _err(400, "Ditt konto saknar koppling till en fastighet.")

    image = request.files.get("bild")
    image_bytes, image_ext, image_type = None, "", ""
    if image is not None and image.filename:
        image_ext = os.path.splitext(image.filename)[1].lower()
        image_type = IMAGE_TYPES.get(image_ext)
        if not image_type:
            return _err(400, "Bilden måste vara JPG, PNG, WEBP eller HEIC.")
        image_bytes = image.read()
        if len(image_bytes) > MAX_IMAGE_BYTES:
            return _err(413, "Bilden är för stor (max 8 MB).")

    now = datetime.now(timezone.utc)
    stamp = now.strftime("%Y%m%dT%H%M%SZ")
    ticket_id = "{0}-{1}".format(stamp, uuid.uuid4().hex[:8])
    pid = u["fastighet"]

    # The user's own file name is never used in the blob path.
    image_name = "{0}/{1}/bild{2}".format(pid, ticket_id, image_ext) if image_bytes else ""

    # 1) Photo.
    if image_bytes:
        c.blob_service.get_container_client(c.IMAGES_CONTAINER).upload_blob(
            name=image_name, data=image_bytes, overwrite=False,
            content_settings=ContentSettings(content_type=image_type),
        )

    # 2) Ticket row (this is the "list" tenants and managers read from).
    entity = {
        "PartitionKey": pid, "RowKey": ticket_id,
        "hyresgastId": u["id"], "hyresgastNamn": u["namn"], "hyresgastMail": u["mail"],
        "enhet": u["enhet"],
        "kategori": cat["id"], "kategoriNamn": cat["namn"], "akut": cat["akut"],
        "rubrik": rubrik, "beskrivning": beskrivning,
        "bild": image_name, "bildTyp": image_type,
        "status": "ny", "skapad": now.isoformat(), "uppdaterad": now.isoformat(),
        "notis": "vantar",
    }
    c.table(c.TICKETS_TABLE).create_entity(entity)

    # 3) Hand over to the notification job. The ticket is already saved, so a
    #    queue problem must not fail the request from the tenant's point of view.
    try:
        c.queue(c.QUEUE_NAME).send_message(json.dumps({"fastighet": pid, "id": ticket_id}))
        app.logger.info("Queued notification for ticket %s", ticket_id)
    except Exception:
        app.logger.exception("Could not queue notification for ticket %s", ticket_id)

    return jsonify({"id": ticket_id, "akut": cat["akut"]}), 201


@app.get("/api/arenden")
@needs_roles("hyresgast", "forvaltare")
def list_tickets():
    u = g.user
    status = request.args.get("status", "")
    rows = []
    tbl = c.table(c.TICKETS_TABLE)
    if u["roll"] == "hyresgast":
        rows = tbl.query_entities(
            "PartitionKey eq @p and hyresgastId eq @u",
            parameters={"p": u["fastighet"], "u": u["id"]},
        )
    else:
        wanted = request.args.get("fastighet", "")
        for pid in u["fastigheter"]:
            if wanted and wanted != pid:
                continue
            rows = list(rows) + list(tbl.query_entities(
                "PartitionKey eq @p", parameters={"p": pid}
            ))
    items = [_public_ticket(e, u["roll"]) for e in rows]
    if status in c.STATUSES:
        items = [i for i in items if i["status"] == status]
    items.sort(key=lambda i: i["id"], reverse=True)
    return jsonify(items[:300])


@app.get("/api/arenden/<ticket_id>")
@needs_roles("hyresgast", "forvaltare")
def get_ticket(ticket_id):
    e = _get_ticket(g.user, ticket_id)
    if e is None:
        return _err(404, "Ärendet finns inte.")
    return jsonify(_public_ticket(e, g.user["roll"]))


@app.get("/api/arenden/<ticket_id>/bild")
@needs_roles("hyresgast", "forvaltare")
def ticket_image(ticket_id):
    e = _get_ticket(g.user, ticket_id)
    if e is None or not e.get("bild"):
        return _err(404, "Bilden finns inte.")
    data = c.blob_service.get_blob_client(c.IMAGES_CONTAINER, e["bild"]).download_blob().readall()
    resp = Response(data, mimetype=e.get("bildTyp") or "application/octet-stream")
    resp.headers["Cache-Control"] = "private, max-age=3600"
    return resp


@app.post("/api/arenden/<ticket_id>/status")
@needs_roles("forvaltare")
def set_status(ticket_id):
    # Body: {"status": "ny|pagar|klar", "losning": "text"}. "losning" is optional:
    # if it is left out, the saved solution is not touched.
    body = request.get_json(silent=True) or {}
    status = body.get("status", "")
    if status not in c.STATUSES:
        return _err(400, "Ogiltig status.")
    e = _get_ticket(g.user, ticket_id)
    if e is None:
        return _err(404, "Ärendet finns inte.")
    now = datetime.now(timezone.utc).isoformat()
    update = {"PartitionKey": e["PartitionKey"], "RowKey": e["RowKey"], "status": status, "uppdaterad": now}
    losning = e.get("losning", "")
    if "losning" in body:
        new = str(body.get("losning") or "").strip()[:4000]
        if new != losning:
            losning = new
            update["losning"] = new
            update["losningAv"] = g.user["namn"] if new else ""
            update["losningTid"] = now if new else ""
    c.table(c.TICKETS_TABLE).update_entity(update, mode=UpdateMode.MERGE)
    return jsonify({"id": ticket_id, "status": status, "losning": losning})


# ---- Documents (contracts, inspection protocols) -------------------------
def _doc_prefix(user):
    """Returns the list of blob prefixes this user may read."""
    if user["roll"] == "hyresgast":
        return ["{0}/{1}/".format(user["fastighet"], user["enhet"])]
    if user["roll"] == "forvaltare":
        return ["{0}/".format(p) for p in user["fastigheter"]]
    return []


def _doc_allowed(user, blob_name):
    if ".." in blob_name or blob_name.startswith("/"):
        return False
    return any(blob_name.startswith(p) for p in _doc_prefix(user))


@app.get("/api/dokument")
@needs_roles("hyresgast", "forvaltare")
def list_documents():
    u = g.user
    prefixes = _doc_prefix(u)
    wanted = request.args.get("fastighet", "")
    unit = request.args.get("enhet", "")
    if u["roll"] == "forvaltare":
        if wanted:
            prefixes = [p for p in prefixes if p == wanted + "/"]
            if prefixes and unit:
                prefixes = [prefixes[0] + unit + "/"]
    cont = c.blob_service.get_container_client(c.DOCS_CONTAINER)
    docs = []
    for p in prefixes:
        for b in cont.list_blobs(name_starts_with=p):
            docs.append({
                "namn": b.name, "visa": b.name[len(p):] if u["roll"] == "hyresgast" else b.name,
                "storlek": b.size,
                "andrad": b.last_modified.isoformat() if b.last_modified else "",
            })
            if len(docs) >= 500:
                break
    docs.sort(key=lambda d: d["andrad"], reverse=True)
    return jsonify(docs)


@app.get("/api/dokument/hamta")
@needs_roles("hyresgast", "forvaltare")
def download_document():
    name = request.args.get("namn", "")
    if not _doc_allowed(g.user, name):
        return _err(404, "Dokumentet finns inte.")
    try:
        blob = c.blob_service.get_blob_client(c.DOCS_CONTAINER, name).download_blob()
    except ResourceNotFoundError:
        return _err(404, "Dokumentet finns inte.")
    resp = Response(blob.readall(), mimetype="application/octet-stream")
    safe = name.rsplit("/", 1)[-1].replace('"', "")
    resp.headers["Content-Disposition"] = "attachment; filename=\"{0}\"".format(safe)
    return resp


# ---- Statistics (no personal data; used by managers and finance) ---------
_stats_cache = {}


@app.get("/api/statistik")
@needs_roles("forvaltare", "ekonomi")
def statistics():
    u = g.user
    props = c.list_properties()
    scope = u["fastigheter"] if u["roll"] == "forvaltare" else list(props.keys())
    key = (u["roll"], tuple(sorted(scope)))
    hit = _stats_cache.get(key)
    if hit and time.time() - hit[0] < 300:
        return jsonify(hit[1])

    since = (datetime.now(timezone.utc) - timedelta(days=365)).strftime("%Y%m%dT000000Z")
    tbl = c.table(c.TICKETS_TABLE)
    per_prop, per_month, per_cat = {}, {}, {}
    for pid in scope:
        rows = tbl.query_entities(
            "PartitionKey eq @p and RowKey ge @s",
            parameters={"p": pid, "s": since},
            select=["PartitionKey", "RowKey", "kategoriNamn", "akut", "status"],
        )
        for e in rows:
            p = per_prop.setdefault(pid, {"fastighet": pid, "namn": props.get(pid, {}).get("namn", pid),
                                          "antal": 0, "akuta": 0, "oppna": 0})
            p["antal"] += 1
            p["akuta"] += 1 if e.get("akut") else 0
            p["oppna"] += 0 if e.get("status") == "klar" else 1
            month = e["RowKey"][:6]
            per_month[month] = per_month.get(month, 0) + 1
            cat = e.get("kategoriNamn", "Övrigt")
            per_cat[cat] = per_cat.get(cat, 0) + 1
    result = {
        "perFastighet": sorted(per_prop.values(), key=lambda x: -x["antal"]),
        "perManad": [{"manad": m, "antal": n} for m, n in sorted(per_month.items())],
        "perKategori": [{"kategori": k, "antal": n} for k, n in sorted(per_cat.items(), key=lambda x: -x[1])],
    }
    _stats_cache[key] = (time.time(), result)
    return jsonify(result)


@app.get("/health")
def health():
    # Used by the Container Apps liveness/readiness probes. Deliberately does not
    # touch storage, so a storage hiccup does not restart healthy replicas.
    return {"status": "ok", "auth_mode": c.AUTH_MODE, "flow_configured": bool(c.FLOW_URL)}
```

#### __V41_common.py__

```python
# Nordvik tenant portal - shared configuration and Azure clients.
# Used by the web app (V41_app.py) and the notification job (V41_worker.py).
#
# Configuration comes from environment variables (set by Bicep):
#   STORAGE_ACCOUNT   Name of the storage account (required)
#   IMAGES_CONTAINER  Blob container for fault-report photos (default: felanmalan)
#   DOCS_CONTAINER    Blob container for contracts / inspection protocols (default: avtal)
#   QUEUE_NAME        Storage queue with notification work (default: notiser)
#   AUTH_MODE         "easyauth" (default, production) or "demo" (test/demo only)
#   AZURE_CLIENT_ID   Client ID of the user-assigned managed identity
#   FLOW_URL          Optional Power Automate HTTP trigger URL (stored as a secret)
#   ACS_ENDPOINT      Azure Communication Services endpoint (e-mail for urgent reports)
#   MAIL_SENDER       Sender address on the ACS e-mail domain
#   SHARED_MAILBOX    Shared mailbox that gets an e-mail for EVERY report
#   AKUT_MAIL_EXTRA   Optional comma-separated extra recipients for urgent reports
#   PORTAL_URL        Public URL of the portal (used in e-mails)

import os

from azure.core.exceptions import ResourceNotFoundError
from azure.data.tables import TableServiceClient
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient
from azure.storage.queue import QueueClient

STORAGE_ACCOUNT = os.environ["STORAGE_ACCOUNT"]
IMAGES_CONTAINER = os.environ.get("IMAGES_CONTAINER", "felanmalan")
DOCS_CONTAINER = os.environ.get("DOCS_CONTAINER", "avtal")
QUEUE_NAME = os.environ.get("QUEUE_NAME", "notiser")
AUTH_MODE = os.environ.get("AUTH_MODE", "easyauth")
FLOW_URL = os.environ.get("FLOW_URL", "")
ACS_ENDPOINT = os.environ.get("ACS_ENDPOINT", "")
MAIL_SENDER = os.environ.get("MAIL_SENDER", "")
SHARED_MAILBOX = os.environ.get("SHARED_MAILBOX", "").strip()
AKUT_MAIL_EXTRA = [a.strip() for a in os.environ.get("AKUT_MAIL_EXTRA", "").split(",") if a.strip()]
PORTAL_URL = os.environ.get("PORTAL_URL", "")

TICKETS_TABLE = "Arenden"
USERS_TABLE = "Anvandare"
PROPERTIES_TABLE = "Fastigheter"

ROLES = ("hyresgast", "forvaltare", "ekonomi")
STATUSES = ("ny", "pagar", "klar")

credential = DefaultAzureCredential(
    managed_identity_client_id=os.environ.get("AZURE_CLIENT_ID")
)
blob_service = BlobServiceClient(
    account_url="https://{0}.blob.core.windows.net".format(STORAGE_ACCOUNT),
    credential=credential,
)
table_service = TableServiceClient(
    endpoint="https://{0}.table.core.windows.net".format(STORAGE_ACCOUNT),
    credential=credential,
)


def table(name):
    return table_service.get_table_client(name)


def queue(name):
    return QueueClient(
        account_url="https://{0}.queue.core.windows.net".format(STORAGE_ACCOUNT),
        queue_name=name,
        credential=credential,
    )


# Categories. "akut" categories trigger an immediate e-mail to the manager.
CATEGORIES = [
    {"id": "vattenlacka", "namn": "Vattenläcka eller översvämning", "akut": True},
    {"id": "stromavbrott", "namn": "Strömavbrott", "akut": True},
    {"id": "varme", "namn": "Värme eller varmvatten saknas", "akut": True},
    {"id": "hiss", "namn": "Hiss har stannat", "akut": True},
    {"id": "inbrott", "namn": "Inbrott eller trasigt lås", "akut": True},
    {"id": "avlopp", "namn": "Stopp i avlopp eller toalett", "akut": False},
    {"id": "el", "namn": "Elfel (uttag, lampor)", "akut": False},
    {"id": "ventilation", "namn": "Ventilation", "akut": False},
    {"id": "fonster_dorr", "namn": "Fönster eller dörr", "akut": False},
    {"id": "tvattstuga", "namn": "Tvättstuga", "akut": False},
    {"id": "skadedjur", "namn": "Skadedjur", "akut": False},
    {"id": "allmanna_ytor", "namn": "Trapphus, utomhus och gemensamma ytor", "akut": False},
    {"id": "ovrigt", "namn": "Övrigt", "akut": False},
]
CATEGORY_BY_ID = {c["id"]: c for c in CATEGORIES}

# Demo data. Only used when AUTH_MODE=demo (never in production, Bicep enforces it).
DEMO_PROPERTIES = {
    "F001": {"namn": "Kvarteret Älvkanten", "forvaltarMail": "forvaltare.demo@example.com"},
    "F002": {"namn": "Hamnhuset", "forvaltarMail": "forvaltare.demo@example.com"},
}
DEMO_USERS = {
    "hyresgast": {"roll": "hyresgast", "namn": "Elin Demo", "mail": "elin.demo@example.com",
                  "fastighet": "F001", "enhet": "1204", "fastigheter": []},
    "hyresgast2": {"roll": "hyresgast", "namn": "Omar Demo", "mail": "omar.demo@example.com",
                   "fastighet": "F002", "enhet": "0302", "fastigheter": []},
    "forvaltare": {"roll": "forvaltare", "namn": "Frida Förvaltare (demo)", "mail": "forvaltare.demo@example.com",
                   "fastighet": "", "enhet": "", "fastigheter": ["F001", "F002"]},
    "ekonomi": {"roll": "ekonomi", "namn": "Erik Ekonomi (demo)", "mail": "ekonomi.demo@example.com",
                "fastighet": "", "enhet": "", "fastigheter": []},
}


def get_user(user_id):
    """Looks up a portal user (user_id = lower-case UPN). None if not registered."""
    if AUTH_MODE == "demo":
        u = DEMO_USERS.get(user_id)
        return dict(u, id=user_id) if u else None
    try:
        e = table(USERS_TABLE).get_entity("anvandare", user_id)
    except ResourceNotFoundError:
        return None
    return {
        "id": user_id,
        "roll": e.get("roll", ""),
        "namn": e.get("namn", ""),
        "mail": e.get("mail", ""),
        "fastighet": e.get("fastighet", ""),
        "enhet": e.get("enhet", ""),
        "fastigheter": [p.strip() for p in e.get("fastigheter", "").split(",") if p.strip()],
    }


def list_properties():
    """Returns {property_id: {"namn": ..., "forvaltarMail": ...}}."""
    if AUTH_MODE == "demo":
        return DEMO_PROPERTIES
    result = {}
    for e in table(PROPERTIES_TABLE).query_entities("PartitionKey eq 'fastighet'"):
        result[e["RowKey"]] = {"namn": e.get("namn", e["RowKey"]), "forvaltarMail": e.get("forvaltarMail", "")}
    return result
```

#### __V41_worker.py__

```python
# Nordvik notification job. Runs as an event-triggered Container Apps Job: it
# starts when messages appear in the "notiser" queue, drains the queue, and exits
# (so nothing is paid for while the queue is empty).
#
# For every ticket it
#   1) sends an e-mail through Azure Communication Services (managed identity):
#        urgent category  -> property manager + shared mailbox (+ AKUT_MAIL_EXTRA)
#        ordinary report  -> shared mailbox only (nothing if SHARED_MAILBOX is empty)
#   2) posts the ticket (incl. photo as base64) to Power Automate, which creates the
#      list item (only if FLOW_URL is set).
# Each step records a flag on the ticket, so a retry never repeats a finished step.
# After 5 failed attempts the message moves to the "<queue>-poison" queue. When Azure
# throttles e-mail sending (HTTP 429) the message is simply retried later and never
# counts as failed; while throttled, ordinary mails wait so urgent ones get through first.

import base64
import html
import json
import logging
import urllib.request
from datetime import datetime, timezone

from azure.communication.email import EmailClient
from azure.core.exceptions import HttpResponseError
from azure.data.tables import UpdateMode

import V41_common as c

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("worker")

MAX_ATTEMPTS = 5
THROTTLE_RETRY_SECONDS = 600


class Throttled(Exception):
    """E-mail sending is rate limited; try again later."""


def _image_b64(entity):
    if not entity.get("bild"):
        return ""
    data = c.blob_service.get_blob_client(c.IMAGES_CONTAINER, entity["bild"]).download_blob().readall()
    return base64.b64encode(data).decode("ascii")


def _post_flow(entity, manager_mail):
    payload = {
        "id": entity["RowKey"], "fastighet": entity["PartitionKey"], "enhet": entity.get("enhet", ""),
        "name": entity.get("hyresgastNamn", ""), "mail": entity.get("hyresgastMail", ""),
        "kategori": entity.get("kategoriNamn", ""), "akut": bool(entity.get("akut", False)),
        "rubrik": entity.get("rubrik", ""), "message": entity.get("beskrivning", ""),
        "created": entity.get("skapad", ""), "forvaltare_mail": manager_mail,
        "image": entity.get("bild", ""),
        "image_content_type": entity.get("bildTyp", ""),
        "image_base64": _image_b64(entity),
    }
    req = urllib.request.Request(
        c.FLOW_URL, data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "Content-Type": "application/json; charset=utf-8",
            "User-Agent": "NordvikWorker/1.0"
        },
        method="POST",
    )
    urllib.request.urlopen(req, timeout=30).read()


def _send_ticket_mail(entity, recipients, urgent):
    e = lambda k: html.escape(str(entity.get(k, "")))
    link = c.PORTAL_URL or ""
    prefix = "AKUT felanmälan" if urgent else "Ny felanmälan"
    plain = (
        "{p}: {kat}\nFastighet: {f}, enhet {en}\nHyresgäst: {n} ({m})\n\n{b}\n\nÄrende: {i}\n{l}"
    ).format(p=prefix, kat=entity.get("kategoriNamn", ""), f=entity["PartitionKey"], en=entity.get("enhet", ""),
             n=entity.get("hyresgastNamn", ""), m=entity.get("hyresgastMail", ""),
             b=entity.get("beskrivning", ""), i=entity["RowKey"], l=link)
    body = (
        "<h2>{p}: {kat}</h2><p><b>Fastighet:</b> {f}, enhet {en}<br>"
        "<b>Hyresgäst:</b> {n} ({m})</p><p>{b}</p><p>Ärende: <code>{i}</code></p><p><a href='{l}'>Öppna portalen</a></p>"
    ).format(p=prefix, kat=e("kategoriNamn"), f=html.escape(entity["PartitionKey"]), en=e("enhet"),
             n=e("hyresgastNamn"), m=e("hyresgastMail"), b=e("beskrivning"),
             i=html.escape(entity["RowKey"]), l=html.escape(link))
    subject = "{0}: {1} - {2}".format("AKUT" if urgent else "Felanmälan", entity.get("kategoriNamn", ""), entity["PartitionKey"])
    message = {
        "senderAddress": c.MAIL_SENDER,
        "recipients": {"to": [{"address": a} for a in recipients]},
        "content": {"subject": subject, "plainText": plain, "html": body},
    }
    try:
        EmailClient(c.ACS_ENDPOINT, c.credential).begin_send(message).result()
    except HttpResponseError as ex:
        if getattr(ex, "status_code", None) == 429:
            raise Throttled(str(ex)) from ex
        raise


def _recipients(entity, manager_mail):
    if entity.get("akut"):
        raw = [manager_mail, c.SHARED_MAILBOX] + c.AKUT_MAIL_EXTRA
    else:
        raw = [c.SHARED_MAILBOX]
    seen, out = set(), []
    for a in raw:
        if a and a.lower() not in seen:
            seen.add(a.lower()); out.append(a)
    return out


def handle(msg, state):
    tbl = c.table(c.TICKETS_TABLE)
    entity = tbl.get_entity(msg["fastighet"], msg["id"])
    ticket_id = entity["RowKey"]
    urgent = bool(entity.get("akut"))
    manager_mail = c.list_properties().get(entity["PartitionKey"], {}).get("forvaltarMail", "")
    done, errors = {}, []

    # E-mail first, and independent of Power Automate: a broken flow must not stop
    # a report from reaching the manager or the shared mailbox.
    if not entity.get("mailSkickad"):
        recipients = _recipients(entity, manager_mail)
        if not recipients:
            if urgent:
                log.error("Urgent ticket %s has no recipients (property manager e-mail missing?)", ticket_id)
                errors.append(ValueError("No recipients for urgent ticket {0}".format(ticket_id)))
            else:
                log.info("Ticket %s: no shared mailbox configured, no mail sent", ticket_id)
        elif not urgent and state["throttled"]:
            errors.append(Throttled("Ordinary mail deferred while sending is throttled"))
        else:
            try:
                _send_ticket_mail(entity, recipients, urgent)
                done["mailSkickad"] = True
                log.info("%s mail sent for ticket %s (%s recipient(s))", "Urgent" if urgent else "Ordinary", ticket_id, len(recipients))
            except Throttled as ex:
                state["throttled"] = True
                log.warning("E-mail sending is throttled; ticket %s will be retried", ticket_id)
                errors.append(ex)
            except Exception as ex:
                log.exception("Mail FAILED for ticket %s (%s recipient(s))", ticket_id, len(recipients))
                errors.append(ex)

    if c.FLOW_URL and not entity.get("flowSkickad"):
        try:
            _post_flow(entity, manager_mail)
            done["flowSkickad"] = True
            log.info("Power Automate notified for ticket %s", ticket_id)
        except Exception as ex:
            log.exception("Power Automate call FAILED for ticket %s", ticket_id)
            errors.append(ex)

    # Record what succeeded, so a retry only repeats the step that failed.
    update = dict(done, PartitionKey=entity["PartitionKey"], RowKey=ticket_id)
    if not errors:
        update.update({"notis": "klar", "notisTid": datetime.now(timezone.utc).isoformat(), "notisFel": ""})
    else:
        update["notisFel"] = str(errors[0])[:500]
    tbl.update_entity(update, mode=UpdateMode.MERGE)
    if errors:
        # Real failures count towards the poison queue, throttling never does.
        raise next((x for x in errors if not isinstance(x, Throttled)), errors[0])


def main():
    q = c.queue(c.QUEUE_NAME)
    poison = c.queue(c.QUEUE_NAME + "-poison")
    handled, state = 0, {"throttled": False}
    log.info("Worker started, reading queue %s", c.QUEUE_NAME)
    while True:
        batch = list(q.receive_messages(messages_per_page=5, visibility_timeout=300, max_messages=5))
        if not batch:
            break
        deferred = 0
        for m in batch:
            try:
                handle(json.loads(m.content), state)
                q.delete_message(m)
                handled += 1
            except Throttled:
                q.update_message(m, visibility_timeout=THROTTLE_RETRY_SECONDS)
                deferred += 1
            except Exception:
                log.exception("Failed (attempt %s) for message %s", m.dequeue_count, m.id)
                if m.dequeue_count >= MAX_ATTEMPTS:
                    poison.send_message(m.content)
                    q.delete_message(m)
        if deferred == len(batch):
            break  # everything left is waiting for the rate limit; stop and let the job end
    log.info("Done, %s message(s) handled", handled)


if __name__ == "__main__":
    main()
```

#### __V41_main.bicep__

```bicep
targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'swedencentral'

@allowed([
  'prod'
  'test'
  'demo'
])
@description('prod = production (zone redundant, 2 instances in office hours). test/demo = same layout, scales to zero, no zone redundancy, demo sign-in allowed.')
param environmentType string = 'prod'

@description('Name of the resource group')
param resourceGroupName string = 'rg-nordvik-${environmentType}'

@description('Object ID of the person/pipeline deploying (admin data access to the storage account). Leave empty to skip. az ad signed-in-user show --query id -o tsv')
param callerObjectId string = ''

@description('Object ID of the Entra group for property managers. Gets read/write on the contracts container. Leave empty to skip.')
param forvaltareGroupId string = ''

@description('Object ID of the Entra group for finance. Gets Cost Management Reader on the resource group (no data access). Leave empty to skip.')
param ekonomiGroupId string = ''

@description('Public IP allowed through the storage firewall. Leave empty to keep public network access to storage fully disabled.')
param allowedIpAddress string = ''

@description('Name of the virtual network')
param vnetName string = 'vnet-nordvik-${environmentType}'

@description('Address space of the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet that holds the private endpoints')
param subnetPeName string = 'snet-pe'

@description('Address prefix of the private endpoint subnet')
param subnetPePrefix string = '10.0.2.0/24'

@description('Name of the subnet used by the Container Apps environment')
param subnetAcaName string = 'snet-aca'

@description('Address prefix of the Container Apps subnet (workload profiles environment needs at least /27)')
param subnetAcaPrefix string = '10.0.4.0/26'

@description('Prefix used to generate a globally unique storage account name (a random suffix is appended)')
param storageAccountNamePrefix string = 'stnordvik'

@description('SKU of the storage account. ZRS keeps data available if one zone fails.')
param storageAccountSku string = environmentType == 'prod' ? 'Standard_ZRS' : 'Standard_LRS'

@description('Blob container for fault-report photos')
param imagesContainerName string = 'felanmalan'

@description('Blob container for contracts and inspection protocols')
param docsContainerName string = 'avtal'

@description('Prefix used to generate a globally unique container registry name')
param acrNamePrefix string = 'acrnordvik'

@description('Name of the Container Apps environment')
param environmentName string = 'cae-nordvik-${environmentType}'

@description('Name of the container app (the portal)')
param appName string = 'ca-nordvik-portal-${environmentType}'

@description('Name of the notification job (reads the queue, calls Power Automate, sends urgent e-mail)')
param jobName string = 'caj-nordvik-notis-${environmentType}'

@description('Deploy the container app and job. Keep false on the first run (registry is still empty), true once the image is built.')
param deployApp bool = false

@description('Image name and tag inside the registry, e.g. portal:v1')
param imageName string = 'portal:v1'

@description('Optional Power Automate HTTP trigger URL that receives each ticket (creates the list item and notifies the manager). Leave empty to disable.')
@secure()
param flowUrl string = ''

@description('Demo sign-in with fake users instead of real authentication. Ignored (forced off) when environmentType is prod.')
param demoMode bool = false

@description('Client ID of the Entra app registration. Created by V41_setup_auth.sh. Leave empty until it exists (the portal is then locked, not open). There is no client secret: the app registration trusts the managed identity.')
param oidcClientId string = ''

@description('Shared mailbox that receives an e-mail for every report. Urgent reports also go to the property manager. Leave empty to send no mail for ordinary reports.')
param delatBrevladaMail string = ''

@allowed([
  'event'
  'schedule'
])
@description('How the notification job starts. event (default) = when the queue has messages. schedule = every minute. NOTE: the trigger type of an existing job cannot be changed; delete the job first (az containerapp job delete).')
param notisJobTrigger string = 'event'

@description('Extra recipients (comma separated) for urgent reports, besides the property manager')
param akutMailExtra string = ''

// ---- Cost allocation tags (applied to the resource group and every resource) ----
@description('Tag avdelning: which department pays for the platform')
param avdelning string = 'Fastighetsforvaltning'

@description('Tag kostnadsstalle')
param kostnadsstalle string = 'ej-angivet'

@description('Tag agare: who owns the environment')
param agare string = 'ej-angivet'

@description('Monthly budget for the resource group, in the currency of the Azure invoice')
param budgetAmount int = 2500

@description('Who gets budget alerts (80 % of actual cost, 100 % of forecast). Leave empty to skip the budget.')
param budgetContactEmails array = []

@description('First day of a month. If a redeploy later complains about the budget start date, pin this to a fixed value.')
param budgetStartDate string = utcNow('yyyy-MM-01')

var tags = {
  foretag: 'Nordvik'
  applikation: 'hyresgastportal'
  miljo: environmentType
  avdelning: avdelning
  kostnadsstalle: kostnadsstalle
  agare: agare
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module nordvik 'V41_resources.bicep' = {
  name: 'nordvik-resources'
  scope: rg
  params: {
    location: location
    tags: tags
    environmentType: environmentType
    callerObjectId: callerObjectId
    forvaltareGroupId: forvaltareGroupId
    ekonomiGroupId: ekonomiGroupId
    allowedIpAddress: allowedIpAddress
    vnetName: vnetName
    vnetAddressPrefix: vnetAddressPrefix
    subnetPeName: subnetPeName
    subnetPePrefix: subnetPePrefix
    subnetAcaName: subnetAcaName
    subnetAcaPrefix: subnetAcaPrefix
    storageAccountNamePrefix: storageAccountNamePrefix
    storageAccountSku: storageAccountSku
    imagesContainerName: imagesContainerName
    docsContainerName: docsContainerName
    acrNamePrefix: acrNamePrefix
    environmentName: environmentName
    appName: appName
    jobName: jobName
    deployApp: deployApp
    imageName: imageName
    flowUrl: flowUrl
    demoMode: demoMode && environmentType != 'prod'
    oidcClientId: oidcClientId
    akutMailExtra: akutMailExtra
    delatBrevladaMail: delatBrevladaMail
    notisJobTrigger: notisJobTrigger
    budgetAmount: budgetAmount
    budgetContactEmails: budgetContactEmails
    budgetStartDate: budgetStartDate
  }
}

output storageAccountName string = nordvik.outputs.storageAccountName
output acrName string = nordvik.outputs.acrName
output appUrl string = nordvik.outputs.appUrl
output oidcRedirectUri string = nordvik.outputs.oidcRedirectUri
output environmentDefaultDomain string = nordvik.outputs.environmentDefaultDomain
output mailSender string = nordvik.outputs.mailSender
```

#### __V41_main.biceparm__

```bicep

```

#### __V41_resources.bicep__

```bicep
@description('Azure region for all resources')
param location string

@description('Cost allocation tags, applied to every resource that supports tags')
param tags object

@allowed([
  'prod'
  'test'
  'demo'
])
param environmentType string

@description('Object ID of the identity that should get admin data access to the storage account (optional)')
param callerObjectId string = ''

@description('Entra group for property managers (optional)')
param forvaltareGroupId string = ''

@description('Entra group for finance (optional)')
param ekonomiGroupId string = ''

@description('Public IP address allowed through the storage account firewall')
param allowedIpAddress string = ''

param vnetName string
param vnetAddressPrefix string
param subnetPeName string
param subnetPePrefix string
param subnetAcaName string
param subnetAcaPrefix string
param storageAccountNamePrefix string
param storageAccountSku string
param imagesContainerName string
param docsContainerName string
param acrNamePrefix string
param environmentName string
param appName string
param jobName string
param deployApp bool
param imageName string

@secure()
@description('Optional Power Automate HTTP trigger URL (contains a signature, so it is stored as a Container App secret)')
param flowUrl string = ''

param demoMode bool = false
@description('Client ID of the Entra app registration. The app proves its identity with the managed identity (federated credential), so there is no client secret.')
param oidcClientId string = ''
param akutMailExtra string = ''
param delatBrevladaMail string = ''

@allowed([
  'event'
  'schedule'
])
@description('How the notification job starts: event = when the queue has messages (scales to zero), schedule = every minute and empties the queue (does not depend on the queue scaler reaching storage).')
param notisJobTrigger string = 'event'
param budgetAmount int
param budgetContactEmails array = []
param budgetStartDate string

@description('Port the app listens on inside the container')
param appPort int = 8000

@description('Storage queue holding notification work')
param notisQueueName string = 'notiser'

// Globally unique names derived from the resource group.
var storageAccountName = toLower('${storageAccountNamePrefix}${uniqueString(resourceGroup().id)}')
var acrName = toLower('${acrNamePrefix}${uniqueString(resourceGroup().id)}')

var tableNames = [
  'Arenden'
  'Anvandare'
  'Fastigheter'
]
var queueNames = [
  notisQueueName
  '${notisQueueName}-poison'
]
var storageSubresources = [
  'blob'
  'table'
  'queue'
]

// Production keeps two instances up during office hours (one can fail). Test and
// demo scale to zero and are only up when somebody uses them.
var isProd = environmentType == 'prod'
var officeHoursReplicas = isProd ? 2 : 0
var authEnabled = !demoMode && !empty(oidcClientId)

// Built-in role definitions.
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var storageBlobDataReaderRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
var storageTableDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3')
var storageQueueDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '974c5e8b-45b9-4653-ba55-5f855dd0fb88')
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var costManagementReaderRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '72fafb9e-0641-4937-9268-a91bfd8191a3')
// "Communication and Email Service Owner" - verify the GUID in your tenant with:
//   az role definition list --name "Communication and Email Service Owner" --query "[0].name"
var communicationEmailOwnerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '09976791-48a7-449e-bb21-39d1a415f350')

// Secrets / env vars that only exist when the feature is configured
// (Container Apps rejects secrets and env vars with an empty value).
var flowSecrets = empty(flowUrl) ? [] : [
  {
    name: 'flow-url'
    value: flowUrl
  }
]
// Built-in sign-in without a client secret: the app registration trusts the managed
// identity (federated credential). Container Apps wants the identity's CLIENT ID in
// a secret with exactly this name. It is an identifier, not a password.
var authSecrets = authEnabled ? [
  {
    name: 'override-use-mi-fic-assertion-client-id'
    value: identity.properties.clientId
  }
] : []
var appSecrets = concat(flowSecrets, authSecrets)
var flowEnv = empty(flowUrl) ? [] : [
  {
    name: 'FLOW_URL'
    secretRef: 'flow-url'
  }
]
var akutEnv = empty(akutMailExtra) ? [] : [
  {
    name: 'AKUT_MAIL_EXTRA'
    value: akutMailExtra
  }
]
var jobIsEvent = notisJobTrigger == 'event'
var sharedMailEnv = empty(delatBrevladaMail) ? [] : [
  {
    name: 'SHARED_MAILBOX'
    value: delatBrevladaMail
  }
]
var baseEnv = concat([
  {
    name: 'STORAGE_ACCOUNT'
    value: storageAccountName
  }
  {
    name: 'IMAGES_CONTAINER'
    value: imagesContainerName
  }
  {
    name: 'DOCS_CONTAINER'
    value: docsContainerName
  }
  {
    name: 'QUEUE_NAME'
    value: notisQueueName
  }
  {
    name: 'AUTH_MODE'
    value: demoMode ? 'demo' : 'easyauth'
  }
  {
    name: 'AZURE_CLIENT_ID'
    value: identity.properties.clientId
  }
  {
    name: 'ACS_ENDPOINT'
    value: 'https://${acs.properties.hostName}'
  }
  {
    name: 'MAIL_SENDER'
    value: 'DoNotReply@${emailDomain.properties.mailFromSenderDomain}'
  }
], akutEnv, sharedMailEnv, flowEnv)

// --------------------------------------------------------------------------
// Identity (image pull, storage access, e-mail sending)
// --------------------------------------------------------------------------
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${appName}'
  location: location
  tags: tags
}

// --------------------------------------------------------------------------
// Networking
// --------------------------------------------------------------------------
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
  }
}

resource subnetPe 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: subnetPeName
  properties: {
    addressPrefix: subnetPePrefix
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource subnetAca 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  parent: vnet
  name: subnetAcaName
  properties: {
    addressPrefix: subnetAcaPrefix
    delegations: [
      {
        name: 'aca-environments'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
  dependsOn: [subnetPe]
}

// --------------------------------------------------------------------------
// Storage account: blobs (photos, contracts), tables (tickets), queue (notifications)
// Reached only through private endpoints. No account keys, no public blobs.
// --------------------------------------------------------------------------
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: { name: storageAccountSku }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    accessTier: 'Hot'
    publicNetworkAccess: empty(allowedIpAddress) ? 'Disabled' : 'Enabled'
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      ipRules: empty(allowedIpAddress) ? [] : [
        {
          value: allowedIpAddress
          action: 'Allow'
        }
      ]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 14
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 14
    }
  }
}

resource imagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: imagesContainerName
}

resource docsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: docsContainerName
}

resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource tablesRes 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-01-01' = [for t in tableNames: {
  parent: tableService
  name: t
}]

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource queuesRes 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-01-01' = [for q in queueNames: {
  parent: queueService
  name: q
}]

// Contracts and protocols are rarely read after about three months, photos even
// less often later on: move both to the cool tier. (Archive is not worth it at
// this size and would add hours of waiting when someone does need a file.)
resource lifecycle 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  parent: storage
  name: 'default'
  properties: {
    policy: {
      rules: [
        {
          name: 'avtal-till-cool'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: ['blockBlob']
              prefixMatch: ['${docsContainerName}/']
            }
            actions: {
              baseBlob: {
                tierToCool: { daysAfterModificationGreaterThan: 90 }
              }
            }
          }
        }
        {
          name: 'bilder-till-cool'
          enabled: true
          type: 'Lifecycle'
          definition: {
            filters: {
              blobTypes: ['blockBlob']
              prefixMatch: ['${imagesContainerName}/']
            }
            actions: {
              baseBlob: {
                tierToCool: { daysAfterModificationGreaterThan: 180 }
              }
            }
          }
        }
      ]
    }
  }
  dependsOn: [
    imagesContainer
    docsContainer
  ]
}

// One private DNS zone + private endpoint per storage service.
resource privateDnsZones 'Microsoft.Network/privateDnsZones@2024-06-01' = [for sub in storageSubresources: {
  name: 'privatelink.${sub}.${environment().suffixes.storage}'
  location: 'global'
  tags: tags
}]

resource dnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = [for (sub, i) in storageSubresources: {
  parent: privateDnsZones[i]
  name: 'link-${vnetName}'
  location: 'global'
  tags: tags
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}]

@batchSize(1)
resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-11-01' = [for sub in storageSubresources: {
  name: 'pe-${storageAccountName}-${sub}'
  location: location
  tags: tags
  properties: {
    subnet: { id: subnetPe.id }
    privateLinkServiceConnections: [
      {
        name: 'conn-pe-${storageAccountName}-${sub}'
        properties: {
          privateLinkServiceId: storage.id
          groupIds: [sub]
        }
      }
    ]
  }
}]

resource peDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = [for (sub, i) in storageSubresources: {
  parent: privateEndpoints[i]
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: sub
        properties: { privateDnsZoneId: privateDnsZones[i].id }
      }
    ]
  }
}]

// --------------------------------------------------------------------------
// E-mail for urgent reports (Azure Communication Services, Azure-managed domain)
// --------------------------------------------------------------------------
resource emailService 'Microsoft.Communication/emailServices@2023-04-01' = {
  name: 'email-${appName}'
  location: 'global'
  tags: tags
  properties: {
    dataLocation: 'Europe'
  }
}

resource emailDomain 'Microsoft.Communication/emailServices/domains@2023-04-01' = {
  parent: emailService
  name: 'AzureManagedDomain'
  location: 'global'
  tags: tags
  properties: {
    domainManagement: 'AzureManaged'
  }
}

resource acs 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: 'acs-${appName}'
  location: 'global'
  tags: tags
  properties: {
    dataLocation: 'Europe'
    linkedDomains: [emailDomain.id]
  }
}

// --------------------------------------------------------------------------
// Container registry
// --------------------------------------------------------------------------
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  tags: tags
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
  }
}

// --------------------------------------------------------------------------
// Role assignments
// --------------------------------------------------------------------------
// The app: write photos, read contracts, read/write tickets and queue, send e-mail.
resource appImagesRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(imagesContainer.id, identity.id, storageBlobDataContributorRoleId)
  scope: imagesContainer
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appDocsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(docsContainer.id, identity.id, storageBlobDataReaderRoleId)
  scope: docsContainer
  properties: {
    roleDefinitionId: storageBlobDataReaderRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appTableRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, identity.id, storageTableDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: storageTableDataContributorRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appQueueRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, identity.id, storageQueueDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: storageQueueDataContributorRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appMailRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acs.id, identity.id, communicationEmailOwnerRoleId)
  scope: acs
  properties: {
    roleDefinitionId: communicationEmailOwnerRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appAcrRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, identity.id, acrPullRoleId)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// People. Tenants never get direct storage access: they only reach their own data
// through the portal. Finance gets cost visibility but no data access.
resource callerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(callerObjectId)) {
  name: guid(storage.id, callerObjectId, storageBlobDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: callerObjectId
    principalType: 'User'
  }
}

// The deployer also needs table access to load users and properties (V41_seed_users.sh).
resource callerTableRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(callerObjectId)) {
  name: guid(storage.id, callerObjectId, storageTableDataContributorRoleId)
  scope: storage
  properties: {
    roleDefinitionId: storageTableDataContributorRoleId
    principalId: callerObjectId
    principalType: 'User'
  }
}

resource forvaltareDocsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(forvaltareGroupId)) {
  name: guid(docsContainer.id, forvaltareGroupId, storageBlobDataContributorRoleId)
  scope: docsContainer
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleId
    principalId: forvaltareGroupId
    principalType: 'Group'
  }
}

resource ekonomiCostRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(ekonomiGroupId)) {
  name: guid(resourceGroup().id, ekonomiGroupId, costManagementReaderRoleId)
  properties: {
    roleDefinitionId: costManagementReaderRoleId
    principalId: ekonomiGroupId
    principalType: 'Group'
  }
}

// --------------------------------------------------------------------------
// Logs + Container Apps environment (inside the VNet)
// --------------------------------------------------------------------------
resource logs 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${appName}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

resource env 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logs.properties.customerId
        sharedKey: logs.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: subnetAca.id
      internal: false
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    zoneRedundant: isProd
  }
}

// --------------------------------------------------------------------------
// The portal (created in the second deployment, once the image exists)
//
// Scaling: no instance runs at night or at weekends. The cron rule keeps
// officeHoursReplicas instances up Mon-Fri 06:00-21:00 (covers the 07-09 and
// 17-20 peaks); the HTTP rule adds instances when many users arrive at once
// (month end, outages). With zone redundancy the instances sit in different zones.
// --------------------------------------------------------------------------
resource app 'Microsoft.App/containerApps@2024-03-01' = if (deployApp) {
  name: appName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: env.id
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: true
        targetPort: appPort
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: identity.id
        }
      ]
      secrets: appSecrets
    }
    template: {
      containers: [
        {
          name: 'portal'
          image: '${acr.properties.loginServer}/${imageName}'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: baseEnv
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: appPort
              }
              initialDelaySeconds: 10
              periodSeconds: 30
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: appPort
              }
              periodSeconds: 10
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        rules: [
          {
            name: 'http'
            http: {
              metadata: {
                concurrentRequests: '20'
              }
            }
          }
          {
            name: 'kontorstid'
            custom: {
              type: 'cron'
              metadata: {
                timezone: 'Europe/Stockholm'
                start: '0 6 * * 1-5'
                end: '0 21 * * 1-5'
                desiredReplicas: string(officeHoursReplicas)
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    appAcrRole
    appImagesRole
    appDocsRole
    appTableRole
    appQueueRole
    appMailRole
    peDnsZoneGroups
  ]
}

// Sign-in: Container Apps built-in authentication against your Entra ID tenant.
// Everything except /health requires a signed-in user. The app registration has a
// federated credential that trusts the managed identity, so no client secret exists.
// Only created once the app registration exists (V41_setup_auth.sh).
resource authConfig 'Microsoft.App/containerApps/authConfigs@2024-03-01' = if (deployApp && authEnabled) {
  parent: app
  name: 'current'
  properties: {
    platform: {
      enabled: true
    }
    globalValidation: {
      unauthenticatedClientAction: 'RedirectToLoginPage'
      redirectToProvider: 'azureactivedirectory'
      excludedPaths: ['/health']
    }
    identityProviders: {
      azureActiveDirectory: {
        enabled: true
        registration: {
          clientId: oidcClientId
          clientSecretSettingName: 'override-use-mi-fic-assertion-client-id'
          openIdIssuer: '${environment().authentication.loginEndpoint}${tenant().tenantId}/v2.0'
        }
      }
    }
  }
}

// --------------------------------------------------------------------------
// Notification job: starts when the queue has messages, exits when it is empty.
// Pays only for the seconds it runs.
// --------------------------------------------------------------------------
resource job 'Microsoft.App/jobs@2024-03-01' = if (deployApp) {
  name: jobName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    environmentId: env.id
    workloadProfileName: 'Consumption'
    configuration: {
      triggerType: jobIsEvent ? 'Event' : 'Schedule'
      replicaTimeout: 600
      replicaRetryLimit: 1
      scheduleTriggerConfig: jobIsEvent ? null : {
        cronExpression: '* * * * *'
        parallelism: 1
        replicaCompletionCount: 1
      }
      eventTriggerConfig: !jobIsEvent ? null : {
        parallelism: 1
        replicaCompletionCount: 1
        scale: {
          minExecutions: 0
          maxExecutions: 5
          pollingInterval: 10
          rules: [
            {
              name: 'notiskon'
              type: 'azure-queue'
              metadata: {
                accountName: storageAccountName
                queueName: notisQueueName
                queueLength: '5'
                cloud: 'AzurePublicCloud'
              }
              identity: identity.id
            }
          ]
        }
      }
      registries: [
        {
          server: acr.properties.loginServer
          identity: identity.id
        }
      ]
      secrets: flowSecrets
    }
    template: {
      containers: [
        {
          name: 'notis'
          image: '${acr.properties.loginServer}/${imageName}'
          command: ['python', 'V41_worker.py']
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: concat(baseEnv, [
            {
              name: 'PORTAL_URL'
              value: 'https://${app!.properties.configuration.ingress.fqdn}'
            }
          ])
        }
      ]
    }
  }
  dependsOn: [
    appAcrRole
    appImagesRole
    appTableRole
    appQueueRole
    appMailRole
    peDnsZoneGroups
  ]
}

// --------------------------------------------------------------------------
// Budget for the resource group (alerts only, nothing is shut down)
// --------------------------------------------------------------------------
resource budget 'Microsoft.Consumption/budgets@2023-05-01' = if (!empty(budgetContactEmails)) {
  name: 'budget-${resourceGroup().name}'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: budgetContactEmails
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: budgetContactEmails
      }
    }
  }
}

output storageAccountName string = storageAccountName
output acrName string = acr.name
output appUrl string = deployApp ? 'https://${app!.properties.configuration.ingress.fqdn}' : ''
output oidcRedirectUri string = 'https://${appName}.${env.properties.defaultDomain}/.auth/login/aad/callback'
output environmentDefaultDomain string = env.properties.defaultDomain
output mailSender string = 'DoNotReply@${emailDomain.properties.mailFromSenderDomain}'
```

#### __V41_requirements.txt__

```txt
flask>=3.0,<4
gunicorn>=22.0
azure-identity>=1.17
azure-storage-blob>=12.20
azure-storage-queue>=12.10
azure-data-tables>=12.5
azure-communication-email>=1.0
```

#### __V41_seed_users.sh__

```bash
#!/usr/bin/env bash
# Loads portal users and properties from CSV files into the storage tables.
#   ./V41_seed_users.sh V41_users.csv V41_properties.csv
#
# Needs: az login, the deploying identity must have "Storage Table Data Contributor"
# (granted by Bicep via callerObjectId), and allowedIpAddress must be set to your
# current public IP, because the storage account is otherwise not reachable.
set -euo pipefail

USERS_CSV="${1:-V41_users.csv}"
PROPS_CSV="${2:-V41_properties.csv}"
ENV_TYPE="${ENVIRONMENT_TYPE:-prod}"
RG="${RESOURCE_GROUP:-rg-nordvik-${ENV_TYPE}}"
SA=$(az storage account list -g "$RG" --query "[0].name" -o tsv)

# users: upn,roll,namn,fastighet,enhet,fastigheter   (fastigheter separated by ';')
tail -n +2 "$USERS_CSV" | tr -d '\r' | while IFS=, read -r upn roll namn fastighet enhet fastigheter || [ -n "$upn" ]; do
  [ -z "$upn" ] && continue
  az storage entity insert --account-name "$SA" --table-name Anvandare --auth-mode login \
    --if-exists replace --only-show-errors -o none --entity \
    PartitionKey=anvandare "RowKey=$(echo "$upn" | tr 'A-Z' 'a-z')" \
    "roll=$roll" "namn=$namn" "mail=$upn" "fastighet=$fastighet" "enhet=$enhet" \
    "fastigheter=${fastigheter//;/,}"
  echo "user: $upn ($roll)"
done

# properties: id,namn,forvaltarMail
tail -n +2 "$PROPS_CSV" | tr -d '\r' | while IFS=, read -r id namn mail || [ -n "$id" ]; do
  [ -z "$id" ] && continue
  az storage entity insert --account-name "$SA" --table-name Fastigheter --auth-mode login \
    --if-exists replace --only-show-errors -o none --entity \
    PartitionKey=fastighet "RowKey=$id" "namn=$namn" "forvaltarMail=$mail"
  echo "property: $id ($namn)"
done
```

#### __V41_setup_auth.sh__

```bash
#!/usr/bin/env bash
# Creates (or updates) the Entra ID app registration the portal signs users in with,
# WITHOUT a client secret: the registration trusts the portal's managed identity
# (federated identity credential). Prints the one value the Bicep deployment needs.
#
# Run after the FIRST deployment (infrastructure, DEPLOY_APP=false) and before the
# second one (DEPLOY_APP=true). The managed identity and the Container Apps
# environment exist by then, so redirect URI and trust can be set up already.
#
#   ENVIRONMENT_TYPE=prod ./V41_setup_auth.sh
#
# Needs: az login with permission to create app registrations in the tenant.
set -euo pipefail

ENV_TYPE="${ENVIRONMENT_TYPE:-prod}"
RG="${RESOURCE_GROUP:-rg-nordvik-${ENV_TYPE}}"
ENV_NAME="${ENV_NAME:-cae-nordvik-${ENV_TYPE}}"
APP_NAME="${APP_NAME:-ca-nordvik-portal-${ENV_TYPE}}"
IDENTITY_NAME="${IDENTITY_NAME:-id-${APP_NAME}}"
DISPLAY_NAME="Nordvik portal (${ENV_TYPE})"
FIC_NAME="nordvik-portal-managed-identity"

TENANT_ID=$(az account show --query tenantId -o tsv)
DOMAIN=$(az containerapp env show -g "$RG" -n "$ENV_NAME" --query properties.defaultDomain -o tsv)
MI_PRINCIPAL_ID=$(az identity show -g "$RG" -n "$IDENTITY_NAME" --query principalId -o tsv)
REDIRECT="https://${APP_NAME}.${DOMAIN}/.auth/login/aad/callback"

APP_ID=$(az ad app list --display-name "$DISPLAY_NAME" --query "[0].appId" -o tsv)
if [ -z "$APP_ID" ]; then
  APP_ID=$(az ad app create --display-name "$DISPLAY_NAME" \
    --sign-in-audience AzureADMyOrg \
    --web-redirect-uris "$REDIRECT" \
    --enable-id-token-issuance true \
    --query appId -o tsv)
else
  az ad app update --id "$APP_ID" --web-redirect-uris "$REDIRECT" --enable-id-token-issuance true >/dev/null
fi

# The enterprise application (service principal) is what lets users sign in.
if [ -z "$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)" ]; then
  az ad sp create --id "$APP_ID" >/dev/null
fi

# Trust the managed identity instead of a secret: issuer = this tenant, subject = the
# identity's principal (object) ID, audience = the fixed Entra token exchange value.
for existing in $(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$FIC_NAME'].id" -o tsv); do
  az ad app federated-credential delete --id "$APP_ID" --federated-credential-id "$existing" >/dev/null
done
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"$FIC_NAME\",
  \"issuer\": \"https://login.microsoftonline.com/${TENANT_ID}/v2.0\",
  \"subject\": \"${MI_PRINCIPAL_ID}\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" >/dev/null

echo "Redirect URI:  $REDIRECT" >&2
echo "Trusted identity: $IDENTITY_NAME ($MI_PRINCIPAL_ID)" >&2
echo "No client secret was created. Export this before the second deployment:" >&2
echo "export OIDC_CLIENT_ID='$APP_ID'"
```

#### __nordvik_maintenance_request.json__

```json
{
    "name": "759eab67-a180-42b4-8383-3365bced64b0",
    "id": "/providers/Microsoft.Flow/flows/759eab67-a180-42b4-8383-3365bced64b0",
    "type": "Microsoft.Flow/flows",
    "properties": {
        "apiId": "/providers/Microsoft.PowerApps/apis/shared_logicflows",
        "displayName": "nordvik_maintenance_request",
        "definition": {
            "metadata": {
                "workflowEntityId": null,
                "processAdvisorMetadata": null,
                "flowChargedByPaygo": null,
                "flowclientsuspensionreason": "None",
                "flowclientsuspensiontime": null,
                "flowclientsuspensionreasondetails": null,
                "creator": {
                    "id": "792176cc-4652-426c-8111-d8b5858fc81c",
                    "type": "User",
                    "tenantId": "70d725da-332c-4f51-adef-7b254380e7a9"
                },
                "provisioningMethod": "FromDefinition",
                "failureAlertSubscription": true,
                "clientLastModifiedTime": "2026-10-08T10:12:35.9015864Z",
                "lastModifiedBy": "792176cc-4652-426c-8111-d8b5858fc81c",
                "connectionKeySavedTimeKey": "2026-10-08T10:12:35.9015864Z",
                "creationSource": "Portal",
                "modifiedSources": "Portal"
            },
            "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
            "contentVersion": "1.0.0.0",
            "parameters": {
                "$authentication": {
                    "defaultValue": {},
                    "type": "SecureObject"
                },
                "$connections": {
                    "defaultValue": {},
                    "type": "Object"
                }
            },
            "triggers": {
                "manual": {
                    "metadata": {},
                    "type": "Request",
                    "kind": "Http",
                    "inputs": {
                        "schema": {},
                        "triggerAuthenticationType": "All"
                    }
                }
            },
            "actions": {
                "Condition": {
                    "actions": {
                        "Send_an_email_-_with_attachment_employee": {
                            "runAfter": {
                                "Add_attachment": [
                                    "Succeeded"
                                ]
                            },
                            "type": "OpenApiConnection",
                            "inputs": {
                                "parameters": {
                                    "emailMessage/To": "maintenance_requests@realtim03gmail.onmicrosoft.com",
                                    "emailMessage/Subject": "Ny felanmälan @{outputs('Create_item_-_with_attachment_')?['body/Title']}",
                                    "emailMessage/Body": "<p class=\"editor-paragraph\">Ny felanmälan har skapats.<br>Hantera den så fort som möjligt.<br><br><i><b><strong class=\"editor-text-bold editor-text-italic\">ID</strong></b></i>: @{outputs('Create_item_-_with_attachment_')?['body/Title']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Anmälare: </strong></b></i>@{body('Parse_JSON')?['mail']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Kategori:</strong></b></i> @{body('Parse_JSON')?['kategori']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Beskrivning:</strong></b></i> @{body('Parse_JSON')?['message']}</p><p class=\"editor-paragraph\"><i><b><strong class=\"editor-text-bold editor-text-italic\">Fastighet:</strong></b></i> @{body('Parse_JSON')?['fastighet']}</p><p class=\"editor-paragraph\"><i><b><strong class=\"editor-text-bold editor-text-italic\">Enhet:</strong></b></i> @{body('Parse_JSON')?['enhet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Akut:</strong></b></i> @{body('Parse_JSON')?['akut']}</p><br>",
                                    "emailMessage/Attachments": [
                                        {
                                            "Name": "@body('Parse_JSON')?['image']",
                                            "ContentBytes": "@base64ToBinary(body('Parse_JSON')?['image_base64'])"
                                        }
                                    ],
                                    "emailMessage/Importance": "Normal"
                                },
                                "host": {
                                    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",
                                    "connectionName": "shared_office365",
                                    "operationId": "SendEmailV2"
                                },
                                "authentication": "@parameters('$authentication')"
                            }
                        },
                        "Add_attachment": {
                            "runAfter": {
                                "Create_item_-_with_attachment_": [
                                    "Succeeded"
                                ]
                            },
                            "type": "OpenApiConnection",
                            "inputs": {
                                "parameters": {
                                    "dataset": "https://realtim03gmail.sharepoint.com/sites/NordvikFastigheterAB",
                                    "table": "aea896c0-81a0-42a8-b634-5aafaa500100",
                                    "itemId": "@outputs('Create_item_-_with_attachment_')?['body/ID']",
                                    "displayName": "@body('Parse_JSON')?['image']",
                                    "body": "@base64ToBinary(body('Parse_JSON')?['image_base64'])"
                                },
                                "host": {
                                    "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                                    "connectionName": "shared_sharepointonline",
                                    "operationId": "CreateAttachment"
                                },
                                "authentication": "@parameters('$authentication')"
                            }
                        },
                        "Create_item_-_with_attachment_": {
                            "type": "OpenApiConnection",
                            "inputs": {
                                "parameters": {
                                    "dataset": "https://realtim03gmail.sharepoint.com/sites/NordvikFastigheterAB",
                                    "table": "aea896c0-81a0-42a8-b634-5aafaa500100",
                                    "item/Title": "@body('Parse_JSON')?['id']",
                                    "item/Status/Value": "Ohanterad",
                                    "item/Kategori": "@body('Parse_JSON')?['kategori']",
                                    "item/Beskrivning": "@body('Parse_JSON')?['message']",
                                    "item/Fastighet": "@body('Parse_JSON')?['fastighet']",
                                    "item/Enhet": "@body('Parse_JSON')?['enhet']",
                                    "item/Hyresg_x00e4_st0": "@body('Parse_JSON')?['name']",
                                    "item/Hyresg_x00e4_st_x0028_e_x002d_po": "@body('Parse_JSON')?['mail']"
                                },
                                "host": {
                                    "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                                    "connectionName": "shared_sharepointonline",
                                    "operationId": "PostItem"
                                },
                                "authentication": "@parameters('$authentication')"
                            }
                        },
                        "Send_an_email_-_with_attachment_customer": {
                            "runAfter": {
                                "Send_an_email_-_with_attachment_employee": [
                                    "Succeeded"
                                ]
                            },
                            "type": "OpenApiConnection",
                            "inputs": {
                                "parameters": {
                                    "emailMessage/To": "@body('Parse_JSON')?['mail']",
                                    "emailMessage/Subject": "Felanmälan har skapats @{outputs('Create_item_-_with_attachment_')?['body/Title']}",
                                    "emailMessage/Body": "<p class=\"editor-paragraph\">Din felanmälan har skapats.</p><p class=\"editor-paragraph\"><br><i><b><strong class=\"editor-text-bold editor-text-italic\">ID:</strong></b></i> @{outputs('Create_item_-_with_attachment_')?['body/Title']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Anmälare: </strong></b></i>@{body('Parse_JSON')?['mail']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Kategori: </strong></b></i>@{body('Parse_JSON')?['kategori']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Beskrivning:</strong></b></i> @{body('Parse_JSON')?['message']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Fastighet:</strong></b></i> @{body('Parse_JSON')?['fastighet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Enhet:</strong></b></i> @{body('Parse_JSON')?['enhet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Akut:</strong></b></i> @{body('Parse_JSON')?['akut']}<br></p><br>",
                                    "emailMessage/Attachments": [
                                        {
                                            "Name": "@body('Parse_JSON')?['image']",
                                            "ContentBytes": "@base64ToBinary(body('Parse_JSON')?['image_base64'])"
                                        }
                                    ],
                                    "emailMessage/Importance": "Normal"
                                },
                                "host": {
                                    "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",
                                    "connectionName": "shared_office365",
                                    "operationId": "SendEmailV2"
                                },
                                "authentication": "@parameters('$authentication')"
                            }
                        }
                    },
                    "runAfter": {
                        "Parse_JSON": [
                            "Succeeded"
                        ]
                    },
                    "else": {
                        "actions": {
                            "Send_an_email_-_no_attachment_employee": {
                                "runAfter": {
                                    "Create_item_-_no_attachment": [
                                        "Succeeded"
                                    ]
                                },
                                "type": "OpenApiConnection",
                                "inputs": {
                                    "parameters": {
                                        "emailMessage/To": "maintenance_requests@realtim03gmail.onmicrosoft.com",
                                        "emailMessage/Subject": "Ny felanmälan @{outputs('Create_item_-_no_attachment')?['body/Title']}",
                                        "emailMessage/Body": "<p class=\"editor-paragraph\"><i><b><strong class=\"editor-text-bold editor-text-italic\">ID:</strong></b></i> @{outputs('Create_item_-_no_attachment')?['body/Title']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Anmälare:</strong></b></i> @{body('Parse_JSON')?['name']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Kategori:</strong></b></i> @{body('Parse_JSON')?['kategori']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Beskrivning:</strong></b></i> @{body('Parse_JSON')?['message']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Fastighet:</strong></b></i> @{body('Parse_JSON')?['fastighet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Enhet:</strong></b></i> @{body('Parse_JSON')?['enhet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Akut:</strong></b></i> @{body('Parse_JSON')?['akut']}</p>",
                                        "emailMessage/Importance": "Normal"
                                    },
                                    "host": {
                                        "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",
                                        "connectionName": "shared_office365",
                                        "operationId": "SendEmailV2"
                                    },
                                    "authentication": "@parameters('$authentication')"
                                }
                            },
                            "Create_item_-_no_attachment": {
                                "type": "OpenApiConnection",
                                "inputs": {
                                    "parameters": {
                                        "dataset": "https://realtim03gmail.sharepoint.com/sites/NordvikFastigheterAB",
                                        "table": "aea896c0-81a0-42a8-b634-5aafaa500100",
                                        "item/Title": "@body('Parse_JSON')?['id']",
                                        "item/Status/Value": "Ohanterad",
                                        "item/Kategori": "@body('Parse_JSON')?['kategori']",
                                        "item/Beskrivning": "@body('Parse_JSON')?['message']",
                                        "item/Fastighet": "@body('Parse_JSON')?['fastighet']",
                                        "item/Enhet": "@body('Parse_JSON')?['enhet']",
                                        "item/Hyresg_x00e4_st0": "@body('Parse_JSON')?['name']",
                                        "item/Hyresg_x00e4_st_x0028_e_x002d_po": "@body('Parse_JSON')?['mail']"
                                    },
                                    "host": {
                                        "apiId": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                                        "connectionName": "shared_sharepointonline",
                                        "operationId": "PostItem"
                                    },
                                    "authentication": "@parameters('$authentication')"
                                }
                            },
                            "Send_an_email_-_no_attachment_customer": {
                                "runAfter": {
                                    "Send_an_email_-_no_attachment_employee": [
                                        "Succeeded"
                                    ]
                                },
                                "type": "OpenApiConnection",
                                "inputs": {
                                    "parameters": {
                                        "emailMessage/To": "@body('Parse_JSON')?['mail']",
                                        "emailMessage/Subject": "Felanmälan har skapats @{outputs('Create_item_-_no_attachment')?['body/Title']}",
                                        "emailMessage/Body": "<p class=\"editor-paragraph\">Din felanmälan har skapats.<br><br><i><b><strong class=\"editor-text-bold editor-text-italic\">ID:</strong></b></i> @{outputs('Create_item_-_no_attachment')?['body/Title']}</p><p class=\"editor-paragraph\"><i><b><strong class=\"editor-text-bold editor-text-italic\">Anmälare:</strong></b></i> @{body('Parse_JSON')?['mail']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Kategori:</strong></b></i> @{body('Parse_JSON')?['kategori']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Beskrivning:</strong></b></i> @{body('Parse_JSON')?['message']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Fastighet:</strong></b></i> @{body('Parse_JSON')?['fastighet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Enhet</strong></b></i>: @{body('Parse_JSON')?['enhet']}<br><i><b><strong class=\"editor-text-bold editor-text-italic\">Akut:</strong></b></i> @{body('Parse_JSON')?['akut']}</p><br>",
                                        "emailMessage/Importance": "Normal"
                                    },
                                    "host": {
                                        "apiId": "/providers/Microsoft.PowerApps/apis/shared_office365",
                                        "connectionName": "shared_office365",
                                        "operationId": "SendEmailV2"
                                    },
                                    "authentication": "@parameters('$authentication')"
                                }
                            }
                        }
                    },
                    "expression": {
                        "and": [
                            {
                                "not": {
                                    "equals": [
                                        "@body('Parse_JSON')?['image_base64']",
                                        ""
                                    ]
                                }
                            }
                        ]
                    },
                    "type": "If"
                },
                "Parse_JSON": {
                    "runAfter": {},
                    "type": "ParseJson",
                    "inputs": {
                        "content": "@triggerBody()",
                        "schema": {
                            "type": "object",
                            "properties": {
                                "id": {},
                                "fastighet": {},
                                "enhet": {},
                                "name": {},
                                "mail": {},
                                "kategori": {},
                                "akut": {},
                                "rubrik": {},
                                "message": {},
                                "created": {},
                                "forvaltare_mail": {},
                                "image": {},
                                "image_content_type": {},
                                "image_base64": {}
                            }
                        }
                    }
                }
            },
            "outputs": {}
        },
        "connectionReferences": {
            "shared_office365": {
                "connectionName": "shared-office365-e6fba794-39c8-4e0d-bf7f-63475ebf813d",
                "source": "Embedded",
                "id": "/providers/Microsoft.PowerApps/apis/shared_office365",
                "tier": "NotSpecified",
                "apiName": "office365",
                "isProcessSimpleApiReferenceConversionAlreadyDone": false
            },
            "shared_sharepointonline": {
                "connectionName": "shared-sharepointonl-edc31114-848d-42c5-875e-d44bd34c7103",
                "source": "Embedded",
                "id": "/providers/Microsoft.PowerApps/apis/shared_sharepointonline",
                "tier": "NotSpecified",
                "apiName": "sharepointonline",
                "isProcessSimpleApiReferenceConversionAlreadyDone": false
            }
        },
        "flowFailureAlertSubscribed": false,
        "isManaged": false
    }
}
```

#### __V41_index.html__

```html
<!DOCTYPE html>
<html lang="sv">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Nordvik – Hyresgästportal</title>
<link rel="stylesheet" href="/static/V41_portal.css">
</head>
<body>
<header class="topbar">
  <div class="brand"><span class="plate">NORDVIK</span><span class="brand-sub">Hyresgästportal</span></div>
  <div class="who" id="who" hidden>
    <span id="who-name"></span>
    <span class="unit" id="who-unit" hidden></span>
    <a id="logout" href="/.auth/logout">Logga ut</a>
  </div>
</header>
<div class="demo-bar" id="demo-bar" hidden>
  Demomiljö, endast påhittad data. Visa som:
  <a href="/demo/byt?roll=hyresgast">Hyresgäst Elin</a>
  <a href="/demo/byt?roll=hyresgast2">Hyresgäst Omar</a>
  <a href="/demo/byt?roll=forvaltare">Förvaltare</a>
  <a href="/demo/byt?roll=ekonomi">Ekonomi</a>
</div>
<nav class="tabs" id="tabs" role="tablist" aria-label="Portalens delar"></nav>
<main id="view" tabindex="-1"><p class="muted">Laddar…</p></main>
<script src="/static/V41_portal.js"></script>
</body>
</html>
```

#### __V41_portal.css__

```css
:root {
  --ink: #12252d;
  --muted: #5a6f77;
  --fjord: #0f5a64;
  --fjord-dark: #0a434b;
  --mist: #e8eef0;
  --paper: #ffffff;
  --line: #c9d6da;
  --akut: #b3261e;
  --akut-bg: #fbe4e1;
  --ny: #1f4e8c;      --ny-bg: #e1ecfb;
  --pagar: #8a5200;   --pagar-bg: #fff0d1;
  --klar: #1d6b43;    --klar-bg: #dff3e7;
  --font: "Avenir Next", "Segoe UI", system-ui, -apple-system, "Helvetica Neue", Arial, sans-serif;
}
* { box-sizing: border-box; }
[hidden] { display: none !important; }
body { margin: 0; background: var(--mist); color: var(--ink); font: 16px/1.5 var(--font); }
a { color: var(--fjord); }
.muted { color: var(--muted); }
:focus-visible { outline: 3px solid #f2b705; outline-offset: 2px; }

.topbar { display: flex; flex-wrap: wrap; gap: 12px 24px; align-items: center; justify-content: space-between;
  background: var(--fjord-dark); color: #fff; padding: 14px clamp(16px, 4vw, 40px); }
.brand { display: flex; align-items: center; gap: 14px; }
.plate { border: 2px solid #fff; border-radius: 4px; padding: 2px 10px; font-weight: 800; letter-spacing: .14em; font-size: 1.15rem; }
.brand-sub { font-size: .95rem; opacity: .85; }
.who { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
.who a { color: #fff; }
.unit { background: #fff; color: var(--ink); border-radius: 4px; padding: 1px 10px; font-weight: 700; font-variant-numeric: tabular-nums; }

.demo-bar { background: #f2b705; color: #2b2100; padding: 6px clamp(16px, 4vw, 40px); font-size: .9rem; display: flex; flex-wrap: wrap; gap: 6px 16px; }
.demo-bar a { color: #2b2100; font-weight: 600; }

.tabs { display: flex; gap: 4px; padding: 0 clamp(16px, 4vw, 40px); background: var(--paper); border-bottom: 1px solid var(--line); overflow-x: auto; }
.tabs button { appearance: none; border: 0; background: none; font: inherit; font-weight: 600; color: var(--muted);
  padding: 14px 16px; cursor: pointer; border-bottom: 3px solid transparent; white-space: nowrap; }
.tabs button[aria-selected="true"] { color: var(--fjord-dark); border-bottom-color: var(--fjord); }

main { max-width: 920px; margin: 0 auto; padding: 28px clamp(16px, 4vw, 40px) 80px; }
main:focus { outline: none; }
h1 { font-size: 1.6rem; margin: 0 0 6px; letter-spacing: -.01em; }
h2 { font-size: 1.15rem; margin: 28px 0 10px; }
.lead { color: var(--muted); margin: 0 0 22px; max-width: 60ch; }

.notice { background: var(--akut-bg); border-left: 4px solid var(--akut); padding: 10px 14px; border-radius: 0 4px 4px 0; margin: 0 0 18px; }
.ok { background: var(--klar-bg); border-left: 4px solid var(--klar); padding: 10px 14px; border-radius: 0 4px 4px 0; margin: 0 0 18px; }

form.card, .ticket, .panel { background: var(--paper); border: 1px solid var(--line); border-radius: 6px; }
form.card { padding: 22px; display: grid; gap: 18px; }
label { display: grid; gap: 6px; font-weight: 600; }
label small { font-weight: 400; color: var(--muted); }
input, select, textarea { font: inherit; padding: 10px 12px; border: 1px solid #8fa3aa; border-radius: 4px; background: #fff; color: var(--ink); width: 100%; }
textarea { min-height: 130px; resize: vertical; }
button.primary { font: inherit; font-weight: 700; background: var(--fjord); color: #fff; border: 0; border-radius: 4px; padding: 12px 22px; cursor: pointer; justify-self: start; }
button.primary:hover { background: var(--fjord-dark); }
button.primary[disabled] { opacity: .6; cursor: wait; }
.preview { max-width: 220px; max-height: 160px; border-radius: 4px; border: 1px solid var(--line); }

.filters { display: flex; flex-wrap: wrap; gap: 10px 16px; margin-bottom: 16px; align-items: end; }
.filters label { min-width: 160px; }

.ticket { padding: 14px 18px; margin-bottom: 10px; }
.ticket.akut { border-left: 5px solid var(--akut); }
.ticket-head { display: flex; flex-wrap: wrap; gap: 6px 12px; align-items: baseline; justify-content: space-between; }
.ticket-title { font-weight: 700; }
.meta { color: var(--muted); font-size: .88rem; }
.chip { display: inline-block; border-radius: 99px; padding: 1px 10px; font-size: .82rem; font-weight: 700; }
.chip.ny { background: var(--ny-bg); color: var(--ny); }
.chip.pagar { background: var(--pagar-bg); color: var(--pagar); }
.chip.klar { background: var(--klar-bg); color: var(--klar); }
.chip.akut { background: var(--akut-bg); color: var(--akut); margin-left: 6px; }
.ticket p { margin: 8px 0 0; white-space: pre-wrap; max-width: 70ch; }
.ticket img { margin-top: 10px; max-width: min(100%, 320px); border-radius: 4px; border: 1px solid var(--line); display: block; }
.ticket .row { display: flex; gap: 10px; align-items: center; margin-top: 12px; flex-wrap: wrap; }
.ticket .row select { width: auto; }

table { width: 100%; border-collapse: collapse; background: var(--paper); border: 1px solid var(--line); border-radius: 6px; overflow: hidden; }
th, td { text-align: left; padding: 9px 14px; border-bottom: 1px solid var(--line); font-variant-numeric: tabular-nums; }
th { background: #f3f7f8; font-size: .9rem; }
td.num, th.num { text-align: right; }
.bar { height: 8px; background: var(--fjord); border-radius: 2px; min-width: 2px; }
.table-wrap { overflow-x: auto; }
ul.docs { list-style: none; padding: 0; margin: 0; }
ul.docs li { background: var(--paper); border: 1px solid var(--line); border-radius: 6px; padding: 10px 14px; margin-bottom: 8px; display: flex; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
@media (prefers-reduced-motion: no-preference) { button.primary { transition: background .15s; } }

.solution-box { background: var(--klar-bg); border-left: 4px solid var(--klar); padding: 8px 14px; border-radius: 0 4px 4px 0; margin-top: 12px; }
.solution-box p { margin: 4px 0 0; }
.manage { margin-top: 14px; display: grid; gap: 10px; }
.manage select { width: auto; margin-left: 6px; }
.manage textarea.solution { min-height: 84px; }
.manage .row { margin-top: 0; }
```

#### __V41_portal.js__

```js
// Nordvik portal front end. All text is inserted with textContent (never innerHTML)
// so ticket text from tenants cannot inject markup.
(function () {
  "use strict";
  var HEADERS = { "X-Requested-With": "nordvik-portal" };
  var STATUS = { ny: "Ny", pagar: "Pågår", klar: "Klar" };
  var ROLE = { hyresgast: "Hyresgäst", forvaltare: "Förvaltare", ekonomi: "Ekonomi" };
  var me = null;
  var view = document.getElementById("view");
  var tabsEl = document.getElementById("tabs");

  function h(tag, attrs) {
    var e = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === "text") e.textContent = attrs[k];
      else if (k === "class") e.className = attrs[k];
      else if (k.slice(0, 2) === "on") e.addEventListener(k.slice(2), attrs[k]);
      else e.setAttribute(k, attrs[k]);
    });
    for (var i = 2; i < arguments.length; i++) {
      var c = arguments[i];
      if (c == null) continue;
      e.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    }
    return e;
  }

  function api(path, opts) {
    opts = opts || {};
    opts.headers = Object.assign({}, HEADERS, opts.headers || {});
    opts.credentials = "same-origin";
    return fetch(path, opts).then(function (r) {
      if (r.status === 401) throw new Error("Du är inte inloggad eller sessionen har gått ut. Ladda om sidan för att logga in igen.");
      return r.json().catch(function () { return {}; }).then(function (body) {
        if (!r.ok) throw new Error(body.fel || "Något gick fel (" + r.status + ").");
        return body;
      });
    });
  }

  function fmtDate(iso) {
    if (!iso) return "";
    var d = new Date(iso);
    return d.toLocaleString("sv-SE", { dateStyle: "short", timeStyle: "short", timeZone: "Europe/Stockholm" });
  }
  function fmtMonth(m) { return m.slice(0, 4) + "-" + m.slice(4, 6); }
  function fmtSize(b) { return b > 1048576 ? (b / 1048576).toFixed(1) + " MB" : Math.max(1, Math.round(b / 1024)) + " kB"; }
  function clear(el) { while (el.firstChild) el.removeChild(el.firstChild); }
  function error(msg) { return h("p", { class: "notice", role: "alert", text: msg }); }

  // ---------- tickets ----------
  function ticketCard(t, manager) {
    var card = h("article", { class: "ticket" + (t.akut ? " akut" : "") });
    var statusChip = h("span", { class: "chip " + t.status, text: STATUS[t.status] || t.status });
    var chips = h("span", null, statusChip);
    if (t.akut) chips.appendChild(h("span", { class: "chip akut", text: "Akut" }));
    card.appendChild(h("div", { class: "ticket-head" },
      h("span", { class: "ticket-title", text: t.rubrik || t.kategoriNamn }), chips));
    var meta = t.kategoriNamn + " · " + fmtDate(t.skapad);
    if (manager) meta += " · " + t.fastighet + ", enhet " + t.enhet + " · " + t.hyresgastNamn;
    card.appendChild(h("div", { class: "meta", text: meta }));
    if (manager && t.hyresgastMail) card.appendChild(h("div", { class: "meta", text: t.hyresgastMail }));
    card.appendChild(h("p", { text: t.beskrivning }));
    if (t.harBild) card.appendChild(h("img", { src: "/api/arenden/" + encodeURIComponent(t.id) + "/bild", alt: "Bifogad bild", loading: "lazy" }));
    if (!manager && t.losning) {
      card.appendChild(h("div", { class: "solution-box" },
        h("strong", { text: "Lösning" + (t.losningTid ? " (" + fmtDate(t.losningTid) + ")" : "") }),
        h("p", { text: t.losning })));
    }
    if (manager) {
      var sel = h("select", { "aria-label": "Status" });
      Object.keys(STATUS).forEach(function (k) {
        var o = h("option", { value: k, text: STATUS[k] }); if (k === t.status) o.selected = true; sel.appendChild(o);
      });
      var ta = h("textarea", { class: "solution", maxlength: "4000", "aria-label": "Lösning",
        placeholder: "Lösning: beskriv vad som har gjorts. Hyresgästen ser texten." });
      ta.value = t.losning || "";
      var msg = h("span", { class: "meta", "aria-live": "polite" });
      var save = h("button", { class: "primary", type: "button", text: "Spara" });
      save.addEventListener("click", function () {
        if (sel.value === "klar" && !ta.value.trim() && !confirm("Markera som klar utan lösning?")) return;
        save.disabled = true; msg.textContent = "";
        api("/api/arenden/" + encodeURIComponent(t.id) + "/status", {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ status: sel.value, losning: ta.value })
        }).then(function (r) {
          statusChip.className = "chip " + r.status; statusChip.textContent = STATUS[r.status] || r.status;
          msg.textContent = "Sparat.";
        }).catch(function (e) { msg.textContent = e.message; })
          .then(function () { save.disabled = false; });
      });
      card.appendChild(h("div", { class: "manage" },
        h("label", { class: "meta" }, "Status ", sel), ta,
        h("div", { class: "row" }, save, msg)));
    }
    return card;
  }

  function showMyTickets(flash) {
    clear(view);
    view.appendChild(h("h1", { text: "Mina ärenden" }));
    view.appendChild(h("p", { class: "lead", text: "Här ser du dina felanmälningar och hur långt de har kommit." }));
    if (flash) view.appendChild(h("p", { class: "ok", role: "status", text: flash }));
    var list = h("div"); view.appendChild(list);
    list.appendChild(h("p", { class: "muted", text: "Laddar…" }));
    api("/api/arenden").then(function (items) {
      clear(list);
      if (!items.length) list.appendChild(h("p", { class: "muted", text: "Du har inga ärenden ännu." }));
      items.forEach(function (t) { list.appendChild(ticketCard(t, false)); });
    }).catch(function (e) { clear(list); list.appendChild(error(e.message)); });
  }

  function showReport() {
    clear(view);
    view.appendChild(h("h1", { text: "Felanmälan" }));
    view.appendChild(h("p", { class: "lead", text: "Beskriv felet så noga du kan. En bild gör det lättare för oss att komma rätt." }));
    view.appendChild(h("p", { class: "notice", text: "Vid brand eller personskada: ring 112. Akuta fel (till exempel vattenläcka eller strömavbrott) går direkt till din förvaltare." }));
    var sel = h("select", { id: "kategori", name: "kategori", required: "required" }, h("option", { value: "", text: "Välj…" }));
    var og1 = h("optgroup", { label: "Akuta fel" }), og2 = h("optgroup", { label: "Övriga fel" });
    me.kategorier.forEach(function (k) { (k.akut ? og1 : og2).appendChild(h("option", { value: k.id, text: k.namn })); });
    sel.appendChild(og1); sel.appendChild(og2);
    var file = h("input", { type: "file", id: "bild", name: "bild", accept: "image/jpeg,image/png,image/webp,image/heic" });
    var preview = h("img", { class: "preview", alt: "Förhandsvisning", hidden: "hidden" });
    file.addEventListener("change", function () {
      var f = file.files[0];
      if (f && f.size > 8 * 1048576) { file.value = ""; preview.hidden = true; alert("Bilden är för stor (max 8 MB)."); return; }
      if (f && f.type !== "image/heic") { preview.src = URL.createObjectURL(f); preview.hidden = false; } else { preview.hidden = true; }
    });
    var msg = h("div", { "aria-live": "polite" });
    var btn = h("button", { class: "primary", type: "submit", text: "Skicka felanmälan" });
    var form = h("form", { class: "card" },
      h("label", null, "Vad gäller det?", sel),
      h("label", null, "Rubrik ", h("small", { text: "Valfritt, en kort rad" }), h("input", { name: "rubrik", maxlength: "120" })),
      h("label", null, "Beskrivning", h("textarea", { name: "beskrivning", required: "required", maxlength: "4000" })),
      h("label", null, "Bild ", h("small", { text: "Valfritt, JPG, PNG eller HEIC, max 8 MB" }), file), preview,
      btn, msg);
    form.addEventListener("submit", function (ev) {
      ev.preventDefault(); btn.disabled = true; clear(msg);
      api("/api/arenden", { method: "POST", body: new FormData(form) }).then(function (r) {
        showMyTickets("Tack! Din felanmälan är skickad" + (r.akut ? " och har gått direkt till din förvaltare." : "."));
      }).catch(function (e) { btn.disabled = false; msg.appendChild(error(e.message)); });
    });
    view.appendChild(form);
  }

  // ---------- manager ----------
  function showManager() {
    clear(view);
    view.appendChild(h("h1", { text: "Ärenden" }));
    var prop = h("select", { id: "f-prop" }, h("option", { value: "", text: "Alla mina fastigheter" }));
    me.fastigheter.forEach(function (p) { prop.appendChild(h("option", { value: p.id, text: p.namn })); });
    var st = h("select", { id: "f-status" }, h("option", { value: "", text: "Alla" }));
    Object.keys(STATUS).forEach(function (k) { st.appendChild(h("option", { value: k, text: STATUS[k] })); });
    var list = h("div");
    function load() {
      clear(list); list.appendChild(h("p", { class: "muted", text: "Laddar…" }));
      var q = "?fastighet=" + encodeURIComponent(prop.value) + "&status=" + encodeURIComponent(st.value);
      api("/api/arenden" + q).then(function (items) {
        clear(list);
        items.sort(function (a, b) { return (b.akut && b.status !== "klar") - (a.akut && a.status !== "klar") || (a.id < b.id ? 1 : -1); });
        if (!items.length) list.appendChild(h("p", { class: "muted", text: "Inga ärenden." }));
        items.forEach(function (t) { list.appendChild(ticketCard(t, true)); });
      }).catch(function (e) { clear(list); list.appendChild(error(e.message)); });
    }
    prop.addEventListener("change", load); st.addEventListener("change", load);
    view.appendChild(h("div", { class: "filters" }, h("label", null, "Fastighet", prop), h("label", null, "Status", st)));
    view.appendChild(list); load();
  }

  // ---------- documents ----------
  function showDocs() {
    clear(view);
    view.appendChild(h("h1", { text: "Dokument" }));
    view.appendChild(h("p", { class: "lead", text: "Hyreskontrakt och besiktningsprotokoll." }));
    var box = h("div");
    var q = "";
    if (me.roll === "forvaltare") {
      var prop = h("select", null, h("option", { value: "", text: "Alla mina fastigheter" }));
      me.fastigheter.forEach(function (p) { prop.appendChild(h("option", { value: p.id, text: p.namn })); });
      var unit = h("input", { placeholder: "Enhet, t.ex. 1204" });
      var go = h("button", { class: "primary", type: "button", text: "Sök" });
      go.addEventListener("click", function () { load("?fastighet=" + encodeURIComponent(prop.value) + "&enhet=" + encodeURIComponent(unit.value.trim())); });
      view.appendChild(h("div", { class: "filters" }, h("label", null, "Fastighet", prop), h("label", null, "Enhet", unit), go));
    }
    view.appendChild(box);
    function load(query) {
      clear(box); box.appendChild(h("p", { class: "muted", text: "Laddar…" }));
      api("/api/dokument" + (query || q)).then(function (docs) {
        clear(box);
        if (!docs.length) { box.appendChild(h("p", { class: "muted", text: "Inga dokument hittades." })); return; }
        var ul = h("ul", { class: "docs" });
        docs.forEach(function (d) {
          ul.appendChild(h("li", null,
            h("a", { href: "/api/dokument/hamta?namn=" + encodeURIComponent(d.namn), text: d.visa }),
            h("span", { class: "meta", text: fmtSize(d.storlek) + " · " + fmtDate(d.andrad) })));
        });
        box.appendChild(ul);
      }).catch(function (e) { clear(box); box.appendChild(error(e.message)); });
    }
    if (me.roll === "hyresgast") load("");
  }

  // ---------- statistics ----------
  function showStats() {
    clear(view);
    view.appendChild(h("h1", { text: "Statistik" }));
    view.appendChild(h("p", { class: "lead", text: "Antal felanmälningar de senaste 12 månaderna. Inga personuppgifter visas." }));
    var box = h("div"); view.appendChild(box); box.appendChild(h("p", { class: "muted", text: "Laddar…" }));
    api("/api/statistik").then(function (s) {
      clear(box);
      function tbl(head, rows, withBar) {
        var max = Math.max.apply(null, rows.map(function (r) { return r[r.length - 1]; }).concat([1]));
        var t = h("table"), tr = h("tr");
        head.forEach(function (x, i) { tr.appendChild(h("th", { class: i ? "num" : "", text: x })); });
        if (withBar) tr.appendChild(h("th", { text: "" }));
        t.appendChild(h("thead", null, tr));
        var tb = h("tbody");
        rows.forEach(function (r) {
          var row = h("tr");
          r.forEach(function (v, i) { row.appendChild(h("td", { class: i ? "num" : "", text: String(v) })); });
          if (withBar) row.appendChild(h("td", { style: "width:30%" }, h("div", { class: "bar", style: "width:" + Math.round(100 * r[r.length - 1] / max) + "%" })));
          tb.appendChild(row);
        });
        t.appendChild(tb);
        return h("div", { class: "table-wrap" }, t);
      }
      box.appendChild(h("h2", { text: "Per fastighet" }));
      box.appendChild(tbl(["Fastighet", "Akuta", "Ej klara", "Totalt"], s.perFastighet.map(function (p) { return [p.namn, p.akuta, p.oppna, p.antal]; }), true));
      box.appendChild(h("h2", { text: "Per månad" }));
      box.appendChild(tbl(["Månad", "Antal"], s.perManad.map(function (m) { return [fmtMonth(m.manad), m.antal]; }), true));
      box.appendChild(h("h2", { text: "Per kategori" }));
      box.appendChild(tbl(["Kategori", "Antal"], s.perKategori.map(function (k) { return [k.kategori, k.antal]; }), true));
    }).catch(function (e) { clear(box); box.appendChild(error(e.message)); });
  }

  // ---------- shell ----------
  var TABS = {
    hyresgast: [["Mina ärenden", function () { showMyTickets(); }], ["Felanmäl", showReport], ["Dokument", showDocs]],
    forvaltare: [["Ärenden", showManager], ["Dokument", showDocs], ["Statistik", showStats]],
    ekonomi: [["Statistik", showStats]]
  };

  function buildTabs() {
    clear(tabsEl);
    var tabs = TABS[me.roll] || [];
    tabs.forEach(function (t, i) {
      var b = h("button", { type: "button", role: "tab", "aria-selected": i === 0 ? "true" : "false", text: t[0] });
      b.addEventListener("click", function () {
        Array.prototype.forEach.call(tabsEl.children, function (x) { x.setAttribute("aria-selected", "false"); });
        b.setAttribute("aria-selected", "true"); t[1]();
      });
      tabsEl.appendChild(b);
    });
    if (tabs.length) tabs[0][1]();
  }

  api("/api/me").then(function (m) {
    me = m;
    document.getElementById("who").hidden = false;
    document.getElementById("who-name").textContent = m.namn + " (" + (ROLE[m.roll] || m.roll) + ")";
    if (m.roll === "hyresgast" && m.enhet) {
      var u = document.getElementById("who-unit");
      var prop = m.fastigheter && m.fastigheter[0];
      u.textContent = (prop && prop.namn ? prop.namn + ", " : "") + "enhet " + m.enhet;
      u.hidden = false;
    }
    if (m.demo) { document.getElementById("demo-bar").hidden = false; document.getElementById("logout").hidden = true; }
    buildTabs();
  }).catch(function (e) { clear(view); view.appendChild(error(e.message)); });
})();
```

#### __V41_users.csv__

```csv

```

#### __V41_properties.csv__

```csv

```



