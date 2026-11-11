
using TOML
using Random
using Statistics

include("preprocessing.jl")
include("fitness.jl")
include("genetic_algorithm.jl")

function run_experiments()
    root = normpath(joinpath(@__DIR__, ".."))
    cfg_base = TOML.parsefile(joinpath(root, "config.toml"))

    # Charger et vectoriser le document une seule fois
    input_path = joinpath(root, cfg_base["nlp"]["input_file"])
    text = load_text(input_path)
    sentences = split_sentences(text)

    tfidf_matrix, text_vector = build_tfidf(
        sentences;
        use_stopwords=cfg_base["nlp"]["use_stopwords"]
    )

    println("Document : ", length(sentences), " phrases")

    mutation_rates = [0.01, 0.05, 0.10, 0.30]
    seeds = [42, 123, 456, 789, 2026]

    mkpath(joinpath(root, "output"))
    output_path = joinpath(
    root, "output", "experiences_mutation.csv"
)

    open(output_path, "w") do io
        println(io, "mutation_rate,seed,fitness,generations,time_seconds")

        for mutation_rate in mutation_rates
    scores = Float64[]
    times = Float64[]
    generations = Int[]

    for seed in seeds
        cfg = deepcopy(cfg_base)

        cfg["ga"]["pop_size"] = 100
        cfg["ga"]["mutation_rate"] = mutation_rate

        Random.seed!(seed)

        elapsed = @elapsed begin
            best_individual, best_score, history =
                genetic_algorithm(
                    tfidf_matrix,
                    text_vector,
                    cfg;
                    verbose=false
                )
        end

        push!(scores, best_score)
        push!(times, elapsed)
        push!(generations, length(history))

        println(
            io,
            "$mutation_rate,$seed,$best_score,$(length(history)),$elapsed"
        )
    end

    println("\nMutation : ", mutation_rate)
    println("Fitness moyenne : ", mean(scores))
    println("Écart-type : ", std(scores))
    println("Temps moyen : ", mean(times), " s")
    println("Générations moyennes : ", mean(generations))
end
    end

    println("\nRésultats enregistrés : ", output_path)
end

run_experiments()
