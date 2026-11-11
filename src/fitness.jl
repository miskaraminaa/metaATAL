
using Statistics
using LinearAlgebra

function fitness(
    chromosome::Vector{Int},
    tfidf::Matrix{Float64},
    text_vector::Vector{Float64};
    alpha::Float64=1.0,
    beta::Float64=0.5,
    gamma::Float64=0.3
)::Float64

    # 1. Nombre total de phrases
    n = length(chromosome)

    @assert size(tfidf, 1) == n
    @assert size(tfidf, 2) == length(text_vector)
    @assert all(x -> x == 0 || x == 1, chromosome)

    # 2. Phrases sélectionnées
    selected = findall(==(1), chromosome)
    k = length(selected)

    # Un résumé vide est invalide
    if k == 0
        return -Inf
    end

    # 3. Représentativité
    summary_vector = vec(
        mean(tfidf[selected, :], dims=1)
    )

    similarity = cosine_similarity(
        summary_vector,
        text_vector
    )

    # 4. Pénalité de longueur
    length_penalty = abs(k / n - gamma)

    # 5. Pénalité de redondance
    redundancy = 0.0

    if k >= 2
        total_similarity = 0.0
        pair_count = 0

        for i in 1:(k-1)
            for j in (i+1):k

                v1 = vec(tfidf[selected[i], :])
                v2 = vec(tfidf[selected[j], :])

                total_similarity += cosine_similarity(v1, v2)
                pair_count += 1
            end
        end

        redundancy = total_similarity / pair_count
    end

    # 6. Fitness finale
    score = alpha * similarity -
            length_penalty -
            beta * redundancy

    return score
end

function summary_metrics(chromosome, tfidf, text_vector)
    selected = findall(==(1), chromosome)
    n = length(chromosome)
    k = length(selected)

    if k == 0
        return (similarity=0.0,
                redundancy=0.0,
                compression_ratio=0.0)
    end

    summary_vector = vec(mean(tfidf[selected, :], dims=1))
    similarity = cosine_similarity(summary_vector, text_vector)

    redundancy = 0.0

    if k >= 2
        total = 0.0
        count = 0

        for i in 1:(k-1)
            for j in (i+1):k
                total += cosine_similarity(
                    vec(tfidf[selected[i], :]),
                    vec(tfidf[selected[j], :])
                )
                count += 1
            end
        end

        redundancy = total / count
    end

    return (
        similarity=similarity,
        redundancy=redundancy,
        compression_ratio=k / n
    )
end