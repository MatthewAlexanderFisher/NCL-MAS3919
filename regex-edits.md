# Regex processing

Search: `\\(label|eqref)\{eq:\s+([\w\s-]+)\}`
Replace: `\\$1{eq-$2}`

This regex search pattern looks for instances of `\label{eq` or `\eqref{eq` and captures the text that follows the colon `:`. The replacement changes the colon to a hyphen `-`.

Search: `(?<=\\label\{eq-[\w-]*?|\\eqref\{eq-[\w-]*?)\s`
Replace: `-`

This regex search pattern looks for instances of `\label{eq-` or `\eqref{eq-` followed by any word characters or hyphens, and captures any whitespace that follows. The replacement changes the whitespace to a hyphen `-`.

Search: `\\begin\{align\}\s*([\s\S]*?)\\label\{(eq-[\w-]+)\}\s*([\s\S]*?)\\end\{align\}`
Replace: `$$$ \n $1 $3 \n$$${#$2}`