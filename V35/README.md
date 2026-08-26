# __IAM och identitet (Godkänt)__

__Repository:__ https://github.com/03timnor/Azure_MOV25

*Tim Noreliusson Lingestedt, 2026-08-20*

Denna veckans uppgift går ut på att hantera identiter och åtkomst (*__IAM__*) i en Azure miljö enligt "*__Least privilege__*" principen. Utöver detta skall vi förbereda en identitet för en applikation som skall användas senare i kursen.

### *__1. Skapa identiteter__*

Två användare och två säkerhetsgrupper har skapats i Entra via portalen.

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

### *__4. Dokumentation__*

### *__5. Verifiering__*

Ett konto som ör medlem i "*__azure_developer__*" har rollen "*__Reader__*" och skall endast kunna se "*__rg_novatrix_V35__*" och dess innehåll. Inte kunna ändra något.

Om ett konto som är medlem i "*__azure_developer__*" försöker stänga av VM i resursgrupp "*__rg_novatrix_V35__*" så får man följande meddelande:
![alt text](developer_restrictions.png)

Ett konto som är medlem i "*__azure_operations__*" har rollen "*__Contributor__*" och skall kunna se och ändra innehåll i  "*__rg_novatrix_V35__*". Men rollen "*__Contributor__*" ger inte rättigheter att tilldela roller i "*__Azure RBAC__*"

Ett konto som är medlem i "*__azure_operations__*" kan stänga av och starta VM i resursgrupp "*__rg_novatrix_V35__*"
![alt text](operations_stop_and_start_VM.png)

Försöker ett konto som är medlem i "*__azure_operations__*" tilldela roller i "*__Azure RBAC__*" så är den funktionen inaktiverad.
![alt text](operations_add_role_assignment_disabled.png)

