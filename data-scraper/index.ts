import { JSDOM } from 'jsdom'
import { mkdir, writeFile } from 'node:fs/promises'
import ora from 'ora'
import { resolve } from 'path'
import { Kennzeichen, isDirectory, scrape } from './util'
import { trainCase } from 'change-case'
import fix from './fix'

const url = 'https://www.kennzeichenking.de/kfz-kennzeichen-liste'

const spinner = ora('Lade Kennzeichen …').start()

const list: Kennzeichen[] = []

const res = await scrape(url)
const dom = new JSDOM(await res.text())
const table = dom.window.document.querySelector('.b-table table tbody')
if (table === null) {
    throw new Error('table not found!')
}

table.childNodes.forEach(row => {
    const item: Kennzeichen = {
        Kuerzel: row.childNodes[0].textContent!,
        Ort: row.childNodes[1].textContent!,
        // Kreis: row.childNodes[2].textContent!,
        Bundesland: row.childNodes[3].textContent!,
        Speziell: null,
    }

    // APPLY FIXES
    fix(item)

    if (item.Ort !== null) {
        item.Ort = trainCase(item.Ort.toLowerCase())
    }

    list.push(item)
})

spinner.text = 'Schreibe Rohdaten …'

const dataDirectory = 'data'
if (! await isDirectory(dataDirectory)) {
    await mkdir(dataDirectory)
}
await writeFile(resolve(dataDirectory, 'raw.json'), JSON.stringify(list, null, 4))

spinner.succeed(`${list.length} Kennzeichen geladen`)
