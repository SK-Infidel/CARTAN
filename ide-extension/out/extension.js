"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const node_1 = require("vscode-languageclient/node");
let client;
function activate(context) {
    console.log('Cartan language extension is now active!');
    // The path to the cartanc executable.
    // In a real release, this would be downloaded or configured in settings.
    // We assume it's in the PATH or we can provide an absolute path to the local build for dev.
    const compilerPath = vscode.workspace.getConfiguration('cartan').get('compilerPath') || 'cartanc';
    const run = {
        command: compilerPath,
        args: ['lsp'],
        options: {
        // For development, we set the cwd to the workspace root if needed, but not strictly required.
        }
    };
    const serverOptions = {
        run,
        debug: run
    };
    const clientOptions = {
        documentSelector: [{ scheme: 'file', language: 'cartan' }],
        synchronize: {
            fileEvents: vscode.workspace.createFileSystemWatcher('**/*.ctn')
        }
    };
    client = new node_1.LanguageClient('cartanLanguageServer', 'Cartan Language Server', serverOptions, clientOptions);
    // Start the client. This will also launch the server
    client.start();
    // Register Hover Provider
    const hoverProvider = vscode.languages.registerHoverProvider('cartan', {
        provideHover(document, position, token) {
            const range = document.getWordRangeAtPosition(position);
            const word = document.getText(range);
            if (word === 'tensor') {
                return new vscode.Hover(new vscode.MarkdownString('**Tensor**\n\nDeclares an N-dimensional contiguous array on the MemoryBus. Natively compiled to the specified precision.'));
            }
            else if (word === 'under') {
                return new vscode.Hover(new vscode.MarkdownString('**under**\n\nPrecision specifier. E.g., `under fp16` or `under int8`.'));
            }
            return null;
        }
    });
    context.subscriptions.push(hoverProvider);
}
function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
//# sourceMappingURL=extension.js.map