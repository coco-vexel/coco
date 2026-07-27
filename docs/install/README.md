# Coco plugin installers

WPS, Microsoft Office, and ONLYOFFICE Docker register remote entries. ONLYOFFICE Desktop keeps a tiny local entry shell because Desktop Editors does not reliably navigate plugin config.json.url to a remote page; the shell loads Coco UI assets from the release server.

## WPS

```powershell
powershell -ExecutionPolicy Bypass -File .\wps-install.ps1
```

```cmd
wps-install.cmd "<wps-entry-url>"
```

```bash
chmod +x ./wps-install.sh
./wps-install.sh
```

## ONLYOFFICE Desktop

```powershell
powershell -ExecutionPolicy Bypass -File .\onlyoffice-desktop-install.ps1
```

```cmd
onlyoffice-desktop-install.cmd "<release-base-url>"
```

```bash
chmod +x ./onlyoffice-desktop-install.sh
./onlyoffice-desktop-install.sh
```

## ONLYOFFICE Docker

```powershell
powershell -ExecutionPolicy Bypass -File .\onlyoffice-docker-install.ps1 -Container onlyoffice-documentserver
```

```cmd
onlyoffice-docker-install.cmd onlyoffice-documentserver "<release-base-url>"
```

```bash
COCO_RELEASE_BASE_URL="<release-base-url>" ./onlyoffice-docker-install.sh onlyoffice-documentserver
```

## Microsoft Office

```powershell
powershell -ExecutionPolicy Bypass -File .\microsoft-install.ps1
```

```cmd
microsoft-install.cmd "<manifest-url>"
```
