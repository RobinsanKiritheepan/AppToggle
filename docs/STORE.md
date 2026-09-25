# Publier AppToggle sur le Microsoft Store

Guide pas à pas pour le Partner Center, avec les textes de la fiche prêts à copier-coller.

## 1. Compte et nom (une seule fois)

1. Aller sur <https://storedeveloper.microsoft.com>, se connecter avec son compte Microsoft, choisir le compte **individuel** (gratuit) et faire la vérification d'identité.
2. Dans le Partner Center : **Apps and games** → **New product** → **MSIX or PWA app** → réserver le nom **AppToggle**.
3. **Product management** → **Product identity** : recopier les 3 valeurs dans `msix\identity.json` :

```json
{
  "IdentityName": "valeur de Package/Identity/Name",
  "Publisher": "valeur de Package/Identity/Publisher (commence par CN=)",
  "PublisherDisplayName": "valeur de Package/Properties/PublisherDisplayName"
}
```

4. Fabriquer le paquet : `powershell -ExecutionPolicy Bypass -File build-store.ps1` → `dist\store\AppToggle-x.y.z.msix`.

## 2. La soumission (Start your submission)

### Pricing and availability
- **Markets** : tous.
- **Visibility** : pour un premier test, **Private audience** avec l'adresse de ton compte Microsoft et celle de ton ami ; ensuite **Public audience**.
- **Pricing** : **Free**.

### Properties
- **Category** : Utilities & tools.
- **Privacy policy URL** : `https://github.com/RobinsanKiritheepan/AppToggle/blob/main/PRIVACY.md`
- **Website** : `https://github.com/RobinsanKiritheepan/AppToggle`
- **Support contact info** : `https://github.com/RobinsanKiritheepan/AppToggle/issues`

### Age ratings
Remplir le questionnaire : catégorie utilitaire, aucune violence, aucun contenu généré ou partagé par les utilisateurs, pas d'achat, pas de localisation. Résultat attendu : 3+ / PEGI 3.

### Packages
Déposer `dist\store\AppToggle-x.y.z.msix`. Le Partner Center demande de justifier la capacité **runFullTrust** : coller le texte de la partie « Notes for certification » ci-dessous.

### Store listings
Ajouter deux langues : **Français (France)** et **English (United States)**. Captures : `docs\store\fr-*.png` pour le français, `docs\store\en-*.png` pour l'anglais (dans l'ordre 1 à 4).

### Submission options → Notes for certification
Coller le texte anglais de la partie « Notes for certification ».

Puis **Submit to the Store**. La certification prend en général de quelques heures à 3 jours ouvrés.

## 3. Textes de la fiche — Français

**Description**

> AppToggle ouvre, ramène ou réduit n'importe quelle application avec une seule touche.
>
> Appuie une fois : l'appli s'ouvre. Encore une fois : elle se réduit. Si elle est cachée derrière d'autres fenêtres, elle revient devant. Idéal pour garder ton assistant IA, tes notes ou ta musique toujours à portée de main, y compris avec la touche Copilot des claviers récents.
>
> AppToggle est un logiciel libre (licence MIT) : son code source est public sur GitHub.

**What's new in this version**

> Première version sur le Microsoft Store : signée par Microsoft, installation en un clic et mises à jour automatiques.

**Product features**

- Plusieurs raccourcis, chacun avec sa touche et son interrupteur
- Choix de l'appli sans rien taper : sélection parmi les fenêtres ouvertes
- Choix de la touche en l'appuyant, touche Copilot reconnue
- Interface moderne en français et en anglais, thème clair ou sombre
- Léger : moins de 2 Mo de mémoire en arrière-plan
- Aucune connexion Internet, aucune donnée collectée

**Short description**

> Ouvre, ramène ou réduis n'importe quelle appli avec une seule touche.

**Search terms**

raccourci clavier · basculer fenêtre · lanceur d'appli · réduire fenêtre · productivité · touche personnalisée · barre des tâches

**Copyright and trademark info**

> © 2026 Kiritheepan Robinsan

**Additional license terms**

> AppToggle est distribué sous licence MIT : https://github.com/RobinsanKiritheepan/AppToggle/blob/main/LICENSE — Il contient l'interpréteur AutoHotkey v2, sous licence GNU GPL v2 ; code source : https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.26

## 4. Store listing texts — English

**Description**

> AppToggle opens, brings back or minimizes any app with a single key.
>
> Press once: the app opens. Press again: it minimizes. If it's hidden behind other windows, it comes back to the front. Perfect for keeping your AI assistant, your notes or your music one key away, including with the Copilot key on recent keyboards.
>
> AppToggle is free software (MIT license): its source code is public on GitHub.

**What's new in this version**

> First release on the Microsoft Store: signed by Microsoft, one-click install and automatic updates.

**Product features**

- Several shortcuts, each with its own key and switch
- Pick an app without typing anything: choose from the open windows
- Set the key by pressing it, the Copilot key is supported
- Modern interface in English and French, light or dark theme
- Lightweight: less than 2 MB of memory in the background
- No internet connection, no data collection

**Short description**

> Open, bring back or minimize any app with a single key.

**Search terms**

keyboard shortcut · toggle window · app launcher · minimize window · productivity · custom hotkey · taskbar

**Copyright and trademark info**

> © 2026 Kiritheepan Robinsan

**Additional license terms**

> AppToggle is released under the MIT license: https://github.com/RobinsanKiritheepan/AppToggle/blob/main/LICENSE — It includes the AutoHotkey v2 interpreter, licensed under the GNU GPL v2; source code: https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.26

## 5. Notes for certification

> AppToggle is a small desktop utility that opens, brings to the front or minimizes an app with a global keyboard shortcut.
>
> runFullTrust is required because AppToggle is a classic Win32 desktop app (built with AutoHotkey) that registers global hotkeys and manages the windows of other apps. For some shortcuts (such as the Copilot key) it uses a low-level keyboard hook, only to detect the shortcuts chosen by the user: no keystroke is recorded, stored or transmitted. The app makes no network connection and collects no data (privacy policy: https://github.com/RobinsanKiritheepan/AppToggle/blob/main/PRIVACY.md).
>
> How to test: launch AppToggle; the settings window opens. Open Notepad, then in AppToggle click "Add", "Pick an open app" and select Notepad. Click "Change", press Ctrl+Alt+N, then "Save". Pressing Ctrl+Alt+N now minimizes Notepad, and pressing it again brings it back.
>
> The startup task is disabled by default; users can turn it on in Settings > Apps > Startup (the "Start with Windows" option in AppToggle opens that page).
