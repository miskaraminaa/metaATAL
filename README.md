# Résumé automatique extractif par algorithme génétique

**Projet de métaheuristiques — Master Informatique, parcours ATAL — Nantes Université (2026–2027)**

## 1. Objectif

Le projet consiste à produire automatiquement un **résumé extractif** d'un document français : sélectionner un sous-ensemble de phrases du texte original, sans générer de nouvelles phrases. Le problème est abordé comme une **optimisation combinatoire** à l'aide d'un **algorithme génétique (AG)** implémenté en **Julia**.

L'objectif est de rechercher un compromis entre :

- **Représentativité** : le résumé doit couvrir le contenu du document.
- **Concision** : le nombre de phrases retenues doit rester proche de la longueur cible.
- **Non-redondance** : éviter de sélectionner plusieurs phrases qui apportent essentiellement la même information.

## 2. Formulation du problème

Pour un texte de `n` phrases, une solution est un chromosome binaire :

`x = (x₁, x₂, …, xₙ)`, où `xᵢ = 1` si la phrase `i` est sélectionnée, `0` sinon.

L'espace de recherche contient `2ⁿ` sous-ensembles possibles, y compris le résumé vide (considéré comme invalide par la fonction d'évaluation). Cette croissance exponentielle motive l'utilisation d'une métaheuristique pour les textes longs.

### Fonction objectif

Les phrases et le document sont représentés par des vecteurs **TF-IDF**. La qualité d'un chromosome est évaluée par :

```text
fitness(x) = α × similarité(x, document)
           − |k/n − γ|
           − β × redondance(x)
```

avec :

- `k` : nombre de phrases sélectionnées ; `n` : nombre total de phrases ;
- `similarité` : similarité cosinus entre le vecteur moyen des phrases retenues et le vecteur du document ;
- `redondance` : moyenne des similarités cosinus entre les paires de phrases retenues ;
- `α` : poids de la représentativité ;
- `β` : poids de la pénalisation de redondance ;
- `γ` : proportion cible de phrases conservées.

**Important :** une fitness plus grande n'est comparable directement que si les coefficients de la fonction objectif et le prétraitement sont identiques. Lorsqu'on modifie `α`, `β` ou `γ`, il faut également comparer les indicateurs indépendants (similarité, redondance et proportion conservée).

## 3. Prétraitement linguistique

1. Lecture du fichier texte UTF-8.
2. Segmentation en phrases.
3. Normalisation des termes (notamment casse et ponctuation).
4. Suppression facultative des mots vides (*stopwords*) français.
5. Construction de la représentation TF-IDF des phrases.
6. Construction du vecteur représentatif du document.

Le prétraitement est réalisé avec **TextAnalysis.jl** et les fonctions du fichier `src/preprocessing.jl`.

## 4. Algorithme génétique

### Représentation et population initiale

Chaque individu est un vecteur binaire de longueur `n`. Une population de solutions candidates est créée aléatoirement, puis évaluée avec la fonction de fitness.

### Sélection et élitisme

Les individus sont classés par fitness. Les meilleurs sont conservés d'une génération à l'autre (**élitisme**) et servent de vivier pour la sélection des parents. Dans cette implémentation, `elite_ratio` influence donc **à la fois le nombre d'individus conservés et le groupe de parents disponibles**.

### Croisement

Deux opérateurs sont comparés :

- **`onepoint`** : séparation des chromosomes à une position de coupure, puis échange des segments ;
- **`uniform`** : choix, pour chaque position, du gène provenant de l'un ou l'autre parent.

### Mutation

Avec la probabilité `mutation_rate`, **un bit choisi aléatoirement** est inversé dans l'enfant. Il ne s'agit pas d'une mutation indépendante de chaque bit.

### Arrêt

L'exécution est limitée par `generations`. Un **arrêt anticipé** peut interrompre l'évolution lorsque la meilleure fitness ne s'améliore pas suffisamment pendant `patience` générations, selon le seuil `min_delta`.

<<<<<<< HEAD
### Pseudo-code

```text
Initialiser une population P
Évaluer tous les individus
Mémoriser la meilleure solution
Pour chaque génération :
    Trier P par fitness
    Copier les meilleurs individus (élitisme)
    Tant que la nouvelle population est incomplète :
        Sélectionner deux parents parmi les élites
        Effectuer un croisement
        Appliquer éventuellement la mutation
        Ajouter l'enfant à la nouvelle population
    Évaluer la nouvelle population
    Actualiser la meilleure solution et l'historique
    Arrêter si le critère de stagnation est atteint
Retourner le meilleur chromosome, sa fitness et l'historique
```

