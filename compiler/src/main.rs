pub mod ast;
pub mod codegen;
pub mod error;
pub mod ir;
pub mod lexer;
pub mod parser;
pub mod token;
pub mod types;
pub mod type_checker;
pub mod macro_pass;
pub mod optimizer;
pub mod autodiff;
pub mod liveness;
pub mod weight_format;
pub mod llvm_codegen;
pub mod wgsl_codegen;
pub mod lsp_server;
pub mod bpe_compiler;
mod eval;

use lexer::Lexer;
use parser::Parser;
use type_checker::TypeChecker;
use macro_pass::MacroPass;
use optimizer::KernelFusionPass;
use autodiff::AutoDiffPass;
// Removed unused import
use liveness::LivenessPass;
use codegen::CodeGenerator;
use llvm_codegen::LLVMGenerator;
use wgsl_codegen::WGSLGenerator;
use std::fs::File;
use std::io::Write;


use std::env;
use std::fs;

use std::process::Command;

fn get_cartan_root() -> std::path::PathBuf {
    if let Ok(path) = env::var("CARTAN_HOME") {
        return std::path::PathBuf::from(path);
    }
    let mut exe_path = env::current_exe().unwrap_or_else(|_| std::path::PathBuf::from("."));
    for _ in 0..5 {
        if exe_path.join("zig-windows-x86_64-0.13.0").exists() || exe_path.join("std").exists() || exe_path.join("zig").exists() {
            return exe_path;
        }
        if !exe_path.pop() {
            break;
        }
    }
    std::path::PathBuf::from(".")
}

