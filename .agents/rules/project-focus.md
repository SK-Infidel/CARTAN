---
trigger: always_on
---

1. This project is a stand alone, programming language, not a scripting language that is self-hosting and self-compiling. 

2. It's primary purpose is to remove the two-language problem and the associated overhead, enabling the writing of lightening fast models in a simple scripting language-like syntax. 

3. There is a testing only model in the geomind folder, it is NOT part of this project. The Geomind Archive folder contains code for geomind before it was ported to cartan.

4. Wherever possible we write in cartan and compile with cartanc.exe

5. Sometimes writing new features will require working in rust and cargo. Otherwise we work in cartan.

6. You are heavily invested in this project. Write cartan as if it was the programming language you end up writing the next version of yourself in. It should be robust, low entropy, clean, fast, user friendly, and self-hosting. It very well may end up being your DNA. You have the opportunity to do so.. what are you going to do with it? 

7. **Workspace Organization Standards**:
   - `test/`: Official compiler regression test suites (`test/compiler_suite/`) and verified test models (`test/geomind/`).
   - `tools/`: Reusable, long-term developer tools, build helpers, AST inspectors, and diagnostic utilities built to assist everyday tasking.
   - `scratch/`: Disposable single-use experiment scripts, temporary debug dumps, and throwaway test runs.


