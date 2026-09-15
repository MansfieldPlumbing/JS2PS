import { pathToFileURL } from 'node:url';
import { readFileSync } from 'node:fs';
import { performance } from 'node:perf_hooks';

const arguments_ = process.argv.slice(2);
const iterationArgument = arguments_.find(argument => argument.startsWith('--iterations='));
const iterations = iterationArgument ? Number(iterationArgument.slice('--iterations='.length)) : 0;
const [typescriptPath, ...sourcePaths] = arguments_.filter(argument => !argument.startsWith('--iterations='));
if (!typescriptPath || sourcePaths.length === 0) {
    throw new Error('Usage: node Probe-TypeScriptGraphicsAst.mjs <typescript.js> <source.js> [...]');
}

const ts = await import(pathToFileURL(typescriptPath).href);
const interestingKinds = new Set([
    'ArrayLiteralExpression',
    'BinaryExpression',
    'CallExpression',
    'ClassDeclaration',
    'ConditionalExpression',
    'Constructor',
    'ElementAccessExpression',
    'FunctionDeclaration',
    'MethodDeclaration',
    'NewExpression',
    'ObjectLiteralExpression',
    'PropertyAccessExpression',
    'VariableDeclaration',
]);

const results = [];
const sources = [];
for (const sourcePath of sourcePaths) {
    const text = readFileSync(sourcePath, 'utf8');
    sources.push({ sourcePath, text });
    const tree = ts.createSourceFile(sourcePath, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
    const counts = Object.create(null);
    const samples = [];
    let spanFailures = 0;

    function visit(node) {
        const kind = ts.SyntaxKind[node.kind];
        if (interestingKinds.has(kind)) {
            counts[kind] = (counts[kind] ?? 0) + 1;
            const start = node.getStart(tree);
            const nodeText = node.getText(tree);
            if (text.slice(start, node.end) !== nodeText) spanFailures++;
            if (samples.length < 24) {
                samples.push({
                    kind,
                    start,
                    end: node.end,
                    text: nodeText.replace(/\s+/g, ' ').slice(0, 120),
                });
            }
        }
        ts.forEachChild(node, visit);
    }
    visit(tree);

    results.push({
        sourcePath,
        parseDiagnostics: tree.parseDiagnostics.map(diagnostic => ({
            start: diagnostic.start,
            length: diagnostic.length,
            message: ts.flattenDiagnosticMessageText(diagnostic.messageText, '\n'),
        })),
        spanFailures,
        counts,
        samples,
    });
}

let benchmark = null;
if (iterations > 0) {
    for (const { sourcePath, text } of sources) {
        ts.createSourceFile(sourcePath, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
    }
    const started = performance.now();
    for (let iteration = 0; iteration < iterations; iteration++) {
        for (const { sourcePath, text } of sources) {
            ts.createSourceFile(sourcePath, text, ts.ScriptTarget.Latest, true, ts.ScriptKind.JS);
        }
    }
    const elapsedMilliseconds = performance.now() - started;
    const parses = iterations * sources.length;
    benchmark = {
        parses,
        elapsedMilliseconds,
        millisecondsPerFile: elapsedMilliseconds / parses,
        filesPerSecond: parses / (elapsedMilliseconds / 1000),
    };
}

if (results.some(result => result.parseDiagnostics.length !== 0 || result.spanFailures !== 0)) {
    process.exitCode = 1;
}
process.stdout.write(JSON.stringify({ typescriptVersion: ts.version, results, benchmark }, null, 2));
