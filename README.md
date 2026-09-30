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

## Boutique Kawaii

Ramasse les coquillages sur les plages (ils repoussent au bout de 2 min),
puis va voir Yuki à la boutique : chapeaux, nourriture à effets (grosse tête,
turbo, hélium) et objets. Vise un choix du menu avec la main + gâchette.
La nourriture se mange en la portant à la bouche.

Yuki a une petite IA locale (`scripts/vendor_brain.gd`) : humeur, affection,
mémoire sauvegardée, marchandage, ragots, et elle remarque les échanges de
corps. Si on lui lance un objet dessus, ses prix augmentent.

## Donjon des Boulettes

À gauche du départ, Riku le punk garde l'entrée. Parle-lui (menu de choix),
réussis son "test de punk" et il te donne l'Épée Rock'n'Roll. Riku a sa
propre IA locale (`scripts/punk_brain.gd`) : respect, humeur, mémoire de tes
exploits au donjon.

Au casque : grip dans le vide = l'épée sort, et on frappe en faisant un vrai
geste (plus c'est rapide, plus ça fait mal). Sur PC : G puis clic.
Monstres : slimes, champignons grognons, chauves-souris et le Roi Gloubi
(il se divise). 5 coffres + un coffre doré qui s'ouvre après le boss et
donne l'Épée de feu. 5 cœurs : à 0, K.O. et retour devant Riku.

## Compilation

Tout se fait sur GitHub Actions (`.github/workflows/build.yml`) : Godot,
modèles d'export et plugin OpenXR Meta sont téléchargés à chaque build.
Les fichiers sortent dans la release `derniere-version`.

`cles/debug.keystore` est une clé de débogage (mot de passe `android`) :
elle reste la même d'un build à l'autre pour pouvoir mettre à jour l'appli
sur le casque sans la désinstaller.