fn resolve_imports(source: &str, visited: &mut std::collections::HashSet<String>) -> String {
    let mut result = String::new();
    let root = get_cartan_root();
    for line in source.lines() {
        if line.trim().starts_with("import ") {
            if let Some(start) = line.find('"') {
                if let Some(end) = line[start+1..].find('"') {
                    let path_str = &line[start+1..start+1+end];
                    if visited.contains(path_str) {
                        continue;
                    }
                    visited.insert(path_str.to_string());
                    
                    let std_path = root.join(path_str);
                    if let Ok(imported) = fs::read_to_string(&std_path) {
                        result.push_str(&resolve_imports(&imported, visited));
                        result.push('\n');
                        continue;
                    } else if let Ok(imported) = fs::read_to_string(path_str) {
                        result.push_str(&resolve_imports(&imported, visited));
                        result.push('\n');
                        continue;
                    }
                }
            }
        }
        result.push_str(line);
        result.push('\n');
    }
    result
}

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 3 {
        println!("Usage: cartanc <command> <file.ctn>");
        println!("Commands:");
        println!("  build   Compile source to .aer bytecode");
        println!("  build-llvm Compile source to LLVM IR (.ll)");
        println!("  build-exe  Compile source to native Windows executable (.exe)");
        println!("  build-gpu  Compile source to native Windows executable with GPU acceleration (.exe)");
        println!("  run     Compile and execute in the Cartan VM");
        println!("  lsp     Start the Language Server on stdio");
        return;
    }

    let command = &args[1];
    let filepath = &args[2];
    
    if command != "build" && command != "run" && command != "build-llvm" && command != "build-exe" && command != "build-gpu" && command != "lsp" {
        println!("Unknown command: {}", command);
        return;
    }

    if command == "lsp" {
        tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap()
            .block_on(async {
                let stdin = tokio::io::stdin();
                let stdout = tokio::io::stdout();
                let (service, socket) = tower_lsp::LspService::build(|client| lsp_server::Backend { client }).finish();
                tower_lsp::Server::new(stdin, stdout, socket).serve(service).await;
            });
        return;
    }

    let raw_source = fs::read_to_string(filepath).expect("Failed to read file");
    let mut visited = std::collections::HashSet::new();
    let source = resolve_imports(&raw_source, &mut visited);

    println!("Compiling Cartan Source...");

    println!("Lexing source code ({} bytes)...", source.len());
    let mut lexer = Lexer::new(&source);
    match lexer.tokenize() {
        Ok(tokens) => {
            println!("Lexing completed: {} tokens.", tokens.len());
            println!("Parsing tokens into AST...");
            let mut parser = Parser::new(tokens);
            match parser.parse() {
                Ok(mut ast) => {
                    println!("Parser Output: AST successfully generated.");
                    // println!("{:#?}", ast);
                    for stmt in &ast {
                        if let crate::ast::Stmt::FunctionDecl(decl) = stmt {
                            println!("Found function: {}", decl.name);
                            if decl.name == "run_causal_pretrain" {
                                println!("DEBUG AST for run_causal_pretrain:");
                                for s in &decl.body.statements {
                                    println!("{:#?}", s);
                                }
                            }
                        }
                    }

                    println!("Running AST Optimizer Pass: Macro Processing...");
                    let mut macro_pass = MacroPass::new();
                    macro_pass.optimize(&mut ast);
                    println!("AST Optimizer: Macros successfully expanded.");

                    println!("Running AST Optimizer Pass: Kernel Fusion...");
                    let mut optimizer = KernelFusionPass::new();
                    optimizer.optimize(&mut ast);
                    println!("AST Optimizer: Kernel Fusion applied.");
                    

                    let mut autodiff = AutoDiffPass::new();
                    autodiff.optimize(&mut ast);
                    println!("AST Optimizer: AutoDiff Unrolling completed.");

                    
                    println!("Running AST Optimizer Pass: Liveness Analysis...");
                    let mut liveness = LivenessPass::new();
                    liveness.optimize(&mut ast);
                    println!("AST Optimizer: Liveness Analysis completed and memory slots assigned.");
                    
                    println!("Running Type Checker...");
                    let mut checker = TypeChecker::new();
                    match checker.check(&mut ast) {
                        Ok(_) => {
                            println!("Type Checker: Symbolic Graph mathematically proven safe.");
                            
                            let mut codegen = CodeGenerator::new();
                            let binary_blob = codegen.generate(&ast);
                            
                            println!("Code Generator Output: {} bytes", binary_blob.len());
                            
                            let _ = std::fs::create_dir_all("build");
                            let _ = std::fs::create_dir_all("release");
                            let path = std::path::Path::new(filepath);
                            let file_stem = path.file_stem().unwrap().to_str().unwrap();
                            
                            if command == "build" {
                                let out_path = format!("build/{}.aer", file_stem);
                                let mut file = File::create(&out_path).expect("Failed to create .aer file");
                                file.write_all(&binary_blob).expect("Failed to write to file");
                                println!("Successfully wrote IR to {}", out_path);
                            } else if command == "build-llvm" {
                                let mut llvm_gen = LLVMGenerator::new();
                                let llvm_ir = llvm_gen.generate(&ast);
                                let out_path = format!("build/{}.ll", file_stem);
                                let mut file = File::create(&out_path).expect("Failed to create .ll file");
                                file.write_all(llvm_ir.as_bytes()).expect("Failed to write to file");
                                println!("Successfully wrote LLVM IR to {}", out_path);
                            } else if command == "build-exe" {
                                let mut llvm_gen = LLVMGenerator::new();
                                let llvm_ir = llvm_gen.generate(&ast);
                                let out_path = format!("build/{}.ll", file_stem);
                                let mut file = File::create(&out_path).expect("Failed to create .ll file");
                                file.write_all(llvm_ir.as_bytes()).expect("Failed to write to file");
                                println!("Successfully wrote LLVM IR to {}. Compiling with Zig...", out_path);
                                
                                let exe_name = format!("release/{}.exe", file_stem);
                                
                                let root = get_cartan_root();
                                let zig_exe = root.join("zig/zig.exe");
                                let mut zig_path = zig_exe.to_str().unwrap().to_string();
                                if !zig_exe.exists() {
                                    if let Some(p) = root.join("zig-windows-x86_64-0.13.0/zig.exe").to_str() {
                                        zig_path = p.to_string();
                                    }
                                }
                                let mut tensor_lib = root.join("lib/cartan_tensor.lib");
                                if !tensor_lib.exists() {
                                    tensor_lib = root.join("tensor_runtime/target/release/cartan_tensor.lib");
                                }
                                let tensor_lib_str = tensor_lib.to_str().unwrap().to_string();
                                
                                let status = Command::new(&zig_path)
                                    .arg("cc")
                                    .arg(&out_path)
                                    .arg("-target")
                                    .arg("x86_64-windows-msvc")
                                    .arg(&tensor_lib_str)
                                    .arg("-o")
                                    .arg(&exe_name)
                                    .arg("-lntdll")
                                    .arg("-luserenv")
                                    .arg("-lws2_32")
                                    .arg("-ladvapi32")
                                    .args(["-lbcrypt", "-lole32", "-loleaut32", "-luser32", "-lgdi32", "-lopengl32", "-ld3d12", "-ldxgi", "-ld3dcompiler"])
                                    .status()
                                    .expect("Failed to execute zig cc");
                                    
                                if status.success() {
                                    println!("Successfully built executable: {}", exe_name);
                                } else {
                                    println!("Clang linkage failed.");
                                }
                            } else if command == "build-gpu" {
                                let mut llvm_gen = LLVMGenerator::new();
                                let llvm_ir = llvm_gen.generate(&ast);
                                let out_path = format!("build/{}.ll", file_stem);
                                let mut file = File::create(&out_path).expect("Failed to create .ll file");
                                file.write_all(llvm_ir.as_bytes()).expect("Failed to write to file");
                                println!("Successfully wrote LLVM IR to {}. Compiling with Zig (GPU Runtime)...", out_path);
                                
                                let exe_name = format!("release/{}.exe", file_stem);
                                
                                let root = get_cartan_root();
                                let zig_exe = root.join("zig/zig.exe");
                                let mut zig_path = zig_exe.to_str().unwrap().to_string();
                                if !zig_exe.exists() {
                                    if let Some(p) = root.join("zig-windows-x86_64-0.13.0/zig.exe").to_str() {
                                        zig_path = p.to_string();
                                    }
                                }
                                let mut gpu_lib = root.join("lib/gpu_runtime.lib");
                                if !gpu_lib.exists() {
                                    gpu_lib = root.join("gpu_runtime/target/release/gpu_runtime.lib");
                                }
                                let gpu_lib_str = gpu_lib.to_str().unwrap().to_string();
                                
                                let status = Command::new(&zig_path)
                                    .arg("cc")
                                    .arg(&out_path)
                                    .arg("-target")
                                    .arg("x86_64-windows-msvc")
                                    .arg(&gpu_lib_str)
                                    .arg("-o")
                                    .arg(&exe_name)
                                    .arg("-lntdll")
                                    .arg("-luserenv")
                                    .arg("-lws2_32")
                                    .arg("-ladvapi32")
                                    .args(["-lbcrypt", "-lole32", "-loleaut32", "-luser32", "-lgdi32", "-lopengl32", "-ld3d12", "-ldxgi", "-ld3dcompiler"])
                                    .status()
                                    .expect("Failed to execute zig cc");
                                    
                                if status.success() {
                                    println!("Successfully built GPU executable: {}", exe_name);
                                } else {
                                    println!("Clang linkage failed for GPU runtime.");
                                }
                                
                                // Optional WGSL generation to satisfy plan
                                let wgsl_gen = WGSLGenerator::new();
                                let wgsl = wgsl_gen.generate(&ast);
                                let wgsl_out_path = format!("build/{}.wgsl", file_stem);
                                let mut file = File::create(&wgsl_out_path).unwrap();
                                file.write_all(wgsl.as_bytes()).unwrap();
                            } else if command == "run" {
                                println!("Executing via Cartan Native Engine...");
                                let mut evaluator = eval::Evaluator::new();
                                evaluator.eval(&ast);
                            }
                        }
                        Err(e) => {
                            println!("Type Checker Failed Fast: {}", e.message);
                        }
                    }
                }
                Err(e) => {
                    println!("Parser Failed Fast: {} at line {}, col {}", e.message, e.span.line, e.span.col_start);
                }
            }
        }
        Err(e) => {
            println!("Lexer Failed Fast: {} at line {}, col {}", e.message, e.span.line, e.span.col_start);
        }
    }
}
