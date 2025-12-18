Contains both the original `Documenter.jl` documentation and the same documentation rendered as markdown to include in the harmonized OpenML docs.

Generating the markdown is done as follows:

* Install [DocumenterMarkDown](https://documentermarkdown.juliadocs.org/dev/).
    * Note: currently this only works with version 0.27 of Documenter.jl
    * In Julia, open the package manager (type ']') and run `add Documenter@0.27` and `add DocumenterMarkdown`.
* Run `julia make-md.jl` in the `docs` folder to generate the markdown filew
    * These appear in the `build` folder
* Run `mkdocs serve` in the root folder to build the markdown docs.

