# __IAM och identitet (Godkänt)__

__Repository:__ https://github.com/03timnor/Azure_MOV25

*Tim Noreliusson Lingestedt, 2026-08-20*

Denna veckans uppgift går ut på att hantera identiter och åtkomst (*__IAM__*) i en *__Azure__* miljö enligt "*__Least privilege__*" principen. Utöver detta skall vi förbereda en identitet till en applikation som skall användas senare i kursen.

### *__1. Skapa identiteter__*

Två användare och två säkerhetsgrupper har skapats i *__Entra__* via portalen.

Ett "*__Developer__*" (utvecklare) konto och ett "*__Operations__*" (drift) konto har skapats.


En "*__azure_developer__*" (utvecklare) säkerhetsgrupp och en "*__azure_operations__*" (drift) säkerhetsgrupp har skapats.

"*__Developer__*" kontot är med i "*__azure_developer__*" (utvecklare) säkerhetsgruppen och "*__Operations__*" kontot är med i "*__azure_operations__*" säkerhetsgruppen. Tilldelingen gjordes manuellt via portalen.

*__Resultat:__*

![alt text](users.png)
![alt text](groups.png)
![alt text](groups_developer_users.png)
![alt text](groups_operations_users.png)

### *__2. Tilldela behörigheter (RBAC)__*

Behörigheter till resursgrupp "*__rg_novatrix_V35__*" styrs via  "*__Role-based access control (RBAC)__*" som hanteras via säkerhetsgrupperna som skapades tidigare.

Medlemmar i "*__azure_developer__*" har rollen "*__Reader__*" och 
medlemmar i "*__azure_operations__*" har rollen "*__Contributor__*". Tilldelningen gjordes via portalen. 

![alt text](role_assignments.png)
![alt text](birger_check_access_result.png)
![alt text](sven_check_access_result.png)

### *__3. Förbered en identitet för appen__*

Skapade en managed identity via portalen.

![alt text](managed_identity.png)

### *__4. Dokumentation__*

Lösningen bygger på "*__Least privilege__*" principen.
Användarkonton skall inte ha mer behörigheter än de som är nödvändiga för att utföra arbetsuppgifterna.

Birger och Sven använder specifika användarkonton när de arbetar med olika saker i *__Azure__* vilket leder till en minskad "*__Blast Radius__*" ifall ett konto skulle hackat / stulet.

### Säkerhetsgrupper som används till "*__Role-based access control (RBAC)__*" och anledningen av tilldelningen av specifika roller:

Säkerhetsgrupp "*__azure_developer__*" - Får rollen "*__Reader__*" för att de inte har behov av att utföra några ändringar i skarp miljö, men de behöver ha möjlighet att se den.

Säkerhetsgrupp "*__azure_operations__*" - Får rollen "*__Contributor__*" då de behöver kunna ändra i resursgruppen för att utföra sitt arbete. De behöver till exempel kunna starta om en VM i skarp miljö. De behöver dock inte tilldela roller i "*__Azure RBAC__*" då "*__IAM__*" avdelningen sköter detta arbete.

Säkerhetsgrupper används som standard för "*__Role-based access control (RBAC)__*" då det möjliggör för bättre skalbarhet, säkerhet och spårbarhet än att ge enskilda användarkonton roller eller behörigheter.

### *__5. Verifiering__*

Ett konto som är medlem i "*__azure_developer__*" har rollen "*__Reader__*" och skall endast kunna se "*__rg_novatrix_V35__*" och dess innehåll. Inte kunna ändra något.

Om ett konto som är medlem i "*__azure_developer__*" försöker stänga av VM i resursgrupp "*__rg_novatrix_V35__*" så får man följande meddelande:
![alt text](developer_restrictions.png)

Ett konto som är medlem i "*__azure_operations__*" har rollen "*__Contributor__*" och skall kunna se och ändra innehåll i  "*__rg_novatrix_V35__*". Men rollen "*__Contributor__*" ger inte rättigheter att tilldela roller i "*__Azure RBAC__*".

Ett konto som är medlem i "*__azure_operations__*" kan stänga av och starta VM i resursgrupp "*__rg_novatrix_V35__*"
![alt text](operations_stop_and_start_VM.png)

Försöker ett konto som är medlem i "*__azure_operations__*" tilldela roller i "*__Azure RBAC__*" så är den funktionen inaktiverad.
![alt text](operations_add_role_assignment_disabled.png)

# __IAM och identitet (Väl Godkänt)__

Uppgiften som skall lösas är att automatisera behörighetsuppsättningen med *__Azure CLI__* samt att designa en genomtänkt "*__Least privilege__*" modell med flera roller.

### *__5. Least privilege__*

