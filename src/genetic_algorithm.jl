
using Random

function crossover_onepoint(
    p1::Vector{Int},
    p2::Vector{Int}
)::Vector{Int}

    @assert length(p1) == length(p2)

    n = length(p1)

    if n < 2
        return copy(p1)
    end

    # Point de coupure aléatoire
    cut = rand(1:n-1)

    # Construire l'enfant
    child = vcat(
        p1[1:cut],
        p2[cut+1:end]
    )

    return child
end


function crossover_uniform(
    p1::Vector{Int},
    p2::Vector{Int}
)::Vector{Int}

    @assert length(p1) == length(p2)

    child = [
        rand(Bool) ? p1[i] : p2[i]
        for i in eachindex(p1)
    ]

    return child
end


function mutate!(
    chromosome::Vector{Int}
)::Vector{Int}

    if isempty(chromosome)
        return chromosome
    end

    # Choisir un gène au hasard
    i = rand(eachindex(chromosome))

    # Inverser le bit
    chromosome[i] = 1 - chromosome[i]

    return chromosome
end




function genetic_algorithm(
    tfidf::Matrix{Float64},
    text_vector::Vector{Float64},
    cfg::Dict;
    verbose::Bool=true
)
    # 1. Lecture des paramètres
    ga = cfg["ga"]
    fit = cfg["fitness"]
    conv = cfg["convergence"]

    pop_size = Int(ga["pop_size"])
    generations = Int(ga["generations"])
    mutation_rate = Float64(ga["mutation_rate"])
    elite_ratio = Float64(ga["elite_ratio"])
    crossover_type = ga["crossover"]

    alpha = Float64(fit["alpha"])
    beta = Float64(fit["beta"])
    gamma = Float64(fit["gamma"])

    convergence_enabled = conv["enabled"]
    patience = Int(conv["patience"])
    min_delta = Float64(conv["min_delta"])

    n = size(tfidf, 1)

    @assert n > 0
    @assert pop_size >= 2
    @assert generations >= 1
    @assert 0 <= mutation_rate <= 1
    @assert 0 < elite_ratio <= 1
    @assert crossover_type in ("uniform", "onepoint")

    # 2. Initialisation de la population
    population = [
        rand(0:1, n)
        for _ in 1:pop_size
    ]

    best_individual = zeros(Int, n)
    best_score = -Inf
    history = Float64[]
    stagnation = 0

    # Nombre d'élites conservées
    n_elites = min(
        pop_size,
        max(2, floor(Int, elite_ratio * pop_size))
    )

    # 3. Boucle des générations
    for generation in 1:generations

        # Évaluation des individus
        scores = [
            fitness(
                individual,
                tfidf,
                text_vector;
                alpha=alpha,
                beta=beta,
                gamma=gamma
            )
            for individual in population
        ]

        # Classement par fitness décroissante
        order = sortperm(scores, rev=true)

        current_best_idx = order[1]
        current_score = scores[current_best_idx]

        # Mise à jour du meilleur individu global
        if current_score > best_score
            if current_score > best_score + min_delta
                stagnation = 0
            else
                stagnation += 1
            end

            best_score = current_score
            best_individual = copy(
                population[current_best_idx]
            )
        else
            stagnation += 1
        end

        # Historique de convergence
        push!(history, best_score)

        if verbose
            println(
                "Génération $generation | Fitness = ",
                round(best_score, digits=5)
            )
        end
       

        # Arrêt anticipé
        if convergence_enabled && stagnation >= patience
    if verbose
        println(
            "Convergence atteinte à la génération $generation"
        )
    end
    break
end

        # 4. Sélection des élites
        elites = [
            copy(population[i])
            for i in order[1:n_elites]
        ]

        new_population = copy(elites)

        # 5. Reproduction
        while length(new_population) < pop_size

            p1 = rand(elites)
            p2 = rand(elites)

            child = if crossover_type == "uniform"
                crossover_uniform(p1, p2)
            else
                crossover_onepoint(p1, p2)
            end

            # Mutation
            if rand() < mutation_rate
                mutate!(child)
            end

            push!(new_population, child)
        end

        population = new_population
    end

    return best_individual, best_score, history
end
