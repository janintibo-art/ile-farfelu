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
| Menu (manette gauche) ou clic du joystick gauche | ouvrir le sac |

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

## Le slip de Pierre (plage, ponton de Luc-Ael)

Pierre a perdu son slip dans la mer. Luc-Ael prête sa canne à pêche :
grip pour la sortir, gâchette pour lancer vers l'eau, puis gâchette (ou un
coup sec vers le haut) quand le bouchon plonge et que la manette vibre.
Si on repêche le slip, la canne est à nous ; en le rendant à Pierre,
15 coquillages. On pêche aussi sardines, poissons arc-en-ciel, poissons
dorés, bottes et algues. Luc-Ael rachète les poissons.
Sur PC : G pour sortir la canne, clic pour lancer et ferrer.

## Sac (inventaire)

Bouton menu de la manette gauche (touche I sur PC). On y équipe la canne ou
l'épée, on mange la nourriture, on sort un objet dans la main, ou on range
ce qu'on tient.

## Prologue : la Plage des Bagages Perdus

On se réveille sur la plage, entouré de valises, avec une photo dans une
valise (grip pour la prendre, retournez-la), Pico enfermé dans une
bouteille (débouchez-la) et un pont cassé : trois planches manquent.
Les planches se trouvent sur la plage. Le château visible au loin est pour
plus tard. Sur PC, la photo tenue dans la main tourne toute seule.

## Graphismes Quest 3

Rendu cel-shading 3 niveaux avec contours, eau animée, ciel manga, herbe qui
bouge au vent, ombres temps réel, MSAA 4x, 90 Hz, rendu fovéal. Le jeu ne
cible plus que la Quest 3 (la Quest 2 n'est plus déclarée).

## Port-Biscornu (v6)

Au nord de l'île, après le pont : un village avec une place (fontaine,
étals de marché déjà rangés), un port et deux pontons, un phare fermé,
l'**auberge du Dernier Verre** (Malo), la **mairie** (guichets 1, 2 et 3,
horloge de la semaine, bureau du maire Théodore Patatras), la boutique de
**Barnabé** (poignée de porte, bouton, corde, miroir fêlé, clé sans serrure)
et la petite **Nina** qui se promène sur la place.

Début de l'histoire : Malo demande de s'enregistrer à la mairie ; le maire
a perdu son registre et inscrit le joueur au dos d'un menu ; avec sa
permission on regarde le calendrier (LUNDI puis MERCREDI), il donne le
carnet d'enquête et la quête « Le mardi qui avait disparu » démarre.
Malo remet alors la clé de la chambre 4. Tous parlent avec leur mini IA
hors ligne (humeur, mémoire, phrases qui ne se répètent pas).
Sur PC : approche, puis touches 1 à 6 ou clic sur le menu.

## Compilation

Tout se fait sur GitHub Actions (`.github/workflows/build.yml`) : Godot,
modèles d'export et plugin OpenXR Meta sont téléchargés à chaque build.
Les fichiers sortent dans la release `derniere-version`.

`cles/debug.keystore` est une clé de débogage (mot de passe `android`) :
elle reste la même d'un build à l'autre pour pouvoir mettre à jour l'appli
sur le casque sans la désinstaller.
