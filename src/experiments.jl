
using TOML
using Random
using Statistics

include("preprocessing.jl")
include("fitness.jl")
include("genetic_algorithm.jl")

const ROOT = normpath(joinpath(@__DIR__, ".."))

const DOCUMENTS = [
    "texte1_HuggingFace.txt",
    "texte2_HuggingFace.txt",
    "texte3_HuggingFace.txt",
    "texte4_HuggingFace.txt"
]

const SEEDS = [42, 123, 456, 789, 2026]

# Charger un document et calculer ses vecteurs TF-IDF
function prepare_document(filename, cfg)
    path = joinpath(ROOT, "data", filename)

    text = load_text(path)
    sentences = split_sentences(text)

    tfidf, text_vector = build_tfidf(
        sentences;
        use_stopwords=cfg["nlp"]["use_stopwords"]
    )

    return sentences, tfidf, text_vector
end

# Tester un paramètre en gardant les autres constants
function experiment(
    parameter::String,
    values,
    document::String,
    cfg_base::Dict
)
sentences = String[]
tfidf = Matrix{Float64}(undef, 0, 0)
text_vector = Float64[]

if parameter != "use_stopwords"
    sentences, tfidf, text_vector =
        prepare_document(document, cfg_base)
end

    println("\nDocument : ", document)
    println("Phrases : ", length(sentences))
    println("Paramètre testé : ", parameter)

    results = []

    for value in values
        scores = Float64[]
        times = Float64[]
        generations = Int[]

        for seed in SEEDS
            cfg = deepcopy(cfg_base)

            if parameter == "use_stopwords"
    cfg["nlp"]["use_stopwords"] = value

    sentences, tfidf, text_vector =
        prepare_document(document, cfg)
end

            # Configuration de référence
            cfg["ga"]["pop_size"] = 100
            cfg["ga"]["generations"] = 100
            cfg["ga"]["mutation_rate"] = 0.10
            cfg["ga"]["elite_ratio"] = 0.50
            cfg["ga"]["crossover"] = "uniform"

            # Modifier uniquement le paramètre étudié
            if parameter in ("patience", "min_delta")
    cfg["convergence"][parameter] = value
elseif parameter in ("alpha", "beta", "gamma")
    cfg["fitness"][parameter] = value
elseif parameter == "use_stopwords"
    cfg["nlp"]["use_stopwords"] = value
else
    cfg["ga"][parameter] = value
end

if parameter in ("patience", "min_delta") && seed == first(SEEDS)
    println(
        "TEST : enabled = ", cfg["convergence"]["enabled"],
        " | patience = ", cfg["convergence"]["patience"],
        " | min_delta = ", cfg["convergence"]["min_delta"]
    )
end
            Random.seed!(seed)

            elapsed = @elapsed begin
                best_individual, best_score, history =
                    genetic_algorithm(
                        tfidf,
                        text_vector,
                        cfg;
                        verbose=false
                    )
                    metrics = summary_metrics(
    best_individual,
    tfidf,
    text_vector
)
            end

            push!(scores, best_score)
            push!(times, elapsed)
            push!(generations, length(history))

            push!(
    results,
    (
        document,
        parameter,
        value,
        seed,
        best_score,
        length(history),
        elapsed,
        metrics.similarity,
        metrics.redundancy,
        metrics.compression_ratio
    )
)
        end

        println("\nValeur : ", value)
        println("Fitness moyenne : ", mean(scores))
        println("Écart-type : ", std(scores))
        println("Temps moyen : ", mean(times), " s")
        println("Générations moyennes : ", mean(generations))
    end

    return results
end

# Sauvegarder les résultats
function save_experiment_results(results, filename)
    output_dir = joinpath(ROOT, "output")
    mkpath(output_dir)

    path = joinpath(output_dir, filename)

    open(path, "w") do io
        println(
            io,
            "document,parameter,value,seed,fitness,generations,time_seconds"
        )

        for result in results
            println(io, join(result, ","))
        end
    end

    println("\nRésultats enregistrés : ", path)
end

function run_all_experiments()
    cfg = TOML.parsefile(joinpath(ROOT, "config.toml"))

    # experiments = [
    #     ("pop_size", [20, 50, 100, 200]),
    #     ("mutation_rate", [0.01, 0.05, 0.10, 0.30]),
    #     ("crossover", ["uniform", "onepoint"])
    # ]
#     experiments = [
#     ("elite_ratio", [0.25, 0.50, 0.75])
# ]
# experiments = [
#     ("patience", [5, 15, 30]),
#     ("min_delta", [1e-4, 1e-6, 1e-8])
# ]

# experiments = [
#     ("alpha", [0.5, 1.0, 2.0]),
#     ("beta", [0.0, 0.5, 1.0]),
#     ("gamma", [0.2, 0.3, 0.4])
# ]
experiments = [
    ("use_stopwords", [true, false])
]
    for (parameter, values) in experiments
        all_results = []

        for document in DOCUMENTS
            append!(
                all_results,
                experiment(
                    parameter,
                    values,
                    document,
                    cfg
                )
            )
        end

        save_experiment_results(
            all_results,
            "experiences_$(parameter).csv"
        )
    end
end

run_all_experiments()