=======
### Architecture fonctionnelle

Le projet sépare le traitement linguistique, l'optimisation et l'analyse expérimentale :

```mermaid
flowchart TD
    A[Texte français dans data/] --> B[preprocessing.jl : segmentation, nettoyage, TF-IDF]
    B --> C[Matrice TF-IDF des phrases et vecteur du document]
    C --> D[genetic_algorithm.jl : recherche de chromosomes]
    F[fitness.jl : similarité, longueur, redondance] <--> D
    G[config.toml : paramètres NLP, fitness, AG, convergence] --> B
    G --> D
    D --> H[Meilleur chromosome, score, historique]
    H --> I[results.jl : résumé et résultats]
    C --> J[exhaustive_search.jl : optimum sur petits textes]
    C --> K[experiments.jl : répétitions et variations des paramètres]
    K --> L[CSV et graphiques dans output/]
```

### Organigramme de l'algorithme génétique

```mermaid
flowchart TD
    A([Début]) --> B[Initialiser P chromosomes binaires]
    B --> C[Évaluer la fitness de chaque individu]
    C --> D[Classer par fitness décroissante]
    D --> E[Mettre à jour meilleur global et stagnation]
    E --> F[Enregistrer le meilleur score dans history]
    F --> G{Stagnation >= patience et arrêt activé ?}
    G -- Oui --> Z([Retourner meilleur chromosome, score, historique])
    G -- Non --> H[Copier les E meilleures solutions : élites]
    H --> I{Nouvelle population complète ?}
    I -- Non --> J[Tirer deux parents parmi les élites]
    J --> K[Croisement uniforme ou à un point]
    K --> L{Mutation déclenchée ?}
    L -- Oui --> M[Inverser un bit aléatoire]
    L -- Non --> N[Ajouter l'enfant]
    M --> N
    N --> I
    I -- Oui --> O[Remplacer la population]
    O --> P{Nombre maximal de générations atteint ?}
    P -- Non --> C
    P -- Oui --> Z
```

**Remarque :** l'évaluation intervient **au début de chaque génération**, et le test de stagnation **avant** la reproduction. Le meilleur global est sauvegardé indépendamment de la population courante. Une nouvelle population créée après la dernière évaluation n'est pas évaluée si la limite de générations est atteinte.

### Pseudo-code fidèle à l'implémentation

```text
Initialiser P chromosomes binaires aléatoires
best_score ← -∞ ; best_individual ← chromosome nul
history ← [] ; stagnation ← 0
E ← min(P, max(2, floor(elite_ratio × P)))

POUR generation = 1 à generations :
    scores ← fitness(individu) pour chaque individu de la population
    order ← indices triés par fitness décroissante
    current_score ← score du meilleur individu courant

    SI current_score > best_score :
        SI current_score > best_score + min_delta :
            stagnation ← 0
        SINON :
            stagnation ← stagnation + 1
        best_score ← current_score
        best_individual ← copie du meilleur individu courant
    SINON :
        stagnation ← stagnation + 1

    Ajouter best_score à history
    SI arrêt activé ET stagnation >= patience :
        ARRÊTER LA BOUCLE

    elites ← copies des E meilleurs individus
    nouvelle_population ← copie de la liste des élites
    TANT QUE taille(nouvelle_population) < P :
        p1, p2 ← tirages aléatoires parmi les élites
        enfant ← croisement(p1, p2)
        SI tirage aléatoire < mutation_rate :
            inverser un seul bit de l'enfant
        Ajouter enfant à nouvelle_population
    population ← nouvelle_population

RETOURNER best_individual, best_score, history
```

### Exemple d'une génération

Pour un texte de cinq phrases, le chromosome `10110` conserve les phrases 1, 3 et 4. Avec `pop_size = 6` et `elite_ratio = 0.5`, les **trois meilleurs chromosomes** sont copiés sans modification. Les trois places restantes sont remplies par des enfants issus de croisements entre élites, suivis éventuellement d'une mutation. Chaque enfant sera évalué au début de la génération suivante.

### Exploration, exploitation et convergence

