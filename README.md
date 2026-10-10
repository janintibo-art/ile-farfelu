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

## v15
- Le diagnostic affiche aussi les messages d erreur du moteur (journal de la session) dans le casque.

## v16
- Export PC : ajoute IleFarfelue.console.exe (fenêtre noire qui affiche les erreurs) à côté du .exe.

## v17
- PC : OpenXR désactivé par défaut sous Windows (le jeu plantait quand le runtime Oculus était actif sans casque branché). Lancer_en_VR.bat démarre le jeu en PC VR.

## v18
- Archive complète du projet (il manquait des fichiers dans le dépôt, ex. rod.gd).

## v19
- Rotation VR douce par défaut (clic du stick droit pour revenir aux à-coups de 45°).
- Le tablier du pont est solide dès le début : plus de chute dans le ruisseau.

## v20 — Chapitre 2, partie 1 : Virevolte
- Éléonore (« Partons pour Virevolte ») emmène le joueur dans la forêt de Virevolte (zone y=500, retour par le panneau au sud).
- Deux familles, un pont, deux actes : Odile Aubépine, Gaspard Ronceval, Mirette, Maître Anselme (notaire).
- Indices : les deux actes (même écriture, même encre violette), la plaque sous le pont, le tiroir du greffe.
- Le pont change de couleur et de nom selon le côté d'où on le regarde ; les panneaux de la forêt changent d'avis quand on s'approche.
- Fin : « Réunir les deux familles » → le pont est à tous (+20 coquillages). La Maison de Travers (donjon) est visible au nord, fermée : à suivre.

## v21 — Chapitre 2, partie 2 : la Maison de Travers
- On entre par la maison penchée au nord de Virevolte (« Entrer dans la maison »). Donjon en 5 salles (zone y=600).
- Salle 1 : trois portes qui mentent (une seule inscription dit vrai). Salle 2 : pièces coulissantes à remettre à leur place. Salle 3 : porte minuscule vers une salle géante, clé géante à prendre. Salle 4 : trois fenêtres, regarder ce qui est dessiné et non écrit. Salle 5 : le Mot Juste.
- Confrontation avec Maître Anselme (le Mot Juste détecte mensonge / vérité), puis dire trois fois « Mon père existe. » : fin du chapitre 2 (+30 coquillages, objet « Le Mot Juste »).
- Progression sauvegardée (tr_room, tr_key, mot_juste, ch2_done). Sortie possible dans chaque salle.

