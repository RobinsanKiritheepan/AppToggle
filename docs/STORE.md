# Publier AppToggle sur le Microsoft Store

Guide pas à pas pour le Partner Center, avec les textes de la fiche prêts à copier-coller.

## 1. Compte et nom (une seule fois)

1. Aller sur <https://storedeveloper.microsoft.com>, se connecter avec son compte Microsoft, choisir le compte **individuel** (gratuit) et faire la vérification d'identité.
2. Dans le Partner Center : **Applications et jeux** → **Nouveau produit** → **Application MSIX ou PWA** (surtout pas « EXE ou MSI », qui demande de signer soi-même) → réserver le nom **AppToggle**.
3. **Gestion des produits** → **Identité du produit** : recopier les 3 valeurs dans `msix\identity.json` (elles ne sont pas secrètes : elles sont écrites dans chaque paquet publié) :

```json
{
  "IdentityName": "valeur de Package/Identity/Name",
  "Publisher": "valeur de Package/Identity/Publisher (commence par CN=)",
  "PublisherDisplayName": "valeur de Package/Properties/PublisherDisplayName"
}
```

4. Fabriquer le paquet : `powershell -ExecutionPolicy Bypass -File build-store.ps1` → `dist\store\AppToggle-x.y.z.msix`.

## 2. La soumission (Démarrer la soumission)

Ce qui a été fait pour la première version (25 septembre 2026). L'interface est en français, les noms anglais sont entre parenthèses.

### Tarification et disponibilité (Pricing and availability)
- **Marchés** : tous les marchés internationaux.
- **Visibilité** : **Public non privé**, « disponible et détectable dans le Microsoft Store ». Une nouvelle appli n'est presque pas trouvée tant qu'on ne partage pas son lien. Pour tester avant tout le monde, choisir plutôt **Public privé** avec les adresses des comptes Microsoft des testeurs.
- **Planifier** : sortie dès que possible.
- **Prix de base** : EUR – France, **0** (gratuit).

### Propriétés (Properties)
- **Catégorie** : Utilitaires + outils, sans sous-catégorie ; catégorie secondaire : Productivité.
- **Politique de confidentialité** : « Oui, mon produit utilise des informations personnelles » (à cause du crochet clavier), avec l'URL `https://github.com/RobinsanKiritheepan/AppToggle/blob/main/PRIVACY.md`
- **Site Web** : `https://github.com/RobinsanKiritheepan/AppToggle`
- **Infos de contact du support technique** : `https://github.com/RobinsanKiritheepan/AppToggle/issues`. Pas de téléphone ni d'adresse : ces champs sont affichés publiquement.
- **Configuration requise** : Clavier, en matériel minimum. Laisser décochées les déclarations « IA générative » et « testé pour l'accessibilité ».

### Évaluation de l'âge (Age ratings)
Questionnaire IARC : **Tous les autres types d'applications**, puis **Non** à toutes les questions. Résultat : 3+ (PEGI 3, ESRB Tout le monde). Cliquer sur **Continuer** sur la page de résumé.

### Packages
Déposer `dist\store\AppToggle-x.y.z.msix`, famille **Windows 10/11 Desktop** seulement. L'avertissement jaune sur **runFullTrust** est normal : la justification se donne dans les options de soumission.

### Descriptions dans le Store (Store listings)
Les langues **Français (France)** et **Anglais (États-Unis)** apparaissent toutes seules (ce sont celles du paquet). Pour chacune : les textes des parties 3 ou 4, et les captures `docs\store\fr-*.png` ou `docs\store\en-*.png` (partie **Bureau**, dans l'ordre 1 à 4). Les mots clés se valident un par un avec Entrée. Logos, bandes-annonces et images Xbox : facultatifs, laissés vides.

### Options de soumission (Submission options)
- Publication : dès que la soumission passe la certification.
- **Fonctionnalités restreintes** : coller le texte « runFullTrust » de la partie 5 (champ limité à **500 caractères**).
- Le texte « How to test… » va dans **Infos supplémentaires → Informations supplémentaires sur les tests**.

Puis **Soumettre pour certification**. Sur la liste de la soumission, « Tarification et disponibilité » et « Classification par âge » n'affichent jamais « Terminé », même complètes : ce n'est pas bloquant. La certification prend de quelques heures à 3 jours ouvrés.

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

> © 2026 Kiritheepan Robinsan. Contient AutoHotkey (licence GNU GPL v2). Copilot est une marque du groupe Microsoft.

**Additional license terms**

> AppToggle est distribué sous licence MIT : https://github.com/RobinsanKiritheepan/AppToggle/blob/main/LICENSE — Il contient l'interpréteur AutoHotkey v2, sous licence GNU GPL v2 ; son code source est joint au paquet (AutoHotkey-v2.0.26-source.zip) et disponible ici : https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.26

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

> © 2026 Kiritheepan Robinsan. Includes AutoHotkey (GNU GPL v2 license). Copilot is a trademark of the Microsoft group of companies.

**Additional license terms**

> AppToggle is released under the MIT license: https://github.com/RobinsanKiritheepan/AppToggle/blob/main/LICENSE — It includes the AutoHotkey v2 interpreter, licensed under the GNU GPL v2; its source code is included in the package (AutoHotkey-v2.0.26-source.zip) and available at: https://github.com/AutoHotkey/AutoHotkey/tree/v2.0.26

## 5. Notes for certification

**runFullTrust** (champ limité à 500 caractères, celui-ci en fait 416) :

> AppToggle is a Win32 desktop utility (built with AutoHotkey) that opens, brings to the front or minimizes an app with a global keyboard shortcut. runFullTrust is needed to register global hotkeys and manage the windows of other apps. A low-level keyboard hook is used only to detect the shortcuts chosen by the user: no keystroke is recorded, stored or sent. The app makes no network connection and collects no data.

**Informations supplémentaires sur les tests** (471 caractères) :

> How to test: launch AppToggle; the settings window opens. Open Notepad, then in AppToggle click "Add", "Pick an open app" and select Notepad. Click "Change", press Ctrl+Alt+N, then "Save". Pressing Ctrl+Alt+N now brings Notepad to the front, pressing it again minimizes it, and pressing it once more brings it back.
>
> The startup task is disabled by default; users can turn it on in Settings > Apps > Startup (the "Start with Windows" option in AppToggle opens that page).
