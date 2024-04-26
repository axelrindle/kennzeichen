import { stat } from 'node:fs/promises'

export interface Kennzeichen {
    Kuerzel: string
    Ort: string|null
    // Kreis: string
    Bundesland: string|null
    Speziell: string|null
}

export async function isDirectory(path: string) {
    try {
        const stats = await stat(path)
        return stats.isDirectory
    } catch(error) {
        if (error.code !== 'ENOENT') {
            throw error
        }
    }

    return false
}

/**
 * Extrahiert eine Liste aller dt. Kennzeichen von der festgelegten URL.
 */
export async function scrape(url: string): Promise<Response> {
    const res = await fetch(url, {
        method: 'GET'
    })

    if (!res.ok) {
        throw new Error(res.statusText)
    }

    return res
}
