function const {
    param(
        [Parameter(ValueFromRemainingArguments)]
        $Args
    )
    $Args | ForEach-Object {
        "[$_] <$($_.GetType().FullName)>"
    }
}

const b = 3
