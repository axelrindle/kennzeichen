import { Kennzeichen } from './util'

export default function fix(item: Kennzeichen) {
    if (item.Ort === 'Leipzig') {
        item.Bundesland = 'Sachsen'
    }

    if (item.Bundesland === 'bundesweit') {
        item.Bundesland = null
        item.Speziell = item.Ort
        item.Ort = null
    }
    if (item.Bundesland === 'Filmproduktion') {
        item.Speziell = `${item.Bundesland}: ${item.Ort}`
        item.Ort = null
        item.Bundesland = null
    }

    if (item.Kuerzel === 'X') {
        item.Speziell = 'Internationale Hauptquartiere der Nato mit Sitz in Deutschland'
    }
    if (item.Kuerzel === 'Y') {
        item.Speziell = 'Bundeswehr'
    }
}
