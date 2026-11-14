using TextAnalysis
using Statistics
using LinearAlgebra


const FRENCH_STOPWORDS = Set([
    "le", "la", "les", "un", "une", "des",
    "du", "de", "d", "l", "au", "aux",
    "et", "ou", "mais", "donc", "car",
    "dans", "sur", "sous", "avec", "sans",
    "pour", "par", "en", "vers", "chez",
    "ce", "cet", "cette", "ces",
    "mon", "ma", "mes", "ton", "ta", "tes",
    "son", "sa", "ses", "notre", "nos",
    "votre", "vos", "leur", "leurs",
    "je", "tu", "il", "elle", "nous",
    "vous", "ils", "elles", "on",
    "me", "te", "se", "y",
    "qui", "que", "quoi", "dont", "où",
    "est", "sont", "être", "été",
    "a", "ont", "avoir", "avait",
    "ne", "pas", "plus", "très",
    "aussi", "comme", "même",
    "tout", "tous", "toute", "toutes",
    "à", "entre", "afin", "ainsi"
])



function remove_stopwords(text::AbstractString)
    tokens = split(text)

    filtered = [
        word for word in tokens
        if !(word in FRENCH_STOPWORDS)
    ]

    return join(filtered, " ")
end

# Charger le texte



function load_text(filepath::AbstractString)::String
    isfile(filepath) || error("Fichier introuvable : $filepath")

    lines = readlines(filepath)

    # Supprimer les métadonnées et les lignes vides
    content_lines = [
        strip(line)
        for line in lines
        if !isempty(strip(line)) &&
           !startswith(strip(line), "#")
    ]

    return join(content_lines, "\n")
end


function split_sentences(text::AbstractString)::Vector{String}
    sentences = String[]

    for line in split(text, '\n')
        line = strip(line)
        isempty(line) && continue

        # Découper les phrases lorsqu'une ligne
        # contient plusieurs phrases
        parts = split(line, r"(?<=[.!?])\s+")

        for part in parts
            sentence = strip(part)

            if !isempty(sentence)
                push!(sentences, String(sentence))
            end
        end
    end

    return sentences
end



# Nettoyer une phrase
function clean_string(sentence::AbstractString)
    text = lowercase(sentence)

    text = replace(text, r"[^\p{L}\p{N}\s]" => " ")
    text = replace(text, r"\s+" => " ")

    return String(strip(text))
end



function build_tfidf(
    sentences::Vector{String};
    use_stopwords::Bool=true
)
    # 1. Nettoyer les phrases
    cleaned = [clean_string(s) for s in sentences]

    # 2. Supprimer éventuellement les stopwords
    if use_stopwords
        cleaned = [
            remove_stopwords(s)
            for s in cleaned
        ]
    end

    # 3. Créer les documents
    docs = [TokenDocument(s) for s in cleaned]

    # 4. Construire le corpus
    corpus = Corpus(docs)
    update_lexicon!(corpus)

    # 5. Construire la matrice TF-IDF
    dtm = DocumentTermMatrix(corpus)
    tfidf_matrix = Matrix{Float64}(tf_idf(dtm))

    # 6. Vecteur global
    text_vector = vec(mean(tfidf_matrix, dims=1))

    return tfidf_matrix, text_vector
end



function cosine_similarity(
    a::AbstractVector,
    b::AbstractVector
)::Float64

    numerator = dot(a, b)

    denominator = norm(a) * norm(b) + eps(Float64)

    return numerator / denominator
end
