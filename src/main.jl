
using TOML
using Random

# ==========================================
# 1. IMPORTATION DES MODULES
# ==========================================

include("preprocessing.jl")
include("fitness.jl")
include("genetic_algorithm.jl")
include("results.jl")
include("exhaustive_search.jl")
# ==========================================
# 2. CONFIGURATION
# ==========================================

project_root = normpath(joinpath(@__DIR__, ".."))

config_path = joinpath(project_root, "config.toml")
cfg = TOML.parsefile(config_path)

# Chemin du texte défini dans config.toml
input_file = cfg["nlp"]["input_file"]
filepath = joinpath(project_root, input_file)

# Graine fixe pour les tests
Random.seed!(42)

# ==========================================
# 3. PRETRAITEMENT NLP
# ==========================================

println("\n===== PRETRAITEMENT NLP =====")

text = load_text(filepath)
sentences = split_sentences(text)


println("\n===== VERIFICATION DU DECOUPAGE =====")

for (i, sentence) in enumerate(sentences)
    println("Phrase $i : ", sentence)
end


println("Nombre de phrases : ", length(sentences))


# Lire l'option depuis config.toml
use_stopwords = cfg["nlp"]["use_stopwords"]

tfidf_matrix, text_vector = build_tfidf(
    sentences;
    use_stopwords=use_stopwords
)

println(
    "Suppression des stopwords : ",
    use_stopwords ? "Activée" : "Désactivée"
)


println("Dimensions TF-IDF : ", size(tfidf_matrix))
println("Taille du vecteur global : ", length(text_vector))

# ==========================================
# 4. ALGORITHME GENETIQUE
# ==========================================

println("\n===== ALGORITHME GENETIQUE =====")

best_individual, best_score, history =
    genetic_algorithm(
        tfidf_matrix,
        text_vector,
        cfg
    )

# ==========================================
# 5. RESULTATS
# ==========================================

println("\n===== RESULTATS FINAUX =====")

println("Meilleur chromosome : ", best_individual)
println("Meilleure fitness : ", best_score)
println("Generations effectuees : ", length(history))

selected_indices = findall(==(1), best_individual)

println("Nombre de phrases selectionnees : ",
        length(selected_indices))

println("Ratio de compression : ",
        round(length(selected_indices) /
              length(sentences), digits=3))

# ==========================================
# 6. RESUME AUTOMATIQUE
# ==========================================

println("\n===== RESUME AUTOMATIQUE =====")

for i in selected_indices
    println(sentences[i])
end



println("\n===== SAUVEGARDE =====")

save_results(
    sentences,
    best_individual,
    best_score,
    history,
    cfg,
    project_root
)




# ==========================================
# VALIDATION PAR RECHERCHE EXHAUSTIVE
# ==========================================

if length(sentences) <= 15

    println("\n===== VALIDATION PAR RECHERCHE EXHAUSTIVE =====")

    best_exact, best_exact_score = exhaustive_search(
        tfidf_matrix,
        text_vector,
        cfg
    )

    println("Chromosome optimal exact : ", best_exact)
    println("Fitness optimale exacte : ", best_exact_score)
    println("Fitness algorithme génétique : ", best_score)

    gap = best_exact_score - best_score
    println("Écart entre exact et GA : ", gap)

    if isapprox(best_score, best_exact_score; atol=1e-10)
        println("Le GA a trouvé une solution optimale !")
    else
        println("Le GA n'a pas atteint l'optimum global.")
    end

else
    println("\n===== VALIDATION EXACTE =====")
    println("Recherche exhaustive ignorée : document trop long.")
end
