# Graphiques du projet metaATAL — Julia / Plots.jl uniquement
using Plots
using Statistics

const ROOT = normpath(joinpath(@__DIR__, ".."))
const OUT = joinpath(ROOT, "output")
const FIG = joinpath(OUT, "figures")
mkpath(FIG)

# Lecture des CSV sans dépendance supplémentaire. Certains fichiers existants
# ont 10 valeurs par ligne mais seulement 7 noms dans leur en-tête.
function read_experiment(parameter::String)
    path = joinpath(OUT, "experiences_$(parameter).csv")
    if !isfile(path)
        @warn "Fichier absent, graphique ignoré" path
        return NamedTuple[]
    end
    lines = readlines(path)
    rows = NamedTuple[]
    for line in lines[2:end]
        isempty(strip(line)) && continue
        c = strip.(split(line, ','))
        length(c) >= 7 || continue
        push!(rows, (
            document=String(c[1]), parameter=String(c[2]),
            value=String(c[3]), seed=parse(Int, c[4]),
            fitness=parse(Float64, c[5]),
            generations=parse(Float64, c[6]),
            time_seconds=parse(Float64, c[7]),
            similarity=length(c) >= 10 ? parse(Float64, c[8]) : NaN,
            redundancy=length(c) >= 10 ? parse(Float64, c[9]) : NaN,
            compression_ratio=length(c) >= 10 ? parse(Float64, c[10]) : NaN
        ))
    end
    return rows
end

function value_order(values::Vector{String})
    if all(v -> tryparse(Float64, v) !== nothing, values)
        return sort(values; by=v -> parse(Float64, v))
    elseif all(v -> v in ("true", "false"), values)
        return [v for v in ["true", "false"] if v in values]
    else
        return sort(values)
    end
end

function plot_parameter(parameter::String, metric::Symbol; ylabel::String="", percent::Bool=false)
    rows = read_experiment(parameter)
    isempty(rows) && return
    if all(r -> isnan(getproperty(r, metric)), rows)
        @warn "Indicateur absent du CSV" parameter metric
        return
    end
    docs = unique(r.document for r in rows)
    values = value_order(unique([r.value for r in rows]))
    p = plot(; xlabel=parameter, ylabel=ylabel,
        title="$(parameter) — $(metric)", legend=:outertopright,
        marker=:circle, linewidth=2, size=(900, 510), dpi=150)
    for (i, doc) in enumerate(docs)
        y = [begin
            vals = [getproperty(r, metric) for r in rows
                    if r.document == doc && r.value == value &&
                       isfinite(getproperty(r, metric))]
            isempty(vals) ? NaN : mean(vals) * (percent ? 100 : 1)
        end for value in values]
        plot!(p, 1:length(values), y; label="Texte $i")
    end
    plot!(p; xticks=(1:length(values), values))
    path = joinpath(FIG, "$(parameter)_$(metric).png")
    savefig(p, path)
    println("Créé : ", path)
end

# Paramètres du GA : fonction objectif inchangée, fitness comparable.
for param in ["pop_size", "mutation_rate", "crossover", "elite_ratio",
              "patience", "min_delta"]
    plot_parameter(param, :fitness; ylabel="Fitness moyenne")
    plot_parameter(param, :generations; ylabel="Générations moyennes")
end

# Paramètres de fitness : NE PAS comparer directement les fitness.
# Utiliser les composantes mesurées et la longueur effective.
for param in ["alpha", "beta", "gamma"]
    plot_parameter(param, :similarity; ylabel="Similarité TF-IDF")
    plot_parameter(param, :redundancy; ylabel="Redondance TF-IDF")
    plot_parameter(param, :compression_ratio;
                   ylabel="Phrases conservées (%)", percent=true)
end

# Avec/sans stopwords : les métriques TF-IDF reposent sur des espaces différents.
for metric in [:similarity, :redundancy, :compression_ratio, :generations]
    plot_parameter("use_stopwords", metric;
                   ylabel=metric == :compression_ratio ? "Phrases conservées (%)" : string(metric),
                   percent=(metric == :compression_ratio))
end

println("\nGraphiques enregistrés dans : ", FIG)
