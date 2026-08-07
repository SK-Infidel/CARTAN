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
    console.log('Cartan Language Extension (v0.3.0) is now active!');
    // The path to the cartanc executable.
    const compilerPath = vscode.workspace.getConfiguration('cartan').get('compilerPath') || 'cartanc';
    const run = {
        command: compilerPath,
        args: ['lsp']
    };
    const serverOptions = {
        run,
        debug: run
    };
    const clientOptions = {
        documentSelector: [{ scheme: 'file', language: 'cartan' }],
        synchronize: {
            fileEvents: vscode.workspace.createFileSystemWatcher('**/*.car')
        }
    };
    client = new node_1.LanguageClient('cartanLanguageServer', 'Cartan Language Server', serverOptions, clientOptions);
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
                return new vscode.Hover(new vscode.MarkdownString('**Tensor Declaration**\n\nDeclares an N-dimensional tensor array allocated on the GPU/MemoryBus.'));
            }
            else if (word === 'parameter') {
                return new vscode.Hover(new vscode.MarkdownString('**Model Parameter**\n\nDeclares a learnable neural network parameter tensor with attached optimizer state (e.g. `Adam`, `SGD`) and Riemannian geometry.'));
            }
            else if (word === 'Euclidean') {
                return new vscode.Hover(new vscode.MarkdownString('**Euclidean Manifold**\n\nStandard flat Riemannian manifold space ($\u211d^N$) with standard zero-curvature metric tensor.'));
            }
            else if (word === 'PoincaréDisk' || word === 'PoincareDisk') {
                return new vscode.Hover(new vscode.MarkdownString('**Poincaré Disk Manifold ($\u214d^N$)**\n\nHyperbolic manifold space with constant negative curvature. Natively calculates hyperbolic geodesics and Mobius gyrovector transformations.'));
            }
            else if (word === 'Minkowski') {
                return new vscode.Hover(new vscode.MarkdownString('**Minkowski Manifold ($\u211d^{1,N-1}$)**\n\nSpacetime pseudo-Riemannian manifold with Lorentz metric tensor ($\u03b7_{\u03bc\u03bd} = \\text{diag}(-1, +1, +1, +1)$).'));
            }
            else if (word === 'extern') {
                return new vscode.Hover(new vscode.MarkdownString('**Extern FFI Declaration**\n\nBinds an external C ABI hardware runtime function (e.g., `libWebGpu`, `libVulkan`, `printf`).'));
            }
            else if (word === 'under') {
                return new vscode.Hover(new vscode.MarkdownString('**Precision Specifier**\n\nSpecifies data precision (`fp16`, `bf16`, `int8`, `fp32`).'));
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