- **Exploitation :** l'élitisme conserve les meilleurs chromosomes et les utilise comme parents. Le nombre d'élites est `min(pop_size, max(2, floor(elite_ratio * pop_size)))`.
- **Exploration :** le croisement recombine les gènes des parents ; la mutation peut ajouter ou retirer une phrase en inversant un bit.
- **Stagnation :** `current_score` est le meilleur score de la génération ; `best_score` est le meilleur depuis le début. Une amélioration strictement supérieure à `min_delta` remet le compteur à zéro. Une petite amélioration positive met à jour `best_score` mais augmente quand même la stagnation.
- **Arrêt anticipé :** si `convergence.enabled = true`, l'AG s'arrête lorsque `stagnation >= patience`, sans garantie d'atteindre l'optimum global. Il s'arrête également au maximum de générations configuré.

>>>>>>> a3be2ee (Documentation et experiences de l'AG)
## 5. Organisation du projet

```text
metaATAL/
├── config.toml                 # Paramètres du NLP, de la fitness et de l'AG
├── Project.toml                # Dépendances Julia (si présent)
├── Manifest.toml               # Versions résolues (si présent)
├── README.md
├── data/
│   ├── texte1_HuggingFace.txt
│   ├── texte2_HuggingFace.txt
│   ├── texte3_HuggingFace.txt
│   └── texte4_HuggingFace.txt
├── src/
│   ├── preprocessing.jl        # Segmentation et TF-IDF
│   ├── fitness.jl              # Fonction objectif
│   ├── genetic_algorithm.jl    # AG et opérateurs
│   ├── main.jl                 # Exécution principale
│   ├── results.jl              # Sauvegarde et visualisation
│   ├── exhaustive_search.jl    # Recherche exacte sur petits textes
│   ├── experiments.jl         # Expériences paramétriques
<<<<<<< HEAD
│   ├── experiments_mutation.jl # Tests complémentaires (si conservés)
=======
│   ├── experiments_mutation.jl # Tests complémentaires de mutation
│   ├── plot_experiments.jl    # Visualisation des résultats (si présent)
>>>>>>> a3be2ee (Documentation et experiences de l'AG)
│   └── test_preprocessing.jl   # Vérification du prétraitement
└── output/
    ├── experiences_*.csv      # Résultats des essais
    ├── *.png                  # Figures de comparaison / convergence
    └── ...
```

> Adapter l'arborescence aux fichiers effectivement présents avant le dépôt. Les textes sont directement dans `data/` : aucun sous-dossier `data/clean/` n'est nécessaire.

## 6. Installation

### Prérequis

- Julia installé et accessible depuis un terminal (`julia --version`).
- Git pour cloner et versionner le projet.
- Dépendances Julia déclarées dans `Project.toml` si le projet en possède un.

```bash
# Cloner le dépôt (remplacer par l'URL réelle)
<<<<<<< HEAD
git clone https://github.com/UTILISATEUR/DEPOT.git
cd DEPOT
=======
git clone https://github.com/miskaraminaa/metaATAL.git
cd metaATAL
>>>>>>> a3be2ee (Documentation et experiences de l'AG)

# Installer les dépendances déclarées dans Project.toml
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

Si `Project.toml` n'existe pas encore, créer un environnement Julia et ajouter les bibliothèques réellement utilisées par le code (notamment `TextAnalysis` et `Plots`, ainsi que les autres dépendances externes importées). Les modules standards de Julia ne nécessitent pas d'installation séparée.

## 7. Configuration

Le fichier `config.toml` permet de modifier les paramètres sans changer le code :

```toml
[nlp]
use_stopwords = true
input_file = "data/texte1_HuggingFace.txt"

[fitness]
alpha = 1.0
beta = 0.5
gamma = 0.3

[ga]
pop_size = 50
generations = 100
mutation_rate = 0.1
elite_ratio = 0.5
crossover = "uniform"

[convergence]
enabled = true
patience = 15
min_delta = 1e-6
```

<<<<<<< HEAD
Ce bloc correspond à une **configuration de référence**, pas nécessairement à la meilleure configuration universelle.
=======
Ce bloc reprend les valeurs du fichier de configuration présenté dans le projet pour une exécution standard. **Attention :** certaines campagnes expérimentales fixent `pop_size = 100` dans le script, indépendamment de la valeur `50` ci-dessus. Il ne s’agit pas d’une meilleure configuration universelle.
>>>>>>> a3be2ee (Documentation et experiences de l'AG)

## 8. Exécution

Depuis la **racine** du dépôt :

```bash
# Générer un résumé du document configuré
julia --project=. src/main.jl

# Lancer les expériences définies dans experiments.jl
julia --project=. src/experiments.jl

# Vérifier le prétraitement (si le script est autonome)
julia --project=. src/test_preprocessing.jl
```

Pour changer de document, modifier `nlp.input_file` dans `config.toml`, puis relancer `src/main.jl`.

Les scripts expérimentaux peuvent écrire des fichiers CSV dans `output/`. **Vérifier la liste des expériences active dans `src/experiments.jl` avant l'exécution**, car ce script a été utilisé successivement pour plusieurs campagnes de tests.

## 9. Protocole expérimental

Les essais utilisent quatre textes français de tailles différentes :

| Document | Nombre de phrases |
|---|---:|
| Texte 1 | 14 |
| Texte 2 | 25 |
| Texte 3 | 38 |
| Texte 4 | 50 |

Chaque configuration est répétée avec cinq graines : `42`, `123`, `456`, `789`, `2026`.

Les résultats étudiés comprennent :

- fitness moyenne et écart-type ;
- temps moyen d'exécution ;
- nombre moyen de générations avant arrêt ;
- proportion de phrases conservées (`k/n`) ;
- similarité TF-IDF du résumé avec le document ;
- redondance moyenne entre phrases sélectionnées.

### Paramètres explorés

| Famille | Paramètre | Valeurs testées |
|---|---|---|
| Population | `pop_size` | 20, 50, 100, 200 |
| Mutation | `mutation_rate` | 0.01, 0.05, 0.10, 0.30 |
| Croisement | `crossover` | `onepoint`, `uniform` |
| Élitisme | `elite_ratio` | 0.25, 0.50, 0.75 |
| Convergence | `patience` | 5, 15, 30 |
| Convergence | `min_delta` | 1e-4, 1e-6, 1e-8 |
| Fitness | `alpha` | 0.5, 1.0, 2.0 |
| Fitness | `beta` | 0.0, 0.5, 1.0 |
| Fitness | `gamma` | 0.2, 0.3, 0.4 |
| NLP | `use_stopwords` | `true`, `false` |

Les paramètres non testés sont maintenus constants dans chaque expérience afin d'isoler l'effet du paramètre étudié.

## 10. Résultats et interprétation

### Taille de population

Une population plus grande améliore globalement la fitness moyenne, mais augmente le coût de calcul. Une population de **100** offre un compromis pratique ; **200** peut être intéressant si la qualité prime sur le temps.

### Croisement

Le croisement **uniforme** obtient une fitness moyenne supérieure ou égale à celle du croisement à un point sur les quatre documents étudiés.

### Mutation

Aucun taux n'est systématiquement meilleur sur tous les documents. La valeur **0.10** constitue une référence raisonnable, tandis que **0.05** est également compétitive dans plusieurs essais.

### Élitisme

Augmenter `elite_ratio` n'améliore pas systématiquement la fitness, mais peut accroître fortement le nombre de générations exécutées. La valeur **0.50** offre un compromis.

### Arrêt anticipé

Une patience plus élevée augmente généralement le nombre de générations, sans gain de fitness proportionnel. Une patience de **15** limite les calculs inutiles.

### Paramètres de fitness

- **`alpha`** : augmenter le poids de la représentativité peut conduire à retenir davantage de phrases. Les valeurs de fitness brutes ne sont pas directement comparables entre différents `alpha`.
- **`beta`** : une pénalisation plus forte réduit globalement la redondance, parfois au prix d'une légère baisse de similarité.
- **`gamma`** : augmenter la proportion cible entraîne des résumés plus longs.

### Stopwords

L'activation de la suppression des stopwords réduit la redondance mesurée dans les essais, tandis que la désactivation peut augmenter la similarité TF-IDF. Attention : le prétraitement modifie aussi l'espace vectoriel, donc les comparaisons doivent être interprétées avec prudence.

### Validation par recherche exhaustive

Pour le **texte 1 (14 phrases)**, une recherche exhaustive permet de calculer l'optimum exact dans l'espace de recherche. Une exécution de l'AG a retrouvé une fitness d'environ **0.668011**, égale à l'optimum exact pour la configuration correspondante. Ce résultat valide le comportement de l'AG sur ce petit exemple, sans garantir l'optimalité sur des textes plus longs.

## 11. Limites

- TF-IDF mesure surtout la proximité lexicale et ne capture pas toutes les relations sémantiques.
- La sélection de phrases originales ne garantit pas une cohérence discursive parfaite.
- Les paramètres de la fonction objectif définissent un compromis, mais ne remplacent pas une évaluation humaine.
- Les performances dépendent du document et de la graine aléatoire.
- Les temps mesurés dans Julia peuvent être influencés par la compilation initiale ; un *warm-up* ou un outil de benchmark spécialisé serait utile pour une mesure plus rigoureuse.

## 12. Perspectives

- Évaluer la qualité des résumés avec des références humaines et des métriques adaptées.
- Comparer TF-IDF à des représentations sémantiques (*embeddings*).
- Comparer l'AG à d'autres métaheuristiques ou à des méthodes gloutonnes.
- Tester des documents plus longs et d'autres domaines.
- Étudier une optimisation multiobjectif séparant représentativité, longueur et redondance.

## 13. Rapport et figures

Le rapport LaTeX présente la formulation, l'algorithme, le protocole, les résultats et leurs limites. Les graphiques de `output/` permettent d'illustrer les tendances ; ils sont complémentaires des fichiers CSV qui conservent les résultats par graine.
<<<<<<< HEAD
=======


## 14. Évaluation qualitative des résumés

La fitness ne mesure pas directement la fluidité de lecture. Une inspection qualitative des textes 3 et 4 a été présentée dans le rapport, sur **une sortie par texte** :

| Critère | Texte 3 : rivalité sino-américaine | Texte 4 : PMA et accès aux origines |
|---|---|---|
| Phrases retenues | 12 sur 38 (31,6 %) | 15 sur 50 (30 %) |
| Pertinence | Plusieurs dimensions de la rivalité sont couvertes | Le droit aux origines et les droits des enfants sont présents |
| Cohérence | Une ouverture avec « Mais elle » manque d'antécédent | Certaines phrases isolées manquent de contexte |
| Redondance | Répétitions thématiques limitées | Quelques recoupements sur les droits et l'accès aux origines |

Cette lecture est **illustrative** et non une évaluation humaine normalisée. L'ordre original des phrases est conservé, mais cela ne suffit pas toujours à assurer des transitions naturelles.

## 15. Limites méthodologiques et reproductibilité

- **Comparabilité :** lorsque `alpha`, `beta` ou `gamma` changent, comparer les composantes (similarité, redondance, ratio de phrases) plutôt que les scores bruts de fitness. Les métriques calculées avec et sans stopwords reposent aussi sur des espaces TF-IDF différents.
- **Mesures de temps :** les premières exécutions Julia peuvent inclure la compilation ; les temps doivent être interprétés avec prudence.
- **Validation exacte :** la recherche exhaustive sur 14 phrases ne permet pas de conclure à l'optimalité sur les textes de 25, 38 et 50 phrases.
- **Arrêt anticipé :** l'effet de `patience` et de `min_delta` a été étudié ; une comparaison spécifique `enabled = true` contre `enabled = false` doit être ajoutée si elle n'a pas encore été exécutée.
- **Fichiers de sortie :** les figures et CSV peuvent dépendre des scripts réellement lancés. Vérifier leur présence avant de les référencer dans le rapport.

## 16. Git et GitHub

Dépôt : **[miskaraminaa/metaATAL](https://github.com/miskaraminaa/metaATAL)**.

Depuis le terminal **à la racine du projet** :

```bash
git status
git add README.md
git commit -m "Documenter l'architecture et les expériences de l'AG"
git pull --rebase origin main
git push origin main
```

Pour publier également d'autres modifications du projet, remplacer `git add README.md` par `git add .` **après vérification** des fichiers à inclure (`git status`). Ne pas utiliser `git push --force` pour résoudre un rejet `non-fast-forward` sans comprendre les changements distants.

Si Git affiche `not a git repository`, se placer dans le dossier `metaATAL` contenant `.git`. Si `git status` indique `nothing to commit, working tree clean`, aucun nouveau commit n'est nécessaire.
>>>>>>> a3be2ee (Documentation et experiences de l'AG)
