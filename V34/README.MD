# __Novatrix, driftsättning av webbserver i Azure (Godkänt)__

__Repository:__ https://github.com/03timnor/Azure_MOV25

_Tim Noreliusson Lingestedt, 2026-08-20_

### *__1. Resursgrupp och VM__*
Skapat Resource Group "rg_novatrix_V34" via Azure Portalen.

Skapat VM i Azure Portalen, VM finns i Resource Group "rg_novatrix_V34" och VM heter "VM-Novatrix-WEB"

VM har OS "Ubuntu Server LTS 24.04 - x64 Gen2"
Storlek på VM är "B2ats_v2".

Portar 80 (HTTP) och 22 (SSH) är öppna för inkommande trafik.

__*Resultat:*__

![alt text](VM_och_RG.png)

### *__2. SSH__*
SSH nyckel genererad, SSH nyckel nerladdad.
Behörighet gavs till nycklen via Terminal.

Loggade in på servern.

`icacls .\vm-novatrix-web_key.pem /inheritance:r`
 
`icacls .\vm-novatrix-web_key.pem /grant:r "$($env:USERNAME):R"`

`ssh -i .\vm-novatrix-web_key.pem azureuser@20.240.208.64`

__*Resultat:*__

![alt text](SSH_Inloggad.png)

### *__3. Serverkonfiguration__*

Uppdaterade operativsystemet.

`sudo apt update`

`sudo apt upgrade -y`

__*Resultat:*__

![alt text](Ubuntu_Uppdaterat.png)

### *__4. Nginx__*

Installerade Nginx.

`sudo apt install nginx`

`systemctl status nginx`

__*Resultat:*__

![alt text](Nginx_Installerad.png)

![alt text](Nginx_Status.png)

### *__4. Driftsättning__*

Konfigurerade webbsidan via html fil.

`cd /var/www/html/`

`sudo nano index.nginx-debian.html`

```
<!DOCTYPE html>
<html>
<head>
<title>Novatrix</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Novatrix</h1>
<form action="skicka.php" method="POST">
  <div>
    <label for="namn">Namn:</label><br>
    <input type="text" id="namn" name="namn" required>
  </div>

  <div>
    <label for="epost">E-post:</label><br>
    <input type="email" id="epost" name="epost" required>
  </div>

  <div>
    <label for="meddelande">Meddelande:</label><br>
    <textarea id="meddelande" name="meddelande" rows="5" cols="30" placeholder="Skriv ditt meddelande..." required></textarea>
  </div>

  <button type="submit">Skicka</button>
</form>

</body>
</html>
```

__*Resultat:*__

![alt text](Novatrix_Hemsida.png)

### *__5. Verifiering__*

Novatrix hemsida visas när man surfar till den lokala IP adressen.

Skärmbild på detta hittas i föregående steg (4. Driftsättning).