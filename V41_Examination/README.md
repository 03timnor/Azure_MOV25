# __Examination (Godkänt och Väl Godkänt)__

Repository: https://github.com/03timnor/Azure_MOV25

*Tim Noreliusson Lingestedt, 2026-10-05*

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

Flöde (*nordvik_ticket*):

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

MiljöN planerades i största del utifrån *Nordvik Fastigheter AB:s*  behov och önskemål. Sen behövde jag ha i åtankte vad jag realistiskt kunde hinna med på cirka 7 dagar. Det finns saker man hade kunnat utveckla om man hade mer tid, ett exempel kan vara en bättre lösning på hur avtal och dokument laddas upp till storage. I dagsläget måste man gå in i bloben och göra det, och det är det bara jag som kan göra (på grund av behörgheter). Man hade kunnat integrera detta i applikationen / webbsidan, men detta fick prioriteras bort då *Nordvik Fastigheter AB:s* uttryckta behov och önskemål gick före och tog upp den tid som fanns tillgänglig.

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

### *__10. Kod__*