## v22 — Chapitre 3, partie 1 : Brumelune
- Après le chapitre 2, Éléonore propose « Partons pour Brumelune » (village sur pilotis, zone y=700). Elle propose aussi « Rentrons à Port-Biscornu » depuis Virevolte et Brumelune.
- Souvenirs échangés, en bulles colorées : le boulanger Honoré (bulle de marin), Marin Ouessant (bulle de chevreaux), la chèvre Capitaine (bulle de navigation), une bulle de pâtes oubliée dans le four, et une bulle dorée portée par Léo.
- On prend une bulle à son porteur (dialogue ou bouton), on lit son contenu (bouton « Réécouter ma bulle »), puis on l'offre à son vrai propriétaire.
- Choix moral : la bulle dorée est la mémoire d'Aristide, le mari qu'Hortense a oublié. La rendre entière, la laisser à Léo, ou la partager (si on a écouté la brume : « Garde-moi une place à table, Hortense »).
- Trois voix dans la brume (dont un indice sur Basile Plume et Pico). Fin : la trappe de l'Archive s'éveille mais ne s'ouvre qu'à marée basse (v23 : l'Archive Engloutie).
- Menu des sauvegardes : étiquettes pour les chapitres 2 et 3.

## v23
- Vue 3e personne en VR : le perso apparaît maintenant en face du regard (avant : placé selon l'orientation de la pièce, donc parfois sur le côté).

## v24 — Chapitre 3, partie 2 : l'Archive Engloutie
- À Brumelune, demander à Marin Ouessant (une fois ses souvenirs de marin rendus) : « La trappe attend la marée basse. » La trappe au nord s'ouvre alors sur l'Archive (zone y=800).
- Salle 1 : régler le niveau de l'eau dans l'ordre de la plaque (bas, haut, moyen). Salle 2 : assembler les souvenirs qui parlent de la même chose. Salle 3 : la bulle-clé monte avec l'eau, mais pas trop haut. Salle 4 : écouter trois souvenirs du Grand Cartographe. Salle 5 : première rencontre (indirecte) avec Basile Plume, trois questions, ses réponses dépendent du choix fait pour Hortense.
- Fin du chapitre 3 : +40 coquillages. Teaser : Belloche.

## v25 — APK téléphone
- Le workflow produit maintenant un 3e fichier : `IleFarfelue_Telephone.apk` (package `com.janintibo.ilefarfelue.phone`, s'installe à côté de la version Quest).
- Commandes tactiles : joystick à gauche, glisser à droite pour regarder (un tap = action), viseur « + » au centre, gros bouton ACTION (rôle du clic souris), SAUT, VUE, PERSO, SAC, ÉCHANGE, RÉPLIQUE, MANGER, OUTIL.
- Activé uniquement par la fonction « phone » du preset Telephone (ou `-- --touch` sur PC pour tester). OpenXR désactivé et MSAA coupé sur cette version.
- Si l'export téléphone échoue, la version Quest et la version PC sont quand même publiées.

## v26
- Pont de la plage : les murs invisibles du ruisseau bouchaient aussi l'entrée du pont (on restait bloqué après la réparation). L'entrée est maintenant dégagée, et des rampes invisibles évitent de buter sur le bord du tablier. Testé en marchant d'une rive à l'autre.
- Si toutes les planches utiles sont perdues (jetées de l'autre côté, tombées à l'eau), de nouvelles s'échouent sur la plage après 15 secondes.

## v27
- Le workflow n'envoie plus d'artefacts (ils comptaient dans le quota de stockage Actions de 0,5 Go, déjà à 90 %) : les fichiers sont publiés uniquement dans la release « derniere-version », qui ne compte pas dans ce quota. Une étape supprime aussi les anciens artefacts à chaque compilation.

## v28 — Chapitre 4, partie 1 : Belloche, « la ville qui perdit sa musique »
- Avec Éléonore (après le chapitre 3) : « Partons pour Belloche. » Plateau avec clocher, quatre cadres de cloches décoratives, atelier de flûtes. Rien ne sonne, les habitants ont perdu la voix : ils miment et Pico « traduit ».
- Trois énigmes sonores (sons fabriqués en direct, spatialisés : on entend d'où ils viennent) :
  1. Petit Tam : trois tambours (bois, métal, pierre). « Écouter Tam », puis refaire le même rythme.
  2. Maître Sifflot : un oiseau jaune caché. « Écouter le vent » : le trille vient du bon arbre. « Regarder dans l'arbre ».
  3. Dame Carillon : cinq cloches de couleur. « Écouter l'air », puis rejouer la mélodie.
- Chaque énigme rend 5 coquillages. Les trois résolues : « Tirer la corde » de la Grosse Cloche → toutes les cloches sonnent, les habitants parlent, +30 coquillages.
- Les pots « CONSERVÉ — Château des Versions Officielles » : les sons étaient mis en conserve (même main que le pont et les souvenirs).
- La porte sous le clocher vibre : la Cathédrale des Échos arrive en v29.
- Nouveaux fichiers : `village_k.gd`, `brain_k.gd`, `bells.gd`. Menu de sauvegarde, journal et dialogues d'Éléonore mis à jour.

## v29 — Chapitre 4, partie 2 : la Cathédrale des Échos
- À Belloche, après la Grosse Cloche : « Descendre sous le clocher ». Cinq salles (zone y=1000, aucun ennemi). Chaque salle redit un son déjà entendu et chaque note a son écho :
  1. Nef des cloches : l'écho rejoue la mélodie de Belloche, il faut la rejouer.
  2. Voûte aux oiseaux : le trille sort de trois perchoirs, l'un après l'autre (on entend d'où il vient). Rejouer l'ordre.
  3. Galerie des tambours : deux coups pressés puis un long silence, avec le grand tambour.
  4. Chœur des échos : trois phrases (cloches, oiseaux, tambours) à remettre dans l'ordre de la plaque (matin, midi, soir) : on obtient la Grande Mélodie.
  5. Porte du Registre : la Grande Mélodie est trop juste, la porte reste fermée. « Laisser Pico chanter » : sa fausse note l'ouvre. Pico découvre qu'il est inscrit au Grand Registre (« voix de secours »).
- Fin du chapitre 4 : Deuxième Page, +50 coquillages. Teaser : Hautes-Miettes et Observatoire Brisé.
- Nouveau fichier : `cathedral.gd`. Menu de sauvegarde, journal et dialogues (Éléonore, Dame Carillon) mis à jour. Version 0.29.

## v30 — Chapitre 5, partie 1 : les Hautes-Miettes, « l'homme qui volait du temps »
- Avec Éléonore (après le chapitre 4) : « Partons pour les Hautes-Miettes. » Village de montagne autour d'une horloge astronomique géante, zone y=1100.
- Boucle locale : toutes les 36 secondes, la place rejoue la même scène de cinq minutes (le facteur laisse tomber une lettre, un homme gris attrape une minute dans un pot). La grande pendule revient en arrière. À chaque répétition, un détail différent s'affiche (lettre, pot, badge) : « Noter ce détail » (au milieu de la place). Il faut les trois.
- Quatre cadrans désaccordés sur la place : « Avancer l'heure d'un cran » jusqu'à trois heures pile (l'heure du conseil, écrite sur la tour ; Madame Quart et le maire l'expliquent).
- Quand les trois détails sont notés et les cadrans accordés, la boucle suivante s'arrête sur le voleur : Hubert Sablier, Receveur des Minutes du Château. Dialogue avec Éléonore et Pico, clé des Rouages, +30 coquillages.
- Indices : lettre « à Mlle L. Plume », pot « CONSERVÉ — destination Château » (la fille de Basile, plus tard).
- Les habitants (Gaspard Minuit, Madame Quart, Petit Zéphyr) changent de réplique selon le nombre de boucles vécues.
- La porte au pied de la tour est le futur accès à l'Observatoire Brisé (v31).
- Nouveaux fichiers : `village_h.gd`, `brain_h.gd` (+ son « tick » dans `bells.gd`). Version 0.30.

## v31 — Chapitre 5, partie 2 : l'Observatoire Brisé + la grande révélation
- Aux Hautes-Miettes, après le Receveur : « Monter à l'Observatoire » (porte au pied de la tour). Cinq salles (zone y=1200, aucun ennemi). Le principe : « Tourner l'aiguille » change l'époque d'un élément du décor.
  1. Porte brisée : AVANT, la porte intacte porte une inscription (« Au soleil, l'étoile, puis la lune ») ; MAINTENANT, il ne reste que des débris et une serrure à symboles (Soleil, Lune, Étoile).
  2. Serre : GRAINE / ARBUSTE / ARBRE. Au stade ARBRE, une branche forme un pont au-dessus du vide (une aiguille de chaque côté). Tomber ramène au début de la salle.
  3. Salle des ombres : deux statues, chacune avec sa propre aiguille (MIDI / SOIR / MATIN). L'ombre du Berger doit couvrir la dalle ouest, celle de la Dame la dalle est.
  4. Pendule : il tique à chaque passage au milieu. L'arrêter trois fois de suite pile au milieu.
  5. Grand cadran : choisir « Il y a 27 ans » puis « Regarder ». (« Il y a 300 ans » et « Hier » montrent de courtes scènes.) On assiste à Armand Chardon et au jeune Basile : le Registre ne décrit pas l'île, c'est l'île qui existe tant qu'on la raconte ; Basile, par peur de l'oubli, tente de la figer ; les pages s'envolent ; Armand court les rattraper et envoie Pico se cacher dans une bouteille.
- Révélation : Pico est la dernière page vivante du Grand Registre. Fin du chapitre 5 : +60 coquillages. Teaser : le bal des Versions Officielles (invitation de Basile).
- Nouveau fichier : `observatory.gd`. Version 0.31.

## v32 — Refonte du son
- Nouveaux sons plus riches et plus propres (32 kHz) : vraie cloche à partielles, marimba, flûte avec souffle et vibrato, corde pincée, nappe douce…
- Quatre « bus » audio : Musique, Ambiance, Effets, Voix, avec un limiteur sur la sortie (fini la saturation).
- Réverbération qui change selon le lieu (sèche dehors, longue dans la Cathédrale, les Archives, l'Observatoire, le donjon).
- Ambiances en boucle sans coupure (mer, vent, salle, grillons), fabriquées en arrière-plan : moins de calcul pendant le jeu (important sur Quest). Mélange différent dans chaque lieu, plus des petits bruits au hasard (oiseaux, gouttes, grenouilles, tic-tac).
- Musique douce générée toute seule, une couleur par lieu. Silence à Belloche avant l'énigme et dans la Cathédrale pour ne pas couvrir les mélodies.
- Bruits de pas selon le sol (sable, herbe, pierre, bois, neige), saut, atterrissage, plouf, coup d'épée.
- Petites voix « bip-bip » quand les personnages parlent (une hauteur par personnage), sons de boutons, pièce gagnée, étincelles.
- Nouveaux fichiers : sfx.gd, music.gd ; réécrits : bells.gd, ambience.gd.

## v33 — Amélioration du graphisme
- Couleurs : exposition réglée pour que les verts ne « brûlent » plus (fini le vert fluo), herbe et touffes plus naturelles.
- Sol de l'île : grandes taches claires/sombres et léger grain, au lieu d'un aplat uniforme.
- Nuages avec un dessous bleuté (du volume).
- Fausses ombres rondes et douces sous les persos et les palmiers (Quest et téléphone, où les vraies ombres sont coupées).
- Particules d'ambiance autour du joueur : pollen, pétales (Virevolte), lucioles (Brumelune), feuilles (Belloche), neige (Hautes-Miettes), poussière lumineuse (donjon, Archives, Cathédrale, Observatoire).
- Étalonnage des couleurs qui change doucement selon le lieu (plus vif à Virevolte, plus froid aux Hautes-Miettes, plus sombre aux Archives…).
- Nouveaux fichiers : visuals.gd, shaders/blob.gdshader.
