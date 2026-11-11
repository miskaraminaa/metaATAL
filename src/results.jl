
using Plots
using Dates

function save_results(
    sentences,
    best_individual,
    best_score,
    history,
    cfg,
    project_root
)
    output_dir = joinpath(project_root, "output")
    mkpath(output_dir)

    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")

    # 1. Courbe de convergence
    
p = plot(
    1:length(history),
    history;
    xlabel="Génération",
    ylabel="Meilleure fitness",
    title="Convergence de l'algorithme génétique",
    label="Meilleure fitness globale",
    linewidth=2,
    marker=:circle,
    markersize=3,
    ylims=(minimum(history) - 0.05,
           maximum(history) + 0.05)
)


    graph_path = joinpath(
        output_dir,
        "convergence_$timestamp.png"
    )

    savefig(p, graph_path)

    # 2. Sauvegarder le résumé et les statistiques
    result_path = joinpath(
        output_dir,
        "resultats_$timestamp.txt"
    )

    selected = findall(==(1), best_individual)

    open(result_path, "w") do io
        println(io, "===== CONFIGURATION =====")
        TOML.print(io, cfg)

        println(io, "\n===== RESULTATS =====")
        println(io, "Chromosome : ", best_individual)
        println(io, "Fitness : ", best_score)
        println(io, "Generations : ", length(history))
        println(io, "Phrases selectionnees : ", length(selected))
        println(io, "Ratio : ", length(selected) / length(sentences))

        println(io, "\n===== RESUME =====")
        for i in selected
            println(io, sentences[i])
        end

        println(io, "\n===== HISTORIQUE FITNESS =====")
        for (generation, score) in enumerate(history)
            println(io, generation, ";", score)
        end
    end

    println("\nFichiers générés :")
    println(graph_path)
    println(result_path)

    return graph_path, result_path
end
