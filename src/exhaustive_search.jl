
function exhaustive_search(
    tfidf::Matrix{Float64},
    text_vector::Vector{Float64},
    cfg::Dict
)
    n = size(tfidf, 1)

    # Réserver cette méthode aux petits documents
    @assert 1 <= n <= 20

    best_exact_score = -Inf
    best_exact = zeros(Int, n)

    for mask in 1:(2^n - 1)

        chromosome = [
            Int((mask >> (i - 1)) & 1)
            for i in 1:n
        ]

        score = fitness(
            chromosome,
            tfidf,
            text_vector;
            alpha=Float64(cfg["fitness"]["alpha"]),
            beta=Float64(cfg["fitness"]["beta"]),
            gamma=Float64(cfg["fitness"]["gamma"])
        )

        if score > best_exact_score
            best_exact_score = score
            best_exact = copy(chromosome)
        end
    end

    return best_exact, best_exact_score
end
