# Île Farfelue

Petit monde ouvert VR façon manga : une île, une maison visitable et trois
persos chibi (Kenji, Mochi, Taro) entre lesquels on échange de corps.

- Moteur : Godot 4.3 (rendu Compatibility, OpenXR)
- Cibles : Meta Quest 2/3 (`.apk`) et PC VR (`.exe`, SteamVR ou Quest Link)
- Sans casque, le `.exe` démarre en mode PC (clavier + souris)

## Commandes au casque

| Bouton | Action |
|---|---|
| Joystick gauche | marcher |
| Joystick droit | tourner par crans de 45° |
| Grip | attraper / lancer un objet |
| Viser un perso + gâchette | échange de corps |
| X | passer au perso suivant |
| B | vue 1re / 3e personne |
| A | sauter |
| Y | réplique du perso |

## Compilation

Tout se fait sur GitHub Actions (`.github/workflows/build.yml`) : Godot,
modèles d'export et plugin OpenXR Meta sont téléchargés à chaque build.
Les fichiers sortent dans la release `derniere-version`.

`cles/debug.keystore` est une clé de débogage (mot de passe `android`) :
elle reste la même d'un build à l'autre pour pouvoir mettre à jour l'appli
sur le casque sans la désinstaller.
