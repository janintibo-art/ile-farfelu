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

## L'enquête du mardi disparu (v7)

Une fois le carnet reçu du maire, six indices sont à trouver (boutons qui
apparaissent près des lieux, à viser comme un menu) :
boulangerie (registre des fournées), ponton (planche neuve de Gérard),
maison bleue (pinceau de Marguerite, traînée de peinture), auberge (livre de
comptes puis Malo : « E. Chardon »), Pétronille (roue verte), phare (papier
bleu glissé sous la porte).
Trois morceaux de roue (boulangerie, atelier, Pétronille) s'assemblent sur
l'établi de la mairie ; Éléonore Chardon (maison abandonnée de l'est, planches
levées quand on connaît son nom) donne la pièce centrale. Roue et pièce posées
sur l'horloge, « Remonter l'horloge » mène aux Mains du Dehors : quatre orbes
(aube, midi, crépuscule, nuit) à poser dans l'ordre du temps de gauche à
droite, le soleil et la lune servent d'indice. Réussir rend le mardi au village.
Le carnet d'enquête (sac > « Ouvrir le carnet ») se remplit tout seul.

## Le Phare de l'Envers et la fin du chapitre 1 (v8)

Une fois le mardi rendu au village et le papier bleu glissé sous la porte du
phare, « Entrer dans le phare » ouvre le premier donjon, sans ennemis, six
salles à la suite (la progression est sauvegardée) :
1. l'escalier impossible (retourner le tableau au soleil plus orange, tirer le levier) ;
2. les quatre fenêtres (une seule montre le village d'aujourd'hui) ;
3. la pièce penchée (guider la boule avec les planches jusqu'à la plaque verte) ;
4. la maquette (tourner trois sections jusqu'à aligner la bande jaune) ;
5. la chambre du gardien (la photo et le journal) ;
6. le sommet (la page : « RETOUR : NON PRÉVU »), puis « Sortir du phare ».
Éléonore commente. Ensuite : Éléonore s'installe à l'auberge, ma chambre (4) et
la chambre 7 s'ouvrent (deuxième photo sous le lit), « Dormir » termine le
chapitre 1. Quêtes secondaires : la porte sans maison (poignée de Barnabé),
le poisson rancunier et la planche (Gérard), la clé inconnue (Barnabé).
Le carnet a un onglet QUÊTES.

## Compilation

Tout se fait sur GitHub Actions (`.github/workflows/build.yml`) : Godot,
modèles d'export et plugin OpenXR Meta sont téléchargés à chaque build.
Les fichiers sortent dans la release `derniere-version`.

`cles/debug.keystore` est une clé de débogage (mot de passe `android`) :
elle reste la même d'un build à l'autre pour pouvoir mettre à jour l'appli
sur le casque sans la désinstaller.

## v10
- Écran de chargement par étapes visible dans le casque (le Quest restait noir pendant la construction du monde).
- Prologue : noir initial raccourci.

## v11
- Écran d'accueil : logo animé + 3 parties (nouvelle aventure / continuer / effacer avec confirmation). La partie 1 reprend l'ancienne sauvegarde.
- Visée à la manette (gâchette) en VR, souris ou touches 1-3 sur PC.

## v12
- Le manifeste Quest redéclare la compatibilité Quest 2 (désactivée en v5 : l'appli ne démarrait pas en VR sur Quest 2).

## v13
- Réglages graphiques revenus à ceux de la v1 (qui démarrait sur Quest 3) : MSAA 2x, foveation 3, pas d'ombres temps réel sur Android.

## v14
- Écran de diagnostic au démarrage (boot.tscn) : affiche l'état de la VR et la liste des scripts qui ne se chargent pas, avant de lancer le jeu.
