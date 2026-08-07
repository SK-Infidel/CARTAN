import * as vscode from 'vscode';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    Executable
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
    console.log('Cartan Language Extension (v0.3.0) is now active!');

    // The path to the cartanc executable.
    const compilerPath = vscode.workspace.getConfiguration('cartan').get<string>('compilerPath') || 'cartanc';

    const run: Executable = {
        command: compilerPath,
        args: ['lsp']
    };

    const serverOptions: ServerOptions = {
        run,
        debug: run
    };

    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'cartan' }],
        synchronize: {
            fileEvents: vscode.workspace.createFileSystemWatcher('**/*.car')
        }
    };

    client = new LanguageClient(
        'cartanLanguageServer',
        'Cartan Language Server',
        serverOptions,
        clientOptions
    );

    // Start Language Server Client
    client.start();

    // Register Hover Provider for CARTAN keywords and manifolds
    const hoverProvider = vscode.languages.registerHoverProvider('cartan', {
        provideHover(document, position) {
            const range = document.getWordRangeAtPosition(position);
            if (!range) {
                return null;
            }
            const word = document.getText(range);

            if (word === 'tensor') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Tensor Declaration**\n\nDeclares an N-dimensional tensor array allocated on the GPU/MemoryBus.'
                ));
            } else if (word === 'parameter') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Model Parameter**\n\nDeclares a learnable neural network parameter tensor with attached optimizer state (e.g. `Adam`, `SGD`) and Riemannian geometry.'
                ));
            } else if (word === 'Euclidean') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Euclidean Manifold**\n\nStandard flat Riemannian manifold space ($\u211d^N$) with standard zero-curvature metric tensor.'
                ));
            } else if (word === 'PoincaréDisk' || word === 'PoincareDisk') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Poincaré Disk Manifold ($\u214d^N$)**\n\nHyperbolic manifold space with constant negative curvature. Natively calculates hyperbolic geodesics and Mobius gyrovector transformations.'
                ));
            } else if (word === 'Minkowski') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Minkowski Manifold ($\u211d^{1,N-1}$)**\n\nSpacetime pseudo-Riemannian manifold with Lorentz metric tensor ($\u03b7_{\u03bc\u03bd} = \\text{diag}(-1, +1, +1, +1)$).'
                ));
            } else if (word === 'extern') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Extern FFI Declaration**\n\nBinds an external C ABI hardware runtime function (e.g., `libWebGpu`, `libVulkan`, `printf`).'
                ));
            } else if (word === 'under') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Precision Specifier**\n\nSpecifies data precision (`fp16`, `bf16`, `int8`, `fp32`).'
                ));
            }
            return null;
        }
    });
    context.subscriptions.push(hoverProvider);
}

export function deactivate(): Thenable<void> | undefined {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
