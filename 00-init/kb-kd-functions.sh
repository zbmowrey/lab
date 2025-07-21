# Kustomize Build (apply) function
kb() {
    if [ $# -eq 0 ]; then
        echo "Usage: kb <overlay-dir>" >&2
        return 1
    fi

    if [ ! -d "$1" ]; then
        echo "Error: Directory '$1' does not exist." >&2
        return 1
    fi

    kustomize build "$1" | kubectl apply -f -
}

# Kustomize Delete function
kd() {
    if [ $# -eq 0 ]; then
        echo "Usage: kd <overlay-dir>" >&2
        return 1
    fi

    if [ ! -d "$1" ]; then
        echo "Error: Directory '$1' does not exist." >&2
        return 1
    fi

    kustomize build "$1" | kubectl delete -f -
}
