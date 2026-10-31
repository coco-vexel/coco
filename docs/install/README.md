# Coco combined plugin installers

Each host installer registers both Coco Word and Coco Excel in one run.

## WPS (Windows)

```powershell
.\wps-install.ps1 -BaseUrl "https://www.cooco.me"
```

## Microsoft Office (Windows)

```powershell
.\microsoft-install.ps1 -BaseUrl "https://www.cooco.me"
```

## ONLYOFFICE

The Desktop and Docker installers install the Word and Spreadsheet plugin configurations together.

### Desktop (Windows)

```powershell
.\onlyoffice-desktop-install.ps1 -BaseUrl "https://www.cooco.me"
```

Pass `-ApiBaseUrl "https://your-server.example/api/v1"` when the plugin should connect to a separately hosted Coco API.

### Desktop (macOS/Linux)

```bash
./onlyoffice-desktop-install.sh "https://www.cooco.me"
```

Set `COCO_DESKTOP_API_BASE_URL` to configure a separately hosted Coco API.

### Docker Document Server (PowerShell)

```powershell
.\onlyoffice-docker-install.ps1 -BaseUrl "https://www.cooco.me" -Container "onlyoffice-documentserver" -Apply
```

Without `-Apply`, the script only generates the two plugin packages locally.

### Docker Document Server (bash)

```bash
COCO_DOCKER_APPLY=1 ./onlyoffice-docker-install.sh "https://www.cooco.me" "onlyoffice-documentserver"
```
