import * as vscode from 'vscode';
import * as path from 'path';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    Executable
} from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
    console.log('Cartan language extension is now active!');

    // The path to the cartanc executable.
    // In a real release, this would be downloaded or configured in settings.
    // We assume it's in the PATH or we can provide an absolute path to the local build for dev.
    const compilerPath = vscode.workspace.getConfiguration('cartan').get<string>('compilerPath') || 'cartanc';

    const run: Executable = {
        command: compilerPath,
        args: ['lsp'],
        options: {
            // For development, we set the cwd to the workspace root if needed, but not strictly required.
        }
    };

    const serverOptions: ServerOptions = {
        run,
        debug: run
    };

    const clientOptions: LanguageClientOptions = {
        documentSelector: [{ scheme: 'file', language: 'cartan' }],
        synchronize: {
            fileEvents: vscode.workspace.createFileSystemWatcher('**/*.ctn')
        }
    };

    client = new LanguageClient(
        'cartanLanguageServer',
        'Cartan Language Server',
        serverOptions,
        clientOptions
    );

    // Start the client. This will also launch the server
    client.start();
    
    // Register Hover Provider
    const hoverProvider = vscode.languages.registerHoverProvider('cartan', {
        provideHover(document, position, token) {
            const range = document.getWordRangeAtPosition(position);
            const word = document.getText(range);

            if (word === 'tensor') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**Tensor**\n\nDeclares an N-dimensional contiguous array on the MemoryBus. Natively compiled to the specified precision.'
                ));
            } else if (word === 'under') {
                return new vscode.Hover(new vscode.MarkdownString(
                    '**under**\n\nPrecision specifier. E.g., `under fp16` or `under int8`.'
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
