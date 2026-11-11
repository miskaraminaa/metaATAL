
include("preprocessing.jl")

root = normpath(joinpath(@__DIR__, ".."))

files = [
    "texte1_HuggingFace.txt",
    "texte2_HuggingFace.txt",
    "texte3_HuggingFace.txt",
    "texte4_HuggingFace.txt"
]

for filename in files
    filepath = joinpath(root, "data", filename)

    println("\n", "="^60)
    println("DOCUMENT : ", filename)

    text = load_text(filepath)
    sentences = split_sentences(text)

    println("Nombre de phrases : ", length(sentences))

    for (i, sentence) in enumerate(sentences)
        println("[$i] ", sentence)
    end
end
