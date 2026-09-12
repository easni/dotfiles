.pragma library

function tokens(query) {
    return query.trim().toLocaleLowerCase().split(/\s+/).filter(Boolean)
}

function applications(entries, query) {
    const words = tokens(query)
    const needle = query.trim().toLocaleLowerCase()
    function rank(entry) {
        const name = entry.name.toLocaleLowerCase()
        return name === needle ? 0 : name.startsWith(needle) ? 1 : name.includes(needle) ? 2 : 3
    }
    return entries.filter(entry => {
        const text = [entry.name, entry.genericName, entry.description, entry.id, entry.keywords.join(" ")].join(" ").toLocaleLowerCase()
        return words.every(word => text.includes(word))
    }).sort((a, b) => (needle ? rank(a) - rank(b) : 0) || a.name.localeCompare(b.name) || a.id.localeCompare(b.id))
}

function clipboard(entries, query) {
    const words = tokens(query)
    return entries.filter(entry => words.every(word => entry.description.toLocaleLowerCase().includes(word)))
}

function parseClipboard(text) {
    const entries = []
    for (const line of text.split("\n")) {
        const separator = line.indexOf("\t")
        if (separator < 1) continue
        const id = line.slice(0, separator)
        const preview = line.slice(separator + 1)
        if (!/^\d+$/.test(id) || preview.startsWith("[[ binary data")) continue
        entries.push({id: id, name: "", description: preview, icon: ""})
    }
    return entries
}
