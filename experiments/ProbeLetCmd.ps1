function let {
    param(
        [Parameter(ValueFromRemainingArguments)]
        $Args
    )
    $Args | ForEach-Object {
        "[$_] <$($_.GetType().FullName)>"
    }
}

let a = @(1,2)
