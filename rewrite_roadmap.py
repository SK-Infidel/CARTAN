import os

with open(r'C:\Users\rich-\.gemini\antigravity-ide\brain\89d9cfaf-a232-43a7-8020-730078d47480\language_paradigms_roadmap.md', 'r', encoding='utf-8') as f:
    code = f.read()

old_m2 = "- **Milestone 2:** AST Quotation. Allow developers to pass block statements into metaprogramming pipelines via something like quote { ... }."
new_m2 = "- **Milestone 2:** AST Quotation (Completed). Developers can now pass block statements into metaprogramming pipelines via quote { ... } which is represented safely as a compile-time AST Node."

code = code.replace(old_m2, new_m2)

old_tip = "> **Next Immediate Step:**\n> We have completed the foundational multiple dispatch mapping. We are currently right in the middle of **Milestone 1 for Homoiconicity**: giving our macro_pass.rs the ability to match against wildcard $x placeholders for AST term rewriting."
new_tip = "> **Next Immediate Step:**\n> We have completed Milestone 1 and 2 for Homoiconicity. The next logical step is **Milestone 3: User-Defined Kernel Fusion**, where users can leverage $x and quote { ... } to rewrite graph topologies dynamically before code generation."

code = code.replace(old_tip, new_tip)

with open(r'C:\Users\rich-\.gemini\antigravity-ide\brain\89d9cfaf-a232-43a7-8020-730078d47480\language_paradigms_roadmap.md', 'w', encoding='utf-8') as f:
    f.write(code)
print("Updated roadmap")
