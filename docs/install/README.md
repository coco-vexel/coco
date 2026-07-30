# Coco plugin installers

WPS and Microsoft Office load remote entries from the release server. ONLYOFFICE Docs / Document Server can use either remote pluginsData or the local sdkjs-plugins installer. ONLYOFFICE Desktop keeps a tiny local entry shell because Desktop Editors does not reliably navigate plugin config.json.url to a remote page; the shell loads Coco UI assets from the release server.

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
powershell -ExecutionPolicy Bypass -File .\onlyoffice-desktop-install.ps1 -BaseUrl "<release-base-url>"
```

```cmd
onlyoffice-desktop-install.cmd "<release-base-url>"
```

```bash
chmod +x ./onlyoffice-desktop-install.sh
COCO_RELEASE_BASE_URL="<release-base-url>" ./onlyoffice-desktop-install.sh
```

## ONLYOFFICE Docker - remote pluginsData

```js
editorConfig: {
  plugins: {
    pluginsData: [
      "<release-base-url>/onlyoffice/config.json"
    ],
    autostart: [
      "asc.{8D9B5A2C-1F3E-4C7A-9B0D-2E6F1A4C8B30}"
    ]
  }
}
```

Add this to the application that creates the DocsAPI.DocEditor config. The Document Server container does not need files copied into sdkjs-plugins for the remote loading mode.

## ONLYOFFICE Docker - local sdkjs-plugins

```powershell
powershell -ExecutionPolicy Bypass -File .\onlyoffice-docker-install.ps1 -Container onlyoffice-documentserver
```

```cmd
onlyoffice-docker-install.cmd onlyoffice-documentserver "<release-base-url>"
```

```bash
COCO_RELEASE_BASE_URL="<release-base-url>" ./onlyoffice-docker-install.sh onlyoffice-documentserver
```

Use this mode when the integration application cannot inject editorConfig.plugins.pluginsData. The script creates a local plugin shell under the Document Server sdkjs-plugins directory.

## Microsoft Office

```powershell
powershell -ExecutionPolicy Bypass -File .\microsoft-install.ps1
```

```cmd
microsoft-install.cmd "<manifest-url>"
```
